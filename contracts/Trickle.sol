pragma solidity 0.5.7;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract Trickle {

    using SafeMath for uint256;

    event AgreementCreated(
        uint256 indexed agreementId,
        address token,
        address indexed recipient,
        address indexed sender,
        uint256 start,
        uint256 duration,
        uint256 totalAmount,
        uint256 createdAt
    );
    event AgreementCanceled(
        uint256 indexed agreementId,
        address token,
        address indexed recipient,
        address indexed sender,
        uint256 start,
        uint256 amountReleased,
        uint256 amountCanceled,
        uint256 endedAt
    );
    event Withdraw(
        uint256 indexed agreementId,
        address token,
        address indexed recipient,
        address indexed sender,
        uint256 amountReleased,
        uint256 releasedAt
    );

    uint256 private lastAgreementId;

    struct Agreement {
        uint256 meta; // Metadata packs 3 values to save on storage:
                      // + uint48 start; // Timestamp with agreement start. Up to year 999999+.
                      // + uint48 duration; // Agreement duration. Up to year 999999+.
                      // + uint160 token; // Token address converted to uint.
        uint256 totalAmount;
        uint256 releasedAmount;
        address recipient;
        address sender;
    }

    mapping (uint256 => Agreement) private agreements;

    modifier allowedOnly(uint256 agreementId) {
        Agreement memory record = agreements[agreementId];
        require (msg.sender == record.sender || msg.sender == record.recipient, "Allowed only for sender or recipient");
        _;
    }

    modifier validAgreement(uint256 agreementId) {
        require(agreementId <= lastAgreementId && agreementId != 0, "Invalid agreement specified");
        Agreement memory record = agreements[agreementId];
        (uint48 start, uint48 duration, address token) = decodeMeta(record.meta);
        require(token != address(0x0), "Invalid agreement specified");
        require(record.releasedAmount < record.totalAmount, "No tokens left for withdraw");
        _;
    }

    function createAgreement(IERC20 token, address recipient, uint256 totalAmount, uint48 duration, uint48 start) external {
        require(duration > 0, "Duration should be greater than zero");
        require(totalAmount > 0, "Total amount should be greater than zero");
        require(start > 0, "Start should be greater than zero");
        require(token != IERC20(0x0), "Token should be valid ethereum address");
        require(recipient != address(0x0), "Recipient should be valid ethereum address");

        uint256 agreementId = ++lastAgreementId;

        agreements[agreementId] = Agreement({
            meta: encodeMeta(start, duration, uint256(address(token))),
            recipient: recipient,
            totalAmount: totalAmount,
            sender: msg.sender,
            releasedAmount: 0
        });

        token.transferFrom(agreements[agreementId].sender, address(this), agreements[agreementId].totalAmount);

        Agreement memory record = agreements[agreementId];
        emit AgreementCreated(
            agreementId,
            address(token),
            record.recipient,
            record.sender,
            start,
            duration,
            record.totalAmount,
            block.timestamp
        );
    }

    function getAgreement(uint256 agreementId) external view returns (
        address token,
        address recipient,
        address sender,
        uint256 start,
        uint256 duration,
        uint256 totalAmount,
        uint256 releasedAmount
    ) {
        Agreement memory record = agreements[agreementId];
        (uint48 startMeta, uint48 durationMeta, address tokenMeta) = decodeMeta(record.meta);
        return (tokenMeta, record.recipient, record.sender, startMeta, durationMeta, record.totalAmount, record.releasedAmount);
    }

    function withdrawTokens(uint256 agreementId) public validAgreement(agreementId) {
        Agreement storage record = agreements[agreementId];

        uint256 unreleased = withdrawAmount(agreementId);
        require(unreleased > 0, "Nothing to withdraw");

        record.releasedAmount = record.releasedAmount.add(unreleased);
        (, , address tokenMeta) = decodeMeta(record.meta);
        IERC20(tokenMeta).transfer(record.recipient, unreleased);

        emit Withdraw(
            agreementId,
            tokenMeta,
            record.recipient,
            record.sender,
            unreleased,
            block.timestamp
        );
    }

    function cancelAgreement(uint256 agreementId) external validAgreement(agreementId) allowedOnly(agreementId) {
        Agreement storage record = agreements[agreementId];

        if (withdrawAmount(agreementId) > 0) {
            withdrawTokens(agreementId);
        }

        uint256 releasedAmount = record.releasedAmount;
        uint256 canceledAmount = record.totalAmount.sub(releasedAmount);

        (uint48 startMeta, , address tokenMeta) = decodeMeta(record.meta);
        if (canceledAmount > 0) {
            IERC20(tokenMeta).transfer(record.sender, canceledAmount);
        }

        record.releasedAmount = record.totalAmount;

        emit AgreementCanceled(
            agreementId,
            tokenMeta,
            record.recipient,
            record.sender,
            startMeta,
            releasedAmount,
            canceledAmount,
            block.timestamp
        );
    }

    function withdrawAmount(uint256 agreementId) private view returns (uint256) {
        return availableAmount(agreementId).sub(agreements[agreementId].releasedAmount);
    }

    function availableAmount(uint256 agreementId) private view returns (uint256) {
        Agreement memory record = agreements[agreementId];
        (uint48 startMeta, uint48 durationMeta, ) = decodeMeta(record.meta);
        uint256 start = uint256(startMeta);
        uint256 duration = uint256(durationMeta);
        if (block.timestamp >= start.add(duration)) {
            return record.totalAmount;
        } else if (block.timestamp <= start) {
            return 0;
        } else {
            return record.totalAmount.mul(
                block.timestamp.sub(start)
            ).div(duration);
        }
    }

    function encodeMeta(uint256 start, uint256 duration, uint256 token) private pure returns(uint256 result) {
        require(
            start < 2 ** 48 &&
            duration < 2 ** 48 &&
            token < 2 ** 160,
            "Invalid input sizes to encode"
        );

        result = start;
        result |= duration << (48);
        result |= token << (48 + 48);

        return result;
    }

    function decodeMeta(uint256 meta) private pure returns(uint48 start, uint48 duration, address token) {
        start = uint48(meta);
        duration = uint48(meta >> (48));
        token = address(meta >> (48 + 48));
    }
}
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
        IERC20 token;
        address recipient;
        address sender;
        uint256 start;
        uint256 duration;
        uint256 totalAmount;
        uint256 releasedAmount;
        bool canceled;
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
        require(record.token != IERC20(0x0), "Invalid agreement specified");
        require(record.releasedAmount < record.totalAmount, "No tokens left for withdraw");
        _;
    }

    function createAgreement(IERC20 token, address recipient, uint256 totalAmount, uint256 duration, uint256 start) external {
        require(duration > 0, "Duration should be greater than zero");
        require(totalAmount > 0, "Total amount should be greater than zero");
        require(start > 0, "Start should be greater than zero");
        require(token != IERC20(0x0), "Token should be valid ethereum address");
        require(recipient != address(0x0), "Recipient should be valid ethereum address");

        uint256 agreementId = ++lastAgreementId;

        agreements[agreementId] = Agreement({
            token: token,
            recipient: recipient,
            start: start,
            duration: duration,
            totalAmount: totalAmount,
            sender: msg.sender,
            releasedAmount: 0,
            canceled: false
        });

        token.transferFrom(agreements[agreementId].sender, address(this), agreements[agreementId].totalAmount);

        Agreement memory record = agreements[agreementId];
        emit AgreementCreated(
            agreementId,
            address(record.token),
            record.recipient,
            record.sender,
            record.start,
            record.duration,
            record.totalAmount,
            block.timestamp
        );
    }

    function getAgreement(uint256 agreementId) external view returns (
        IERC20 token,
        address recipient,
        address sender,
        uint256 start,
        uint256 duration,
        uint256 totalAmount,
        uint256 releasedAmount
    ) {
        Agreement memory record = agreements[agreementId];

        return (record.token, record.recipient, record.sender, record.start, record.duration, record.totalAmount, record.releasedAmount);
    }

    function withdrawTokens(uint256 agreementId) public validAgreement(agreementId) {
        Agreement storage record = agreements[agreementId];

        uint256 unreleased = withdrawAmount(agreementId);
        require(unreleased > 0, "Nothing to withdraw");

        record.releasedAmount = record.releasedAmount.add(unreleased);
        record.token.transfer(record.recipient, unreleased);

        emit Withdraw(
            agreementId,
            address(record.token),
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

        if (canceledAmount > 0) {
            record.token.transfer(record.sender, canceledAmount);
        }

        record.releasedAmount = record.totalAmount;

        emit AgreementCanceled(
            agreementId,
            address(record.token),
            record.recipient,
            record.sender,
            record.start,
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
        if (block.timestamp >= record.start.add(record.duration)) {
            return record.totalAmount;
        } else if (block.timestamp <= record.start) {
            return 0;
        } else {
            return record.totalAmount.mul(
                block.timestamp.sub(record.start)
            ).div(record.duration);
        }
    }
}
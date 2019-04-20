pragma solidity 0.5.7;

import "openzeppelin-solidity/contracts/math/SafeMath.sol";
import "openzeppelin-solidity/contracts/token/ERC20/IERC20.sol";

contract Trickle {
    
    using SafeMath for uint256;
    
    event AgreementCreated(uint256 indexed agreementId, address token, address indexed recipient, address indexed sender, uint256 start, uint256 duration, uint256 totalAmount, uint256 createdAt);
    event AgreementCancelled(uint256 indexed agreementId, address token, address indexed recipient, address indexed sender, uint256 start, uint256 amountReleased, uint256 amountCancelled, uint256 endedAt);
    event Withdraw(uint256 indexed agreementId, address token, address indexed recipient, address indexed sender, uint256 amountReleased, uint256 releasedAt);
    
    uint256 private lastAgreementId;
    
    struct Agreement {
        IERC20 token;
        address recipient;
        address sender;
        uint256 start;
        uint256 duration;
        uint256 totalAmount;
        uint256 releasedAmount;
        bool cancelled;
    }
    
    mapping (uint256 => Agreement) private agreements;
    
    modifier senderOnly(uint256 agreementId) {
        require (msg.sender == agreements[agreementId].sender);
        _;
    }
    
    function createAgreement(IERC20 token, address recipient, uint256 totalAmount, uint256 duration, uint256 start) external {
        require(duration > 0);
        require(totalAmount > 0);
        require(start > 0);
        require(token != IERC20(0x0));
        require(recipient != address(0x0));
        
        uint256 agreementId = ++lastAgreementId;
        
        agreements[agreementId] = Agreement({
            token: token,
            recipient: recipient,
            start: start,
            duration: duration,
            totalAmount: totalAmount,
            sender: msg.sender,
            releasedAmount: 0,
            cancelled: false
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
        uint256 releasedAmount,
        bool cancelled
    ) {
        Agreement memory record = agreements[agreementId];
        
        return (record.token, record.recipient, record.sender, record.start, record.duration, record.totalAmount, record.releasedAmount, record.cancelled);
    }
    
    function withdrawTokens(uint256 agreementId) public {
        require(agreementId <= lastAgreementId && agreementId != 0, "Invalid agreement specified");

        Agreement storage record = agreements[agreementId];
        
        require(!record.cancelled);

        uint256 unreleased = withdrawAmount(agreementId);
        require(unreleased > 0);

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
    
    function cancelAgreement(uint256 agreementId) senderOnly(agreementId) external {
        Agreement storage record = agreements[agreementId];

        require(!record.cancelled);

        if (withdrawAmount(agreementId) > 0) {
            withdrawTokens(agreementId);
        }
        
        uint256 releasedAmount = record.releasedAmount;
        uint256 cancelledAmount = record.totalAmount.sub(releasedAmount); 
        
        record.token.transfer(record.sender, cancelledAmount);
        record.cancelled = true;
        
        emit AgreementCancelled(
            agreementId,
            address(record.token),
            record.recipient,
            record.sender,
            record.start,
            releasedAmount,
            cancelledAmount,
            block.timestamp
        );
    }
    
    function withdrawAmount (uint256 agreementId) private view returns (uint256) {
        return availableAmount(agreementId).sub(agreements[agreementId].releasedAmount);
    }
    
    function availableAmount(uint256 agreementId) private view returns (uint256) {
        if (block.timestamp >= agreements[agreementId].start.add(agreements[agreementId].duration)) {
            return agreements[agreementId].totalAmount;
        } else if (block.timestamp <= agreements[agreementId].start) {
            return 0;
        } else {
            return agreements[agreementId].totalAmount.mul(
                block.timestamp.sub(agreements[agreementId].start)
            ).div(agreements[agreementId].duration);
        }
    }
}
pragma solidity ^0.5.0;

/**
 *  @title - CrowdFunding 
 *  @dev   - Contract for CrowdFunding
 */
contract CrowdFunding {
    //initiator of the contract
    address public administrator; 
    
    //target amount
    uint public targetGoalAmount;
    
    //minimum contribution
    uint public minimumContribution;
    
    //current Total of contribution
    uint public totalRaised = 0;
    
    //address of contributors
    mapping(address => uint) public contributors;
    
    //number of contributors
    uint public noOfContributors;
    
    //ending date
    uint public endingDate;
    
    
    //data structs for spending request
    struct SpendingRequest {
        string description;
        address payable receiver;
        uint amount;
        uint noOfApprovers;
        bool completed;
        mapping(address => bool) approverList;
    }
    SpendingRequest[] public spendingRequests;
    
    event SendContributionEvent(address _sender, uint _value);
    event RefundContribution(address _sender, uint _value);
    event CreateSpendingRequestEvent(string _description, uint _amount, address _receiver);
    event ApproveSpendingRequestEvent(uint _indexOfSpendingRequest);
    event SendSpendingRequestEvent(uint _indexOfSpendingRequest);
    
    
    //@dev - initialize all state variables
    constructor(uint _targetGoalAmount, uint _endingDate) public {
        administrator = msg.sender;
        endingDate = now + _endingDate;
        targetGoalAmount = _targetGoalAmount;
        minimumContribution = 10;
    }
    
    //@dev - require that CrowdFunding is still active
    modifier isCrowdFundingActive() {
        require(now <= endingDate, "CrowdFunding is now finished");
        _;
    }
    
    //@dev - require that CrowdFunding is not  active
    modifier isCrowdFundingNotActive() {
        require(now > endingDate, "CrowdFunding is not finished");
        _;
    }
    
    //@dev - if raisedAmount is less than targetGoalAmount and enddate expire
    modifier isTargetGoalAmountReach() {
        require(targetGoalAmount >= totalRaised,"Target goal was not reached");
        _;
    }
    
    //@dev - require that contribution is equal or greater than the minimumContribution
    modifier aboveMinimumContribution() {
        require(minimumContribution <= msg.value, "Your contribution is not enough");
        _;
    }
    
    //@dev - require that the sender has a contributions
    modifier isLegitContributor() {
        require(contributors[msg.sender] > 0, "You are not a contributor");
        _;
    }
    
    //@dev - administrator rights
    modifier isAdministator() {
        require(administrator == msg.sender,"Only administrator can use this function");
        _;
    }
    
    //@dev - send contributions
    function sendContribution() public payable isCrowdFundingActive aboveMinimumContribution {
        
        //increment new contributors
        if(contributors[msg.sender] == 0 ) {
            noOfContributors++;
        }
        
        //add contribution 
        contributors[msg.sender]+= msg.value;
        
        //add msg.value to targetGoalAmount
        totalRaised += msg.value;
     
        emit SendContributionEvent(msg.sender, msg.value);   
    }
    
    //@dev - get total contributions
    function getTotalContributions() public view returns(uint) {
        return address(this).balance;
    }
    
    //@dev - request a refund if CrowdFunding did not react its target after deadline
    function refundContribution() public isLegitContributor isCrowdFundingNotActive isTargetGoalAmountReach {
        uint _value = contributors[msg.sender];
        
        msg.sender.transfer(_value);
        contributors[msg.sender] = 0;
        
        emit RefundContribution(msg.sender, _value);
    }
    
    //@dev - create a new spending request;
    function createSpendingRequest(string memory _description, uint _amount, address payable _receiver) public isAdministator {
        SpendingRequest memory _request = SpendingRequest({
             description: _description,
             receiver : _receiver,
             amount : _amount,
             noOfApprovers: 0,
             completed : false
        });
        spendingRequests.push(_request);
        
        emit CreateSpendingRequestEvent(_description, _amount, _receiver);
    }
    
    
    //@dev - only allowed user to vote if approverList[msg.sender] = false
    modifier contributorNotVoted(uint index) {
        require(spendingRequests[index].approverList[msg.sender] == false,"You already approved the Spending Request");
        _;
    }
    
    //@dev - request is not yet completed
    modifier spendingRequestIsNotCompleted(uint index) {
         require(spendingRequests[index].completed == false,"Spending Request was completed already");
        _;
    }
   
   //@dev - 50% of total votes before getting all approval
   modifier hasEnoughApprovers(uint index) {
       uint _noOfVotes = spendingRequests[index].noOfApprovers;
       require(_noOfVotes > (noOfContributors / 2),"You dont have enough approvers");
       _;
   }
   
    //@dev - approve a spendingRequest
    function approveSpendingRequest(uint _indexOfSpendingRequest) public isLegitContributor contributorNotVoted(_indexOfSpendingRequest) {
        SpendingRequest storage _request = spendingRequests[_indexOfSpendingRequest];
        spendingRequests[_indexOfSpendingRequest].approverList[msg.sender] = true;
        _request.noOfApprovers++;
        
        emit ApproveSpendingRequestEvent(_indexOfSpendingRequest);
    }
    
    function sendSpendingRequest(uint _indexOfSpendingRequest) public isAdministator spendingRequestIsNotCompleted(_indexOfSpendingRequest) hasEnoughApprovers(_indexOfSpendingRequest) {
        SpendingRequest storage _request = spendingRequests[_indexOfSpendingRequest];
        address payable _recipient = _request.receiver;
        _recipient.transfer(_request.amount);
        _request.completed = true;
        
        emit SendSpendingRequestEvent(_indexOfSpendingRequest);
    }
}
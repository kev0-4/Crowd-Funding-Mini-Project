//SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.5.0 < 0.9.0;

contract CrowdFunding{
    mapping(address=>uint) public contributors;//address -> eth
    //this will link adress of contributor to their donation amount
    address public manager;
    uint public minimumContribution;
    uint public deadline;
    uint public target;
    uint public raisedAmount;
    uint public noOfContributors;//help to check if votes >=50%

    struct Request{
        string description;
        address payable receipient;
        uint value;
        bool completed;
        uint noOfVoters;
        mapping(address=>bool) voters;
    }
    mapping(uint=>Request) public requests;
    uint public numRequests;
    //will help if there are multiple request from the manager

    constructor(uint _target, uint _deadline){
        //setting default value for the first time;
        target=_target;
        deadline=block.timestamp+_deadline;//global varirable returning current time stamp of blocl in sec
        minimumContribution=100 wei;
        manager=msg.sender;
    }

    function sendEth() public payable {
        //for contributors to donate eth
        require(block.timestamp < deadline,"Deadline has passed");
        require(msg.value >= minimumContribution,"Minimum contribution is not met");
        if(contributors[msg.sender]==0){
            //if this sender is not in contributors
            noOfContributors++;
        }
        contributors[msg.sender]+=msg.value;
        raisedAmount+=msg.value;//increasing collected value

    }

    function getContractBalance() public view returns(uint){
        return address(this).balance;
    }

    function refund() public {
        require(block.timestamp>deadline && raisedAmount<target," You are not eligible for refund.");
        require(contributors[msg.sender]>0);
        address payable user=payable (msg.sender);
        //this will make current user(msg.sender)'s address eligible for transferring eth
        user.transfer(contributors[msg.sender]);//user.transfer(100);
        contributors[msg.sender]=0;

    }

    modifier onlyManager(){
        //allows only manager to send requests
        require(msg.sender==manager,"Only Manager can call this function");
        _;
    }

    function createRequests(string memory _description, address payable _recipient,uint _value) public onlyManager{
        Request storage newRequest = requests[numRequests];
        //newRequest variable of Request type and will be used ot create requests
        numRequests++;
        newRequest.description=_description;
        newRequest.receipient=_recipient;
        newRequest.value=_value;
        newRequest.completed=false;
        newRequest.noOfVoters=0;

    }

    function voteRequest(uint _requestNo) public {
        //used by contributors to vote on a request
        require(contributors[msg.sender]>0,"You must be a contributor");
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.voters[msg.sender]==false,"You have already voted");
        thisRequest.voters[msg.sender]=true;
        thisRequest.noOfVoters++;
    }

    function makePayment(uint _requestNo) public onlyManager{
        require(raisedAmount>=target);
        Request storage thisRequest=requests[_requestNo];
        require(thisRequest.completed==false,"The request has been completed");
        require(thisRequest.noOfVoters > noOfContributors/2,"Majority does not support");
        thisRequest.receipient.transfer(thisRequest.value);
        thisRequest.completed=true;
    }
}
// SPDX-License-Identifier: MIT
pragma solidity 0.8.16;

contract Consumer{
    function getBalance()public view returns(uint){
        return address(this).balance;
    }

    function deposit() public payable {}
}

contract SimpleSmartContractWallet{

    address payable public owner;

    mapping (address => uint) public allowance;
    mapping (address => bool) public isAllowedToSend;

    mapping (address => bool) public guardians;

    address payable nextOwner;
    uint guardiansResetCount;
    uint public constant confirmationsFromGruardiansForReset = 3;

    mapping (address => mapping (address=>bool)) nextOwnerGuardianVotedBool;

    constructor(){
        owner = payable (msg.sender);
    }

    function proposeNewOwner(address payable _newOwner)public{
        require(guardians[msg.sender], "You are not the guardian of this wallet, aborting");
        require(nextOwnerGuardianVotedBool[_newOwner][msg.sender] == false, "You already voted, aborting");
        if(_newOwner != nextOwner){
            nextOwner = _newOwner;
            guardiansResetCount = 0;
        }
        guardiansResetCount++;

        if(guardiansResetCount >= confirmationsFromGruardiansForReset){
            owner=nextOwner;
            nextOwner= payable (address(0));
        }
    }

    function setGuardian(address _guardian, bool isGuardian) public{
        require(msg.sender==owner, "You are not the owner, aborting");
        guardians[_guardian] = isGuardian;
    }


    function setAllowance(address _for, uint _amount) public {
        require(msg.sender==owner, "You are not the owner, aborting");

        allowance[_for] = _amount;
        if(_amount > 0){
            isAllowedToSend[_for] = true;
        }else{
            isAllowedToSend[_for] = false;
        }
    }


    receive() external payable { }

    function transfer(address payable _to, uint _amount, bytes memory _payload) public returns(bytes memory){
        //require(msg.sender==owner, "You are not the owner, aborting");
        if(msg.sender != owner){
            require(isAllowedToSend[msg.sender], "You are not allowed to send anything from this smart contract, aborting");
            require(allowance[msg.sender] >= _amount, "You are trying to send more than you are allowed to, aborting");

            allowance[msg.sender] -= _amount;
        }

        (bool success, bytes memory returnData) = _to.call{value: _amount}(_payload);
        require(success, "Aborting, call was not succesful");
        return returnData;
    }

}

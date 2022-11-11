//SPDX-License-Identifier: GPL-3.0 
pragma solidity ^0.8.0;

contract Destroy {
    uint public balance;
    address public owner = msg.sender;

    modifier onlyOwner() {
        require(owner == msg.sender, "Not an owner!");
        _;
    }

    function pay() public payable {
        balance += msg.value;
    }

    function destroy() public onlyOwner {
        selfdestruct(payable(msg.sender));
    }
}
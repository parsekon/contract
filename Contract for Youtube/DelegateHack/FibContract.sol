// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./LibFibonacci.sol";


contract FibContract {
	address public libFibonacci;
	address public owner;

	uint public start;
	uint public countUser;
	uint public calculatedFibNumber;

	constructor(address _libFibonacci) {
		libFibonacci = _libFibonacci;
		owner = msg.sender;
	}

	modifier OnlyOwner() { 
		require (msg.sender == owner, "Not an owner"); 
		_; 
	}
	
	function setStart(uint n) external {
		(bool success,) = libFibonacci.delegatecall(
			abi.encodeWithSelector(
				LibFibonacci(libFibonacci).setStart.selector,
				n
			)
		);
		require(success);
	}

	function withdraw() public {
		countUser++;

		(bool success,) = libFibonacci.delegatecall(
			abi.encodeWithSelector(
				LibFibonacci(libFibonacci).setFibonacci.selector,
				countUser
			)
		);

		require(success);
		payable(msg.sender).transfer(calculatedFibNumber * 1 ether / 10 ** 4);
	}

	function withdrawAll() external OnlyOwner {
		uint balance = address(this).balance;
		require(balance > 0, "Not enough ether!");
		payable(owner).transfer(address(this).balance);
	}

	receive() external payable {}
 }
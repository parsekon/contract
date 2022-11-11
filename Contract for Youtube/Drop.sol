// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Drop is Ownable {
	IERC20 public token;
	mapping(address => bool) public successAirdrop;
	uint public amountDrop;

	constructor(address _token, uint _amountDrop) {
		require (address(_token) != address(0), "Address token is zero!");
		token = IERC20(_token);
		amountDrop = _amountDrop;
	}

	event GetAirdrop(address dropper, uint amount);
	event Withdraw(address _owner, uint _withdraw);

	function getDrop() external {
		require(!successAirdrop[msg.sender], "You alredy get drop!");
        successAirdrop[msg.sender] = true;
		token.transfer(msg.sender, amountDrop);

		emit GetAirdrop(msg.sender, amountDrop);
	}

	function getBalance() public view returns(uint) {
		return token.balanceOf(address(this));
	}

	function withdraw() external onlyOwner {
		uint value = getBalance();
        address owner = owner();
		require(value > 0, "Not enough tokens!");
		token.transfer(owner, value);

		emit Withdraw(owner, value);
	}

	function changeAmountDrop(uint _value) external onlyOwner {
		amountDrop = _value;
	}

	function changeToken(address token_) external onlyOwner {
		token = IERC20(token_);
	}

	function changeSuccess(address _dropper) external onlyOwner {
		successAirdrop[_dropper] = false;
	}

	function renounceOwnership() public pure override {
		revert("Not success!");
	}
}
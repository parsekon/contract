// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Airdrop is Ownable {
	IERC20 public token;
	mapping (address => bool) public successAirdrops;
	uint public amountAirdrop;
	

	constructor(address token_, uint _amountAirdrop) {
		require(token_ != address(0x0));
		token = IERC20(token_);
        amountAirdrop = _amountAirdrop;
	}

	modifier airdropNotMake() { 
		require (!successAirdrops[msg.sender], "Your address already received airdrop!"); 
		_; 
	}

	event AirdropReceived(address droper, uint value);
    event Withdraw(uint amount);
	
    // To distribute tokens, it is necessary to transfer the required number of tokens to the contract address
    // Any address gets an airdrop
	function getAirdrop() external airdropNotMake {
        successAirdrops[msg.sender] = true;
		token.transfer(msg.sender, amountAirdrop);
		emit AirdropReceived(msg.sender, amountAirdrop);
	}

    // Changing the token
    function changeToken(address newToken) external onlyOwner {
        token = IERC20(newToken);
    }

	// Changing the amount of airdrop
	function changeAmountAirdrop(uint _amount) external onlyOwner {
		amountAirdrop = _amount;
	}

	// Removes the address from the list of addresses that received airdrop
	function cancelSuccessAirdrop(address _droper) external onlyOwner {
		require(successAirdrops[_droper], "This address not received airdrop!");
		successAirdrops[_droper] = false;
	}

	// Checking the balance of tokens on the contract
	function getBalance() external view returns(uint) {
		return token.balanceOf(address(this));
	}

    // Withdrawal of tokens to the wallet of the contract creator
	function withdrawToken() external onlyOwner {
		uint _amount = token.balanceOf(address(this));
		require(_amount > 0, "Not enough tokens!");
		token.transfer(msg.sender, _amount);
        emit Withdraw(_amount);
	}

    function renounceOwnership() public pure override  {
        revert();
    }

	fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }
}
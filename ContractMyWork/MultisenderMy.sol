// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";


contract Multisender is Ownable {
	using SafeMath for uint;



	event WithdrawToken(address _token, address _recipient, uint _value);

	

	function withsrawToken(address _token, address _recipient) external onlyOwner {
		IERC20 token = IERC20(_token);
		uint _balance = token.balanceOf(address(this));
		require(_token != address(0));
		require(_recipient != address(0));
		require(_balance > 0);

		token.transfer(_recipient, _balance);

		emit WithdrawToken(_token, _recipient, _balance);
	}


	function getAllowanceToken(address _ownerToken, address _token) external view returns(uint) {
		IERC20 _tokenForSend = IERC20(_token);
		return _tokenForSend.allowance(_ownerToken, address(this));
	}


    function stringAreEqual(string memory _one, string memory _two) internal pure returns(bool) {
    	bytes32 hashOne = keccak256(abi.encodePacked(_one));
    	bytes32 hashTwo = keccak256(abi.encodePacked(_two));
    	return hashOne == hashTwo;
    }


	fallback() external payable {
        revert();
    }


    receive() external payable {
        revert();
    }


	function renounceOwnership() public pure override {
		revert();
	}
}
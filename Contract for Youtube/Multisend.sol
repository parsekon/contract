// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Multisender is Ownable {
    IERC20 public token;
    // address[] public addressForSend;
    // uint[] public amount;

    event SendSingleSuccess(string success, uint lengthArr, uint amount);
    event SendSingleBatch(string successBatch, uint lengthArrBatch);
    event ChangeToken(address newToken);

    constructor(address _token) {
        token = IERC20(_token);
    }

    function changeToken(address _token_) external onlyOwner {
        require(_token_ != address(0), "Address should not be zero!");
        token = IERC20(_token_);

        emit ChangeToken(_token_);
    }

    function multisendSingle(address[] memory _addressForSend, uint _amount) external {
        for(uint i = 0; i < _addressForSend.length; i++) {
            require(_addressForSend[i] != address(0));
            token.transferFrom(msg.sender, _addressForSend[i], _amount);
        }

        emit SendSingleSuccess("Success!", _addressForSend.length, _amount);
    }

    function multisendBatch(address[] memory _addressForSend, uint[] memory value) external {
        for(uint i = 0; i < _addressForSend.length; i++) {
            require(_addressForSend[i] != address(0));
            require(_addressForSend.length == value.length);
            token.transferFrom(msg.sender, _addressForSend[i], value[i]);
        }

        emit SendSingleBatch("Success!", _addressForSend.length);
    }
}
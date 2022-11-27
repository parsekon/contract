// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

//  Если вызывать функцию approve из контракта, msg.sender для токена будет адрес контракта, который обращается к функции
//  для того чтобы это работало, необходимо переопределять функцию approve в токене
// что вероятно не безопасно, тк каждый контракт может вызвать такую функцию

// пример токена

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TokenDrop is ERC20 {
    constructor(address _toAllToken) ERC20("TokenDrop", "TAD") {
        _mint(_toAllToken, 100000000 * 10 ** decimals());
    }

    function decimals() public pure override returns (uint8) {
        return 0;
    }

    // но в таком варианте функция дает возможность любому адресу аппрувить любой адрес, даже не свой
    function approve(address _owner, address spender, uint256 amount) public returns (bool) {
        _approve(_owner, spender, amount);
        return true;
    }
}

//////////////////////////////////////

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

interface IToken {
    function approve(address _owner, address spender, uint256 amount) external returns (bool);
}

contract ApproveContract {
    address private _TOKEN;

    function setToken(address _token) external {
        _TOKEN = _token;
    }

    function getApprove(uint _amount) external {
        IToken(_TOKEN).approve(msg.sender, address(this), _amount);
    }

    function getAllowance() public view returns(uint _approveValue) {
        _approveValue = ERC20(_TOKEN).allowance(msg.sender, address(this));
    }

    function deposit(uint _amount) external {
        require(getAllowance() >= _amount, "Not approved");
        ERC20(_TOKEN).transferFrom(msg.sender, address(this), _amount);
    }

    function balance() external view returns (uint _balance) {
        _balance = ERC20(_TOKEN).balanceOf(address(this));
    }
}
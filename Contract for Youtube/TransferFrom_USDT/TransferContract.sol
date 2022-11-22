// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract TransferUSDT is Ownable {

    IERC20 private immutable USDTContract;

    mapping(address => uint) private balances;

    constructor(address _usdt) {
        USDTContract = IERC20(_usdt);
    }

    function deposit(uint _amount) external {
        require(getAllowance() >= _amount);
        USDTContract.transferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] += _amount;
    }

    function balanceUSDT() public view returns(uint) {
        return USDTContract.balanceOf(address(this));
    }


    function getAllowance() public view returns(uint) {
        return USDTContract.allowance(msg.sender, address(this));
    }
}



// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/access/Ownable.sol";
import "openzeppelin-solidity/contracts/token/ERC20/utils/SafeERC20.sol";


contract USDT_pool is Ownable {
    using SafeERC20 for IERC20;

    IERC20 private immutable USDTContract;

    mapping(address => uint) private balances;

    constructor(address _usdt) {
        USDTContract = IERC20(_usdt);
    }

    function deposit(uint _amount) external {
        require(getAllowance() >= _amount);
        USDTContract.safeTransferFrom(msg.sender, address(this), _amount);
        balances[msg.sender] += _amount;
    }

    function balanceUSDT() public view returns(uint) {
        return USDTContract.balanceOf(address(this));
    }


    function getAllowance() public view returns(uint) {
        return USDTContract.allowance(msg.sender, address(this));
    }
}


// https://github.com/aave/aave-protocol/blob/master/contracts/lendingpool/LendingPoolCore.sol#L431
// https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/token/ERC20/utils/SafeERC20.sol

//  https://ethereum.stackexchange.com/questions/64517/how-to-transfer-and-transferfrom-on-the-tether-smart-contract-from-another-smart
// https://blog-coinfabrik-com.translate.goog/blockchain/blockchain-development/smart-contract-short-address-attack-mitigation-failure/?_x_tr_sl=auto&_x_tr_tl=ru&_x_tr_hl=ru
// https://ethereum-stackexchange-com.translate.goog/questions/20828/validating-msg-data-length?_x_tr_sl=auto&_x_tr_tl=ru&_x_tr_hl=ru
// https://etherscan.io/address/0xdac17f958d2ee523a2206206994597c13d831ec7#readContract


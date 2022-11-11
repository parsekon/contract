// SPDX-License-Identifier: AGPL-3.0
pragma solidity ^0.8.0;

import "./FlashLoanReceiverBase.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract TestFlashLoanAave is FlashLoanReceiverBase {
    Target public target;
    address tokenAddress;

    constructor(IPoolAddressesProvider addressProvider, address _target, address _tokenAddress)
        FlashLoanReceiverBase(addressProvider)
    {
        target = Target(_target);
        tokenAddress = _tokenAddress;
    }

    function flashLoan(uint256 amount) public {
        address[] memory assets = new address[](1);
        assets[0] = tokenAddress;

        uint[] memory amounts = new uint[](1);
        amounts[0] = amount;

        uint[] memory modes = new uint[](1);
        modes[0] = 0;

        address onBehalfOf = address(this);

        bytes memory params = ""; // extra data to pass abi.encode(...)
        uint16 referralCode = 0;

        POOL.flashLoan(
            address(this), // The address of the contract receiving the funds, implementing the IFlashLoanReceiver interface
            assets,        // The addresses of the assets being flash-borrowed
            amounts,       // The amounts amounts being flash-borrowed
            modes,         // Types of the debt to open if the flash loan is not returned
            onBehalfOf,    // The address  that will receive the debt in the case of using on `modes` 1 or 2
            params,        // Packed params to pass to the receiver as extra information
            referralCode   // Code used to register the integrator originating the operation, for potential rewards.
        );
    }

    function executeOperation(
        address[] calldata assets,
        uint256[] calldata amounts,
        uint256[] calldata premiums,
        address initiator,
        bytes calldata params
    ) external override returns (bool) {
        target.check();
        for (uint i = 0; i < assets.length; i++) {
            uint amountOwing = amounts[i] + premiums[i];
            IERC20(assets[i]).approve(address(POOL), amountOwing);
        }
        return true;
    }
}

contract Target {
    ERC20 usdt = ERC20(0xc2132D05D31c914a87C6611C10748AEb04B58e8F);

    string public phrase = "You have nothing";
    uint256 public balance;

    function check() public {
        balance = usdt.balanceOf(msg.sender);
        phrase = "You are here. Check balance";
    }
}

// usdt 0xc2132D05D31c914a87C6611C10748AEb04B58e8F;
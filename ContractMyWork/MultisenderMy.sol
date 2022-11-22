// SPDX-License-Identifier: MIT
pragma solidity 0.8.15;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";

contract Multisender is Ownable {
    using SafeMath for uint;

    mapping(address => uint) public tokenCheckDrops;

    mapping(address => bool) public isPremiumMember;
    mapping(address => string) public isAffiliatedWith;
    mapping(address => bool) public isAffiliate;
    mapping(string => address) public affiliateCodeToAddr;
    mapping(string => bool) public affiliateCodeExists;
    mapping(address => string) public affiliateCodeOfAddr;

    uint public oneDropPrice;
    uint public rate;
    uint public premiumMemberFee;

    event WithdrawToken(address _token, address _recipient, uint _value);
    event TokenAirdrop(
        address indexed by,
        address indexed tokenAddress,
        uint totalTransfers
    );
    event CommissionPaid(address indexed to, uint value);
    event EthAirdrop(address indexed by, uint totalTransfers, uint ethValue);
    event ChangeRate(uint from, uint to);
    event AffiliatePartnershipRevoked(
        address indexed affiliate,
        string indexed affiliateCode
    );
    event NewAffiliatePartnership(
        address indexed newAffiliate,
        string indexed affiliateCode
    );
    event PremiumMemberFeeUpdated(uint newFee);
    event NewPremiumMembership(address indexed premiumMember);
    event RefundIssued(address indexed to, uint totalWei);

    constructor() {
        rate = 10000;
        oneDropPrice = 1e14;
        premiumMemberFee = 25e16;
    }

    function sendSingleValueEth(
        address[] memory _droper,
        uint _value,
        string memory _afCode
    ) public payable {
        uint price = _droper.length.mul(oneDropPrice);
        uint totalCost = _value.mul(_droper.length).add(price);

        require(
            msg.value >= totalCost || isPremiumMember[msg.sender],
            "Not enough ETH sent with transaction!"
        );

        _afCode = processAffiliateCode(_afCode);

        if (!isPremiumMember[msg.sender]) {
            distributeCommission(_droper.length, _afCode);
        }

        giveChange(totalCost);

        for (uint i = 0; i < _droper.length; i++) {
            if (_droper[i] != address(0)) {
                payable(_droper[i]).transfer(_value);
            }
        }

        emit EthAirdrop(msg.sender, _droper.length, _value.mul(_droper.length));
    }

    function sendMultiValueEth(
        address[] memory _droper,
        uint[] memory _values,
        string memory _afCode
    ) public payable {
        require(
            _droper.length == _values.length,
            "Total member of droper and values are not equal"
        );

        uint totalEthValue = _getTotalEthValue(_values);
        uint price = _droper.length.mul(oneDropPrice);
        uint totalCost = totalEthValue.add(price);

        require(
            msg.value >= totalCost || isPremiumMember[msg.sender],
            "Not enough Eth send with transaction!"
        );

        _afCode = processAffiliateCode(_afCode);

        if (!isPremiumMember[msg.sender]) {
            distributeCommission(_droper.length, _afCode);
        }

        giveChange(totalCost);

        for (uint i = 0; i < _droper.length; i++) {
            if (_droper[i] != address(0) && _values[i] > 0) {
                payable(_droper[i]).transfer(_values[i]);
            }
        }

        emit EthAirdrop(msg.sender, _droper.length, totalEthValue);
    }

    function sendSingleValueToken(
        address _token,
        address[] memory _droper,
        uint _value,
        string memory _afCode
    ) public payable {
        IERC20 token = IERC20(_token);

        uint price = _droper.length.mul(oneDropPrice);

        require(
            msg.value >= price ||
                tokenHasFreeTrial(_token) ||
                isPremiumMember[msg.sender],
            "Yon can not send Airdrop"
        );

        giveChange(price);

        _afCode = processAffiliateCode(_afCode);

        for (uint i = 0; i < _droper.length; i++) {
            if (_droper[i] != address(0)) {
                token.transferFrom(msg.sender, _droper[i], _value);
            }
        }
        if (tokenHasFreeTrial(_token)) {
            tokenCheckDrops[_token] = tokenCheckDrops[_token].add(
                _droper.length
            );
        } else {
            if (!isPremiumMember[msg.sender]) {
                distributeCommission(_droper.length, _afCode);
            }
        }

        emit TokenAirdrop(msg.sender, _token, _droper.length);
    }

    function sendMultiValueToken(
        address _token,
        address[] memory _droper,
        uint[] memory _values,
        string memory _afCode
    ) public payable {
        IERC20 token = IERC20(_token);
        require(
            _droper.length == _values.length,
            "Total number droper and values are not equel!"
        );

        uint price = _droper.length.mul(oneDropPrice);

        require(
            msg.value >= price ||
                tokenHasFreeTrial(_token) ||
                isPremiumMember[msg.sender],
            "Yon can not send Airdrop"
        );

        giveChange(price);

        _afCode = processAffiliateCode(_afCode);

        for (uint i = 0; i < _droper.length; i++) {
            if (_droper[i] != address(0) && _values[i] > 0) {
                token.transferFrom(msg.sender, _droper[i], _values[i]);
            }
        }

        if (tokenHasFreeTrial(_token)) {
            tokenCheckDrops[_token] = tokenCheckDrops[_token].add(
                _droper.length
            );
        } else {
            if (isPremiumMember[msg.sender]) {
                distributeCommission(_droper.length, _afCode);
            }
        }

        emit TokenAirdrop(msg.sender, _token, _droper.length);
    }

    function withdrawToken(address _token, address _recipient)
        external
        onlyOwner
    {
        IERC20 token = IERC20(_token);
        uint _balance = token.balanceOf(address(this));
        require(_token != address(0));
        require(_recipient != address(0));
        require(_balance > 0);

        token.transfer(_recipient, _balance);

        emit WithdrawToken(_token, _recipient, _balance);
    }

    function getAllowanceToken(address _ownerToken, address _token)
        external
        view
        returns (uint)
    {
        IERC20 _tokenForSend = IERC20(_token);
        return _tokenForSend.allowance(_ownerToken, address(this));
    }

    function stringsAreEqual(string memory _one, string memory _two)
        internal
        pure
        returns (bool)
    {
        bytes32 hashOne = keccak256(abi.encodePacked(_one));
        bytes32 hashTwo = keccak256(abi.encodePacked(_two));
        return hashOne == hashTwo;
    }

    function tokenHasFreeTrial(address _token) public view returns (bool) {
        return tokenCheckDrops[_token] < 100;
    }

    function getRemainingTrialDrops(address _token) public view returns (uint) {
        if (tokenHasFreeTrial(_token)) {
            uint maxTrialDrops = 100;
            return maxTrialDrops.sub(tokenCheckDrops[_token]);
        }
        return 0;
    }

    function giveChange(uint _price) internal {
        if (msg.value > _price) {
            uint change = msg.value.sub(_price);
            payable(msg.sender).transfer(change);
            emit RefundIssued(msg.sender, change);
        }
    }

    function processAffiliateCode(string memory _afCode)
        internal
        returns (string memory)
    {
        if (
            stringsAreEqual(isAffiliatedWith[msg.sender], "void") ||
            !isAffiliate[affiliateCodeToAddr[_afCode]]
        ) {
            isAffiliatedWith[msg.sender] = "void";
            return "void";
        }

        if (
            !stringsAreEqual(_afCode, "") &&
            stringsAreEqual(isAffiliatedWith[msg.sender], "") &&
            affiliateCodeExists[_afCode]
        ) {
            if (affiliateCodeToAddr[_afCode] == msg.sender) {
                return "void";
            }
            isAffiliatedWith[msg.sender] = _afCode;
        }

        if (
            stringsAreEqual(_afCode, "") &&
            !stringsAreEqual(isAffiliatedWith[msg.sender], "")
        ) {
            _afCode = isAffiliatedWith[msg.sender];
        }

        if (stringsAreEqual(_afCode, "") || !affiliateCodeExists[_afCode]) {
            isAffiliatedWith[msg.sender] = "void";
            _afCode = "void";
        }

        return _afCode;
    }

    function distributeCommission(uint _drops, string memory _afCode) internal {
        address owner = owner();
        if (
            !stringsAreEqual(_afCode, "void") &&
            isAffiliate[affiliateCodeToAddr[_afCode]]
        ) {
            uint profitSplit = _drops.mul(oneDropPrice).div(2);
            payable(owner).transfer(profitSplit);
            payable(affiliateCodeToAddr[_afCode]).transfer(profitSplit);
            emit CommissionPaid(affiliateCodeToAddr[_afCode], profitSplit);
        } else {
            payable(owner).transfer(_drops.mul(oneDropPrice));
        }
    }

    function _getTotalEthValue(uint[] memory _values)
        internal
        pure
        returns (uint)
    {
        uint totalVal = 0;
        for (uint i = 0; i < _values.length; i++) {
            totalVal = totalVal.add(_values[i]);
        }
        return totalVal;
    }

    function setRate(uint _newRate) public onlyOwner {
        require(_newRate != rate && _newRate > 0);

        emit ChangeRate(rate, _newRate);

        rate = _newRate;
        uint eth = 1 ether;
        oneDropPrice = eth.div(rate);
    }

    // Affiliate Programm
    function addAffiliate(address _addr, string memory _code) public onlyOwner {
        require(!isAffiliate[_addr], "Address is already an affiliate.");
        require(_addr != address(0));
        require(!affiliateCodeExists[_code]);
        affiliateCodeExists[_code] = true;
        isAffiliate[_addr] = true;
        affiliateCodeToAddr[_code] = _addr;
        affiliateCodeOfAddr[_addr] = _code;
        emit NewAffiliatePartnership(_addr, _code);
    }

    function removeAffiliate(address _addr) public onlyOwner {
        require(isAffiliate[_addr]);
        isAffiliate[_addr] = false;
        affiliateCodeToAddr[affiliateCodeOfAddr[_addr]] = address(0);
        emit AffiliatePartnershipRevoked(_addr, affiliateCodeOfAddr[_addr]);
        affiliateCodeOfAddr[_addr] = "No longer an affiliate partner";
    }

    // Premium Member
    function grantPremiumMembership(address _addr) public onlyOwner {
        require(!isPremiumMember[_addr], "Is already premiumMember member");
        isPremiumMember[_addr] = true;
        emit NewPremiumMembership(_addr);
    }

    function becomePremiumMember(string memory _afCode) public payable {
        require(
            !isPremiumMember[msg.sender],
            "Is already premiumMember member"
        );
        require(
            msg.value >= premiumMemberFee,
            string(
                abi.encodePacked(
                    "premiumMember fee is: ",
                    uint2str(premiumMemberFee),
                    ". Not enough ETH sent. ",
                    uint2str(msg.value)
                )
            )
        );

        isPremiumMember[msg.sender] = true;

        _afCode = processAffiliateCode(_afCode);

        giveChange(premiumMemberFee);

        address owner = owner();

        if (
            !stringsAreEqual(_afCode, "void") &&
            isAffiliate[affiliateCodeToAddr[_afCode]]
        ) {
            payable(owner).transfer(premiumMemberFee.mul(80).div(100));
            uint commission = premiumMemberFee.mul(20).div(100);
            payable(affiliateCodeToAddr[_afCode]).transfer(commission);
            emit CommissionPaid(affiliateCodeToAddr[_afCode], commission);
        } else {
            payable(owner).transfer(premiumMemberFee);
        }
        emit NewPremiumMembership(msg.sender);
    }

    function uint2str(uint _i)
        internal
        pure
        returns (string memory _uintAsString)
    {
        if (_i == 0) {
            return "0";
        }
        uint j = _i;
        uint len;
        while (j != 0) {
            len++;
            j /= 10;
        }
        bytes memory bstr = new bytes(len);
        uint k = len;
        while (_i != 0) {
            k = k - 1;
            uint8 temp = (48 + uint8(_i - (_i / 10) * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        return string(bstr);
    }

    function setPremiumMemberFee(uint _fee) public onlyOwner {
        require(_fee > 0 && _fee != premiumMemberFee);
        premiumMemberFee = _fee;
        emit PremiumMemberFeeUpdated(_fee);
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

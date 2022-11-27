// SPDX-License-Identifier: MIT
pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC1155/IERC1155.sol";


// нужно реализовать чтобы по реферальному коду человек получал скидку 15%, а пригласивший процент

contract Multisender is Ownable {
    mapping (address => uint256) public tokenTrialDrops;
    mapping (address => uint256) public userTrialDrops;

    mapping (address => uint256) public premiumMembershipDiscount;
    mapping (address => uint256) public membershipExpiryTime;

    mapping (address => bool) public isGrantedPremiumMember;

    mapping (address => bool) public isListedToken;
    mapping (address => uint256) public tokenListingFeeDiscount;

    mapping (address => bool) public isGrantedListedToken;

    mapping (address => bool) public isAffiliate;
    mapping (string => address) public affiliateCodeToAddr;
    mapping (string => bool) public affiliateCodeExists;
    mapping (address => string) public affiliateCodeOfAddr;
    mapping (address => string) public isAffiliatedWith;
    mapping (string => uint256) public commissionPercentage;

    uint256 public oneDayMembershipFee;
    uint256 public sevenDayMembershipFee;
    uint256 public oneMonthMembershipFee;
    uint256 public lifetimeMembershipFee;
    uint256 public tokenListingFee;
    uint256 public rate;
    uint256 public dropUnitPrice;

    event TokenAirdrop(address indexed by, address indexed tokenAddress, uint256 totalTransfers);
    event EthAirdrop(address indexed by, uint256 totalTransfers, uint256 ethValue);
    event NftAirdrop(address indexed by, address indexed nftAddress, uint256 totalTransfers);
    event RateChanged(uint256 from, uint256 to);
    event RefundIssued(address indexed to, uint256 totalWei);
    event ERC20TokensWithdrawn(address token, address sentTo, uint256 value);
    event CommissionPaid(address indexed to, uint256 value);
    event NewPremiumMembership(address indexed premiumMember);
    event NewAffiliatePartnership(address indexed newAffiliate, string indexed affiliateCode);
    event AffiliatePartnershipRevoked(address indexed affiliate, string indexed affiliateCode);
    
    constructor() {
        rate = 3000;
        dropUnitPrice = 333333333333333; 
        oneDayMembershipFee = 9e17;
        sevenDayMembershipFee = 125e16;
        oneMonthMembershipFee = 2e18;
        lifetimeMembershipFee = 25e17;
        tokenListingFee = 5e18;
    }


    // Affilate programm

    function addAffiliate(address _addr, string memory _code, uint256 _percentage) public onlyOwner returns(bool success) {
        require(!isAffiliate[_addr], "Address is already an affiliate.");
        require(_addr != address(0), "0x00 address not allowed");
        require(!affiliateCodeExists[_code], "Affiliate code already exists!");
        require(_percentage <= 100 && _percentage > 0, "Percentage must be > 0 && <= 100");
        affiliateCodeExists[_code] = true;
        isAffiliate[_addr] = true;
        affiliateCodeToAddr[_code] = _addr;
        affiliateCodeOfAddr[_addr] = _code;
        commissionPercentage[_code] = _percentage;
        emit NewAffiliatePartnership(_addr,_code);
        return true;
    }


    function changeAffiliatePercentage(address _addressOfAffiliate, uint256 _percentage) public onlyOwner returns(bool success) { 
        require(isAffiliate[_addressOfAffiliate]);
        string storage affCode = affiliateCodeOfAddr[_addressOfAffiliate];
        commissionPercentage[affCode] = _percentage;
        return true;
    }
    

    function removeAffiliate(address _addr) public onlyOwner returns(bool success) {
        require(isAffiliate[_addr]);
        isAffiliate[_addr] = false;
        affiliateCodeToAddr[affiliateCodeOfAddr[_addr]] = address(0);
        emit AffiliatePartnershipRevoked(_addr, affiliateCodeOfAddr[_addr]);
        affiliateCodeOfAddr[_addr] = "No longer an affiliate partner";
        return true;
    }


    // Free Trial Drops
    function tokenHasFreeTrial(address _addressOfToken) public view returns(bool hasFreeTrial) {
        return tokenTrialDrops[_addressOfToken] < 100;
    }


    function userHasFreeTrial(address _addressOfUser) public view returns(bool hasFreeTrial) {
        return userTrialDrops[_addressOfUser] < 100;
    }


    function getRemainingTokenTrialDrops(address _addressOfToken) public view returns(uint256 remainingTrialDrops) {
        if(tokenHasFreeTrial(_addressOfToken)) {
            uint256 maxTrialDrops =  100;
            return maxTrialDrops - tokenTrialDrops[_addressOfToken];
        } 
        return 0;
    }


    function getRemainingUserTrialDrops(address _addressOfUser) public view returns(uint256 remainingTrialDrops) {
        if(userHasFreeTrial(_addressOfUser)) {
            uint256 maxTrialDrops =  100;
            return maxTrialDrops - userTrialDrops[_addressOfUser];
        }
        return 0;
    }


    // Set
    function setRate(uint256 _newRate) public onlyOwner returns(bool success) {
        require(
            _newRate != rate 
            && _newRate > 0
        );
        emit RateChanged(rate, _newRate);
        rate = _newRate;
        uint256 eth = 1 ether;
        dropUnitPrice = eth / rate;
        return true;
    }

    function distributeCommission(uint256 _profits, string memory _afCode) internal {
        if(!stringsAreEqual(_afCode,"void") && isAffiliate[affiliateCodeToAddr[_afCode]]) {
            uint256 commission = _profits * commissionPercentage[_afCode] / 100;
            payable(owner()).transfer(_profits - commission);
            payable(affiliateCodeToAddr[_afCode]).transfer(commission);
            emit CommissionPaid(affiliateCodeToAddr[_afCode], commission);
        } else {
            payable(owner()).transfer(_profits);
        }
    }

    function processAffiliateCode(string memory _afCode) internal returns(string memory code) {
        if(stringsAreEqual(isAffiliatedWith[msg.sender], "void") || !isAffiliate[affiliateCodeToAddr[_afCode]]) {
            isAffiliatedWith[msg.sender] = "void";
            return "void";
        }
        if(!stringsAreEqual(_afCode, "") && stringsAreEqual(isAffiliatedWith[msg.sender],"") 
                                                                && affiliateCodeExists[_afCode]) {
            if(affiliateCodeToAddr[_afCode] == msg.sender) {
                return "void";
            }
            isAffiliatedWith[msg.sender] = _afCode;
        }
        if(stringsAreEqual(_afCode,"") && !stringsAreEqual(isAffiliatedWith[msg.sender],"")) {
            _afCode = isAffiliatedWith[msg.sender];
        } 
        if(stringsAreEqual(_afCode,"") || !affiliateCodeExists[_afCode]) {
            isAffiliatedWith[msg.sender] = "void";
            _afCode = "void";
        }
        return _afCode;
    }

    // Withdrawal eth and erc20
    function withdrawFunds() public onlyOwner returns(bool success) {
        payable(owner()).transfer(address(this).balance);
        return true;
    }

    function withdrawERC20Tokens(address _addressOfToken,  address _recipient, uint256 _value) public onlyOwner returns(bool success){
        IERC20 token = IERC20(_addressOfToken);
        token.transfer(_recipient, _value);
        emit ERC20TokensWithdrawn(_addressOfToken, _recipient, _value);
        return true;
    }

    function giveChange(uint256 _price) internal {
        if(msg.value > _price) {
            uint256 change = msg.value - _price;
            payable(msg.sender).transfer(change);
        }
    }

    // Main function
    // function airdropNativeCurrency(address[] memory _recipients, uint256[] memory _values, uint256 _totalToSend, string memory _afCode) public payable returns(bool success) {
    //     require(_recipients.length == _values.length, "Total number of recipients and values are not equal");
    //     uint256 totalEthValue = _totalToSend;
    //     uint256 price = _recipients.length * dropUnitPrice;
    //     uint256 totalCost = totalEthValue + price;
    //     bool userHasTrial = userHasFreeTrial(msg.sender);
    //     bool isVIP = checkIsPremiumMember(msg.sender) == true;
    //     require(
    //         msg.value >= totalCost || isVIP || userHasTrial, 
    //         "Not enough funds sent with transaction!"
    //     );
    //     _afCode = processAffiliateCode(_afCode);
    //     if(!isVIP && !userHasTrial) {
    //         distributeCommission(price, _afCode);
    //     }
    //     if((isVIP || userHasTrial) && msg.value > _totalToSend) {
    //         payable(msg.sender).transfer((msg.value) - _totalToSend);
    //     } else {
    //         giveChange(totalCost);
    //     }
    //     for(uint i = 0; i < _recipients.length; i++) {
    //         payable(_recipients[i]).transfer(_values[i]);
    //     }
    //     if(userHasTrial) {
    //         userTrialDrops[msg.sender] = userTrialDrops[msg.sender] + _recipients.length;
    //     }
    //     emit EthAirdrop(msg.sender, _recipients.length, totalEthValue);
    //     return true;
    // }


    function erc20Airdrop(address _addressOfToken,  address[] memory _recipients, uint256[] memory _values, uint256 _totalToSend, bool _isDeflationary, string memory _afCode) public payable returns(bool success) {
        string memory afCode = processAffiliateCode(_afCode);
        IERC20 token = IERC20(_addressOfToken);
        require(_recipients.length == _values.length, "Total number of recipients and values are not equal");
        uint256 price = _recipients.length * dropUnitPrice;

        bool eligibleForFreeTrial = tokenHasFreeTrial(_addressOfToken) && userHasFreeTrial(msg.sender);
        require(
            msg.value >= price || tokenHasFreeTrial(_addressOfToken) || userHasFreeTrial(msg.sender),
            "Not enough funds sent with transaction!"
        );
        if(eligibleForFreeTrial && msg.value > 0) {
            payable(msg.sender).transfer(msg.value);
        } else {
            giveChange(price);
        }

        if(!_isDeflationary) {
            token.transferFrom(msg.sender, address(this), _totalToSend);
            for(uint i = 0; i < _recipients.length; i++) {
                token.transfer(_recipients[i], _values[i]);
            }
            if(token.balanceOf(address(this)) > 0) {
                token.transfer(msg.sender,token.balanceOf(address(this)));
            }
        } else {
            for(uint i=0; i < _recipients.length; i++) {
                token.transferFrom(msg.sender, _recipients[i], _values[i]);
            }
        }
        

        if(tokenHasFreeTrial(_addressOfToken)) {
            tokenTrialDrops[_addressOfToken] = tokenTrialDrops[_addressOfToken] + _recipients.length;
        }
        if(userHasFreeTrial(msg.sender)) {
            userTrialDrops[msg.sender] = userTrialDrops[msg.sender] + _recipients.length;
        }
        if(!eligibleForFreeTrial) {
            distributeCommission(_recipients.length * dropUnitPrice, afCode);
        }
        emit TokenAirdrop(msg.sender, _addressOfToken, _recipients.length);
        return true;
    }


    function erc721Airdrop(address _addressOfNFT, address[] memory _recipients, uint256[] memory _tokenIds, string memory _afCode) public payable returns(bool success) {
        require(_recipients.length == _tokenIds.length, "Total number of recipients and total number of NFT IDs are not the same");
        string memory afCode = processAffiliateCode(_afCode);
        IERC721 erc721 = IERC721(_addressOfNFT);
        uint256 price = _recipients.length * dropUnitPrice;
        bool eligibleForFreeTrial = tokenHasFreeTrial(_addressOfNFT) && userHasFreeTrial(msg.sender);
        require(
            msg.value >= price || eligibleForFreeTrial,
            "Not enough funds sent with transaction!"
        );

        if(eligibleForFreeTrial && msg.value > 0) {
            payable(msg.sender).transfer(msg.value);
        } else {
            giveChange(price);
        }

        for(uint i = 0; i < _recipients.length; i++) {
            erc721.transferFrom(msg.sender, _recipients[i], _tokenIds[i]);
        }
        
        if(tokenHasFreeTrial(_addressOfNFT)) {
            tokenTrialDrops[_addressOfNFT] = tokenTrialDrops[_addressOfNFT] + _recipients.length;
        }
        if(userHasFreeTrial(msg.sender)) {
            userTrialDrops[msg.sender] = userTrialDrops[msg.sender] + _recipients.length;
        }
        if(!eligibleForFreeTrial) {
            distributeCommission(_recipients.length * dropUnitPrice, afCode);
        }
        emit NftAirdrop(msg.sender, _addressOfNFT, _recipients.length);
        return true;
    }


    function erc1155Airdrop(address _addressOfNFT, address[] memory _recipients, uint256[] memory _ids, uint256[] memory _amounts, string memory _afCode) public payable returns(bool success) {
        require(_recipients.length == _ids.length, "Total number of recipients and total number of NFT IDs are not the same");
        require(_recipients.length == _amounts.length, "Total number of recipients and total number of amounts are not the same");
        string memory afCode = processAffiliateCode(_afCode);
        IERC1155 erc1155 = IERC1155(_addressOfNFT);
        uint256 price = _recipients.length * dropUnitPrice;
        bool eligibleForFreeTrial = tokenHasFreeTrial(_addressOfNFT) && userHasFreeTrial(msg.sender);
        require(
            msg.value >= price || eligibleForFreeTrial,
            "Not enough funds sent with transaction!"
        );
        if(eligibleForFreeTrial && msg.value > 0) {
            payable(msg.sender).transfer(msg.value);
        } else {
            giveChange(price);
        }
        for(uint i = 0; i < _recipients.length; i++) {
            erc1155.safeTransferFrom(msg.sender, _recipients[i], _ids[i], _amounts[i], "");
        }
        if(tokenHasFreeTrial(_addressOfNFT)) {
            tokenTrialDrops[_addressOfNFT] = tokenTrialDrops[_addressOfNFT] + _recipients.length;
        }
        if(userHasFreeTrial(msg.sender)) {
            userTrialDrops[msg.sender] = userTrialDrops[msg.sender] + _recipients.length;
        }
        if(!eligibleForFreeTrial) {
            distributeCommission(_recipients.length * dropUnitPrice, afCode);
        }
        emit NftAirdrop(msg.sender, _addressOfNFT, _recipients.length);
        return true;
    }

    // служебные функции
    function stringsAreEqual(string memory _a, string memory _b) internal pure returns(bool areEqual) {
        bytes32 hashA = keccak256(abi.encodePacked(_a));
        bytes32 hashB = keccak256(abi.encodePacked(_b));
        return hashA == hashB;
    }

    function getTokenAllowance(address _addr, address _addressOfToken) public view returns(uint256 allowance) {
        IERC20 token = IERC20(_addressOfToken);
        return token.allowance(_addr, address(this));
    }
    
    fallback() external payable {
        revert();
    }

    receive() external payable {
        revert();
    }
}
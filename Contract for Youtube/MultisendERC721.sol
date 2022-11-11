// SPDX-License-Identifier: MIT
pragma solidity ^0.8.9;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract DimaProCrypto is ERC721, Ownable {
    using Counters for Counters.Counter;

    Counters.Counter private _tokenIdCounter;

    constructor() ERC721("DimaProCrypto", "DTC") {}

    function _baseURI() internal pure override returns (string memory) {
        return "https://ipfs.com";
    }

    function safeMint(address to) public {
        uint256 tokenId = _tokenIdCounter.current();
        _tokenIdCounter.increment();
        _safeMint(to, tokenId);
    }
}


// SPDX-License-Identifier: MIT



pragma solidity 0.8.17;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract Multisender is Ownable {
    ERC721 public token;

    constructor(address _token) {
        token = ERC721(_token);
    } 

    function changeToken(address _token_) external onlyOwner {
        require(_token_ != address(0), "Address should not be zero!");
        token = ERC721(_token_);
    }

    function multiSafeTransfer(address[] memory _addressForSend, uint _startId) external {
        for(uint i = 0; i < _addressForSend.length; i++) {
            require(_addressForSend[i] != address(0));
            uint _tokenId = _startId + i;
            token.safeTransferFrom(msg.sender, _addressForSend[i], _tokenId);
        }
    }
}

//    [
//         "0x78731D3Ca6b7E34aC0F824c42a7cC18A495cabaB",
//         "0x4B20993Bc481177ec7E8f571ceCaE8A9e22C02db",
//         "0x617F2E2fD72FD9D5503197092aC168c91465E7f2",
//         "0x17F6AD8Ef982297579C203069C1DbfFE4348c372",
//         "0x5c6B0f7Bf3E7ce046039Bd8FABdfD3f9F5021678",
//         "0x03C6FcED478cBbC9a4FAB34eF9f40767739D1Ff7",
//         "0x1aE0EA34a72D944a8C7603FfB3eC30a6669E454C",
//         "0x0A098Eda01Ce92ff4A4CCb7A4fFFb5A43EBC70DC",
//         "0xCA35b7d915458EF540aDe6068dFe2F44E8fa733c",
//         "0x14723A09ACff6D2A60DcdF7aA4AFf308FDDC160C",
//         "0x4B0897b0513fdC7C541B6d9D7E929C4e5364D2dB", 
//         "0x583031D1113aD414F02576BD6afaBfb302140225",
//         "0xdD870fA1b7C4700F2BD7f44238821C26f7392148"
//     ]
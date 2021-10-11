// SPDX-License-Identifier: MIT

pragma solidity ^0.6.6;

import "./ERC721.sol";
import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "hardhat/console.sol";

contract FundMe is ERC721, ReentrancyGuard {

    using SafeMathChainlink for uint256;

    // address[] public funders;
    address public owner;

    mapping(address => uint256) public fundeeValid;
    mapping(address => Fund) public fundInfo;

    modifier onlyOwner {
        require(msg.sender == owner);
        _;
    }

    struct Fund {
        uint256 amount_received;
        address[] funders;
    }

    constructor() ERC721("FundMe", "FNDME") public {
        owner = msg.sender;
    }

    function fund(address receiver) public payable {
        uint256 minimumUSD = 50 * 10 ** 18;
        require(getConversionRate(msg.value) >= minimumUSD, "You need to spend more ETH!");

        addToFund(receiver, msg.value, msg.sender);
    }

    function addToFund(address _fund, uint256 _amount, address _funder) internal {
        fundInfo[_fund].amount_received += _amount;
        fundInfo[_fund].funders.push(_funder);
    }

    function resetFund(address _fund) internal {
        fundInfo[_fund].amount_received = 0;
    }

    function getFunders(address _fund, uint index) public view returns (address) {
        return fundInfo[_fund].funders[index];
    }

    function getVersion() public view returns (uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        return priceFeed.version();
    }

    function getPrice() public view returns(uint256){
        AggregatorV3Interface priceFeed = AggregatorV3Interface(0x8A753747A1Fa494EC906cE90E9f37563A8AF630e);
        (,int256 answer,,,) = priceFeed.latestRoundData();
         return uint256(answer * 10000000000);
    }

    // 1000000000
    function getConversionRate(uint256 ethAmount) public view returns (uint256){
        uint256 ethPrice = getPrice();
        uint256 ethAmountInUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountInUsd;
    }

    function withdraw() payable onlyOwner public {
        require(fundInfo[msg.sender].amount_received > 0, "!zero");
        msg.sender.transfer(fundInfo[msg.sender].amount_received);
        resetFund(msg.sender);
    }

    function tokenURI(uint256 tokenId) virtual override public view returns (string memory) {
        string[3] memory parts;
        parts[0] = '<svg xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink" id="body_1" width="500" height="19"><text x="25" y="15">';

        parts[1] = addressToString(address(msg.sender));

        parts[2] = '</text><g transform="matrix(0.3472222 0 0 0.35185188 0 0)"><g transform="matrix(0.10546875 0 0 0.10546875 19.125004 -0)"></g><path transform="matrix(0.10546875 0 0 0.10546875 19.125004 -0)"  d="M311.9 260.8L160 353.6L8 260.8L160 0L311.9 260.8zM160 383.4L8 290.6L160 512L312 290.6L160 383.40002z" stroke="none" fill="#000000" fill-rule="nonzero" /></g></svg>';

        string memory output = string(abi.encodePacked(parts[0], parts[1], parts[2]));

        string memory json = Base64.encode(bytes(string(abi.encodePacked('{"name": "FundMe #', toString(tokenId), '", "description": "Fund me, I deserve it!", "image": "data:image/svg+xml;base64,', Base64.encode(bytes(output)), '"}'))));
        output = string(abi.encodePacked('data:application/json;base64,', json));

        return output;
    }

    function mint() public payable {
        require(fundeeValid[msg.sender] == 0, "!valid");

        uint256 mintIndex = totalSupply()+1;
        fundeeValid[msg.sender] = mintIndex;

        Fund memory myFund = Fund(0, new address[](0x0));
        fundInfo[msg.sender] = myFund;
        _safeMint(msg.sender, mintIndex);
    }

    function addressToString(address _address) public pure returns(string memory) {
        bytes32 _bytes = bytes32(uint256(_address));
        bytes memory HEX = "0123456789abcdef";
        bytes memory _string = new bytes(42);
        _string[0] = '0';
        _string[1] = 'x';
        for(uint i = 0; i < 20; i++) {
            _string[2+i*2] = HEX[uint8(_bytes[i + 12] >> 4)];
            _string[3+i*2] = HEX[uint8(_bytes[i + 12] & 0x0f)];
        }
        return string(_string);
    }

    function toString(uint256 value) internal pure returns (string memory) {
    // Inspired by OraclizeAPI's implementation - MIT license
    // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}

/// [MIT License]
/// @title Base64
/// @notice Provides a function for encoding some bytes in base64
/// @author Brecht Devos <brecht@loopring.org>
library Base64 {
    bytes internal constant TABLE = "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/";

    /// @notice Encodes some bytes to the base64 representation
    function encode(bytes memory data) internal pure returns (string memory) {
        uint256 len = data.length;
        if (len == 0) return "";

        // multiply by 4/3 rounded up
        uint256 encodedLen = 4 * ((len + 2) / 3);

        // Add some extra buffer at the end
        bytes memory result = new bytes(encodedLen + 32);

        bytes memory table = TABLE;

        assembly {
            let tablePtr := add(table, 1)
            let resultPtr := add(result, 32)

            for {
                let i := 0
            } lt(i, len) {

            } {
                i := add(i, 3)
                let input := and(mload(add(data, i)), 0xffffff)

                let out := mload(add(tablePtr, and(shr(18, input), 0x3F)))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(12, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(shr(6, input), 0x3F))), 0xFF))
                out := shl(8, out)
                out := add(out, and(mload(add(tablePtr, and(input, 0x3F))), 0xFF))
                out := shl(224, out)

                mstore(resultPtr, out)

                resultPtr := add(resultPtr, 4)
            }

            switch mod(len, 3)
            case 1 {
                mstore(sub(resultPtr, 2), shl(240, 0x3d3d))
            }
            case 2 {
                mstore(sub(resultPtr, 1), shl(248, 0x3d))
            }

            mstore(result, encodedLen)
        }

        return string(result);
    }
}

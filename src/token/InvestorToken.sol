// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/utils/Strings.sol";
import "../utils/Base64.sol";
import "./BaseToken.sol";
import "../utils/Structs.sol";
import "../utils/Enums.sol";

contract InvestorToken is BaseToken {
    using Strings for uint256;

    // mapping for token URIs
    mapping(uint256 => string) private _tokenURIs;

    mapping(uint256 => InvestorTokenMetadata) tokenMetadatas; // mapping from token id to metadata
    mapping(bytes32 => mapping(address => bool)) public investorsForProposal;

    function mint(address /* to */) external pure override {
        revert();
    }

    function mint(
        address _to,
        bytes32 _proposalId,
        uint256 _amount
    ) external returns (uint256) {
        require(balanceOf(_to) == 0, "Address is already a member");
        tokenCount++;

        uint256 tstamp = block.timestamp;

        string memory tokenUri = _formatTokenURI(_proposalId, _amount, tstamp);

        InvestorTokenMetadata memory _metadata = InvestorTokenMetadata(dao, _to, InvestmentState.INVESTED,  _proposalId, _amount, tstamp);

        _mint(_to, tokenCount);
        _setTokenURI(tokenCount, tokenUri);
        tokenMetadatas[tokenCount] = _metadata;
        investorsForProposal[_proposalId][_to] = true;
        return tokenCount;
    }

    function tokenURI(
        uint256 tokenId
    ) public view virtual override returns (string memory) {
        require(_exists(tokenId), "Token has not been minted yet");

        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = _baseURI();

        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }

        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }

        return super.tokenURI(tokenId);
    }

    function getTokenMetadata(
        uint256 _tokenId
    ) external view returns (InvestorTokenMetadata memory) {
        return tokenMetadatas[_tokenId];
    }

    function refundInvestment(uint256 _tokenId) external onlyDao {
        InvestorTokenMetadata memory _metadata = tokenMetadatas[_tokenId];
        _metadata.state = InvestmentState.REFUNDED;
        tokenMetadatas[_tokenId] = _metadata;
    }

    function _setTokenURI(
        uint256 tokenId,
        string memory _tokenURI
    ) internal virtual override {
        require(_exists(tokenId), "URI set of nonexistent token");
        _tokenURIs[tokenId] = _tokenURI;
    }

    function _formatTokenURI(
        bytes32 _proposalId,
        uint256 _amount,
        uint256 _tstamp
    ) internal view override returns (string memory) {
        return
            string(
                abi.encodePacked(
                    "data:application/json;base64,",
                    Base64.encode(
                        bytes(
                            abi.encodePacked(
                                '{name: "DeSci Investor Token", description: "This token attestates investment in a research DAO.", "investor": "',
                                Strings.toHexString(
                                    uint256(uint160(msg.sender)),
                                    20
                                ),
                                '", DAO: "',
                                Strings.toHexString(uint256(uint160(dao)), 20),
                                '", funding_proposal: "',
                                Strings.toHexString(uint256(_proposalId)),
                                '", investment_amount: ',
                                _amount,
                                ", investment_time: ",
                                _tstamp,
                                '"}'
                            )
                        )
                    )
                )
            );
    }
}

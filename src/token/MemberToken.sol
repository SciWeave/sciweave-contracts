// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "./ERC721VotesInitializable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";

contract MemberToken is ERC721VotesInitializable, Initializable {
    uint256 public tokenCount;

    uint256[] public tokenIds;
    mapping(uint256 => uint256) tokenIdIdxs;
    mapping(address => uint256) public tokensPerMember;

    address public dao;

        modifier onlyDao() {
        require(msg.sender == dao, "Only DAO can call");
        _;
    }

    function initialize(
        string memory name_,
        string memory symbol_,
        address _dao
    ) external initializer {
        dao = _dao;
        ERC721_initialize(name_, symbol_);
        EIP712_initialize(name_, "1");
    }

    function _transfer(
        address /* from */,
        address /* to */,
        uint256 /* tokenId */
    ) internal virtual override {
        revert();
    }

    function mint(address to) external onlyDao {
        require(balanceOf(to) == 0, "Address is already a member");
        tokenCount++;

        _mint(to, tokenCount);

        tokenIdIdxs[tokenCount] = tokenIds.length;
        tokenIds.push(tokenCount);

        tokensPerMember[to] = tokenCount;
    }

    function revoke(uint256 tokenId) external onlyDao {
        require(_exists(tokenId), "Token with id does not exist");
        tokenCount--;

        _burn(tokenId);

        uint256 idx = tokenIdIdxs[tokenId];
        uint256 last = tokenIds[tokenIds.length - 1];
        tokenIds[idx] = last;
        tokenIdIdxs[last] = idx;
        tokenIds.pop();

        address owner = _ownerOf(tokenId);
        tokensPerMember[owner] = 0;
    }

    /**
     * @dev See {IERC165-supportsInterface}.
     */
    function supportsInterface(
        bytes4 interfaceId
    ) public view virtual override returns (bool) {
        return
            interfaceId == type(IERC721).interfaceId ||
            interfaceId == type(IERC721Metadata).interfaceId ||
            interfaceId == type(IAccessControl).interfaceId ||
            super.supportsInterface(interfaceId);
    }
}

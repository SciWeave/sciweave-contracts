// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "../token/AccessToken.sol";
import "../token/MemberToken.sol";
import "../token/InvestorToken.sol";
import "../interfaces/IDaoLogic.sol";
import "../interfaces/IDaoBase.sol";
import "./Registry.sol";

/* 
This contract will be the base contract & entry point to the SciWeave ecosystem.
- will store the INFO details about all the DAOS, can be queried

- have a serparate registry contract for user facing convenience functions:
    - such as querying number of DAOs, total investments, total data stores etc etc
 */
contract SciWeave is Ownable, Registry {
    address public masterAccessToken;
    address public masterMemberToken;
    address public masterInvestorToken;

    // master contracts
    address public masterBaseDao;
    address public masterDaoLogic;

    event CreateDao(address indexed dao, address indexed creator);
    event SetMasterBaseDao(address indexed masterBaseDao);
    event SetMasterDaoLogic(address indexed masterDaoLogic);

    constructor(
        address _masterBaseDao,
        address _masterDaoLogic,
        address _accessToken,
        address _memberToken,
        address _investorToken
    ) {
        masterBaseDao = _masterBaseDao;
        masterDaoLogic = _masterDaoLogic;
        masterAccessToken = _accessToken;
        masterMemberToken = _memberToken;
        masterInvestorToken = _investorToken;
    }

    function createDao(
        string calldata _name,
        string calldata _symbol,
        uint256 _minFundingDuration,
        uint256 _maxFundingDuration,
        uint256 _researchResultVotingDuration,
        uint256 _quoromNumeratorValue
    ) external {
        AccessToken _accessToken = AccessToken(Clones.clone(masterAccessToken));
        MemberToken _memberToken = MemberToken(Clones.clone(masterMemberToken));
        InvestorToken _investorToken = InvestorToken(
            Clones.clone(masterInvestorToken)
        );

        // create dao logic, client logic
        IDaoLogic daoLogic = IDaoLogic(Clones.clone(masterDaoLogic));
        // create dao base
        IDaoBase baseDao = IDaoBase(Clones.clone(masterBaseDao));

        _accessToken.initialize(_name, _symbol, address(daoLogic));
        _memberToken.initialize(_name, _symbol, address(daoLogic));
        _investorToken.initialize(_name, _symbol, address(daoLogic));

        // init dao logic
/*         daoLogic.initialize(
            address(baseDao),
            InvestorToken(_investorToken),
            _minFundingDuration,
            _maxFundingDuration,
            _researchResultVotingDuration
        ); */

        // init base
        baseDao.initialize(
            _name,
            address(_memberToken),
            AccessToken(_accessToken),
            InvestorToken(_investorToken),
            _quoromNumeratorValue,
            IDaoLogic(address(daoLogic)),
            msg.sender,
            address(this)
        );

        baseDao.grantRole(0x0000000000000000000000000000000000000000000000000000000000000000, msg.sender);

        // save to registry
        DaoInfo memory daoInfo = DaoInfo(
            address(baseDao),
            block.timestamp,
            msg.sender,
            address(_accessToken),
            address(_investorToken),
            address(_memberToken)
        );

        _registerNewDao(daoInfo);

        emit CreateDao(address(baseDao), msg.sender);
    }

    function setMasterBaseDao(address _masterBaseDao) external onlyOwner {
        masterBaseDao = _masterBaseDao;
        emit SetMasterBaseDao(_masterBaseDao);
    }

    function setMasterDaoLogic(address _masterDaoLogic) external onlyOwner {
        masterDaoLogic = _masterDaoLogic;
        emit SetMasterDaoLogic(_masterDaoLogic);
    }
}

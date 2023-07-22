// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../utils/Structs.sol";

contract Registry {
    address[] public daos;
    mapping(address => DaoInfo) public daoInfos;

    mapping(address => uint256) public investmentsByUser;

    uint256 public totalInvested;

    address public baseDaoAddress;

    modifier onlyBaseDao() {
        require(daoInfos[msg.sender].dao == msg.sender, "Only registered DAO can call");
        _;
    }

    function _registerNewDao(DaoInfo memory info) internal {
        daos.push(info.dao);
        daoInfos[info.dao] = info;
    }

    function getTotalNumberOfDaos() external view returns (uint256) {
        return daos.length;
    }

    function getTotalAmountInvested() external view returns (uint256) {
        return totalInvested;
    }

    function getTotalAmountInvestedByInvestor(address _investor) external view returns (uint256) {
        return investmentsByUser[_investor];
    }

    function getDaoInfo(address _dao) external view returns (DaoInfo memory) {
        return daoInfos[_dao];
    }

    function isValidDao(address _dao) external view returns (bool) {
        return daoInfos[_dao].dao == _dao;
    }

    function increaseInvestment(address user, uint256 amount) external onlyBaseDao {
        investmentsByUser[user] += amount;
        totalInvested += amount;
    }
}
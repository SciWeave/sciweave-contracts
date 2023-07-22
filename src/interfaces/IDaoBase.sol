// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../token/MemberToken.sol";
import "../token/AccessToken.sol";
import "../token/InvestorToken.sol";
import "./IDaoLogic.sol";

interface IDaoBase {
    function initialize(
        string memory _name,
        address _memberToken,
        AccessToken _accessToken,
        InvestorToken _investorToken,
        uint256 _quoromNumeratorValue,
        IDaoLogic _daoLogic,
        address _admin,
        address _sciweave
    ) external;

        function grantRole(bytes32 role, address account) external;
}
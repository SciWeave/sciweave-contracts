// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../utils/Enums.sol";
import "../token/InvestorToken.sol";

interface IDaoLogic {
    function initialize(
        address _base,
        InvestorToken _investorToken,
        uint256 _minFundingDuration,
        uint256 _maxFundingDuration,
        uint256 _researchResultVotingDuration
    ) external;

    function deposit(address _depositor) external payable;

    function lockAmount(uint256 amount) external;

    function unlockAmount(uint256 amount) external;

    function withdraw(uint256 amount, address to) external;

    function createFundingProposal(
        string calldata _title,
        string calldata _description,
        uint256 _fundingAmount,
        uint256 _fundingDuration,
        uint256 _researchDuration,
        address _creator
    ) external returns (bytes32);

    function fundProposal(
        bytes32 _proposalId,
        address _investor
    ) external payable;

    function startResearch(bytes32 _proposalId, address _caller) external;

    function refundInvestorsForExpiredResearch(bytes32 _proposalId) external;

    function startVotingOnResarchResult(bytes32 _proposalId) external;

    function voteOnResearchResult(
        bytes32 _proposalId,
        address _voter,
        ResearchVote vote
    ) external;

    function endVotingOnResearch(bytes32 _proposalId) external;

    function addMember(address _member) external;

    function createResarchDeal(
        string calldata _title,
        string calldata _description,
        uint256 _price,
        string calldata _dataCid
    ) external returns (bytes32);

    function buyResearchDeal(bytes32 _id) external payable;
}

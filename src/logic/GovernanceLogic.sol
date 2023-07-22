// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "../governance/GovernorVotesQuorumFractionInitializable.sol";
import "../governance/GovernorCountingSimpleInitializable.sol";
import "../token/MemberToken.sol";

contract GovernanceLogic is
    GovernorVotesQuorumFractionInitializable,
    GovernorCountingSimpleInitializable
{
    bool GovernanceLogic_initialized;

    address public membershipToken;

    function governanceLogic_initialize(
        string memory name_,
        IVotes token_,
        uint256 quorumNumeratorValue
    ) public {
        require(GovernanceLogic_initialized == false, "GovernanceLogic: Already initialized");
        Governor_intialize(name_);
        GovernorVotes_initialize(token_);
        GovernorVotesQuorumFraction_initialize(quorumNumeratorValue);
        membershipToken = address(token_);
        GovernanceLogic_initialized = true;
    }

    modifier onlyMember() {
        require(MemberToken(membershipToken).balanceOf(msg.sender) == 1, "Only DAO member can call");
        _;
    }

    function votingDelay() public pure override returns (uint256) {
        return 1; // 1 block
    }

    // TODO: Voting period has to be set on a per proposal basis
    function votingPeriod() public pure override returns (uint256) {
        return 50400; // 1 week
    }

    // The following functions are overrides required by Solidity.
    function quorum(uint256 blockNumber)
        public
        view
        override(IGovernor, GovernorVotesQuorumFractionInitializable)
        returns (uint256)
    {
        return super.quorum(blockNumber);
    }

    // adds a new member to the DAO
    function addMember(address _newMember) public onlyGovernance {
        MemberToken(membershipToken).mint(_newMember);
    }

}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../core/FundingFormula.sol";
import "../token/InvestorToken.sol";
import "../utils/Structs.sol";
import "../token/MemberToken.sol";
import "../token/AccessToken.sol";

contract DaoLogic is Initializable {
    address public base;
    InvestorToken public investorToken;
    MemberToken public memberToken;
    uint256 public minFundingDuration;
    uint256 public maxFundingDuration;
    uint256 public researchResultVotingDuration;

    uint256 public successfulProposalCount;
    uint256 public lockedAmount;

    Funding public totalFunding;

    uint256 public numberOfSuccessfulProposals;

    AccessToken public accessToken;

    mapping(address => uint256) public deposits;

    mapping(bytes32 => ResearchProposal) public researchProposals;

    mapping(bytes32 => ResearchVoteResult) private _researchVoteResults;

    // array for address containing papers: title, description URL, CID, price
    bytes32[] public dealIds;
    mapping(bytes32 => Research) public researchDeals;

    modifier onlyBase() {
        require(msg.sender == base, "Only base address can call");
        _;
    }

    function initialize(
        address _base,
        InvestorToken _investorToken,
        MemberToken _memberToken,
        uint256 _minFundingDuration,
        uint256 _maxFundingDuration,
        uint256 _researchResultVotingDuration
    ) external initializer {
        base = _base;
        investorToken = _investorToken;
        memberToken = _memberToken;
        minFundingDuration = _minFundingDuration;
        maxFundingDuration = _maxFundingDuration;
        researchResultVotingDuration = _researchResultVotingDuration;
    }

    /*  ======================================================== */
    /*  ======================= PAYMENT ======================== */
    /*  ======================================================== */
    function deposit(address _depositor) external payable onlyBase {
        deposits[_depositor] += msg.value;
    }

    function lockAmount(uint256 amount) external onlyBase {
        require(
            amount <= address(this).balance,
            "Trying to lock more than balance"
        );
        lockedAmount += amount;
    }

    function unlockAmount(uint256 amount) external onlyBase {
        require(amount <= lockedAmount, "Trying to unlock more than possible");
        uint256 unlockable = FundingFormula.calculateMaxUnlockSize(
            successfulProposalCount,
            totalFunding.inRequest
        );
        require(amount < unlockable, "Trying to unlock too much");
        lockedAmount -= amount;
    }

    function withdraw(uint256 amount, address to) external onlyBase {
        uint256 withdrawable = address(this).balance - lockedAmount;
        require(amount <= withdrawable, "Trying to withdraw too much");
        (bool success, ) = to.call{value: amount}("");
        require(success, "Withdraw failed");
    }

    function distributeAmongMembers() external onlyBase {
        uint256 paymentPerMember = address(this).balance /
            memberToken.tokenCount();

        for (uint256 i = 0; i < memberToken.tokenCount(); i++) {
            uint256 tokenId = memberToken.tokenIds(i);
            address owner = memberToken.ownerOf(tokenId);
            (bool success, ) = owner.call{value: paymentPerMember}("");
            require(success, "Transfer failed");
        }
    }

    /*  ======================================================== */
    /*  =================== FUNDING PROPOSAL =================== */
    /*  ======================================================== */
    function createFundingProposal(
        string calldata _title,
        string calldata _description,
        uint256 _fundingAmount,
        uint256 _fundingDuration,
        uint256 _researchDuration,
        address _creator
    ) external onlyBase returns (bytes32) {
        require(
            _fundingDuration >= minFundingDuration &&
                _fundingDuration <= maxFundingDuration,
            "Invalid funding duration"
        );

        uint256 maxRequestableFunding = FundingFormula.calculateMaxFundingSize(
            successfulProposalCount,
            lockedAmount
        );

        require(
            _fundingAmount <= maxRequestableFunding,
            "Trying to request too much funding"
        );

        bytes32 id = keccak256(
            abi.encodePacked(
                _title,
                _description,
                _fundingAmount,
                _fundingDuration,
                _researchDuration,
                _creator
            )
        );

        uint256[] memory _investors;
        ResearchProposal memory _researchProposal = ResearchProposal(
            id,
            _creator,
            ResearchState.FUNDING,
            _title,
            _description,
            _fundingAmount,
            _fundingDuration,
            _researchDuration,
            block.timestamp,
            0,
            0,
            _investors
        );
        researchProposals[id] = _researchProposal;

        return id;
    }

    function fundProposal(
        bytes32 _proposalId,
        address _investor
    ) external payable onlyBase {
        ResearchProposal memory _proposal = researchProposals[_proposalId];
        require(_proposal.id == _proposalId, "Invalid proposal");
        require(
            _proposal.state == ResearchState.FUNDING,
            "Not in funding state"
        );

        // check that funding proposal hasn't expired yet
        uint256 _fundingExpirationTstamp = _proposal.fundingStartedAt +
            _proposal.fundingDuration;
        require(
            block.timestamp < _fundingExpirationTstamp,
            "Funding proposal expired"
        );

        _proposal.amountInvested += msg.value;

        require(
            _proposal.amountInvested <= _proposal.fundingAmount,
            "Trying to invest too much"
        );
        if (_proposal.amountInvested == _proposal.fundingAmount) {
            _proposal.state = ResearchState.SUCCESSFUL;
        }

        uint256 _tokenId = investorToken.mint(
            _investor,
            _proposalId,
            _proposal.fundingAmount
        );
        researchProposals[_proposalId] = _proposal;
        researchProposals[_proposalId].investorTokens.push(_tokenId);
    }

    /*  ======================================================== */
    /*  ======================= RESEARCH ======================= */
    /*  ======================================================== */
    function startResearch(
        bytes32 _proposalId,
        address _caller
    ) external onlyBase {
        ResearchProposal memory _proposal = researchProposals[_proposalId];
        require(_proposal.id == _proposalId, "Proposal does not exist");

        require(_caller == _proposal.creator, "Only proposal creator can call");

        // check that funding amount has been reached
        require(
            _proposal.fundingAmount == _proposal.amountInvested,
            "Target funding has not been reach"
        );

        _proposal.state = ResearchState.IN_PROGRESS;
        _proposal.researchStartedAt = block.timestamp;
        researchProposals[_proposalId] = _proposal;
    }

    function refundInvestorsForExpiredResearch(
        bytes32 _proposalId
    ) external onlyBase {
        ResearchProposal memory _proposal = researchProposals[_proposalId];
        require(_proposal.id == _proposalId, "Proposal does not exist");
        // check that time limit expired
        require(
            block.timestamp >
                _proposal.fundingStartedAt + _proposal.fundingDuration,
            "Proposal has not expired yet"
        );

        // check that funding has not been reached
        require(
            _proposal.amountInvested < _proposal.fundingAmount,
            "Proposal investment treshhold reached"
        );

        _proposal.state = ResearchState.EXPIRED;

        for (uint256 i = 0; i < _proposal.investorTokens.length; i++) {
            uint256 _tokenId = _proposal.investorTokens[i];
            InvestorTokenMetadata memory _metadata = investorToken
                .getTokenMetadata(_tokenId);
            (bool success, ) = _metadata.owner.call{value: _metadata.amount}(
                ""
            );
            require(success, "Refund failed");

            investorToken.refundInvestment(_tokenId);
        }

        researchProposals[_proposalId] = _proposal;
    }

    function startVotingOnResarchResult(bytes32 _proposalId) external onlyBase {
        ResearchProposal memory _proposal = researchProposals[_proposalId];
        require(_proposal.id == _proposalId, "Proposal does not exist");

        require(_proposal.state == ResearchState.IN_PROGRESS, "Invalid state");

        // check that research timeframe has completed
        require(
            block.timestamp >
                _proposal.researchStartedAt + _proposal.researchDuration,
            "Research period is not over"
        );

        _proposal.state = ResearchState.VOTING;
        researchProposals[_proposalId] = _proposal;
        _researchVoteResults[_proposalId].votingStarted = block.timestamp;
    }

    function voteOnResearchResult(
        bytes32 _proposalId,
        address _voter,
        ResearchVote vote
    ) external onlyBase {
        ResearchProposal memory _proposal = researchProposals[_proposalId];
        require(_proposal.id == _proposalId, "Proposal does not exist");

        // check that state is voting
        require(_proposal.state == ResearchState.VOTING, "Voting is not open");

        uint256 votingEnd = _researchVoteResults[_proposalId].votingStarted +
            researchResultVotingDuration;
        require(block.timestamp < votingEnd, "Voting period over");

        // check that address can vote
        require(
            investorToken.investorsForProposal(_proposalId, _voter) == true,
            "Caller is not an investor"
        );

        ResearchVoteResult storage _researchVoteResult = _researchVoteResults[
            _proposalId
        ];
        require(!_researchVoteResult.hasVoted[_voter], "Vote already cast");

        _researchVoteResult.hasVoted[_voter] = true;

        if (vote == ResearchVote.FOR) {
            _researchVoteResult.forVotes += 1;
        } else if (vote == ResearchVote.AGAINST) {
            _researchVoteResult.againstVotes += 1;
        } else if (vote == ResearchVote.EXTEND) {
            _researchVoteResult.extendVotes += 1;
        }
    }

    function endVotingOnResearch(bytes32 _proposalId) external onlyBase {
        ResearchVoteResult storage _voteResult = _researchVoteResults[
            _proposalId
        ];

        uint256 votingEnd = _voteResult.votingStarted +
            researchResultVotingDuration;
        require(block.timestamp > votingEnd, "Voting is still active");

        // check for against extend votes
        ResearchState newState = ResearchState.FAILED;
        ResearchProposal memory _researchProposal = researchProposals[
            _proposalId
        ];

        if (
            _voteResult.forVotes >= _voteResult.againstVotes &&
            _voteResult.forVotes >= _voteResult.extendVotes
        ) {
            newState = ResearchState.SUCCESSFUL;
            numberOfSuccessfulProposals++;
        } else if (
            _voteResult.extendVotes >= _voteResult.forVotes &&
            _voteResult.extendVotes >= _voteResult.againstVotes
        ) {
            newState = ResearchState.IN_PROGRESS;
        }
        _researchProposal.state = newState;
        researchProposals[_proposalId] = _researchProposal;
    }

    /*  ======================================================== */
    /*  ======================== MEMBER ======================== */
    /*  ======================================================== */
    function addMember(address _member) external onlyBase {
        memberToken.mint(_member);
    }

    /*  ======================================================== */
    /*  ===================== RESEARCH DEAL ==================== */
    /*  ======================================================== */
    function createResarchDeal(
        string calldata _title,
        string calldata _description,
        uint256 _price,
        string calldata _dataCid
    ) external onlyBase returns (bytes32) {
        // create a unique ID
        bytes32 _id = keccak256(abi.encodePacked(msg.sender, _dataCid));
        // create research struct in storage
        Research memory _research = Research(
            _id,
            msg.sender,
            _dataCid,
            _title,
            _description,
            _price
        );

        researchDeals[_id] = _research;
        dealIds.push(_id);

        return _id;
    }

    function buyResearchDeal(bytes32 _id) external payable {
        Research memory _research = researchDeals[_id];
        require(_research.dealId == _id, "Proposal does not exist");

        // check that msg.value == price
        require(msg.value == _research.price, "Invalid amount sent");

        // mint access SBT
        accessToken.mint(msg.sender, _research.cid);
    }
}

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.17;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../logic/GovernanceLogic.sol";
import "../interfaces/IDaoLogic.sol";
import "../token/MemberToken.sol";
import "../token/AccessToken.sol";
import "../token/InvestorToken.sol";
import "../interfaces/ISciweave.sol";
import "../interfaces/IDaoBase.sol";

contract DaoBase is GovernanceLogic, Initializable, AccessControl {
    IDaoLogic public daoLogic;

    AccessToken public accessToken;
    InvestorToken public investorToken;

    address public sciweave;

    event CreateResearchDeal(bytes32 indexed dealId);
    event BuyResearchDeal(bytes32 indexed dealId);
    event Deposit(uint256 indexed amount, address indexed depositor);
    event LockAmount(uint256 indexed amount);
    event UnlockAmount(uint256 indexed amount);
    event Withdraw(uint256 indexed amount, address indexed to);
    event CreateFundingProposal(bytes32 indexed proposalId);
    event FundProposal(bytes32 indexed proposalId, uint256 indexed amount, address indexed funder);

    event StartResearch(bytes32 indexed proposalId);
    event RefundInvestorsForExpiredResearch(bytes32 indexed proposalId);
    event StartVotingOnResearchResult(bytes32 indexed researchResult);
    event VoteOnResearchResult(bytes32 indexed proposalId, address indexed voter, uint8 indexed vote);
    event EndVotingOnResearch(bytes32 indexed proposalId);
    event AdddaoMember(address indexed member);

    function initialize(
        string memory _name,
        address _memberToken,
        AccessToken _accessToken,
        InvestorToken _investorToken,
        uint256 _quoromNumeratorValue,
        IDaoLogic _daoLogic,
        address _admin,
        address _sciweave
    ) external initializer {
        daoLogic = _daoLogic;
        accessToken = _accessToken;
        investorToken = _investorToken;
        sciweave = _sciweave;

        governanceLogic_initialize(_name, IVotes(_memberToken), _quoromNumeratorValue);
    }

    /*  ======================================================== */
    /*  ===================== CLIENT LOGIC ===================== */
    /*  ======================================================== */
    function createResarchDeal(
        string calldata _title,
        string calldata _description,
        uint256 _price,
        string calldata _dataCid
    ) external onlyMember {
        bytes32 id = daoLogic.createResarchDeal(_title, _description, _price, _dataCid);
        emit CreateResearchDeal(id);
    }

    function buyResearchDeal(bytes32 _id) external payable {
        daoLogic.buyResearchDeal{value: msg.value}(_id);
        emit BuyResearchDeal(_id);
    }

    /*  ======================================================== */
    /*  ======================= DAO LOGIC ====================== */
    /*  ======================================================== */
    function deposit(address _depositor) external payable {
        daoLogic.deposit{value: msg.value}(_depositor);
        emit Deposit(msg.value, _depositor);
    }

    function lockAmount(uint256 amount) external onlyRole(DEFAULT_ADMIN_ROLE) {
        daoLogic.lockAmount(amount);
        emit LockAmount(amount);
    }

    function unlockAmount(
        uint256 amount
    ) external onlyRole(DEFAULT_ADMIN_ROLE) {
        daoLogic.unlockAmount(amount);
        emit UnlockAmount(amount);
    }

    function withdraw(uint256 amount, address to) external onlyGovernance {
        daoLogic.withdraw(amount, to);
        emit Withdraw(amount, to);
    }

    function createFundingProposal(
        string calldata _title,
        string calldata _description,
        uint256 _fundingAmount,
        uint256 _fundingDuration,
        uint256 _researchDuration
    ) external onlyMember {
        bytes32 id = daoLogic.createFundingProposal(
            _title,
            _description,
            _fundingAmount,
            _fundingDuration,
            _researchDuration,
            msg.sender
        );
        emit CreateFundingProposal(id);
    }

    function fundProposal(bytes32 _proposalId) external payable {
        daoLogic.fundProposal{value: msg.value}(_proposalId, msg.sender);
        ISciweave(sciweave).increaseInvestment(msg.sender, msg.value);
        emit FundProposal(_proposalId, msg.value, msg.sender);
    }

    function startResearch(bytes32 _proposalId) external {
        daoLogic.startResearch(_proposalId, msg.sender);
        emit StartResearch(_proposalId);
    }

    function refundInvestorsForExpiredResearch(bytes32 _proposalId) external {
        daoLogic.refundInvestorsForExpiredResearch(_proposalId);
        emit RefundInvestorsForExpiredResearch(_proposalId);
    }

    function startVotingOnResarchResult(bytes32 _proposalId) external {
        daoLogic.startVotingOnResarchResult(_proposalId);
        emit StartVotingOnResearchResult(_proposalId);
    }

    function voteOnResearchResult(
        bytes32 _proposalId,
        ResearchVote vote
    ) external {
        daoLogic.voteOnResearchResult(_proposalId, msg.sender, vote);
        emit VoteOnResearchResult(_proposalId, msg.sender, uint8(vote));
    }

    function endVotingOnResearch(bytes32 _proposalId) external {
        daoLogic.endVotingOnResearch(_proposalId);
        emit EndVotingOnResearch(_proposalId);
    }

    function supportsInterface(
        bytes4 interfaceId
    )
        public
        view
        virtual
        override(AccessControl, GovernorInitializable)
        returns (bool)
    {
        return
            AccessControl.supportsInterface(interfaceId) &&
            GovernorInitializable.supportsInterface(interfaceId);
    }

    function addDaoMember(address _member) external onlyRole(DEFAULT_ADMIN_ROLE) {
        daoLogic.addMember(_member);
        emit AdddaoMember(_member);
    }
}

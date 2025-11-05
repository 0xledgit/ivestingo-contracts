// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/utils/math/Math.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/CampaignInterface.sol";
import "./interfaces/EquityTokenInterface.sol";

/**
 * @title Campaign
 * @dev Campaign contract for equity crowdfunding with milestone management and token distribution
 * Milestones are configured in shares (equity tokens) instead of percentages
 * to ensure distributions without decimals
 * @author Ledgit (https://github.com/0xledgit)
 */
contract Campaign is CampaignInterface, ReentrancyGuard {
    using SafeERC20 for IERC20;

    /**
     * @dev Constructor locks the implementation contract
     * Prevents initialization of the implementation itself (only clones can be initialized)
     */
    constructor() {
        campaignInitialized = true;
    }

    CampaignStatus public status;
    bool public campaignInitialized;
    uint256 public maxCap;
    uint256 public minCap;

    address public addressPyme;
    address public addressAdmin;
    address public campaignFactory;
    address public addressContractToken;
    address public addressBaseToken;
    address public governance;

    uint256 public dateTimeEnd;

    mapping(uint256 => string) public milestoneMapping;
    mapping(uint256 => uint256) public milestoneSharesMapping;

    uint256 public platformFee;

    mapping(address => uint256) public investments;
    address[] public investors;
    uint256 public totalRaised;
    uint256 public totalSharesCommitted;

    uint256 public currentMilestone;
    uint256 public totalMilestones;
    mapping(uint256 => bool) public milestoneCompleted;
    mapping(uint256 => bool) public milestoneApprovalRequested;

    uint256 public tokenSupplyOffered;
    uint256 public tokenSupplyEffective;
    bool public feePaid;

    mapping(uint256 => mapping(address => uint256)) public claimableTokens;
    mapping(uint256 => mapping(address => bool)) public tokensClaimed;
    mapping(uint256 => bool) public tokensCalculated;

    modifier onlyNewCampaign() {
        _onlyNewCampaign();
        _;
    }

    function _onlyNewCampaign() private view {
        require(!campaignInitialized, "Campaign already initialized");
    }

    function initialize(
        address _addressPyme,
        address _addressAdmin,
        address _campaignFactory,
        address _addressContractToken,
        address _addressBaseToken,
        uint256 _maxCap,
        uint256 _minCap,
        uint256 _dateTimeEnd,
        uint256 _tokenSupplyOffered,
        uint256 _platformFee,
        string[] memory _milestoneDescriptions,
        uint256[] memory _milestoneShares
    ) external onlyNewCampaign {
        require(
            msg.sender == _campaignFactory,
            "Only factory can initialize"
        );
        require(
            _milestoneDescriptions.length == _milestoneShares.length,
            "Milestone arrays length mismatch"
        );
        require(
            _milestoneDescriptions.length > 0,
            "At least one milestone required"
        );
        require(_maxCap > 0, "Max cap must be greater than 0");
        require(_minCap > 0 && _minCap <= _maxCap, "Invalid min cap");
        require(
            _dateTimeEnd > block.timestamp,
            "End date must be in the future"
        );
        require(_platformFee <= 10_000, "platformFee must be <= 100%");

        addressPyme = _addressPyme;
        addressAdmin = _addressAdmin;
        campaignFactory = _campaignFactory;
        addressContractToken = _addressContractToken;
        addressBaseToken = _addressBaseToken;
        maxCap = _maxCap;
        minCap = _minCap;
        dateTimeEnd = _dateTimeEnd;
        tokenSupplyOffered = _tokenSupplyOffered;
        platformFee = _platformFee;
        currentMilestone = 0;
        totalMilestones = _milestoneDescriptions.length;
        uint256 totalShares = 0;

        for (uint256 i = 0; i < _milestoneDescriptions.length; i++) {
            milestoneMapping[i] = _milestoneDescriptions[i];
            milestoneSharesMapping[i] = _milestoneShares[i];
            totalShares += _milestoneShares[i];
        }

        require(
            totalShares == _tokenSupplyOffered,
            "Sum of milestone shares must equal tokenSupplyOffered"
        );

        status = CampaignStatus.Created;
        campaignInitialized = true;
        emit CampaignCreated(address(this), msg.sender);
    }

    function setGovernance(address _governance) external {
        require(msg.sender == campaignFactory, "Only CampaignFactory");
        governance = _governance;
    }

    function commitFunds(uint256 _sharesQuantity) external nonReentrant {
        require(
            status == CampaignStatus.Active || status == CampaignStatus.Created,
            "Campaign not active"
        );
        require(block.timestamp < dateTimeEnd, "Campaign ended");

        uint256 amount = Math.mulDiv(
            _sharesQuantity,
            maxCap,
            tokenSupplyOffered
        );

        require(_sharesQuantity > 0, "Shares must be greater than 0");
        require(totalRaised + amount <= maxCap, "Exceeds max cap");

        IERC20(addressBaseToken).safeTransferFrom(
            msg.sender,
            address(this),
            amount
        );

        if (investments[msg.sender] == 0) {
            investors.push(msg.sender);
        }

        investments[msg.sender] += amount;
        totalSharesCommitted += _sharesQuantity;
        totalRaised += amount;

        if (totalRaised == maxCap) {
            status = CampaignStatus.Successful;
            emit CampaignSuccessful(address(this), totalRaised);
        }

        emit FundsCommitted(msg.sender, amount);
    }

    function finalizeCampaign() external {
        if ((block.timestamp >= dateTimeEnd && totalRaised >= minCap)) {
            status = CampaignStatus.Successful;
        }

        if (totalRaised < minCap && block.timestamp >= dateTimeEnd) {
            status = CampaignStatus.Failed;
            emit CampaignFailed(address(this), status);
            return;
        }

        require(
            (block.timestamp >= dateTimeEnd && totalRaised >= minCap) ||
                totalRaised == maxCap,
            "Campaign not ended yet"
        );
        require(
            status == CampaignStatus.Successful,
            "Campaign already finalized"
        );

        if (totalRaised >= minCap) {
            status = CampaignStatus.Successful;

            tokenSupplyEffective = (totalRaised * tokenSupplyOffered) / maxCap;
            for (uint64 i = 0; i < totalMilestones; i++) {
                milestoneSharesMapping[i] =
                    (milestoneSharesMapping[i] * totalSharesCommitted) /
                    tokenSupplyOffered;
            }

            freeFunds(0);
        }

        emit CampaignFinalized(address(this), status);
    }

    function claimFunds() external nonReentrant {
        if (
            block.timestamp > dateTimeEnd &&
            totalRaised < minCap &&
            status == CampaignStatus.Created
        ) {
            status = CampaignStatus.Failed;
            emit CampaignFailed(address(this), status);
        }

        require(status == CampaignStatus.Failed, "Campaign not failed");
        uint256 amount = investments[msg.sender];
        require(amount > 0, "No funds to claim");

        investments[msg.sender] = 0;

        IERC20(addressBaseToken).safeTransfer(msg.sender, amount);

        emit FundsClaimed(msg.sender, amount);
    }

    function requestApproveMilestone(
        uint256 milestoneId,
        string calldata evidence
    ) external {
        require(
            msg.sender == addressPyme,
            "Only Pyme can request milestone approval"
        );
        require(status == CampaignStatus.Successful, "Campaign not successful");
        require(
            milestoneId == currentMilestone,
            "Invalid milestone: not the current one"
        );
        require(milestoneId < totalMilestones, "Invalid milestone ID");
        require(
            !milestoneCompleted[milestoneId],
            "Milestone already completed"
        );
        require(
            !milestoneApprovalRequested[milestoneId],
            "Approval already requested for this milestone"
        );

        milestoneApprovalRequested[milestoneId] = true;

        emit MilestoneApprovalRequested(milestoneId, msg.sender, evidence);
    }

    function completeMilestone(uint256 milestoneId) external {
        require(
            msg.sender == addressAdmin,
            "Only admin can complete milestones"
        );
        require(status == CampaignStatus.Successful, "Campaign not successful");
        require(milestoneId == currentMilestone, "Invalid milestone order");
        require(
            !milestoneCompleted[milestoneId],
            "Milestone already completed"
        );
        require(milestoneId < totalMilestones, "Invalid milestone ID");
        require(
            milestoneApprovalRequested[milestoneId],
            "Milestone approval not requested yet"
        );

        milestoneCompleted[milestoneId] = true;

        freeFunds(milestoneId + 1);

        currentMilestone++;

        uint256 milestoneShares = milestoneSharesMapping[milestoneId];
        uint256 pricePerShare = Math.mulDiv(
            totalRaised,
            1,
            tokenSupplyEffective
        );
        uint256 milestoneAmount = Math.mulDiv(
            milestoneShares,
            pricePerShare,
            1
        );
        emit MilestoneCompleted(milestoneId, milestoneAmount);
    }

    function completeMilestoneByGovernance(uint256 milestoneId) external {
        require(msg.sender == governance, "Only governance");
        require(status == CampaignStatus.Successful, "Campaign not successful");
        require(milestoneId == currentMilestone, "Invalid milestone order");
        require(!milestoneCompleted[milestoneId], "Already completed");
        require(milestoneId < totalMilestones, "Invalid ID");

        milestoneCompleted[milestoneId] = true;
        freeFunds(milestoneId + 1);
        currentMilestone++;

        if (currentMilestone == totalMilestones) {
            status = CampaignStatus.Finalized;
        }

        emit MilestoneCompleted(milestoneId, 0); // amount can be computed if needed
    }

    function getMilestone(
        uint256 milestoneId
    )
        external
        view
        returns (string memory description, uint256 amount, bool completed)
    {
        require(milestoneId < totalMilestones, "Invalid milestone ID");

        uint256 milestoneShares = milestoneSharesMapping[milestoneId];
        uint256 pricePerShare = Math.mulDiv(
            totalRaised,
            1,
            tokenSupplyEffective
        );
        uint256 milestoneAmount = Math.mulDiv(
            milestoneShares,
            pricePerShare,
            1
        );

        return (
            milestoneMapping[milestoneId],
            milestoneAmount,
            milestoneCompleted[milestoneId]
        );
    }

    function claimTokens(uint256 milestoneId) external nonReentrant {
        require(
            status == CampaignStatus.Successful ||
                status == CampaignStatus.Finalized,
            "Campaign not successful"
        );
        require(
            tokensCalculated[milestoneId],
            "Tokens not ready for this milestone"
        );
        require(
            !tokensClaimed[milestoneId][msg.sender],
            "Tokens already claimed"
        );
        require(investments[msg.sender] > 0, "No investment found");

        uint256 milestoneShares = milestoneSharesMapping[milestoneId];
        uint256 tokensForInvestor = (milestoneShares *
            investments[msg.sender]) / totalRaised;

        require(tokensForInvestor > 0, "No tokens to claim");

        tokensClaimed[milestoneId][msg.sender] = true;

        IERC20(addressContractToken).safeTransfer(
            msg.sender,
            tokensForInvestor
        );
        EquityTokenInterface(addressContractToken).delegate(msg.sender);

        emit TokensDistributed(msg.sender, tokensForInvestor);
    }

    function getClaimableTokens(
        uint256 milestoneId,
        address investor
    ) external view returns (uint256) {
        if (!tokensCalculated[milestoneId]) return 0;
        if (tokensClaimed[milestoneId][investor]) return 0;
        if (investments[investor] == 0) return 0;

        uint256 milestoneShares = milestoneSharesMapping[milestoneId];
        return (milestoneShares * investments[investor]) / totalRaised;
    }

    function finalizeContract(uint256 milestoneId) private {
        require(milestoneId == totalMilestones, "Invalid milestone ID");
        status = CampaignStatus.Finalized;
        emit CampaignFinalized(address(this), status);
    }

    function freeFunds(uint256 milestoneId) private {
        if (milestoneId == totalMilestones) {
            finalizeContract(milestoneId);
            return;
        }

        uint256 milestoneShares = milestoneSharesMapping[milestoneId];
        require(milestoneShares > 0, "Invalid milestone shares");

        uint256 pricePerShare = Math.mulDiv(
            totalRaised,
            1,
            tokenSupplyEffective
        );
        uint256 milestoneNoFee = Math.mulDiv(
            milestoneShares,
            pricePerShare,
            1
        ) * 10000;
        uint256 milestoneAmount = Math.mulDiv(
            milestoneNoFee,
            (10000 - platformFee),
            100000000
        );

        uint256 feeAmount = 0;
        if (milestoneId == 0 && !feePaid) {
            feeAmount = Math.mulDiv(totalRaised, platformFee, 10000);
            feePaid = true;
        }

        uint256 tokensForMilestone = milestoneShares;

        EquityTokenInterface(addressContractToken).mint(
            address(this),
            tokensForMilestone
        );

        if (feeAmount > 0) {
            IERC20(addressBaseToken).safeTransfer(addressAdmin, feeAmount);
        }

        IERC20(addressBaseToken).safeTransfer(addressPyme, milestoneAmount);

        tokensCalculated[milestoneId] = true;
        emit MilestoneTokensReady(milestoneId, tokensForMilestone);
    }
}

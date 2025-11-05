// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface CampaignInterface {
    enum CampaignStatus {
        Created,
        Active,
        Successful,
        Failed,
        Finalized
    }

    // ============ EVENTS ============

    event CampaignCreated(
        address indexed campaignAddress,
        address indexed creator
    );
    event CampaignFinalized(
        address indexed campaignAddress,
        CampaignStatus status
    );
    event CampaignFailed(
        address indexed campaignAddress,
        CampaignStatus status
    );
    event FundsCommitted(address indexed investor, uint256 amount);
    event FundsClaimed(address indexed investor, uint256 amount);
    event MilestoneCompleted(
        uint256 indexed milestoneId,
        uint256 amountReleased
    );
    event TokensDistributed(address indexed investor, uint256 amount);
    event MilestoneApprovalRequested(
        uint256 indexed milestoneId,
        address indexed requester,
        string evidence
    );
    event CampaignSuccessful(
        address indexed campaignAddress,
        uint256 totalRaised
    );

    // ============ INITIALIZATION FUNCTIONS ============

    /**
     * @dev Initializes a cloned campaign with all its parameters
     * @param _addressPyme Address of the Pyme wallet
     * @param _addressAdmin Address of the admin/platform
     * @param _campaignFactory Address of the CampaignFactory contract
     * @param _addressContractToken Address of the equity token (ERC20)
     * @param _addressBaseToken Address of the investment token (USDC, etc.)
     * @param _maxCap Hard cap (maximum goal)
     * @param _minCap Soft cap (minimum goal)
     * @param _dateTimeEnd Campaign closing timestamp
     * @param _tokenSupplyOffered Maximum token supply to offer
     * @param _platformFee Platform fee in basis points (300 = 3%)
     * @param _milestoneDescriptions Array of milestone descriptions
     * @param _milestoneShares Array of share quantities (equity tokens) per milestone (sum = _tokenSupplyOffered)
     */
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
    ) external;

    // ============ INVESTMENT FUNCTIONS ============

    /**
     * @dev Allows investors to commit a quantity of equity shares
     * @param sharesQuantity Number of equity shares to acquire
     * @notice The contract will automatically calculate the required base token amount
     */
    function commitFunds(uint256 sharesQuantity) external;

    /**
     * @dev Allows investors to reclaim funds if the campaign fails
     */
    function claimFunds() external;

    // ============ FINALIZATION FUNCTIONS ============

    /**
     * @dev Finalizes the campaign upon reaching dateTimeEnd
     * Determines if it was successful (totalRaised >= minCap) or failed
     * If successful, automatically releases milestone 0
     */
    function finalizeCampaign() external;

    // ============ MILESTONE FUNCTIONS ============

    /**
     * @dev Pyme requests approval for a completed milestone
     * @param milestoneId Milestone ID (0, 1, 2...)
     * @param evidence URL or hash of evidence of completed work
     */
    function requestApproveMilestone(
        uint256 milestoneId,
        string calldata evidence
    ) external;

    /**
     * @dev Admin approves a milestone and releases funds/tokens
     * @param milestoneId Milestone ID to complete
     */
    function completeMilestone(uint256 milestoneId) external;

    /**
     * @dev Queries milestone information
     * @param milestoneId Milestone ID
     * @return description Milestone description
     * @return amount Calculated amount based on totalRaised
     * @return completed Whether the milestone was completed
     */
    function getMilestone(
        uint256 milestoneId
    )
        external
        view
        returns (string memory description, uint256 amount, bool completed);
}

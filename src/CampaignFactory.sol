// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.30;

import "./interfaces/CampaignFactoryInterface.sol";

contract CampaignFactory is CampaignFactoryInterface {  
    CampaignStatus public status;
    bool public campaignInitialized;
    bool public fundedCompleted;
    uint256 public maxCap;
    uint256 public minCap;

    address public addressPyme;
    address public addressAdmin;
    address public addressContractToken;
    address public addressBaseToken;

    uint256 public dateTimeEnd;

    address[] public deployedCampaigns;

    mapping(uint256 => string) milestoneMapping;
    mapping(uint256 => uint256) milestoneAmountMapping;

    mapping(uint256 => uint64) feeMapping;

    modifier onlyNewCampaign() {
        require(!campaignInitialized, "Campaign already initialized");
        _;
    }

    constructor(
        address _addressAdmin,
        address _addressBaseToken
    ) {
        addressAdmin = _addressAdmin;
        addressBaseToken = _addressBaseToken;
    }

    function initialize(
        address _addressPyme,
        address _addressContractToken,
        uint256 _maxCap,
        uint256 _minCap,
        uint256 _dateTimeEnd
    ) external onlyNewCampaign {
        addressPyme = _addressPyme;
        addressContractToken = _addressContractToken;
        maxCap = _maxCap;
        minCap = _minCap;
        dateTimeEnd = _dateTimeEnd;
        status = CampaignStatus.Created;
        campaignInitialized = true;
        emit CampaignCreated(address(this), msg.sender);
    }
    
    function createCampaign() public {
        deployedCampaigns.push(msg.sender);
    }

    function finalizeCampaign() public {}
    function commitFunds() public {}
    function claimFunds() public {}
    function approveMilestone() public {}
    function completeMilestone() public {}
    function finalizeContract() public {}
    function getMilestone() public {}
    function freeFunds() private {}
}
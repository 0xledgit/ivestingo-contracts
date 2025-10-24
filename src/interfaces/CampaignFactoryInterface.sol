// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.30;

interface CampaignFactoryInterface {
    enum CampaignStatus {
        Created,
        Active,
        Successful,
        Failed
    }

    event CampaignCreated(address indexed campaignAddress, address indexed creator);
    event CampaignFinalized(address indexed campaignAddress, CampaignStatus status);

    function createCampaign() external;
    function finalizeCampaign() external;
    function commitFunds() external;
    function claimFunds() external;
    function approveMilestone() external;
    function completeMilestone() external;
    function finalizeContract() external;
    function getMilestone() external;
}
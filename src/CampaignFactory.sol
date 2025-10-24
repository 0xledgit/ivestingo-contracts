// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.30;

contract CampaignFactory {
    address[] public deployedCampaigns;

    function createCampaign() public {
        deployedCampaigns.push(msg.sender);
    }
}
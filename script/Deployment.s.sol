// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/CampaignFactory.sol";

contract DeploymentScript is Script {
    function run() external {
        vm.startBroadcast();

        address campaignFactory = address(new CampaignFactory(
            address(0x1),
            address(0x2)
        ));

        console.log("CampaignFactory deployed at:", campaignFactory);

        vm.stopBroadcast();
    }
}
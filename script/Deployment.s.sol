// SPDX-Licence-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Script.sol";
import "../src/CampaignFactory.sol";
import {MockERC20} from "../test/mocks/MockERC20.sol";

contract DeploymentScript is Script {
    function run() external {
        vm.startBroadcast();

        address mockERC20 = address(new MockERC20("MOCK_COP", "COP"));
        address campaignFactory = address(new CampaignFactory(
            address(0x05703526dB38D9b2C661c9807367C14EB98b6c54),
            mockERC20
        ));

        console.log("CampaignFactory deployed at:", campaignFactory);
        console.log("Mock erc 20 deployed at:", mockERC20);

        vm.stopBroadcast();
    }
}
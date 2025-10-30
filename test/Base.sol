// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "forge-std/Test.sol";
import "../src/Campaign.sol";
import "../src/CampaignFactory.sol";
import "../src/EquityToken.sol";
import "./Mocks/MockERC20.sol";

contract BaseTest is Test {
    Campaign public campaign;
    CampaignFactory public factory;
    EquityToken public equityToken;
    MockERC20 public baseToken;

    address public admin;
    address public pyme;
    address public investor1;
    address public investor2;
    address public investor3;

    uint256 public maxCap;
    uint256 public minCap;
    uint256 public dateTimeEnd;
    uint256 public tokenSupplyOffered;
    uint256 public platformFee;

    string[] public milestoneDescriptions;
    uint256[] public milestoneShares;

    function setUp() public virtual {
        admin = makeAddr("admin");
        pyme = makeAddr("pyme");
        investor1 = makeAddr("investor1");
        investor2 = makeAddr("investor2");
        investor3 = makeAddr("investor3");

        vm.startPrank(admin);
        baseToken = new MockERC20("Mock COP", "COP");
        factory = new CampaignFactory(admin, address(baseToken));
        vm.stopPrank();

        maxCap = 100000 * 10 ** 6;
        minCap = 50000 * 10 ** 6;
        dateTimeEnd = block.timestamp + 30 days;
        tokenSupplyOffered = 10000;
        platformFee = 500;

        milestoneDescriptions.push("Product development");
        milestoneDescriptions.push("Market launch");
        milestoneDescriptions.push("Scaling operations");

        milestoneShares.push(3000);
        milestoneShares.push(3000);
        milestoneShares.push(4000);

        baseToken.mint(investor1, 100000 * 10 ** 6);
        baseToken.mint(investor2, 100000 * 10 ** 6);
        baseToken.mint(investor3, 100000 * 10 ** 6);
    }

    function createBaseCampaign() internal {
        (address campaignAddress, address tokenAddress) = factory.createCampaign(
            "TestEquity",
            "TEQ",
            pyme,
            maxCap,
            minCap,
            dateTimeEnd,
            tokenSupplyOffered,
            platformFee,
            milestoneDescriptions,
            milestoneShares
        );

        campaign = Campaign(campaignAddress);
        equityToken = EquityToken(tokenAddress);
    }
}

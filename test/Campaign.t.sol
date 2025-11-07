// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./Base.sol";

contract CampaignTest is BaseTest {
    function setUp() public override {
        super.setUp();
        createBaseCampaign();
    }

    function test_commitFunds_success() public {
        uint256 sharesToBuy = 1000;
        uint256 amountToPay = (sharesToBuy * maxCap) / tokenSupplyOffered;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        assertEq(campaign.investments(investor1), amountToPay);
        assertEq(campaign.totalRaised(), amountToPay);
        assertEq(campaign.totalSharesCommitted(), sharesToBuy);
    }

    function test_commitFunds_multipleInvestors() public {
        uint256 sharesToBuy = 2000;
        uint256 amountToPay = (sharesToBuy * maxCap) / tokenSupplyOffered;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        vm.startPrank(investor2);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        assertEq(campaign.totalRaised(), amountToPay * 2);
        assertEq(campaign.totalSharesCommitted(), sharesToBuy * 2);
    }

    function test_commitFunds_reachMaxCap() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        assertEq(campaign.totalRaised(), maxCap);
        assertEq(uint256(campaign.status()), uint256(CampaignInterface.CampaignStatus.Successful));
    }

    function test_commitFunds_exceedsMaxCap() public {
        uint256 sharesToBuy = tokenSupplyOffered + 1;
        uint256 amountToPay = (sharesToBuy * maxCap) / tokenSupplyOffered;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        vm.expectRevert("Exceeds max cap");
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();
    }

    function test_commitFunds_campaignEnded() public {
        vm.warp(dateTimeEnd + 1);

        uint256 sharesToBuy = 1000;
        uint256 amountToPay = (sharesToBuy * maxCap) / tokenSupplyOffered;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        vm.expectRevert("Campaign ended");
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();
    }

    function test_finalizeCampaign_successAtMinCap() public {
        uint256 sharesToBuy = (minCap * tokenSupplyOffered) / maxCap;
        uint256 amountToPay = minCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        vm.warp(dateTimeEnd + 1);

        campaign.finalizeCampaign();

        assertEq(uint256(campaign.status()), uint256(CampaignInterface.CampaignStatus.Successful));
        assertEq(campaign.tokenSupplyEffective(), sharesToBuy);
    }

    function test_finalizeCampaign_successAtMaxCap() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        assertEq(uint256(campaign.status()), uint256(CampaignInterface.CampaignStatus.Successful));
        assertEq(campaign.tokenSupplyEffective(), tokenSupplyOffered);
    }

    function test_finalizeCampaign_failedBelowMinCap() public {
        uint256 sharesToBuy = 1000;
        uint256 amountToPay = (sharesToBuy * maxCap) / tokenSupplyOffered;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        vm.warp(dateTimeEnd + 1);

        campaign.finalizeCampaign();

        assertEq(uint256(campaign.status()), uint256(CampaignInterface.CampaignStatus.Failed));
    }

    function test_finalizeCampaign_notEndedYet() public {
        uint256 sharesToBuy = 1000;
        uint256 amountToPay = (sharesToBuy * maxCap) / tokenSupplyOffered;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        vm.expectRevert("Campaign not ended yet");
        campaign.finalizeCampaign();
    }

    function test_finalizeCampaign_distributesFirstMilestone() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        uint256 pymeBalanceBefore = baseToken.balanceOf(pyme);
        uint256 adminBalanceBefore = baseToken.balanceOf(admin);

        campaign.finalizeCampaign();

        uint256 pymeBalanceAfter = baseToken.balanceOf(pyme);
        uint256 adminBalanceAfter = baseToken.balanceOf(admin);

        assertGt(pymeBalanceAfter, pymeBalanceBefore);
        assertGt(adminBalanceAfter, adminBalanceBefore);

        assertTrue(campaign.tokensCalculated(0));

        vm.prank(investor1);
        campaign.claimTokens(0);

        assertGt(equityToken.balanceOf(investor1), 0);
    }

    function test_claimFunds_success() public {
        uint256 sharesToBuy = 1000;
        uint256 amountToPay = (sharesToBuy * maxCap) / tokenSupplyOffered;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        vm.warp(dateTimeEnd + 1);

        campaign.finalizeCampaign();

        uint256 balanceBefore = baseToken.balanceOf(investor1);

        vm.prank(investor1);
        campaign.claimFunds();

        uint256 balanceAfter = baseToken.balanceOf(investor1);

        assertEq(balanceAfter, balanceBefore + amountToPay);
        assertEq(campaign.investments(investor1), 0);
    }

    function test_claimFunds_multipleInvestors() public {
        uint256 sharesToBuy = 1000;
        uint256 amountToPay = (sharesToBuy * maxCap) / tokenSupplyOffered;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        vm.startPrank(investor2);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        vm.warp(dateTimeEnd + 1);

        campaign.finalizeCampaign();

        uint256 balance1Before = baseToken.balanceOf(investor1);
        uint256 balance2Before = baseToken.balanceOf(investor2);

        vm.prank(investor1);
        campaign.claimFunds();

        vm.prank(investor2);
        campaign.claimFunds();

        assertEq(baseToken.balanceOf(investor1), balance1Before + amountToPay);
        assertEq(baseToken.balanceOf(investor2), balance2Before + amountToPay);
    }

    function test_claimFunds_campaignNotFailed() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        vm.prank(investor1);
        vm.expectRevert("Campaign not failed");
        campaign.claimFunds();
    }

    function test_claimFunds_noFundsToClaim() public {
        vm.warp(dateTimeEnd + 1);

        campaign.finalizeCampaign();

        vm.prank(investor1);
        vm.expectRevert("No funds to claim");
        campaign.claimFunds();
    }

    function test_requestApproveMilestone_success() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        vm.prank(pyme);
        campaign.requestApproveMilestone(0, "Completed product development");

        assertTrue(campaign.milestoneApprovalRequested(0));
    }

    function test_requestApproveMilestone_onlyPyme() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        vm.prank(investor1);
        vm.expectRevert("Only Pyme can request milestone approval");
        campaign.requestApproveMilestone(0, "Evidence");
    }

    function test_requestApproveMilestone_campaignNotSuccessful() public {
        vm.prank(pyme);
        vm.expectRevert("Campaign not successful");
        campaign.requestApproveMilestone(0, "Evidence");
    }

    function test_requestApproveMilestone_invalidMilestone() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        vm.prank(pyme);
        vm.expectRevert("Invalid milestone: not the current one");
        campaign.requestApproveMilestone(1, "Evidence");
    }

    function test_requestApproveMilestone_alreadyRequested() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        vm.startPrank(pyme);
        campaign.requestApproveMilestone(0, "Evidence");
        vm.expectRevert("Approval already requested for this milestone");
        campaign.requestApproveMilestone(0, "Evidence again");
        vm.stopPrank();
    }

    function test_completeMilestone_success() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        vm.prank(pyme);
        campaign.requestApproveMilestone(0, "Evidence");

        uint256 pymeBalanceBefore = baseToken.balanceOf(pyme);
        uint256 investorTokensBefore = equityToken.balanceOf(investor1);

        vm.prank(admin);
        campaign.completeMilestone(0);

        assertTrue(campaign.milestoneCompleted(0));
        assertEq(campaign.currentMilestone(), 1);
        assertGt(baseToken.balanceOf(pyme), pymeBalanceBefore);

        assertTrue(campaign.tokensCalculated(1));

        vm.prank(investor1);
        campaign.claimTokens(1);

        assertGt(equityToken.balanceOf(investor1), investorTokensBefore);
    }

    function test_completeMilestone_multipleMilestones() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        vm.prank(pyme);
        campaign.requestApproveMilestone(0, "Evidence 1");

        vm.prank(admin);
        campaign.completeMilestone(0);

        assertEq(campaign.currentMilestone(), 1);

        vm.prank(pyme);
        campaign.requestApproveMilestone(1, "Evidence 2");

        vm.prank(admin);
        campaign.completeMilestone(1);

        assertEq(campaign.currentMilestone(), 2);
        assertTrue(campaign.milestoneCompleted(0));
        assertTrue(campaign.milestoneCompleted(1));
    }

    function test_completeMilestone_onlyAdmin() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        vm.prank(pyme);
        campaign.requestApproveMilestone(0, "Evidence");

        vm.prank(investor1);
        vm.expectRevert("Only admin can complete milestones");
        campaign.completeMilestone(0);
    }

    function test_completeMilestone_notRequested() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        vm.prank(admin);
        vm.expectRevert("Milestone approval not requested yet");
        campaign.completeMilestone(0);
    }

    function test_completeMilestone_invalidOrder() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        vm.prank(pyme);
        campaign.requestApproveMilestone(0, "Evidence");

        vm.prank(admin);
        vm.expectRevert("Invalid milestone order");
        campaign.completeMilestone(1);
    }

    function test_completeMilestone_alreadyCompleted() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        vm.prank(pyme);
        campaign.requestApproveMilestone(0, "Evidence");

        vm.prank(admin);
        campaign.completeMilestone(0);

        vm.prank(admin);
        vm.expectRevert("Invalid milestone order");
        campaign.completeMilestone(0);
    }

    function test_freeFunds_distributesTokensCorrectly() public {
        uint256 sharesToBuy1 = 6000;
        uint256 sharesToBuy2 = 4000;

        uint256 amountToPay1 = (sharesToBuy1 * maxCap) / tokenSupplyOffered;
        uint256 amountToPay2 = (sharesToBuy2 * maxCap) / tokenSupplyOffered;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay1);
        campaign.commitFunds(sharesToBuy1);
        vm.stopPrank();

        vm.startPrank(investor2);
        baseToken.approve(address(campaign), amountToPay2);
        campaign.commitFunds(sharesToBuy2);
        vm.stopPrank();

        campaign.finalizeCampaign();

        assertTrue(campaign.tokensCalculated(0));

        vm.prank(investor1);
        campaign.claimTokens(0);

        vm.prank(investor2);
        campaign.claimTokens(0);

        uint256 expectedTokensInv1 = (milestoneShares[0] * amountToPay1) / maxCap;
        uint256 expectedTokensInv2 = (milestoneShares[0] * amountToPay2) / maxCap;

        assertEq(equityToken.balanceOf(investor1), expectedTokensInv1);
        assertEq(equityToken.balanceOf(investor2), expectedTokensInv2);
    }

    function test_freeFunds_paysPlatformFee() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        uint256 adminBalanceBefore = baseToken.balanceOf(admin);

        campaign.finalizeCampaign();

        uint256 adminBalanceAfter = baseToken.balanceOf(admin);
        uint256 expectedFee = (maxCap * platformFee) / 10000;

        assertEq(adminBalanceAfter - adminBalanceBefore, expectedFee);
        assertTrue(campaign.feePaid());
    }

    function test_finalizeContract_allMilestonesCompleted() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        for (uint256 i = 0; i < 3; i++) {
            vm.prank(pyme);
            campaign.requestApproveMilestone(i, "Evidence");

            vm.prank(admin);
            campaign.completeMilestone(i);
        }

        assertEq(uint256(campaign.status()), uint256(CampaignInterface.CampaignStatus.Finalized));

        for (uint256 i = 0; i < 3; i++) {
            vm.prank(investor1);
            campaign.claimTokens(i);
        }

        assertEq(equityToken.balanceOf(investor1), tokenSupplyOffered);
    }

    function test_finalizeContract_tokensDistributedProperly() public {
        uint256 sharesToBuy1 = 3000;
        uint256 sharesToBuy2 = 3000;
        uint256 sharesToBuy3 = 4000;

        uint256 amountToPay1 = (sharesToBuy1 * maxCap) / tokenSupplyOffered;
        uint256 amountToPay2 = (sharesToBuy2 * maxCap) / tokenSupplyOffered;
        uint256 amountToPay3 = (sharesToBuy3 * maxCap) / tokenSupplyOffered;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay1);
        campaign.commitFunds(sharesToBuy1);
        vm.stopPrank();

        vm.startPrank(investor2);
        baseToken.approve(address(campaign), amountToPay2);
        campaign.commitFunds(sharesToBuy2);
        vm.stopPrank();

        vm.startPrank(investor3);
        baseToken.approve(address(campaign), amountToPay3);
        campaign.commitFunds(sharesToBuy3);
        vm.stopPrank();

        campaign.finalizeCampaign();

        for (uint256 i = 0; i < 3; i++) {
            vm.prank(pyme);
            campaign.requestApproveMilestone(i, "Evidence");

            vm.prank(admin);
            campaign.completeMilestone(i);
        }

        for (uint256 i = 0; i < 3; i++) {
            vm.prank(investor1);
            campaign.claimTokens(i);

            vm.prank(investor2);
            campaign.claimTokens(i);

            vm.prank(investor3);
            campaign.claimTokens(i);
        }

        assertEq(equityToken.balanceOf(investor1), sharesToBuy1);
        assertEq(equityToken.balanceOf(investor2), sharesToBuy2);
        assertEq(equityToken.balanceOf(investor3), sharesToBuy3);
        assertEq(equityToken.totalSupply(), tokenSupplyOffered);
    }

    function test_getMilestone_returnsCorrectInfo() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        (string memory description, uint256 amount, bool completed) = campaign.getMilestone(0);

        assertEq(description, "Product development");
        assertGt(amount, 0);
        assertFalse(completed);

        vm.prank(pyme);
        campaign.requestApproveMilestone(0, "Evidence");

        vm.prank(admin);
        campaign.completeMilestone(0);

        (, , bool completedAfter) = campaign.getMilestone(0);
        assertTrue(completedAfter);
    }

    function test_claimTokens_success() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        assertTrue(campaign.tokensCalculated(0));

        vm.prank(investor1);
        campaign.claimTokens(0);

        assertEq(equityToken.balanceOf(investor1), milestoneShares[0]);
        assertTrue(campaign.tokensClaimed(0, investor1));
    }

    function test_claimTokens_alreadyClaimed() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        vm.prank(investor1);
        campaign.claimTokens(0);

        vm.prank(investor1);
        vm.expectRevert("Tokens already claimed");
        campaign.claimTokens(0);
    }

    function test_claimTokens_tokensNotReady() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        vm.prank(investor1);
        vm.expectRevert("Tokens not ready for this milestone");
        campaign.claimTokens(1);
    }

    function test_claimTokens_noInvestment() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        vm.prank(investor2);
        vm.expectRevert("No investment found");
        campaign.claimTokens(0);
    }

    function test_getClaimableTokens_success() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        uint256 claimable = campaign.getClaimableTokens(0, investor1);
        assertEq(claimable, milestoneShares[0]);
    }

    function test_getClaimableTokens_afterClaimed() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        vm.prank(investor1);
        campaign.claimTokens(0);

        uint256 claimable = campaign.getClaimableTokens(0, investor1);
        assertEq(claimable, 0);
    }

    function test_getClaimableTokens_notReady() public {
        uint256 sharesToBuy = tokenSupplyOffered;
        uint256 amountToPay = maxCap;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay);
        campaign.commitFunds(sharesToBuy);
        vm.stopPrank();

        campaign.finalizeCampaign();

        uint256 claimable = campaign.getClaimableTokens(1, investor1);
        assertEq(claimable, 0);
    }

    function test_claimTokens_multipleInvestorsProportional() public {
        uint256 sharesToBuy1 = 6000;
        uint256 sharesToBuy2 = 4000;

        uint256 amountToPay1 = (sharesToBuy1 * maxCap) / tokenSupplyOffered;
        uint256 amountToPay2 = (sharesToBuy2 * maxCap) / tokenSupplyOffered;

        vm.startPrank(investor1);
        baseToken.approve(address(campaign), amountToPay1);
        campaign.commitFunds(sharesToBuy1);
        vm.stopPrank();

        vm.startPrank(investor2);
        baseToken.approve(address(campaign), amountToPay2);
        campaign.commitFunds(sharesToBuy2);
        vm.stopPrank();

        campaign.finalizeCampaign();

        uint256 claimable1 = campaign.getClaimableTokens(0, investor1);
        uint256 claimable2 = campaign.getClaimableTokens(0, investor2);

        assertEq(claimable1, (milestoneShares[0] * amountToPay1) / maxCap);
        assertEq(claimable2, (milestoneShares[0] * amountToPay2) / maxCap);

        vm.prank(investor1);
        campaign.claimTokens(0);

        vm.prank(investor2);
        campaign.claimTokens(0);

        assertEq(equityToken.balanceOf(investor1), claimable1);
        assertEq(equityToken.balanceOf(investor2), claimable2);
    }
}

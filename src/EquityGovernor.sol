// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";
import "@openzeppelin/contracts/utils/introspection/IERC165.sol";

contract EquityGovernor is
    Governor,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorCountingSimple
{
    constructor(IVotes _token)
        Governor("EquityGovernor")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4)
    {}

    function votingDelay() public pure override returns (uint256) {
        return 60;
    }

    function votingPeriod() public pure override returns (uint256) {
        return 180;
    }

    function proposalThreshold() public pure override returns (uint256) {
        return 0;
    }
}
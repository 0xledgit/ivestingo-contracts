// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "@openzeppelin/contracts/governance/Governor.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotes.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorVotesQuorumFraction.sol";
import "@openzeppelin/contracts/governance/extensions/GovernorCountingSimple.sol";

contract EquityGovernor is
    Governor,
    GovernorVotes,
    GovernorVotesQuorumFraction,
    GovernorCountingSimple
{
    constructor(IVotes _token)
        Governor("EquityGovernor")
        GovernorVotes(_token)
        GovernorVotesQuorumFraction(4) // 4% quorum
    {}

    // 1 day delay (in blocks ~7200) — adjust if using timestamps
    function votingDelay() public pure override returns (uint256) {
        return 7200;
    }

    // 1 week voting period
    function votingPeriod() public pure override returns (uint256) {
        return 50400;
    }

    // Anyone can propose (set >0 to require min voting power)
    function proposalThreshold() public pure override returns (uint256) {
        return 0;
    }

    // Optional: allow execution without timelock
    function _execute(
        uint256 proposalId,
        address[] memory targets,
        uint256[] memory values,
        bytes[] memory calldatas,
        bytes32 descriptionHash
    ) internal override(Governor) {
        // No timelock: execute directly
        for (uint256 i = 0; i < targets.length; ++i) {
            (bool success, bytes memory returndata) = targets[i].call{value: values[i]}(calldatas[i]);
            if (!success) {
                if (returndata.length > 0) {
                    // Forward revert reason
                    assembly {
                        let returndata_size := mload(returndata)
                        revert(add(32, returndata), returndata_size)
                    }
                } else {
                    revert("Governor: call reverted without message");
                }
            }
        }
    }

    // Required for compatibility
    function supportsInterface(bytes4 interfaceId)
        public view override(Governor, IERC165)
        returns (bool)
    {
        return super.supportsInterface(interfaceId);
    }
}
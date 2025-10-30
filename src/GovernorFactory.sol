// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import "./EquityGovernor.sol";

/**
 * @title GovernorFactory
 * @dev Factory to deploy EquityGovernor contracts
 * This contract separates the governor creation logic from CampaignFactory
 * to reduce the bytecode size of CampaignFactory
 * @author Ledgit (https://github.com/0xledgit)
 */
contract GovernorFactory {
    event GovernorCreated(address indexed governor, address indexed token);

    /**
     * @dev Creates a new EquityGovernor
     * @param _token The ERC20Votes token that will be used for voting
     * @return governor The address of the newly created governor
     */
    function createGovernor(IVotes _token) external returns (address governor) {
        governor = address(new EquityGovernor(_token));

        emit GovernorCreated(governor, address(_token));

        return governor;
    }
}

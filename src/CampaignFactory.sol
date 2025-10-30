// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import "./Campaign.sol";
import "./EquityToken.sol";
import "./interfaces/CampaignFactoryInterface.sol";
import "./GovernorFactory.sol";

/**
 * @title CampaignFactory
 * @dev Factory to deploy equity crowdfunding campaigns using the clone pattern (EIP-1167)
 * @author Ledgit (https://github.com/0xledgit)
 */
contract CampaignFactory is CampaignFactoryInterface {
    address public immutable CAMPAIGN_IMPLEMENTATION;
    address public immutable ADDRESS_ADMIN;
    address public immutable ADDRESS_BASE_TOKEN;
    GovernorFactory public immutable GOVERNOR_FACTORY;

    address[] public deployedCampaigns;
    mapping(address => address[]) public campaignsByPyme;

    constructor(address _addressAdmin, address _addressBaseToken) {
        ADDRESS_ADMIN = _addressAdmin;
        ADDRESS_BASE_TOKEN = _addressBaseToken;

        CAMPAIGN_IMPLEMENTATION = address(new Campaign());
        GOVERNOR_FACTORY = new GovernorFactory();
    }

    /**
     * @dev Creates a new campaign by cloning the implementation and deploying a new EquityToken
     */
    function createCampaign(
        string memory tokenName,
        string memory tokenSymbol,
        address _addressPyme,
        uint256 _maxCap,
        uint256 _minCap,
        uint256 _dateTimeEnd,
        uint256 _tokenSupplyOffered,
        uint256 _platformFee,
        string[] memory _milestoneDescriptions,
        uint256[] memory _milestonePercentages
    ) external returns (address campaignAddress, address tokenAddress) {
        campaignAddress = Clones.clone(CAMPAIGN_IMPLEMENTATION);

        tokenAddress = address(
            new EquityToken(
                tokenName,
                tokenSymbol,
                _tokenSupplyOffered,
                campaignAddress
            )
        );

        Campaign(campaignAddress).initialize(
            _addressPyme,
            ADDRESS_ADMIN,
            address(this),
            tokenAddress,
            ADDRESS_BASE_TOKEN,
            _maxCap,
            _minCap,
            _dateTimeEnd,
            _tokenSupplyOffered,
            _platformFee,
            _milestoneDescriptions,
            _milestonePercentages
        );

        address governor = GOVERNOR_FACTORY.createGovernor(IVotes(tokenAddress));
        Campaign(campaignAddress).setGovernance(governor);

        deployedCampaigns.push(campaignAddress);
        campaignsByPyme[_addressPyme].push(campaignAddress);

        emit CampaignDeployed(
            campaignAddress,
            _addressPyme,
            tokenAddress,
            msg.sender
        );

        return (campaignAddress, tokenAddress);
    }

    /**
     * @dev Returns the list of deployed campaigns
     */
    function getDeployedCampaigns() external view returns (address[] memory) {
        return deployedCampaigns;
    }

    /**
     * @dev Returns the list of campaigns associated with a pyme
     */
    function getCampaignsByPyme(
        address pyme
    ) external view returns (address[] memory) {
        return campaignsByPyme[pyme];
    }

    /**
     * @dev Returns the total number of deployed campaigns
     */
    function getTotalCampaigns() external view returns (uint256) {
        return deployedCampaigns.length;
    }
}

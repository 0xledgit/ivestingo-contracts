// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

import {Clones} from "@openzeppelin/contracts/proxy/Clones.sol";
import "./Campaign.sol";
import "./EquityToken.sol";
import "./interfaces/CampaignFactoryInterface.sol";

/**
 * @title CampaignFactory
 * @dev Fábrica para desplegar campañas de equity crowdfunding usando el patrón de clonado (EIP-1167)
 * @author Ledgit (https://github.com/0xledgit)
 */
contract CampaignFactory is CampaignFactoryInterface {
    address public immutable CAMPAIGN_IMPLEMENTATION;
    address public immutable ADDRESS_ADMIN;
    address public immutable ADDRESS_BASE_TOKEN;

    address[] public deployedCampaigns;
    mapping(address => address[]) public campaignsByPyme;

    constructor(address _addressAdmin, address _addressBaseToken) {
        ADDRESS_ADMIN = _addressAdmin;
        ADDRESS_BASE_TOKEN = _addressBaseToken;

        CAMPAIGN_IMPLEMENTATION = address(new Campaign());
    }

    /**
     * @dev Crea una nueva campaña clonando la implementación y desplegando un nuevo EquityToken
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
     * @dev Retorna la lista de campañas desplegadas
     */
    function getDeployedCampaigns() external view returns (address[] memory) {
        return deployedCampaigns;
    }

    /**
     * @dev Retorna la lista de campañas asociadas a una pyme
     */
    function getCampaignsByPyme(
        address pyme
    ) external view returns (address[] memory) {
        return campaignsByPyme[pyme];
    }

    /**
     * @dev Retorna el total de campañas desplegadas
     */
    function getTotalCampaigns() external view returns (uint256) {
        return deployedCampaigns.length;
    }
}

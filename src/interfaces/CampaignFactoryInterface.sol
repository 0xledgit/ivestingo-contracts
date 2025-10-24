// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface CampaignFactoryInterface {

    // ============ EVENTOS ============

    /**
     * @dev Emitido cuando se despliega una nueva campaña
     * @param campaignAddress Dirección del contrato Campaign clonado
     * @param pyme Dirección de la Pyme dueña de la campaña
     * @param equityToken Dirección del token de equity creado
     * @param creator Dirección que llamó a createCampaign
     */
    event CampaignDeployed(
        address indexed campaignAddress,
        address indexed pyme,
        address indexed equityToken,
        address creator
    );

    // ============ FUNCIONES DE CREACIÓN ============

    /**
     * @dev Crea una nueva campaña usando el patrón Clone (EIP-1167)
     * @param tokenName Nombre del token de equity (ej: "EcoPlastix S.A. Equity")
     * @param tokenSymbol Símbolo del token (ej: "EPE")
     * @param _addressPyme Dirección de la wallet de la Pyme
     * @param _maxCap Hard cap (objetivo máximo) en wei
     * @param _minCap Soft cap (objetivo mínimo) en wei
     * @param _dateTimeEnd Timestamp de cierre de la campaña
     * @param _tokenSupplyOffered Supply máximo de tokens a ofrecer
     * @param _platformFee Fee de plataforma en basis points (300 = 3%)
     * @param _milestoneDescriptions Array de descripciones de milestones
     * @param _milestonePercentages Array de porcentajes en basis points (suma = 10000)
     * @return campaignAddress Dirección del contrato Campaign creado
     * @return tokenAddress Dirección del token de equity creado
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
    ) external returns (address campaignAddress, address tokenAddress);

    // ============ FUNCIONES DE CONSULTA ============

    /**
     * @dev Retorna todas las campañas desplegadas
     * @return Array con direcciones de todas las campañas
     */
    function getDeployedCampaigns() external view returns (address[] memory);

    /**
     * @dev Retorna las campañas de una Pyme específica
     * @param pyme Dirección de la Pyme
     * @return Array con direcciones de campañas de la Pyme
     */
    function getCampaignsByPyme(address pyme) external view returns (address[] memory);

    /**
     * @dev Retorna el total de campañas creadas
     * @return Número total de campañas
     */
    function getTotalCampaigns() external view returns (uint256);

    // ============ VARIABLES PÚBLICAS ============

    /**
     * @dev Dirección de la implementación base del contrato Campaign
     */
    function CAMPAIGN_IMPLEMENTATION() external view returns (address);

    /**
     * @dev Dirección del admin de la plataforma
     */
    function ADDRESS_ADMIN() external view returns (address);

    /**
     * @dev Dirección del token base usado para inversiones (USDC, etc.)
     */
    function ADDRESS_BASE_TOKEN() external view returns (address);

    /**
     * @dev Retorna la campaña en el índice especificado
     * @param index Índice en el array deployedCampaigns
     */
    function deployedCampaigns(uint256 index) external view returns (address);

    /**
     * @dev Retorna las campañas de una Pyme en el índice especificado
     * @param pyme Dirección de la Pyme
     * @param index Índice en el array de campañas de la Pyme
     */
    function campaignsByPyme(address pyme, uint256 index) external view returns (address);
}

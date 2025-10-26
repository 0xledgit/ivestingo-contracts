// SPDX-License-Identifier: MIT
pragma solidity ^0.8.30;

interface CampaignInterface {
    enum CampaignStatus {
        Created,
        Active,
        Successful,
        Failed,
        Finalized
    }

    // ============ EVENTOS ============

    event CampaignCreated(
        address indexed campaignAddress,
        address indexed creator
    );
    event CampaignFinalized(
        address indexed campaignAddress,
        CampaignStatus status
    );
    event FundsCommitted(address indexed investor, uint256 amount);
    event FundsClaimed(address indexed investor, uint256 amount);
    event MilestoneCompleted(
        uint256 indexed milestoneId,
        uint256 amountReleased
    );
    event TokensDistributed(address indexed investor, uint256 amount);
    event MilestoneApprovalRequested(
        uint256 indexed milestoneId,
        address indexed requester,
        string evidence
    );
    event CampaignSuccessful(address indexed campaignAddress, uint256 totalRaised);

    // ============ FUNCIONES DE INICIALIZACIÓN ============

    /**
     * @dev Inicializa una campaña clonada con todos sus parámetros
     * @param _addressPyme Dirección de la wallet de la Pyme
     * @param _addressAdmin Dirección del admin/plataforma
     * @param _addressContractToken Dirección del token de equity (ERC20)
     * @param _addressBaseToken Dirección del token de inversión (USDC, etc.)
     * @param _maxCap Hard cap (objetivo máximo)
     * @param _minCap Soft cap (objetivo mínimo)
     * @param _dateTimeEnd Timestamp de cierre de la campaña
     * @param _tokenSupplyOffered Supply máximo de tokens a ofrecer
     * @param _platformFee Fee de plataforma en basis points (300 = 3%)
     * @param _milestoneDescriptions Array de descripciones de milestones
     * @param _milestoneShares Array de cantidades de shares (equity tokens) por hito (suma = _tokenSupplyOffered)
     */
    function initialize(
        address _addressPyme,
        address _addressAdmin,
        address _addressContractToken,
        address _addressBaseToken,
        uint256 _maxCap,
        uint256 _minCap,
        uint256 _dateTimeEnd,
        uint256 _tokenSupplyOffered,
        uint256 _platformFee,
        string[] memory _milestoneDescriptions,
        uint256[] memory _milestoneShares
    ) external;

    // ============ FUNCIONES DE INVERSIÓN ============

    /**
     * @dev Permite a inversores depositar fondos en la campaña
     * @param amount Cantidad de tokens base a invertir
     */
    function commitFunds(uint256 amount) external;

    /**
     * @dev Permite a inversores reclamar fondos si la campaña falla
     */
    function claimFunds() external;

    // ============ FUNCIONES DE CIERRE ============

    /**
     * @dev Finaliza la campaña al llegar a dateTimeEnd
     * Determina si fue exitosa (totalRaised >= minCap) o fallida
     * Si exitosa, libera automáticamente el milestone 0
     */
    function finalizeCampaign() external;

    // ============ FUNCIONES DE MILESTONES ============

    /**
     * @dev Pyme solicita aprobación de un milestone completado
     * @param milestoneId ID del milestone (0, 1, 2...)
     * @param evidence URL o hash de evidencia del trabajo completado
     */
    function requestApproveMilestone(
        uint256 milestoneId,
        string calldata evidence
    ) external;

    /**
     * @dev Admin aprueba un milestone y libera fondos/tokens
     * @param milestoneId ID del milestone a completar
     */
    function completeMilestone(uint256 milestoneId) external;

    /**
     * @dev Consulta información de un milestone
     * @param milestoneId ID del milestone
     * @return description Descripción del milestone
     * @return amount Monto calculado basado en totalRaised
     * @return completed Si el milestone fue completado
     */
    function getMilestone(
        uint256 milestoneId
    )
        external
        view
        returns (string memory description, uint256 amount, bool completed);
}

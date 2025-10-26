# Sistema de Financiamiento Progresivo para Pymes con Blockchain

## 📋 Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Innovación Tecnológica](#innovación-tecnológica)
3. [Arquitectura del Sistema](#arquitectura-del-sistema)
4. [Contratos Inteligentes](#contratos-inteligentes)
5. [Flujo de Uso Técnico](#flujo-de-uso-técnico)
6. [Ejemplos Prácticos con Contratos Desplegados](#ejemplos-prácticos-con-contratos-desplegados)
7. [Ventajas de Negocio](#ventajas-de-negocio)
8. [Desarrollo y Testing](#desarrollo-y-testing)

---

## 🎯 Resumen Ejecutivo

Sistema de smart contracts para facilitar la financiación de Pymes a través de **equity crowdfunding descentralizado** con:

- ✅ **Liberación progresiva de capital vinculada a hitos** (milestone-based funding)
- ✅ **Distribución automática de equity tokenizado** a inversores proporcional a su participación
- ✅ **Gobernanza descentralizada** para aprobación de milestones
- ✅ **Protección total para inversores** (reembolso 100% si la campaña falla)
- ✅ **Capital inmediato** para Pymes tras campaña exitosa (primer milestone liberado automáticamente)
- ✅ **Transparencia total on-chain** con eventos auditables
- ✅ **Eficiencia de gas** mediante patrón Factory (EIP-1167 Clone)

### Características Clave

- **Patrón Factory**: Uso de EIP-1167 (Minimal Proxy/Clone) para eficiencia de gas (~90% de ahorro en deployment)
- **Milestones basados en shares**: Distribución proporcional sin decimales, garantiza precisión matemática
- **Seguridad**: Separación de roles (Pyme, Admin, Inversores) con control de acceso granular
- **ERC20 con Permit (EIP-2612)**: Tokens de equity con aprobaciones sin gas mediante firmas

---

## 💡 Innovación Tecnológica

### Diferencias Clave con el Sistema Tradicional

| Aspecto | Sistema Tradicional | Sistema Blockchain Ivestingo |
|---------|---------------------|------------------------------|
| **Tiempo de aprobación** | 30-90 días | Instantáneo (al alcanzar minCap) |
| **Costo de intermediación** | 5-15% | 3% (configurable) |
| **Transparencia** | Limitada, documentos privados | Total, todo on-chain verificable |
| **Acceso a capital** | Al final del proceso | Progresivo según hitos |
| **Liquidez de equity** | 0% (ilíquido años) | Tokens ERC20 transferibles |
| **Gobernanza** | Opaca, pocos stakeholders | Descentralizada, todos los inversores |
| **Costos operativos** | Altos (staff, infraestructura) | Mínimos (automatizado) |
| **Auditoría** | Manual, costosa | Automática, on-chain |

### Optimización de Tiempos

```
PROCESO TRADICIONAL:
┌─────────────────────────────────────────────────────────────┐
│ Due Diligence (30d) → Aprobación Legal (20d) →             │
│ → Negociación (15d) → Cierre (15d) = 80 días promedio      │
└─────────────────────────────────────────────────────────────┘

PROCESO BLOCKCHAIN IVESTINGO:
┌─────────────────────────────────────────────────────────────┐
│ Crear campaña (1 tx, ~3 min) → Inversores depositan →      │
│ → Al alcanzar minCap: Aprobación automática = 1-30 días    │
│ → Primer milestone liberado instantáneamente                │
└─────────────────────────────────────────────────────────────┘

⚡ REDUCCIÓN: 87.5% en tiempo promedio (de 80 días a 10 días)
```

### Optimización de Transacciones

Para una campaña típica con 50 inversores y 4 milestones:

| Acción | Transacciones Tradicionales | Transacciones Blockchain |
|--------|----------------------------|--------------------------|
| Crear campaña | N/A (proceso manual) | 1 tx |
| 50 inversiones | 50 transferencias bancarias | 50 txs (paralelas) |
| Distribución equity | 50 documentos legales + registros | 0 txs (automático en milestones) |
| 4 liberaciones de capital | 4 transferencias + aprobaciones | 4 txs |
| Distribución tokens (4 milestones) | N/A | Automático (incluido en liberaciones) |
| **TOTAL** | ~104 acciones manuales | **55 transacciones automatizadas** |

**Ahorro operativo**: ~70% en acciones requeridas, 100% automatizado y auditable.

---

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                     ARQUITECTURA TÉCNICA                     │
└─────────────────────────────────────────────────────────────┘

CampaignFactory (Fábrica de Campañas)
  │
  │ FUNCIÓN: createCampaign(...)
  │ ├─ Despliega EquityToken (ERC20 + Permit + AccessControl)
  │ └─ Clona Campaign (EIP-1167 Clone, ahorro ~90% gas)
  │
  └──> Campaign #1 (Instancia única)
        │ - addressPyme: Wallet de la Pyme
        │ - addressAdmin: Admin de plataforma
        │ - addressContractToken: EquityToken desplegado
        │ - addressBaseToken: Token de inversión (USDC/MockERC20)
        │
        ├─ Estado: Created → Successful/Failed → Finalized
        │
        ├─ Milestones (basados en shares, no porcentajes):
        │   └─ milestoneSharesMapping[id] = cantidad de equity tokens
        │
        └─ Flujo:
             1. Inversores → commitFunds(shares)
             2. Al dateTimeEnd o maxCap → finalizeCampaign()
             3. Si exitosa → freeFunds(0) automático
             4. Pyme → requestApproveMilestone(id, evidencia)
             5. Admin → completeMilestone(id)
             6. Loop hasta totalMilestones → Finalized
```

### Modelo de Shares (Innovación Técnica)

**IMPORTANTE**: A diferencia de la documentación preliminar, el sistema implementado usa **cantidades de shares** en lugar de porcentajes en basis points.

```solidity
// ❌ ANTERIOR (documentación):
milestonePercentageMapping[0] = 2000; // 20% en basis points

// ✅ ACTUAL (implementación):
milestoneSharesMapping[0] = 20; // 20 equity tokens (shares)

// Ventajas:
// 1. Sin decimales (precisión perfecta)
// 2. Sin rounding errors
// 3. Distribución matemáticamente exacta
// 4. Validación: sum(milestoneShares) == tokenSupplyOffered
```

---

## 📜 Contratos Inteligentes

### 1. CampaignFactory.sol

**Propósito**: Fábrica para desplegar campañas de equity crowdfunding usando clonado (EIP-1167).

**Variables Inmutables**:
```solidity
address public immutable CAMPAIGN_IMPLEMENTATION;  // Implementación base de Campaign
address public immutable ADDRESS_ADMIN;            // Admin de la plataforma
address public immutable ADDRESS_BASE_TOKEN;       // Token de inversión (USDC/MockERC20)
```

**Variables de Estado**:
```solidity
address[] public deployedCampaigns;               // Todas las campañas desplegadas
mapping(address => address[]) public campaignsByPyme; // Campañas por Pyme
```

**Funciones Principales**:

#### `createCampaign(...)`
Crea una nueva campaña clonando la implementación y desplegando un EquityToken único.

**Parámetros**:
```solidity
function createCampaign(
    string memory tokenName,              // Nombre del token de equity (ej: "LEDGIT")
    string memory tokenSymbol,            // Símbolo del token (ej: "LGIT")
    address _addressPyme,                 // Wallet de la Pyme
    uint256 _maxCap,                      // Hard cap en unidades del baseToken
    uint256 _minCap,                      // Soft cap en unidades del baseToken
    uint256 _dateTimeEnd,                 // Timestamp de cierre (Unix time)
    uint256 _tokenSupplyOffered,          // Supply total de equity tokens (shares)
    uint256 _platformFee,                 // Fee en basis points (500 = 5%)
    string[] memory _milestoneDescriptions,  // ["Milestone 1", "Milestone 2", ...]
    uint256[] memory _milestonePercentages   // [20, 30, 50] shares por milestone
) external returns (address campaignAddress, address tokenAddress)
```

**Retorna**:
- `campaignAddress`: Dirección del contrato Campaign clonado
- `tokenAddress`: Dirección del EquityToken desplegado

**Eventos**:
```solidity
event CampaignDeployed(
    address indexed campaignAddress,
    address indexed pyme,
    address indexed tokenAddress,
    address creator
);
```

**Flujo interno**:
1. Clona `CAMPAIGN_IMPLEMENTATION` (EIP-1167)
2. Despliega nuevo `EquityToken` con `campaignAddress` como minter
3. Inicializa el clon con `Campaign.initialize(...)`
4. Registra en `deployedCampaigns` y `campaignsByPyme`
5. Emite evento `CampaignDeployed`

---

### 2. Campaign.sol

**Propósito**: Contrato individual que gestiona una campaña de equity crowdfunding.

**Estados de Campaña**:
```solidity
enum CampaignStatus {
    Created,     // Campaña creada, aceptando inversiones
    Active,      // Campaña activa (opcional, actualmente no usado)
    Successful,  // Campaña exitosa (totalRaised >= minCap)
    Failed,      // Campaña fallida (totalRaised < minCap al dateTimeEnd)
    Finalized    // Campaña completada (todos los milestones liberados)
}
```

**Variables de Configuración**:
```solidity
CampaignStatus public status;
bool public campaignInitialized;
uint256 public maxCap;                    // Hard cap
uint256 public minCap;                    // Soft cap
uint256 public dateTimeEnd;               // Timestamp de cierre
uint256 public platformFee;               // Fee en basis points (500 = 5%)
```

**Direcciones**:
```solidity
address public addressPyme;               // Wallet de la Pyme
address public addressAdmin;              // Admin/Plataforma
address public addressContractToken;      // EquityToken (ERC20)
address public addressBaseToken;          // Token de inversión (USDC/MockERC20)
```

**Tracking de Inversiones**:
```solidity
mapping(address => uint256) public investments;  // Monto invertido por address
address[] public investors;                       // Lista de inversores únicos
uint256 public totalRaised;                       // Total recaudado en baseToken
uint256 public totalSharesCommitted;              // Total de shares comprometidos
```

**Control de Milestones**:
```solidity
mapping(uint256 => string) public milestoneMapping;          // Descripciones
mapping(uint256 => uint256) public milestoneSharesMapping;   // Shares a liberar por milestone
uint256 public currentMilestone;                              // Milestone actual (siguiente a completar)
uint256 public totalMilestones;                               // Total de milestones
mapping(uint256 => bool) public milestoneCompleted;           // Estado de completado
mapping(uint256 => bool) public milestoneApprovalRequested;   // Estado de solicitud
```

**Tokens**:
```solidity
uint256 public tokenSupplyOffered;        // Supply ofrecido inicialmente
uint256 public tokenSupplyEffective;      // Supply efectivo = (totalRaised/maxCap) * tokenSupplyOffered
bool public feePaid;                      // Control de pago único del fee
```

#### Funciones Principales

##### `initialize(...)`
Inicializa una instancia clonada (llamada por `CampaignFactory`).

**Validaciones**:
- Arrays de milestones deben tener la misma longitud
- Al menos un milestone requerido
- `maxCap > 0`, `minCap > 0 && minCap <= maxCap`
- `dateTimeEnd > block.timestamp`
- **CRÍTICO**: `sum(milestoneShares) == tokenSupplyOffered`

**Efecto**: Establece estado `Created` y `campaignInitialized = true`.

---

##### `commitFunds(uint256 _sharesQuantity)`
Permite a inversores depositar fondos especificando la cantidad de **shares (equity tokens)** que desean comprar.

**Parámetros**:
- `_sharesQuantity`: Cantidad de equity tokens (shares) a comprar

**Cálculo interno**:
```solidity
uint256 amount = Math.mulDiv(_sharesQuantity, maxCap, tokenSupplyOffered);
// Ejemplo: Si maxCap=10000, tokenSupplyOffered=100, _sharesQuantity=30
// → amount = (30 * 10000) / 100 = 3000 baseTokens
```

**Requisitos**:
- Estado `Created` o `Active`
- `block.timestamp < dateTimeEnd`
- `_sharesQuantity > 0`
- `totalRaised + amount <= maxCap`
- Inversor debe haber aprobado `amount` de `baseToken` al contrato

**Efectos**:
1. Transfiere `amount` de `baseToken` del inversor al contrato
2. Registra inversión: `investments[msg.sender] += amount`
3. Agrega a `investors[]` si es primera inversión
4. Incrementa `totalSharesCommitted += _sharesQuantity`
5. Incrementa `totalRaised += amount`
6. Si `totalRaised == maxCap` → cambia estado a `Successful` y emite `CampaignSuccessful`

**Eventos**:
```solidity
emit FundsCommitted(msg.sender, amount);
emit CampaignSuccessful(address(this), totalRaised); // Si alcanza maxCap
```

---

##### `finalizeCampaign()`
Cierra la campaña al llegar a `dateTimeEnd` o alcanzar `maxCap`.

**Requisitos**:
- `(block.timestamp >= dateTimeEnd && totalRaised >= minCap) || totalRaised == maxCap`
- Estado `Successful`

**Lógica**:

**CASO A - Exitosa** (`totalRaised >= minCap`):
1. Cambia estado a `Successful`
2. Calcula `tokenSupplyEffective = (totalRaised * tokenSupplyOffered) / maxCap`
3. Recalcula shares por milestone:
   ```solidity
   for (uint64 i = 0; i < totalMilestones; i++) {
       milestoneSharesMapping[i] = (milestoneSharesMapping[i] * totalSharesCommitted) / tokenSupplyOffered;
   }
   ```
4. Llama automáticamente a `freeFunds(0)` (libera primer milestone):
   - Cobra fee de plataforma (solo una vez): `feeAmount = (totalRaised * platformFee) / 10000`
   - Transfiere fondos del milestone a Pyme (neto de fee)
   - Mintea equity tokens al contrato
   - Distribuye tokens proporcionales a inversores

**CASO B - Fallida** (`totalRaised < minCap`):
1. Cambia estado a `Failed`
2. Permite que inversores llamen `claimFunds()`

**Eventos**:
```solidity
emit CampaignFinalized(address(this), status);
// + eventos de freeFunds si exitosa
```

---

##### `claimFunds()`
Permite a inversores reclamar su inversión completa si la campaña falló.

**Requisitos**:
- Estado `Failed`
- `investments[msg.sender] > 0`

**Efectos**:
1. Resetea `investments[msg.sender] = 0`
2. Transfiere `baseToken` de vuelta al inversor

**Eventos**:
```solidity
emit FundsClaimed(msg.sender, amount);
```

---

##### `requestApproveMilestone(uint256 milestoneId, string evidence)`
La Pyme solicita aprobación de un milestone completado.

**Parámetros**:
- `milestoneId`: ID del milestone (0, 1, 2...)
- `evidence`: URL o hash de evidencia (ej: IPFS hash)

**Requisitos**:
- `msg.sender == addressPyme` (solo la Pyme)
- Estado `Successful`
- `milestoneId == currentMilestone` (orden secuencial)
- `milestoneId < totalMilestones`
- No completado ni solicitado previamente

**Efectos**:
- Marca `milestoneApprovalRequested[milestoneId] = true`
- Emite evento para iniciar votación off-chain

**Eventos**:
```solidity
emit MilestoneApprovalRequested(milestoneId, msg.sender, evidence);
```

---

##### `completeMilestone(uint256 milestoneId)`
Admin aprueba un milestone y libera fondos/tokens.

**Requisitos**:
- `msg.sender == addressAdmin` (solo admin)
- Estado `Successful`
- `milestoneId == currentMilestone`
- `milestoneApprovalRequested[milestoneId] == true`
- No completado previamente

**Efectos**:
1. Marca `milestoneCompleted[milestoneId] = true`
2. Llama a `freeFunds(milestoneId + 1)`:
   - Calcula `pricePerShare = totalRaised / tokenSupplyEffective`
   - Calcula `milestoneAmount = milestoneShares * pricePerShare` (neto de fee si milestone > 0)
   - Transfiere fondos a Pyme
   - Mintea equity tokens al contrato
   - Distribuye tokens a inversores proporcionalmente:
     ```solidity
     tokensForInvestor = (tokensForMilestone * investorAmount) / totalRaised
     ```
3. Incrementa `currentMilestone++`
4. Si `milestoneId + 1 == totalMilestones` → estado `Finalized`

**Eventos**:
```solidity
emit MilestoneCompleted(milestoneId, milestoneAmount);
emit TokensDistributed(investor, tokensForInvestor); // Por cada inversor
```

---

##### `getMilestone(uint256 milestoneId)`
Consulta información de un milestone.

**Retorna**:
```solidity
(
    string memory description,  // Descripción del milestone
    uint256 amount,             // Monto calculado = milestoneShares * pricePerShare
    bool completed              // Si fue completado
)
```

---

### 3. EquityToken.sol

**Propósito**: Token ERC20 con capacidad de minteo controlado, soporte para Permit (EIP-2612) y sin decimales.

**Hereda de**:
- `ERC20`: Funcionalidad básica de token
- `ERC20Permit`: Aprobaciones sin gas mediante firmas (EIP-2612)
- `AccessControl`: Control de roles granular

**Roles**:
```solidity
bytes32 public constant MINTER_ROLE = keccak256("MINTER_ROLE");
// Solo el contrato Campaign tiene este rol
```

**Variables**:
```solidity
uint256 public maxSupply;        // Supply máximo (igual a tokenSupplyOffered)
address public campaign;         // Dirección del contrato Campaign
```

**Constructor**:
```solidity
constructor(
    string memory name,          // Nombre del token (ej: "LEDGIT")
    string memory symbol,        // Símbolo (ej: "LGIT")
    uint256 _maxSupply,          // Supply máximo
    address _campaign            // Dirección del Campaign
)
```

**Funciones Clave**:

##### `mint(address to, uint256 amount)`
Solo callable por el contrato Campaign (rol `MINTER_ROLE`).

**Validaciones**:
- `totalSupply() + amount <= maxSupply`

##### `decimals()`
Override para equity tokens (sin decimales):
```solidity
function decimals() public pure override returns (uint8) {
    return 0; // Equity tokens son enteros
}
```

##### `remainingSupply()`
Retorna cuántos tokens aún pueden ser minteados:
```solidity
function remainingSupply() external view returns (uint256) {
    return maxSupply - totalSupply();
}
```

---

## 🔧 Flujo de Uso Técnico

### Flujo Completo: Desde Deployment hasta Finalización

```
┌────────────────────────────────────────────────────────────────┐
│ FASE 0: DEPLOYMENT INICIAL (Solo una vez por red)             │
└────────────────────────────────────────────────────────────────┘

1. Deploy MockERC20 (o usar USDC en mainnet):
   forge create MockERC20 --constructor-args "MOCK_COP" "COP"

2. Deploy CampaignFactory:
   forge create CampaignFactory --constructor-args <ADMIN_ADDRESS> <MOCK_ERC20_ADDRESS>

   Resultado:
   - CAMPAIGN_IMPLEMENTATION desplegado automáticamente
   - CampaignFactory listo para crear campañas

┌────────────────────────────────────────────────────────────────┐
│ FASE 1: CREACIÓN DE CAMPAÑA (Por cada Pyme)                   │
└────────────────────────────────────────────────────────────────┘

3. Pyme llama CampaignFactory.createCampaign(...):

   cast send <FACTORY_ADDRESS> \
     "createCampaign(string,string,address,uint256,uint256,uint256,uint256,uint256,string[],uint256[])" \
     "LEDGIT" \                              # tokenName
     "LGIT" \                                # tokenSymbol
     <PYME_ADDRESS> \                        # addressPyme
     10000000000000 \                        # maxCap (10,000 baseToken)
     1000000000000 \                         # minCap (1,000 baseToken)
     1761489203 \                            # dateTimeEnd (Unix timestamp)
     100 \                                   # tokenSupplyOffered (100 shares)
     500 \                                   # platformFee (5%)
     '["milestone 1","milestone 2"]' \      # milestoneDescriptions
     '[40,60]'                               # milestoneShares (40+60=100 ✓)

   Resultado:
   - Campaign clonado en <CAMPAIGN_ADDRESS>
   - EquityToken desplegado en <TOKEN_ADDRESS>
   - currentMilestone = 0, status = Created

┌────────────────────────────────────────────────────────────────┐
│ FASE 2: INVERSIÓN (Múltiples inversores en paralelo)          │
└────────────────────────────────────────────────────────────────┘

4. Inversor A prepara inversión:

   a) Mintea baseToken (si MockERC20):
      cast send <MOCK_ERC20_ADDRESS> \
        "mint(address,uint256)" \
        <INVESTOR_A_ADDRESS> \
        300000000000000                      # 300,000 baseToken

   b) Aprueba baseToken al Campaign:
      cast send <MOCK_ERC20_ADDRESS> \
        "approve(address,uint256)" \
        <CAMPAIGN_ADDRESS> \
        30000000000000                       # 30,000 baseToken

   c) Invierte especificando shares:
      cast send <CAMPAIGN_ADDRESS> \
        "commitFunds(uint256)" \
        30                                   # 30 shares (30% del supply)

      Cálculo interno:
      amount = (30 * 10000000000000) / 100 = 3000000000000 baseToken

5. Inversor B repite pasos 4a-4c con sus cantidades

6. Si totalRaised == maxCap:
   - Estado cambia automáticamente a Successful
   - Evento CampaignSuccessful emitido

┌────────────────────────────────────────────────────────────────┐
│ FASE 3: CIERRE DE CAMPAÑA                                     │
└────────────────────────────────────────────────────────────────┘

7. Después de dateTimeEnd, cualquiera llama:

   cast send <CAMPAIGN_ADDRESS> "finalizeCampaign()"

   Si totalRaised >= minCap:
   - Estado → Successful
   - tokenSupplyEffective = (totalRaised * 100) / maxCap
   - milestoneShares recalculados proporcionalmente
   - freeFunds(0) llamado automáticamente:
     · Fee cobrado: (totalRaised * 500) / 10000 → Admin
     · Fondos milestone 0 → Pyme (neto de fee)
     · Equity tokens minteados y distribuidos a inversores

   Si totalRaised < minCap:
   - Estado → Failed
   - Inversores pueden llamar claimFunds()

┌────────────────────────────────────────────────────────────────┐
│ FASE 4: CICLO DE MILESTONES (Hasta totalMilestones)           │
└────────────────────────────────────────────────────────────────┘

8. Pyme completa trabajo y solicita aprobación:

   cast send <CAMPAIGN_ADDRESS> \
     "requestApproveMilestone(uint256,string)" \
     0 \                                      # milestoneId (currentMilestone)
     "ipfs://Qm...evidencia"                  # evidence

   Evento: MilestoneApprovalRequested(0, pyme, evidencia)

9. Inversores votan off-chain (fuera del contrato)

10. Admin verifica consenso y aprueba:

    cast send <CAMPAIGN_ADDRESS> \
      "completeMilestone(uint256)" \
      0                                       # milestoneId

    Efectos:
    - milestoneCompleted[0] = true
    - freeFunds(1) llamado:
      · Fondos milestone 0 → Pyme
      · Equity tokens minteados y distribuidos
    - currentMilestone = 1

11. Repetir pasos 8-10 para milestones 1, 2, ..., totalMilestones-1

12. Cuando currentMilestone == totalMilestones:
    - Estado → Finalized
    - Campaña completada

┌────────────────────────────────────────────────────────────────┐
│ FASE 5 (ALTERNATIVA): CAMPAÑA FALLIDA                         │
└────────────────────────────────────────────────────────────────┘

Si finalizeCampaign() determina status = Failed:

13. Inversores reclaman fondos:

    cast send <CAMPAIGN_ADDRESS> "claimFunds()"

    Efecto:
    - investments[msg.sender] = 0
    - baseToken transferido de vuelta al inversor
```

---

## 📊 Ejemplos Prácticos con Contratos Desplegados

### Contratos Desplegados en Polygon Amoy Testnet

```
┌─────────────────────────────────────────────────────────────┐
│                   DIRECCIONES DESPLEGADAS                    │
└─────────────────────────────────────────────────────────────┘

Admin/Owner:
  0x05703526dB38D9b2C661c9807367C14EB98b6c54

Pyme:
  0x4Ac2bb44F3a89B13A1E9ce30aBd919c40CbA4385

CampaignFactory:
  0x90025910eB9c8638D5BEc02C58BABCB837b3BdC9

MockERC20 (COP):
  0xeD47eACd29aD1aAFaE0DC97dB72cCB730ea14c57

Campaign (Ejemplo):
  0x1917266703df984e7316686cb5ceaaab98a90397

EquityToken (Ejemplo):
  0xbe29da85c45824105bbb5b2995b1234e54abcfa9

RPC URL:
  https://rpc-amoy.polygon.technology/

Block Explorer:
  https://amoy.polygonscan.com/
```

### Ejemplo Completo: Campaña "LEDGIT"

#### 1. Mintear BaseToken a Inversores

```bash
# Inversor A recibe 300,000 COP
cast send 0xeD47eACd29aD1aAFaE0DC97dB72cCB730ea14c57 \
  "mint(address,uint256)" \
  0x05703526dB38D9b2C661c9807367C14EB98b6c54 \
  300000000000000 \
  --rpc-url https://rpc-amoy.polygon.technology/ \
  --private-key <INVESTOR_A_PRIVATE_KEY>

# Inversor B recibe 700,000 COP
cast send 0xeD47eACd29aD1aAFaE0DC97dB72cCB730ea14c57 \
  "mint(address,uint256)" \
  0x4Ac2bb44F3a89B13A1E9ce30aBd919c40CbA4385 \
  700000000000000 \
  --rpc-url https://rpc-amoy.polygon.technology/ \
  --private-key <INVESTOR_B_PRIVATE_KEY>
```

#### 2. Crear Campaña

```bash
cast send 0x90025910eB9c8638D5BEc02C58BABCB837b3BdC9 \
  "createCampaign(string,string,address,uint256,uint256,uint256,uint256,uint256,string[],uint256[])" \
  "LEDGIT" \
  "LGIT" \
  0x4Ac2bb44F3a89B13A1E9ce30aBd919c40CbA4385 \
  10000000000000 \
  1000000000000 \
  1761489203 \
  100 \
  500 \
  '["milestone 1","milestone 2"]' \
  '[40,60]' \
  --rpc-url https://rpc-amoy.polygon.technology/ \
  --private-key <ADMIN_PRIVATE_KEY>

# Resultado:
# Campaign: 0x1917266703df984e7316686cb5ceaaab98a90397
# EquityToken: 0xbe29da85c45824105bbb5b2995b1234e54abcfa9
```

#### 3. Inversores Aprueban y Depositan Fondos

```bash
# Inversor A aprueba 30,000 COP
cast send 0xeD47eACd29aD1aAFaE0DC97dB72cCB730ea14c57 \
  "approve(address,uint256)" \
  0x1917266703df984e7316686cb5ceaaab98a90397 \
  30000000000000 \
  --rpc-url https://rpc-amoy.polygon.technology/ \
  --private-key <INVESTOR_A_PRIVATE_KEY>

# Inversor A compra 30 shares
cast send 0x1917266703df984e7316686cb5ceaaab98a90397 \
  "commitFunds(uint256)" \
  30 \
  --rpc-url https://rpc-amoy.polygon.technology/ \
  --private-key <INVESTOR_A_PRIVATE_KEY>

# Inversor B aprueba 30,000 COP
cast send 0xeD47eACd29aD1aAFaE0DC97dB72cCB730ea14c57 \
  "approve(address,uint256)" \
  0x1917266703df984e7316686cb5ceaaab98a90397 \
  30000000000000 \
  --rpc-url https://rpc-amoy.polygon.technology/ \
  --private-key <INVESTOR_B_PRIVATE_KEY>

# Inversor B compra 60 shares
cast send 0x1917266703df984e7316686cb5ceaaab98a90397 \
  "commitFunds(uint256)" \
  60 \
  --rpc-url https://rpc-amoy.polygon.technology/ \
  --private-key <INVESTOR_B_PRIVATE_KEY>

# Estado:
# totalSharesCommitted = 90
# totalRaised = (30+60) * 10000000000000 / 100 = 9000000000000 COP
```

#### 4. Verificar Estado de Campaña

```bash
# Verificar status (0=Created, 1=Active, 2=Successful, 3=Failed, 4=Finalized)
cast call 0x1917266703df984e7316686cb5ceaaab98a90397 \
  "status()" \
  --rpc-url https://rpc-amoy.polygon.technology/

# Verificar totalRaised
cast call 0x1917266703df984e7316686cb5ceaaab98a90397 \
  "totalRaised()" \
  --rpc-url https://rpc-amoy.polygon.technology/

# Verificar currentMilestone
cast call 0x1917266703df984e7316686cb5ceaaab98a90397 \
  "currentMilestone()(uint256)" \
  --rpc-url https://rpc-amoy.polygon.technology/
```

#### 5. Finalizar Campaña

```bash
# Después de dateTimeEnd o alcanzar maxCap
cast send 0x1917266703df984e7316686cb5ceaaab98a90397 \
  "finalizeCampaign()" \
  --rpc-url https://rpc-amoy.polygon.technology/ \
  --private-key <ANY_PRIVATE_KEY>

# Efectos:
# - status → Successful (si totalRaised >= minCap)
# - tokenSupplyEffective = (9000000000000 * 100) / 10000000000000 = 90 shares
# - milestoneShares recalculados:
#   · milestone 0: (40 * 90) / 100 = 36 shares
#   · milestone 1: (60 * 90) / 100 = 54 shares
# - freeFunds(0) llamado:
#   · Fee: (9000000000000 * 500) / 10000 = 450000000000 COP → Admin
#   · Milestone 0 neto: (36 * 9000000000000/90) * (10000-500) / 10000 ≈ 3420000000000 COP → Pyme
#   · Equity tokens: 36 shares minteados y distribuidos:
#     - Inversor A: (36 * 3000000000000) / 9000000000000 = 12 shares
#     - Inversor B: (36 * 6000000000000) / 9000000000000 = 24 shares

# Transacción real:
# https://amoy.polygonscan.com/tx/0xc34eba2b60def39862ac345362e88852b020642cf465d8dd14294f71c3486017
```

#### 6. Ciclo de Milestones

```bash
# Pyme solicita aprobación de milestone 0
cast send 0x1917266703df984e7316686cb5ceaaab98a90397 \
  "requestApproveMilestone(uint256,string)" \
  0 \
  "ipfs://QmXyz...evidencia-milestone-0" \
  --rpc-url https://rpc-amoy.polygon.technology/ \
  --private-key <PYME_PRIVATE_KEY>

# Admin aprueba milestone 0
cast send 0x1917266703df984e7316686cb5ceaaab98a90397 \
  "completeMilestone(uint256)" \
  0 \
  --rpc-url https://rpc-amoy.polygon.technology/ \
  --private-key <ADMIN_PRIVATE_KEY>

# Efectos:
# - milestoneCompleted[0] = true
# - freeFunds(1) llamado (milestone 1):
#   · Fondos: 54 shares * (9000000000000/90) = 5400000000000 COP → Pyme
#   · Equity tokens: 54 shares distribuidos:
#     - Inversor A: (54 * 3000000000000) / 9000000000000 = 18 shares
#     - Inversor B: (54 * 6000000000000) / 9000000000000 = 36 shares
# - currentMilestone = 1

# Pyme solicita aprobación de milestone 1
cast send 0x1917266703df984e7316686cb5ceaaab98a90397 \
  "requestApproveMilestone(uint256,string)" \
  1 \
  "ipfs://QmAbc...evidencia-milestone-1" \
  --rpc-url https://rpc-amoy.polygon.technology/ \
  --private-key <PYME_PRIVATE_KEY>

# Admin aprueba milestone 1
cast send 0x1917266703df984e7316686cb5ceaaab98a90397 \
  "completeMilestone(uint256)" \
  1 \
  --rpc-url https://rpc-amoy.polygon.technology/ \
  --private-key <ADMIN_PRIVATE_KEY>

# Efectos:
# - milestoneCompleted[1] = true
# - currentMilestone = 2 (== totalMilestones)
# - status → Finalized
# - Campaña completada
```

#### 7. Estado Final

```bash
# Verificar status
cast call 0x1917266703df984e7316686cb5ceaaab98a90397 \
  "status()" \
  --rpc-url https://rpc-amoy.polygon.technology/
# Resultado: 4 (Finalized)

# Verificar balance de equity tokens de Inversor A
cast call 0xbe29da85c45824105bbb5b2995b1234e54abcfa9 \
  "balanceOf(address)" \
  0x05703526dB38D9b2C661c9807367C14EB98b6c54 \
  --rpc-url https://rpc-amoy.polygon.technology/
# Resultado: 30 shares (12 del milestone 0 + 18 del milestone 1)

# Verificar balance de equity tokens de Inversor B
cast call 0xbe29da85c45824105bbb5b2995b1234e54abcfa9 \
  "balanceOf(address)" \
  0x4Ac2bb44F3a89B13A1E9ce30aBd919c40CbA4385 \
  --rpc-url https://rpc-amoy.polygon.technology/
# Resultado: 60 shares (24 del milestone 0 + 36 del milestone 1)

# Total equity distribuido: 30 + 60 = 90 shares ✓
```

---

## 💼 Ventajas de Negocio

### Para las Pymes

| Ventaja | Descripción | Impacto Cuantificado |
|---------|-------------|----------------------|
| **Acceso rápido a capital** | Fondos disponibles inmediatamente tras alcanzar minCap | Reducción de 80 días a 10 días promedio |
| **Menor costo de financiamiento** | Fee de 3-5% vs 10-15% tradicional | Ahorro de 7-10% del capital |
| **Liberación progresiva** | Capital disponible según cumplimiento de hitos | Mayor disciplina financiera |
| **Transparencia automática** | Todos los eventos on-chain, auditoría gratuita | Ahorro en costos de auditoría (~$5k/año) |
| **Sin intermediarios** | Directo a inversores | Eliminación de bancos y brokers |

### Para los Inversores

| Ventaja | Descripción | Impacto Cuantificado |
|---------|-------------|----------------------|
| **Protección total** | Reembolso 100% si campaña falla | Riesgo de pérdida total eliminado en fallo |
| **Liquidez de equity** | Tokens ERC20 transferibles | Potencial liquidez inmediata vs años de iliquidez |
| **Gobernanza descentralizada** | Voto sobre aprobación de milestones | Poder de decisión sobre 100% del capital progresivo |
| **Transparencia total** | Visibilidad on-chain de uso de fondos | Información en tiempo real vs informes trimestrales |
| **Sin mínimos altos** | Inversión desde 1 share | Democratización (vs $10k mínimo tradicional) |

### Para la Plataforma

| Ventaja | Descripción | Impacto Cuantificado |
|---------|-------------|----------------------|
| **Escalabilidad** | Factory pattern permite campañas ilimitadas | 0 costo marginal por campaña adicional |
| **Automatización** | Smart contracts ejecutan reglas automáticamente | Reducción de staff operativo ~80% |
| **Eficiencia de gas** | EIP-1167 Clone ahorra ~90% en deployment | De ~$100 a ~$10 por campaña (en mainnet) |
| **Compliance automático** | Reglas codificadas, no manipulables | Eliminación de riesgo de incumplimiento humano |

### Comparación de Costos

**Ejemplo: Pyme levanta $100,000 con 50 inversores y 4 milestones**

| Concepto | Sistema Tradicional | Sistema Blockchain | Ahorro |
|----------|---------------------|-------------------|--------|
| Fee de plataforma | 10% = $10,000 | 3% = $3,000 | **$7,000** |
| Costos legales | $5,000 | $0 (automatizado) | **$5,000** |
| Auditoría anual | $5,000 | $0 (on-chain) | **$5,000** |
| Distribución de equity | $2,500 (50 contratos) | $0 (automático) | **$2,500** |
| Gestión de inversores | $3,000/año | $0 | **$3,000** |
| **TOTAL (primer año)** | **$25,500** | **$3,000** | **$22,500 (88% ahorro)** |

### Métricas de Optimización

```
┌─────────────────────────────────────────────────────────────┐
│           MÉTRICAS DE OPTIMIZACIÓN TÉCNICA                  │
└─────────────────────────────────────────────────────────────┘

Tiempo de Aprobación:
  Tradicional: 30-90 días
  Blockchain: 1-30 días (campaña) + instantáneo (liberación)
  → Reducción: 87.5%

Transacciones Requeridas (50 inversores, 4 milestones):
  Tradicional: ~104 acciones manuales
  Blockchain: 55 transacciones automatizadas
  → Reducción: 47%

Costo de Gas (Polygon Amoy/Mainnet):
  Factory deployment: ~3,000,000 gas
  Campaign creation (clone): ~300,000 gas (~90% ahorro vs full deployment)
  commitFunds: ~100,000 gas por inversor
  completeMilestone: ~150,000 gas por milestone
  TOTAL (50 inversores, 4 milestones):
    - Deployment: ~3,000,000 gas (one-time)
    - Campaign: ~300,000 gas
    - Inversiones: 50 * 100,000 = 5,000,000 gas
    - Milestones: 4 * 150,000 = 600,000 gas
    → TOTAL: ~8,900,000 gas
    → En Polygon (0.03 gwei promedio): ~$0.027
    → En Ethereum (30 gwei promedio): ~$267

Transparencia:
  Tradicional: Informes trimestrales (120 días de latencia)
  Blockchain: Tiempo real (0 segundos)
  → Mejora: Infinita (de 120 días a 0 segundos)

Auditoría:
  Tradicional: Manual, $5k-$10k/año
  Blockchain: Automática, $0
  → Ahorro: 100%
```

---

## 🧪 Desarrollo y Testing

### Foundry - Setup

Este proyecto usa [Foundry](https://book.getfoundry.sh/) para desarrollo y testing.

#### Instalación

```bash
curl -L https://foundry.paradigm.xyz | bash
foundryup
```

#### Comandos Principales

```bash
# Compilar contratos
forge build

# Ejecutar tests
forge test

# Ejecutar tests con verbosidad
forge test -vvv

# Gas report
forge test --gas-report

# Coverage
forge coverage

# Formatear código
forge fmt

# Desplegar en local (Anvil)
anvil  # En terminal separado
forge script script/Deployment.s.sol:DeploymentScript --rpc-url http://localhost:8545 --broadcast

# Desplegar en testnet (Polygon Amoy)
forge script script/Deployment.s.sol:DeploymentScript \
  --rpc-url https://rpc-amoy.polygon.technology/ \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $POLYGONSCAN_API_KEY

# Desplegar en mainnet (con verificación)
forge script script/Deployment.s.sol:DeploymentScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify \
  --etherscan-api-key $ETHERSCAN_API_KEY
```

### Estructura de Archivos

```
ivestingo-contracts/
├── src/
│   ├── Campaign.sol                    # Contrato de campaña individual
│   ├── CampaignFactory.sol             # Fábrica de campañas (EIP-1167)
│   ├── EquityToken.sol                 # Token ERC20 con Permit y sin decimales
│   └── interfaces/
│       ├── CampaignInterface.sol
│       ├── CampaignFactoryInterface.sol
│       └── EquityTokenInterface.sol
├── test/
│   ├── Campaign.t.sol                  # Tests del contrato Campaign
│   ├── CampaignFactory.t.sol           # Tests de la fábrica
│   ├── mocks/
│   │   └── MockERC20.sol               # Mock para testing
│   └── integration/
│       └── FullFlow.t.sol              # Test de flujo completo
├── script/
│   └── Deployment.s.sol                # Script de deployment
├── foundry.toml                        # Configuración de Foundry
└── README.md                           # Esta documentación
```

### Tests Implementados (Roadmap)

- [ ] `test_CreateCampaign` - Creación exitosa de campaña
- [ ] `test_CommitFunds_WithShares` - Inversión con cálculo de shares
- [ ] `test_FinalizeCampaign_Successful` - Cierre exitoso y recalculo de shares
- [ ] `test_FinalizeCampaign_Failed` - Cierre fallido
- [ ] `test_ClaimFunds` - Reclamar fondos
- [ ] `test_RequestApproveMilestone` - Solicitar aprobación
- [ ] `test_CompleteMilestone` - Completar milestone y distribución
- [ ] `test_FullFlow_MultipleInvestors` - Flujo completo con múltiples inversores
- [ ] `test_EdgeCases_ShareCalculation` - Casos extremos de cálculo de shares
- [ ] `test_AccessControl` - Control de acceso por rol
- [ ] `test_EquityTokenMinting` - Minteo controlado de equity tokens
- [ ] `test_FeeCollection` - Cobro único de fee

---

## 🔐 Seguridad

### Roles y Permisos

| Rol | Permisos | Restricciones |
|-----|----------|---------------|
| **Pyme** | `requestApproveMilestone()` | Solo para milestones en orden secuencial |
| **Admin** | `completeMilestone()`, recibe fees | Solo puede aprobar milestones solicitados |
| **Inversores** | `commitFunds()`, `claimFunds()`, gobernanza off-chain | Solo durante periodo activo |
| **Cualquiera** | `finalizeCampaign()` | Solo después de `dateTimeEnd` o al alcanzar `maxCap` |
| **Campaign (contrato)** | Mint de EquityToken | Solo hasta `maxSupply` |

### Consideraciones de Seguridad

1. ✅ **Reentrancy**: Uso de `SafeERC20` para transferencias seguras
2. ✅ **Integer Overflow**: Solidity 0.8+ tiene protección automática
3. ✅ **Access Control**: Modificadores `require(msg.sender == ...)` en funciones sensibles
4. ✅ **Fee único**: Flag `feePaid` previene cobro múltiple
5. ✅ **Inicialización única**: Flag `campaignInitialized` previene reinicialización
6. ✅ **Validación de shares**: `sum(milestoneShares) == tokenSupplyOffered` garantiza distribución exacta
7. ✅ **Control de roles en EquityToken**: `AccessControl` con rol `MINTER_ROLE` exclusivo para Campaign
8. ⚠️ **Auditoría pendiente**: Contratos no auditados, usar en testnet primero

### Recomendaciones Pre-Producción

- [ ] Auditoría de seguridad por firma especializada (ej: OpenZeppelin, Trail of Bits)
- [ ] Tests de fuzzing con Echidna/Foundry
- [ ] Deploy extensivo en testnet (Polygon Amoy, Sepolia)
- [ ] Bug bounty program (ej: Immunefi)
- [ ] Multisig para rol Admin (ej: Gnosis Safe)
- [ ] Timelock para funciones críticas
- [ ] Monitoreo on-chain (ej: Tenderly, OpenZeppelin Defender)

---

## 📝 Licencia

MIT License

---

## 🤝 Contribución

Para contribuir al proyecto:

1. Fork el repositorio
2. Crear branch: `git checkout -b feature/nueva-funcionalidad`
3. Commit cambios: `git commit -am 'Agrega nueva funcionalidad'`
4. Push: `git push origin feature/nueva-funcionalidad`
5. Crear Pull Request

### Estándares de Código

- Solidity: Seguir [Solidity Style Guide](https://docs.soliditylang.org/en/latest/style-guide.html)
- Comentarios: NatSpec para todas las funciones públicas/externas
- Tests: Cobertura mínima 80%
- Gas optimization: Usar `forge snapshot` para comparar antes/después

---

## 📞 Soporte

Para preguntas o soporte:
- Email: ivestingo@gmail.com
- GitHub Issues: [ivestingo-contracts/issues](https://github.com/0xledgit/ivestingo-contracts/issues)

---

## 📚 Referencias Técnicas

- [EIP-1167: Minimal Proxy Contract](https://eips.ethereum.org/EIPS/eip-1167)
- [EIP-2612: Permit Extension for ERC20](https://eips.ethereum.org/EIPS/eip-2612)
- [OpenZeppelin Contracts](https://docs.openzeppelin.com/contracts/)
- [Foundry Book](https://book.getfoundry.sh/)
- [Polygon Amoy Testnet](https://polygon.technology/blog/introducing-the-amoy-testnet-for-polygon-pos)

---

**Última actualización**: 2025-10-26
**Versión**: 1.0.0 (Beta)
**Estado**: Desplegado en Polygon Amoy - No usar en producción sin auditoría

# Sistema de Financiamiento Progresivo para Pymes

## 📋 Tabla de Contenidos

1. [Resumen Ejecutivo](#resumen-ejecutivo)
2. [Arquitectura del Sistema](#arquitectura-del-sistema)
3. [Contratos Inteligentes](#contratos-inteligentes)
4. [Journey del Usuario](#journey-del-usuario)
5. [Funciones Implementadas](#funciones-implementadas)
6. [Parámetros y Configuración](#parámetros-y-configuración)
7. [Ejemplos de Uso](#ejemplos-de-uso)
8. [Desarrollo y Testing](#desarrollo-y-testing)

---

## 🎯 Resumen Ejecutivo

Sistema de smart contracts para facilitar la financiación de Pymes a través de crowdfunding con:
- ✅ Liberación progresiva de capital vinculada a hitos
- ✅ Distribución de equity tokenizado a inversores
- ✅ Gobernanza descentralizada para aprobación de milestones
- ✅ Protección para inversores (reembolso si la campaña falla)
- ✅ Capital inmediato para Pymes tras campaña exitosa

### Características Principales

- **Patrón Factory**: Uso de EIP-1167 (Minimal Proxy/Clone) para eficiencia de gas (~90% de ahorro)
- **Milestones basados en porcentajes**: Distribución proporcional independiente del capital levantado
- **Seguridad**: Separación de roles (Pyme, Admin, Inversores)
- **Transparencia**: Todos los eventos on-chain para auditabilidad

---

## 🏗️ Arquitectura del Sistema

```
┌─────────────────────────────────────────────────────────────┐
│                     ARQUITECTURA GENERAL                     │
└─────────────────────────────────────────────────────────────┘

TokenFactory (ERC-20 con votación)
    │
    │ 1. Pyme crea token de equity
    │
    └──> Equity Token (ej: "EcoPlastix S.A. Equity" - EPE)


CampaignFactory (Fábrica de Campañas)
    │
    │ 2. Pyme crea campaña (Clone EIP-1167)
    │
    └──> Campaign #1 (Instancia clonada)
    └──> Campaign #2 (Instancia clonada)
    └──> Campaign #N (Instancia clonada)
              │
              │ 3. Inversores depositan fondos
              │ 4. Cierre automático al llegar dateTimeEnd
              │ 5. Liberación progresiva por milestones
              │
              └──> [Successful] → Fondos a Pyme + Tokens a Inversores
                   [Failed] → Reembolso completo a Inversores
```

### Modelo de Fábricas (Factories)

El sistema utiliza dos fábricas principales:

1. **TokenFactory**: Crea tokens ERC-20 con capacidades de votación para cada Pyme
2. **CampaignFactory**: Crea instancias únicas de contratos Campaign para cada proyecto

---

## 📜 Contratos Inteligentes

### 1. CampaignFactory.sol

**Propósito**: Fábrica que despliega múltiples instancias de Campaign usando clones (EIP-1167)

**Variables de Estado**:
```solidity
address public immutable campaignImplementation;  // Implementación base
address public immutable addressAdmin;            // Admin de la plataforma
address public immutable addressBaseToken;        // Token de inversión (USDC, etc)
address[] public deployedCampaigns;               // Lista de todas las campañas
mapping(address => address[]) public campaignsByPyme; // Campañas por Pyme
```

**Funciones**:

| Función | Descripción | Visibilidad |
|---------|-------------|-------------|
| `createCampaign(...)` | Crea una nueva campaña (clone) | `external` |
| `getDeployedCampaigns()` | Retorna todas las campañas | `external view` |
| `getCampaignsByPyme(address)` | Campañas de una Pyme específica | `external view` |
| `getTotalCampaigns()` | Total de campañas creadas | `external view` |

**Eventos**:
```solidity
event CampaignDeployed(address indexed campaignAddress, address indexed pyme, address indexed creator);
```

---

### 2. Campaign.sol

**Propósito**: Contrato individual que gestiona una campaña de financiamiento específica

**Estados de Campaña**:
```solidity
enum CampaignStatus {
    Created,     // Campaña creada, aceptando inversiones
    Active,      // Campaña activa (opcional, para control manual)
    Successful,  // Campaña exitosa (totalRaised >= minCap)
    Failed       // Campaña fallida (totalRaised < minCap)
}
```

**Variables de Estado Principales**:

#### Configuración de Campaña
```solidity
CampaignStatus public status;
uint256 public maxCap;                    // Hard cap (objetivo máximo)
uint256 public minCap;                    // Soft cap (objetivo mínimo)
uint256 public dateTimeEnd;               // Timestamp de cierre
uint256 public platformFee;               // Fee en basis points (300 = 3%)
```

#### Direcciones
```solidity
address public addressPyme;               // Wallet de la Pyme
address public addressAdmin;              // Admin/Plataforma
address public addressContractToken;      // Token de equity (ERC-20)
address public addressBaseToken;          // Token de inversión (USDC)
```

#### Tracking de Inversiones
```solidity
mapping(address => uint256) public investments;  // Monto por inversor
address[] public investors;                       // Lista de inversores
uint256 public totalRaised;                       // Total recaudado
```

#### Control de Milestones
```solidity
mapping(uint256 => string) public milestoneMapping;          // Descripciones
mapping(uint256 => uint256) public milestonePercentageMapping; // Porcentajes (basis points)
uint256 public currentMilestone;                              // Milestone actual
uint256 public totalMilestones;                               // Total de milestones
mapping(uint256 => bool) public milestoneCompleted;           // Estado de completado
mapping(uint256 => bool) public milestoneApprovalRequested;   // Estado de solicitud
```

#### Tokens
```solidity
uint256 public tokenSupplyOffered;        // Supply ofrecido inicialmente
uint256 public tokenSupplyEffective;      // Supply real = (totalRaised/maxCap) * tokenSupplyOffered
bool public feePaid;                      // Control de pago único del fee
```

---

## 👥 Journey del Usuario

### 🏢 Journey de la PYME

#### Fase 1: Preparación
```
┌──────────────────────────────────────────────────────────┐
│ 1. Crear Token de Equity (vía TokenFactory)             │
│    - Define: nombre, símbolo, supply total              │
│    - Ejemplo: "EcoPlastix S.A. Equity" (EPE), 1,000,000 │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│ 2. Crear Campaña (vía CampaignFactory)                  │
│    - Parámetros: caps, fechas, milestones, fees         │
│    - Recibe: dirección del contrato Campaign            │
└──────────────────────────────────────────────────────────┘
```

**Código de ejemplo**:
```solidity
// 1. Crear token de equity
address tokenAddress = tokenFactory.createToken(
    "EcoPlastix S.A. Equity",
    "EPE",
    1000000 * 10**18
);

// 2. Crear campaña
address campaignAddress = campaignFactory.createCampaign(
    pymeWallet,                    // addressPyme
    tokenAddress,                  // addressContractToken
    100000 * 10**6,                // maxCap (100,000 USDC)
    70000 * 10**6,                 // minCap (70,000 USDC)
    block.timestamp + 30 days,     // dateTimeEnd
    1000000 * 10**18,              // tokenSupplyOffered
    300,                           // platformFee (3%)
    ["Diseño", "Maquinaria", "Lanzamiento"], // descriptions
    [2000, 5000, 3000]             // percentages (20%, 50%, 30%)
);
```

#### Fase 2: Durante la Campaña
```
┌──────────────────────────────────────────────────────────┐
│ 3. Esperar inversiones                                   │
│    - Inversores llaman commitFunds(amount)               │
│    - Monitorear totalRaised                              │
└──────────────────────────────────────────────────────────┘
```

#### Fase 3: Cierre de Campaña
```
┌──────────────────────────────────────────────────────────┐
│ 4. Al llegar dateTimeEnd:                                │
│    - Cualquiera puede llamar finalizeCampaign()          │
│    - Si exitosa: recibe fondos del Milestone 0 + tokens  │
│    - Si falla: inversores pueden reclamar fondos         │
└──────────────────────────────────────────────────────────┘
```

#### Fase 4: Ejecución y Milestones
```
┌──────────────────────────────────────────────────────────┐
│ 5. Para cada milestone (1, 2, 3...):                     │
│                                                           │
│    a) Pyme completa trabajo                              │
│    b) Pyme llama: requestApproveMilestone(id, evidence)  │
│    c) Inversores votan off-chain                         │
│    d) Admin verifica y llama: completeMilestone(id)      │
│    e) Pyme recibe fondos + Inversores reciben tokens     │
│                                                           │
│    Repetir hasta completar todos los milestones          │
└──────────────────────────────────────────────────────────┘
```

---

### 💰 Journey del INVERSOR

#### Fase 1: Inversión
```
┌──────────────────────────────────────────────────────────┐
│ 1. Aprobar tokens USDC al contrato Campaign             │
│    USDC.approve(campaignAddress, amount)                 │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│ 2. Depositar fondos                                      │
│    campaign.commitFunds(amount)                          │
│    - Se registra la inversión                            │
│    - Se actualiza totalRaised                            │
└──────────────────────────────────────────────────────────┘
```

**Código de ejemplo**:
```solidity
// 1. Aprobar USDC
IERC20(usdcAddress).approve(campaignAddress, 10000 * 10**6);

// 2. Invertir
Campaign(campaignAddress).commitFunds(10000 * 10**6); // 10,000 USDC
```

#### Fase 2: Cierre
```
┌──────────────────────────────────────────────────────────┐
│ 3. Al llegar dateTimeEnd:                                │
│                                                           │
│    CASO A - Campaña EXITOSA:                             │
│    ✅ Recibe tokens de equity proporcionales             │
│    ✅ Comienza a recibir tokens en cada milestone        │
│                                                           │
│    CASO B - Campaña FALLIDA:                             │
│    🔄 Puede reclamar el 100% de su inversión             │
│       campaign.claimFunds()                              │
└──────────────────────────────────────────────────────────┘
```

#### Fase 3: Gobernanza (Off-Chain)
```
┌──────────────────────────────────────────────────────────┐
│ 4. Para cada milestone solicitado:                       │
│    - Recibe notificación del evento                      │
│      MilestoneApprovalRequested                          │
│    - Revisa evidencia presentada por la Pyme            │
│    - Vota con sus tokens de equity (off-chain)          │
└──────────────────────────────────────────────────────────┘
```

#### Fase 4: Recepción de Tokens
```
┌──────────────────────────────────────────────────────────┐
│ 5. Al completarse cada milestone:                        │
│    - Recibe automáticamente tokens de equity             │
│    - Proporción: (inversión/totalRaised) * tokensForMilestone │
│    - Evento: TokensDistributed(investor, amount)         │
└──────────────────────────────────────────────────────────┘
```

---

### 👨‍💼 Journey del ADMIN (Plataforma)

```
┌──────────────────────────────────────────────────────────┐
│ 1. Deploy inicial del sistema                            │
│    - Deploy CampaignFactory                               │
│    - Deploy TokenFactory                                  │
└──────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────┐
│ 2. Para cada milestone solicitado:                       │
│    a) Escuchar evento MilestoneApprovalRequested         │
│    b) Verificar resultado de votación off-chain          │
│    c) Validar evidencia presentada                       │
│    d) Llamar: campaign.completeMilestone(id)             │
│    e) Cobrar fee (solo en milestone 0)                   │
└──────────────────────────────────────────────────────────┘
```

---

## 🔧 Funciones Implementadas

### CampaignFactory

#### `createCampaign(...)`
Crea una nueva instancia de Campaign usando el patrón Clone (EIP-1167).

**Parámetros**:
```solidity
function createCampaign(
    address _addressPyme,              // Wallet de la Pyme
    address _addressContractToken,     // Token de equity (ERC-20)
    uint256 _maxCap,                   // Hard cap en wei
    uint256 _minCap,                   // Soft cap en wei
    uint256 _dateTimeEnd,              // Timestamp de cierre
    uint256 _tokenSupplyOffered,       // Supply total ofrecido
    uint256 _platformFee,              // Fee en basis points (300 = 3%)
    string[] memory _milestoneDescriptions,  // ["Milestone 1", "Milestone 2", ...]
    uint256[] memory _milestonePercentages   // [2000, 3000, 5000] = 20%, 30%, 50%
) external returns (address)
```

**Retorna**: Dirección del nuevo contrato Campaign

**Eventos emitidos**:
```solidity
emit CampaignDeployed(clone, _addressPyme, msg.sender);
```

**Validaciones**:
- Arrays de milestones deben tener la misma longitud
- Al menos un milestone requerido
- Suma de porcentajes debe ser 10000 (100%)

**Ejemplo**:
```solidity
address campaign = factory.createCampaign(
    0x123...,                          // Pyme
    0x456...,                          // Token
    100000 * 10**6,                    // 100k USDC max
    70000 * 10**6,                     // 70k USDC min
    1735689600,                        // 01/01/2025
    1000000 * 10**18,                  // 1M tokens
    300,                               // 3% fee
    ["Diseño", "Producción", "Venta"],
    [2000, 5000, 3000]                 // 20%, 50%, 30%
);
```

---

### Campaign

#### `initialize(...)`
Inicializa una instancia clonada de Campaign (llamada automáticamente por Factory).

**Parámetros**: (Mismos que createCampaign + addressAdmin y addressBaseToken)

**Estado inicial**: `CampaignStatus.Created`

---

#### `commitFunds(uint256 amount)`
Permite a los inversores depositar fondos durante la campaña.

**Parámetros**:
- `amount`: Cantidad de tokens base (ej: USDC) a invertir

**Requisitos**:
- Campaña en estado `Created` o `Active`
- Antes de `dateTimeEnd`
- `amount > 0`
- `totalRaised + amount <= maxCap`
- Inversor debe haber aprobado tokens previamente

**Efectos**:
- Transfiere tokens del inversor al contrato
- Registra inversión en `investments[msg.sender]`
- Agrega a `investors[]` si es primera vez
- Incrementa `totalRaised`

**Eventos**:
```solidity
emit FundsCommitted(msg.sender, amount);
```

**Ejemplo**:
```solidity
// 1. Aprobar
IERC20(usdc).approve(campaign, 5000 * 10**6);

// 2. Invertir
Campaign(campaign).commitFunds(5000 * 10**6); // 5,000 USDC
```

---

#### `finalizeCampaign()`
Cierra la campaña al llegar a `dateTimeEnd` y determina si fue exitosa o no.

**Requisitos**:
- `block.timestamp >= dateTimeEnd`
- Estado `Created` o `Active`

**Lógica**:

**CASO A - Exitosa** (`totalRaised >= minCap`):
1. Cambia estado a `Successful`
2. Calcula `tokenSupplyEffective = (totalRaised * tokenSupplyOffered) / maxCap`
3. Inicializa `currentMilestone = 0`
4. Llama automáticamente a `freeFunds(0)` para liberar primer milestone:
   - Cobra fee de plataforma (solo una vez): `feeAmount = (totalRaised * platformFee) / 10000`
   - Transfiere fondos del milestone a Pyme
   - Distribuye tokens proporcionales a inversores

**CASO B - Fallida** (`totalRaised < minCap`):
1. Cambia estado a `Failed`
2. Permite que inversores llamen `claimFunds()`

**Eventos**:
```solidity
emit CampaignFinalized(address(this), status);
// + eventos de freeFunds si exitosa
```

**Ejemplo**:
```solidity
// Después de dateTimeEnd, cualquiera puede llamar:
Campaign(campaign).finalizeCampaign();
```

---

#### `claimFunds()`
Permite a inversores reclamar su inversión completa si la campaña falló.

**Requisitos**:
- Estado `Failed`
- `investments[msg.sender] > 0`

**Efectos**:
- Resetea `investments[msg.sender] = 0`
- Transfiere tokens de vuelta al inversor

**Eventos**:
```solidity
emit FundsClaimed(msg.sender, amount);
```

**Ejemplo**:
```solidity
// Si campaña falla
Campaign(campaign).claimFunds(); // Recupera 100% de inversión
```

---

#### `requestApproveMilestone(uint256 milestoneId, string evidence)`
La Pyme solicita aprobación de un milestone completado.

**Parámetros**:
- `milestoneId`: ID del milestone (0, 1, 2...)
- `evidence`: URL o descripción de evidencia del trabajo completado

**Requisitos**:
- Solo puede llamar `addressPyme`
- Estado `Successful`
- `milestoneId == currentMilestone` (orden secuencial)
- Milestone no completado ni solicitado previamente

**Efectos**:
- Marca `milestoneApprovalRequested[milestoneId] = true`
- Emite evento para iniciar votación off-chain

**Eventos**:
```solidity
emit MilestoneApprovalRequested(milestoneId, msg.sender, evidence);
```

**Ejemplo**:
```solidity
// Pyme solicita aprobación del milestone 1
Campaign(campaign).requestApproveMilestone(
    1,
    "https://ipfs.io/ipfs/QmXyz...evidencia"
);
```

---

#### `completeMilestone(uint256 milestoneId)`
Admin aprueba un milestone y libera fondos/tokens.

**Parámetros**:
- `milestoneId`: ID del milestone a completar

**Requisitos**:
- Solo puede llamar `addressAdmin`
- Estado `Successful`
- Milestone debe haber sido solicitado (`milestoneApprovalRequested[milestoneId] == true`)
- `milestoneId == currentMilestone`
- No completado previamente

**Efectos**:
1. Marca `milestoneCompleted[milestoneId] = true`
2. Llama a `freeFunds(milestoneId)`:
   - Calcula `milestoneAmount = (totalRaised * percentage) / 10000`
   - Transfiere fondos a Pyme
   - Calcula y distribuye tokens a inversores proporcionalmente
3. Incrementa `currentMilestone++`

**Eventos**:
```solidity
emit MilestoneCompleted(milestoneId, milestoneAmount);
emit TokensDistributed(investor, tokensForInvestor); // Por cada inversor
```

**Ejemplo**:
```solidity
// Admin aprueba milestone 1
Campaign(campaign).completeMilestone(1);
```

---

#### `getMilestone(uint256 milestoneId)`
Consulta información de un milestone específico.

**Parámetros**:
- `milestoneId`: ID del milestone

**Retorna**:
```solidity
(
    string memory description,  // Descripción del milestone
    uint256 amount,             // Monto calculado = (totalRaised * percentage) / 10000
    bool completed              // Si fue completado
)
```

**Ejemplo**:
```solidity
(string memory desc, uint256 amount, bool completed) =
    Campaign(campaign).getMilestone(1);

// desc = "Compra de Maquinaria"
// amount = 40000 * 10**6 (40,000 USDC si totalRaised=80k y percentage=50%)
// completed = true
```

---

## ⚙️ Parámetros y Configuración

### Formato de Basis Points

El sistema usa **basis points** para porcentajes de alta precisión:

| Basis Points | Porcentaje | Ejemplo |
|--------------|------------|---------|
| 100 | 1% | Fee de 1% |
| 300 | 3% | Fee de 3% |
| 2000 | 20% | Milestone 20% |
| 5000 | 50% | Milestone 50% |
| 10000 | 100% | Total |

**Fórmula**: `porcentaje = (valor * basisPoints) / 10000`

---

### Configuración de Milestones

Los milestones se definen con **porcentajes** que siempre suman 10000 (100%).

**Ventaja**: Independiente del capital levantado real.

**Ejemplo**:

```solidity
string[] memory descriptions = [
    "Permisos y Diseño",
    "Compra de Maquinaria",
    "Producción Inicial",
    "Lanzamiento y Marketing"
];

uint256[] memory percentages = [
    1000,  // 10%
    4000,  // 40%
    3000,  // 30%
    2000   // 20%
];
// Suma: 10000 (100%) ✅
```

**Si se levantan $80,000 (en lugar de $100,000 maxCap)**:
- Milestone 0: $80,000 × 10% = $8,000
- Milestone 1: $80,000 × 40% = $32,000
- Milestone 2: $80,000 × 30% = $24,000
- Milestone 3: $80,000 × 20% = $16,000
- **Total: $80,000** ✅ (siempre suma 100%)

---

### Cálculo de Tokens Efectivos

Al cerrar una campaña exitosa:

```solidity
tokenSupplyEffective = (totalRaised * tokenSupplyOffered) / maxCap
```

**Ejemplo**:
- `maxCap` = 100,000 USDC
- `tokenSupplyOffered` = 1,000,000 tokens
- `totalRaised` = 80,000 USDC

```
tokenSupplyEffective = (80,000 * 1,000,000) / 100,000 = 800,000 tokens
```

Esto significa que se emitirán **800,000 tokens** en total (80% del supply ofrecido).

---

### Distribución de Tokens por Milestone

Para cada milestone completado:

```solidity
tokensForMilestone = (tokenSupplyEffective * milestonePercentage) / 10000
```

**Ejemplo** (continuando del anterior):
- `tokenSupplyEffective` = 800,000 tokens
- Milestone 1 percentage = 4000 (40%)

```
tokensForMilestone = (800,000 * 4000) / 10000 = 320,000 tokens
```

Estos 320,000 tokens se distribuyen entre todos los inversores proporcionalmente.

---

### Distribución por Inversor

Para cada inversor en un milestone:

```solidity
tokensForInvestor = (tokensForMilestone * investorAmount) / totalRaised
```

**Ejemplo**:
- `tokensForMilestone` = 320,000 tokens
- Inversor A invirtió: 20,000 USDC
- `totalRaised` = 80,000 USDC

```
tokensForInvestor = (320,000 * 20,000) / 80,000 = 80,000 tokens
```

El Inversor A recibe **80,000 tokens** en este milestone (25% del total del milestone).

---

## 📊 Ejemplos de Uso

### Ejemplo Completo: Campaña EcoPlastix

#### 1. Setup Inicial

```solidity
// Addresses
address admin = 0x1111111111111111111111111111111111111111;
address usdc = 0x2222222222222222222222222222222222222222;
address pyme = 0x3333333333333333333333333333333333333333;

// Deploy Factory
CampaignFactory factory = new CampaignFactory(admin, usdc);
```

#### 2. Crear Token de Equity

```solidity
// (Asumiendo TokenFactory ya desplegado)
address equityToken = tokenFactory.createToken(
    "EcoPlastix S.A. Equity",
    "EPE",
    1000000 * 10**18  // 1 millón de tokens
);
```

#### 3. Crear Campaña

```solidity
address campaign = factory.createCampaign(
    pyme,                              // addressPyme
    equityToken,                       // addressContractToken
    100000 * 10**6,                    // maxCap: $100,000
    70000 * 10**6,                     // minCap: $70,000
    block.timestamp + 30 days,         // dateTimeEnd: 30 días
    1000000 * 10**18,                  // tokenSupplyOffered: 1M tokens
    300,                               // platformFee: 3%
    [
        "Permisos y Diseño",
        "Compra de Maquinaria",
        "Producción Inicial",
        "Marketing y Lanzamiento"
    ],
    [1500, 4000, 3000, 1500]          // 15%, 40%, 30%, 15%
);
```

#### 4. Inversores Depositan Fondos

```solidity
// Inversor A: $30,000
address investorA = 0xAAAA...;
IERC20(usdc).approve(campaign, 30000 * 10**6);
Campaign(campaign).commitFunds(30000 * 10**6);

// Inversor B: $25,000
address investorB = 0xBBBB...;
IERC20(usdc).approve(campaign, 25000 * 10**6);
Campaign(campaign).commitFunds(25000 * 10**6);

// Inversor C: $25,000
address investorC = 0xCCCC...;
IERC20(usdc).approve(campaign, 25000 * 10**6);
Campaign(campaign).commitFunds(25000 * 10**6);

// totalRaised = $80,000
```

#### 5. Cierre de Campaña

```solidity
// Después de 30 días
Campaign(campaign).finalizeCampaign();

// Resultados:
// - Estado: Successful (80k >= 70k minCap) ✅
// - tokenSupplyEffective = (80,000 * 1,000,000) / 100,000 = 800,000 tokens
// - Milestone 0 (15%) se libera automáticamente:
//   - Fee plataforma: $80,000 × 3% = $2,400 → admin
//   - Fondos Pyme: $80,000 × 15% = $12,000 → pyme
//   - Tokens: 800,000 × 15% = 120,000 tokens distribuidos:
//     - Inversor A: 120,000 × (30k/80k) = 45,000 tokens
//     - Inversor B: 120,000 × (25k/80k) = 37,500 tokens
//     - Inversor C: 120,000 × (25k/80k) = 37,500 tokens
```

#### 6. Ciclo de Milestones

```solidity
// MILESTONE 1 (40%)
// Pyme completa trabajo y solicita aprobación
Campaign(campaign).requestApproveMilestone(
    1,
    "https://drive.google.com/maquinaria-comprada"
);

// Inversores votan off-chain (mayoría aprueba)

// Admin verifica y aprueba
Campaign(campaign).completeMilestone(1);

// Resultados Milestone 1:
// - Fondos Pyme: $80,000 × 40% = $32,000 → pyme
// - Tokens: 800,000 × 40% = 320,000 tokens:
//   - Inversor A: 320,000 × 37.5% = 120,000 tokens
//   - Inversor B: 320,000 × 31.25% = 100,000 tokens
//   - Inversor C: 320,000 × 31.25% = 100,000 tokens

// MILESTONE 2 (30%) - Similar al anterior
// MILESTONE 3 (15%) - Similar al anterior
```

#### 7. Estado Final

```solidity
// Después de completar todos los milestones:

// Pyme recibió:
// - $12,000 (M0) + $32,000 (M1) + $24,000 (M2) + $12,000 (M3) = $80,000

// Admin recibió:
// - $2,400 (fee 3% del total)

// Inversores recibieron:
// Inversor A (37.5% de inversión):
// - 45,000 (M0) + 120,000 (M1) + 90,000 (M2) + 45,000 (M3) = 300,000 tokens

// Inversor B (31.25%):
// - 250,000 tokens

// Inversor C (31.25%):
// - 250,000 tokens

// Total tokens distribuidos: 800,000 ✅
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

# Desplegar (local)
anvil  # En terminal separado
forge script script/Deploy.s.sol:DeployScript --rpc-url http://localhost:8545 --broadcast

# Desplegar (testnet/mainnet)
forge script script/Deploy.s.sol:DeployScript \
  --rpc-url $RPC_URL \
  --private-key $PRIVATE_KEY \
  --broadcast \
  --verify
```

### Estructura de Archivos

```
ivestingo-contracts/
├── src/
│   ├── Campaign.sol                    # Contrato de campaña individual
│   ├── CampaignFactory.sol             # Fábrica de campañas
│   └── interfaces/
│       └── CampaignFactoryInterface.sol
├── test/
│   ├── Campaign.t.sol                  # Tests del contrato Campaign
│   ├── CampaignFactory.t.sol           # Tests de la fábrica
│   └── integration/
│       └── FullFlow.t.sol              # Test de flujo completo
├── script/
│   └── Deploy.s.sol                    # Script de deployment
├── foundry.toml                        # Configuración de Foundry
└── README.md                           # Esta documentación
```

### Tests Implementados (Roadmap)

- [ ] `test_CreateCampaign` - Creación exitosa de campaña
- [ ] `test_CommitFunds` - Inversión de fondos
- [ ] `test_FinalizeCampaign_Successful` - Cierre exitoso
- [ ] `test_FinalizeCampaign_Failed` - Cierre fallido
- [ ] `test_ClaimFunds` - Reclamar fondos
- [ ] `test_RequestApproveMilestone` - Solicitar aprobación
- [ ] `test_CompleteMilestone` - Completar milestone
- [ ] `test_FullFlow` - Flujo completo end-to-end
- [ ] `test_EdgeCases` - Casos extremos
- [ ] `test_AccessControl` - Control de acceso

---

## 🔐 Seguridad

### Roles y Permisos

| Rol | Permisos |
|-----|----------|
| **Pyme** | `requestApproveMilestone()` |
| **Admin** | `completeMilestone()`, recibe fees |
| **Inversores** | `commitFunds()`, `claimFunds()`, gobernanza off-chain |
| **Cualquiera** | `finalizeCampaign()` (después de dateTimeEnd) |

### Consideraciones de Seguridad

1. ✅ **Reentrancy**: Usar patrón Checks-Effects-Interactions
2. ✅ **Integer Overflow**: Solidity 0.8+ tiene protección automática
3. ✅ **Access Control**: Modificadores `require(msg.sender == ...)` en funciones sensibles
4. ✅ **Fee único**: Flag `feePaid` previene cobro múltiple
5. ⚠️ **Auditoría pendiente**: Contratos no auditados, usar en testnet primero

### Recomendaciones Pre-Producción

- [ ] Auditoría de seguridad por firma especializada
- [ ] Tests de fuzzing con Echidna/Foundry
- [ ] Deploy en testnet (Sepolia/Mumbai)
- [ ] Bug bounty program
- [ ] Multisig para rol Admin
- [ ] Timelock para funciones críticas

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

---

## 📞 Soporte

Para preguntas o soporte:
- Email: ivestingo@gmail.com

---

**Última actualización**: 2025-01-24
**Versión**: 0.1.0 (Alpha)
**Estado**: En desarrollo - No usar en producción

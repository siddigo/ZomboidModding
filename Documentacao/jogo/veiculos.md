# Veículos — o bloco `vehicle`, o `template` e a ponte para o Lua

O veículo é a construção mais composta do `media/scripts`: um bloco `.txt` com nove tipos de
sub-bloco, um sistema de herança por `template` que só existe aqui, e cada peça amarrada por nome a
uma função Lua. Página de **estrutura e acoplamento**.

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\`,
`STEAM/` = `…\steamapps\workshop\content\108600\`.

## Onde fica

Tudo em **`PZ/media/scripts/generated/vehicles/`** — 310 `.txt`, a maior massa de script do jogo
depois dos itens. A pasta mistura três coisas:

| Padrão de nome | O que é |
|---|---|
| `vehicle_*.txt` | o veículo em si (47 blocos `vehicle`) |
| `template_*.txt` | peça ou conjunto reutilizável (68 blocos `template vehicle`) |
| `models_vehicles.txt` | os blocos `model` das carrocerias |

Mais quatro subpastas: `burntAndSmashedVehicles/`, `professionVehicles/`,
`professionVehicles_General/`, `regionalPoliceVehicles/`.

O lado Lua são **66 arquivos**, com o núcleo em `PZ/media/lua/server/Vehicles/` — sete arquivos, dos
quais `Vehicles.lua` (1.538 linhas) concentra a implementação das peças.

## `template` — o único bloco com herança, e ele tem duas formas

O `template` só é usado por veículo em todo o `media/scripts`. A definição leva um **subtipo**:

```
module Base
{
    template vehicle Engine
    {
        part Engine
        {
            mechanicArea = Engine,
            area = Engine,
            category = engine,
            mechanicRequireKey = true,
            durability = 10,
            lua
            {
                create = Vehicles.Create.Engine,
                update = Vehicles.Update.Engine,
                checkEngine = Vehicles.CheckEngine.Engine,
            }
        }
    }
}
```

(`generated/vehicles/template_engine.txt:1-20`.) `template vehicle <Nome>` — o `vehicle` no meio é
parte da sintaxe, não o nome. Todas as 68 definições usam esse subtipo.

O consumo é por campo dentro do `vehicle`, e **existem duas grafias**:

```
    vehicle CarLuxury
    {
        template! = CarLuxury,
        specialKeyRing = Base.KeyRing_WestMaple,
        model
        {
            file = Vehicles_LuxuryCar,
            scale = 1.82,
            offset = 0.0 0.3022 0.0,
        }
        template = PassengerSeat2,
        template = CarLuxuryCollision,
```

(`generated/vehicles/vehicle_car_luxury.txt:3-14`.) `template!` com exclamação e `template` sem.
No censo da pasta: **3.312 `template =` contra 200 `template! =`**. A forma com `!` aparece
tipicamente como a **primeira** linha do bloco, e a sem `!` depois — o padrão é consistente, mas o
que o `!` faz (substituir em vez de somar? aplicar antes? ignorar conflito?) não está escrito em
lugar nenhum do `media/`.

`template` é também o campo mais frequente do bloco: 1.114 ocorrências como campo direto de
`vehicle`, contra 64 do segundo colocado. **Um veículo do jogo é majoritariamente composição, não
declaração** — copiar um `vehicle_*.txt` sem trazer os `template_*.txt` que ele cita produz um
veículo incompleto, e a falta de um `template` citado não é reportada.

## Os sub-blocos

Censo em `generated/vehicles/`, por frequência:

| Sub-bloco | Ocorrências | Papel |
|---|---|---|
| `area` | 1.309 | retângulo `xywh` onde o jogador precisa estar para interagir |
| `part` | 961 | a peça: motor, porta, pneu, banco, janela |
| `attachment` | 519 | ponto de engate (reboque, acessório) |
| `wheel` | 516 | roda, com posição e suspensão |
| `passenger` | 400 | assento, com `position inside` e `position outside` |
| `skin` | 298 | variação de textura da carroceria |
| `model` | 241 | malha da peça ou do veículo — ver [arte-e-modelos.md](arte-e-modelos.md) |
| `sound` | 102 | evento sonoro da peça — ver [som.md](som.md) |
| `physics` | 84 | forma de colisão |
| `crawlThroughWheel` | 80 | |
| `lightbar` | 23 | barra de luzes (polícia, ambulância) |

`passenger` é o único que aninha três níveis: `passenger FrontLeft { position inside { … } position
outside { … } }`, e o `outside` carrega `area = SeatFrontLeft`, que aponta para um bloco `area` irmão
(`vehicle_car_luxury.txt:15-45`). **Nome de `area` é referência textual**, não índice — errar a caixa
quebra a interação sem erro de carga.

### Campos diretos de `vehicle`

Os 43 veículos "completos" declaram o mesmo conjunto físico: `extents`, `centerOfMassOffset`,
`physicsChassisShape`, `mass`, `seats`, `wheelFriction`, `rollInfluence`, `steeringIncrement`,
`steeringClamp`, `suspensionStiffness`, `suspensionDamping`, `suspensionCompression`,
`suspensionRestLength`, mais o grupo de textura — `textureRust`, `textureMask`, `textureLights`,
`textureDamage1Shell`, `textureDamage1Overlay`, `textureDamage2Shell`, `textureDamage2Overlay`.

**`specialKeyRing`** (71 ocorrências) é campo de `vehicle`, não de `model`, apesar de vizinho dele no
arquivo. O valor é lista de IDs de item separada por `;`:

```
specialKeyRing = Base.KeyRing_EagleFlag;Base.KeyRing_EightBall;Base.KeyRing_Panther;Base.KeyRing_RabbitFoot;Base.KeyRing_Sexy,
```

É o chaveiro que nasce na chave daquele carro. Mais um caso do separador `;` dentro de um formato que
usa `,` para terminar campo — ver [scripts-txt.md](scripts-txt.md).

### O `model` de veículo usa `file`, não `mesh`

Dentro de `vehicle`, o bloco `model` aponta a malha com **`file`** (`vehicle_car_luxury.txt:8`),
enquanto o `model` de topo em `generated/models_*.txt` usa `mesh` — 1.732 vezes, com zero `file`.
Contrato completo em [arte-e-modelos.md](arte-e-modelos.md).

## A ponte para o Lua — o bloco `lua { }`

Cada `part` pode declarar um bloco `lua` que amarra eventos da peça a funções por **nome pontuado**:

```
            lua
            {
                create = Vehicles.Create.Engine,
                update = Vehicles.Update.Engine,
                checkEngine = Vehicles.CheckEngine.Engine,
            }
```

As chaves observadas, por frequência: `update` (96), `create` (30), `init` (10), `use` (6),
`checkEngine` (2), `checkOperate` (1).

Do outro lado, `PZ/media/lua/server/Vehicles/Vehicles.lua` declara as tabelas-namespace no topo, e é
nelas que o nome resolve:

`Vehicles.Create`, `Vehicles.Init`, `Vehicles.Update`, `Vehicles.Use`, `Vehicles.CheckEngine`,
`Vehicles.CheckOperate`, `Vehicles.ContainerAccess`, `Vehicles.InstallTest`,
`Vehicles.InstallComplete`, `Vehicles.UninstallTest`, `Vehicles.UninstallComplete`.

A função é global e recebe `(vehicle, part)` — `function Vehicles.Create.Engine(vehicle, part)`
(`Vehicles.lua:262`).

**As onze tabelas são globais sem namespace de mod.** Um mod que queira peça nova escreve dentro
delas; dois mods que escolham o mesmo nome de função se sobrescrevem em silêncio, do mesmo jeito que
acontece em `ProceduralDistributions.list` (ver [distribuicao-loot.md](distribuicao-loot.md)). O nome
citado no `.txt` que não exista na tabela é a falha típica, e ela só aparece quando a peça é usada,
não na carga.

## Loot dentro do veículo

Três arquivos dedicados em `lua/server/Vehicles/`, separados por compartimento:
`VehicleDistribution_GloveBoxJunk.lua`, `VehicleDistribution_SeatJunk.lua`,
`VehicleDistribution_TrunkJunk.lua`, mais `VehicleDistributions.lua` que os agrega. É tabela Lua, não
`.txt`, e segue o modelo geral de [distribuicao-loot.md](distribuicao-loot.md).

`ProfessionVehicles.lua` liga profissão a veículo, casando com as subpastas
`professionVehicles*/` dos scripts.

## Pontos a confirmar

- **O que o `!` de `template!` faz.** A forma existe com 200 ocorrências e posição consistente
  (primeira linha do bloco), mas nem o `media/` nem o PZ-API-Docs a descrevem — o índice de `scripts`
  da fonte lista `vehicle` e `template`, sem mencionar a variante
  (`pz-wiki-modding.github.io/PZ-API-Docs/scripts/`). É a pergunta que mais importa para quem for
  derivar um veículo de outro, e ela mora no Java.
- **Ordem de aplicação de múltiplos `template =`** no mesmo `vehicle`, e o que acontece quando dois
  templates declaram a mesma `part`. Não há comentário nem exemplo que desempate.
- **Se um mod pode declarar `vehicle` em módulo próprio.** Todos os 47 do jogo usam `module Base`.
  Mesma pendência aberta para `item` em [scripts-txt.md](scripts-txt.md).
- **Semântica dos campos físicos** (`rollInfluence`, `suspensionStiffness`, …): faixa, unidade e
  default não estão no `media/`. Os valores observados são de 43 veículos afinados à mão, o que dá
  ordem de grandeza e não contrato.
- **`crawlThroughWheel`** — a **forma fechou**, a semântica não. É sub-bloco nomeado, com a mesma
  assinatura de uma roda
  (`PZ/media/scripts/generated/vehicles/burntAndSmashedVehicles/burntvehicles.txt:32-38`):

  ```
          crawlThroughWheel FrontLeft
          {
              front = true,
              offset = 0.3462 -0.3956 0.7582,
              radius = 0.15,
              width = 0.2,
          }
  ```

  As 80 ocorrências estão **todas num único arquivo** — `burntvehicles.txt` —, e são 20 veículos ×
  4 posições (`FrontLeft`, `FrontRight`, `RearLeft`, `RearRight`), sempre as quatro. Como esses
  veículos são carcaças queimadas/destruídas, que não andam, a leitura de "geometria de colisão para
  atravessar o destroço" ganhou muito peso — mas continua inferência, não confirmação.
- **Os 66 `.lua` de veículo** — o mapa de topo fechou; os arquivos grandes seguem por ler. A
  distribuição real é 7 em `lua/server/Vehicles/` e 1 em `lua/client/Vehicles/`
  (`ISVehicleTrailerUtils.lua`); **`lua/shared/Vehicles/` tem zero `.lua`**, ao contrário do que a
  contagem de [mapa-media.md](mapa-media.md) (22 arquivos em `shared/Vehicles/`) sugere — os dois
  números medem coisas diferentes e isso não foi reconciliado.

  `PZ/media/lua/server/Vehicles/Vehicles.lua` (1.538 linhas) é **o dono do bloco `lua { }`** do
  `.txt`: as primeiras 12 linhas declaram os namespaces que aquele bloco referencia —
  `Vehicles.CheckEngine`, `CheckOperate`, `ContainerAccess`, `Create`, `Init`, `InstallComplete`,
  `InstallTest`, `UninstallComplete`, `UninstallTest`, `Update`, `Use`. Cada função tem assinatura
  `(vehicle, part, chr)` (`Vehicles.lua:24`). O que falta ler é o corpo dessas 1.538 linhas,
  `VehicleCommands.lua` (469) e o `ISUI/` do cliente. `VehicleDistributions.lua` tem **11.888
  linhas** e é dado, não lógica.
- **Como um mod adiciona peça nova a um veículo existente** — se por `template` que o veículo do jogo
  não cita (o que exigiria editar o `vehicle`), ou por caminho Lua. Nenhum dos 89 mods de `STEAM/`
  foi cruzado para isto.

> Última verificação: 2026-08-07 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

# Fazenda, pesca, acampamento, armadilha, mineração e fluidos

Os seis sistemas de recurso do B42: onde cada um **define seus dados**, qual é o **arquivo canônico**
e **por onde um mod entra**. Não reexplica a mecânica de jogo — o código é legível; o caro é achar.

Alias de caminho conforme [../index.md](../index.md): `PZ/` = instalação do jogo, `STEAM/` = os 89
mods baixados da Workshop.

## O formato comum — e por que ele importa

Os cinco primeiros seguem o **mesmo padrão**, e ele não é o que a maior parte do modding de PZ
sugere: **nenhum deles tem bloco `.txt` próprio, e nenhum tem função de registro.** A definição é uma
**tabela global Lua** preenchida no topo do arquivo, e o mod entra escrevendo nessa tabela.

O único dos seis com bloco `.txt` é `fluid`, e ele já está descrito em
[scripts-txt.md](scripts-txt.md) (seção `fluid`, `PZ/media/scripts/generated/fluids.txt:3`) — esta
página cobre só o **lado Lua** dele.

| Sistema | `.lua` | Arquivo canônico (`PZ/media/lua/`) | Tabela global | Idioma da 1ª linha |
|---|---|---|---|---|
| Fazenda | 24 | `server/Farming/farming_vegetableconf.lua` | `farming_vegetableconf.props` | `farming_vegetableconf = {};` (`:1`) |
| Pesca | 22 | `shared/Fishing/fishing_properties.lua` | `Fishing.fishes`, `Fishing.lure` | `Fishing = Fishing or {}` (`:1`) |
| Armadilha | 14 | `server/Traps/TrapDefinition.lua` | `Traps`, `TrapAnimals` | `Traps = {};` (`:1`) |
| Acampamento | 17 | `server/Camping/camping_fuel.lua` | `campingFuelType` (legado) | comentário; sem `require` |
| Mineração | 1 | `client/Mining/DiggingUtil.lua` | — (só UI) | `DiggingUtil = {` (`:1`) |
| Fluido | 9 | `shared/Fluids/ISFluidUtil.lua` | — (API sobre Java) | `ISFluidUtil = {};` (`:1`) |

Contagem por `find` sobre `client/`, `server/` e `shared/`; a de Fluido é `client/Fluids/` (5) +
`shared/Fluids/` (4), fora o `client/DebugUIs/DebugMenu/Fluids/`.

### A pegadinha: reset duro vs. idioma defensivo

A coluna "idioma da 1ª linha" acima **não é detalhe de estilo** — é o que decide se uma segunda
declaração da tabela sobrevive ou apaga a primeira. O jogo não é consistente:

- **Defensivo** — `Fishing = Fishing or {}`
  (`PZ/media/lua/shared/Fishing/fishing_properties.lua:1`, idem
  `shared/Fishing/FishingZones.lua:1`) e `TrapAnimals = TrapAnimals or {};`
  (`server/Traps/TrapDefinition.lua:50`). Recarregar não perde o que já estava lá.
- **Reset duro** — `Traps = {};` (`server/Traps/TrapDefinition.lua:1`),
  `farming_vegetableconf = {};` (`server/Farming/farming_vegetableconf.lua:1`) e
  `farming_vegetableconf.props = {};` (`:392`), `camping = {}`
  (`server/Camping/camping_tent.lua:1`), `campingText = {};` (`server/Camping/camping_text.lua:1`).
  Quem rodar depois **zera** a tabela.

Repare que os dois idiomas convivem **no mesmo arquivo**: `Traps` é reset duro na linha 1 e
`TrapAnimals` é defensivo na linha 50.

O segundo agravante é que **o jogo nem sempre usa `require`** para garantir a ordem:

- `server/Farming/farming_vegetableconf_herbs.lua:1` **tem** `require "Farming/farming_vegetableconf"`.
- `server/Farming/farming_vegetableconf_vegetables.lua:1` **não tem** — as três primeiras linhas são
  comentários (`-- Flax`, `-- Hemp`, `-- Hops`) e o arquivo depende de ordem de carga alfabética para
  `farming_vegetableconf.props` já existir.
- `shared/Fishing/fishing_properties.lua` e `server/Camping/camping_fuel.lua` **não são requeridos
  por ninguém** (`grep -rn 'require.*fishing_properties'` e `require.*camping_` em `media/lua` só
  acham um `require` comentado em `shared/TimedActions/ISBBQLightFromLiterature.lua:2`). Por isso
  `fishing_properties.lua` precisa do idioma defensivo: ele não controla quem roda antes.

**Um mod que escreve nessas tabelas deve declarar `require` do arquivo dono**, como
`_herbs.lua` faz — não confiar em ordem alfabética. Ordem exata entre arquivo do jogo e arquivo de
mod não está confirmada (ver "Pontos a confirmar").

## Fazenda

Duas tabelas paralelas, **indexadas pela mesma chave** (o nome da planta):

1. **`farming_vegetableconf.props`** (`server/Farming/farming_vegetableconf.lua:392`) — os atributos.
2. **Cinco tabelas de sprite** (`:394`–`:398`): `sprite`, `unhealthySprite`, `dyingSprite`,
   `deadSprite`, `trampledSprite`.

Quem escolhe entre as cinco em runtime é `farming_vegetableconf.getSpriteName`
(`server/Farming/farming_vegetableconf.lua:242`), por `plant.state`, `health` e doença — e ela
retorna `nil` se a combinação não existir, então **faltar uma das cinco tabelas some com o sprite
sem erro**.

Entrada canônica, `server/Farming/farming_vegetableconf_vegetables.lua:5`:

```lua
farming_vegetableconf.props.Barley = {
    icon = "Item_Barley",
    texture = "vegetation_farming_01b_6",
    waterLvl = 30,
    waterNeeded = 70,
    timeToGrow = 432,
    minVeg = 2,
    maxVeg = 4,
    minVegAutorized = 6,
    maxVegAutorized = 8,
    vegetableName =  "Base.BarleySheaf",
    seedName = "Base.BarleySheaf",
    seedTypes = { "Base.BarleySeed",},
    badMonth = { 6, 7 },
    sowMonth = { 8, 9, 10 },
    bestMonth = { 9 },
    riskMonth = { 10 },
    seasonRecipe = "base:barley growing season",
    harvestLevel = 6,
    mature = 5,
    fullGrown = 6,
    scytheHarvest = true,
    harvestPosition = "High",
    coldHardy = true,
}
```

(Bloco reproduzido sem as linhas comentadas `waterLvl = 35`, `timeToGrow = 960` e `produceExtra`, que
existem no arquivo.) O sprite correspondente é um array por estágio de crescimento —
`server/Farming/farming_vegetableconf_vegetables_sprites.lua:3`, este **com** `require` na linha 1:

```lua
farming_vegetableconf.sprite["Barley"] = {
"vegetation_farming_01b_0",
...
"vegetation_farming_01b_7"
}
```

As ervas moram em `_herbs.lua` / `_herbs_sprites.lua`, mesmo formato.

**A volta do sprite para o objeto** é `server/Map/MapObjects/MOFarming.lua`, que monta um
`cropSpriteMap` (`:8`) e registra cada sprite via `MapObjects.OnNewWithSprite(...)` (`:99`). É o que
faz uma planta já existente no mapa virar objeto do sistema — sem isso a planta só existe se plantada
pelo jogador.

### Colheita, semente, rebrota e nome na UI `[levantado 2026-10-29]`

Os campos de `props` que um mod precisa entender para fechar o ciclo, todos lidos pelo código do
jogo. O mod não escreve código de colheita:

- **Colheita** (`server/Farming/SFarmingSystem.lua:344-383`): dá `vegetableName` × N (`:344-347`),
  `produceExtra` × N se houver (`:349-352`) e, com `hasSeed`, `seedName` ×
  `max(floor(N × seedPerVeg), 1)` (`:354-358`). `seedPerVeg` é opcional, com padrão `0.5` (`:355`).
  A colheita sempre devolve pelo menos uma semente, e é isso que torna a cultura autossustentável.
- **`growBack`** (`:366-376`): se presente, a planta volta ao estágio `nbOfGrow = growBack`, zera o
  fertilizante e continua no canteiro. Sem ele, vira resto de colheita (`harvestThis()`, `:379`). As
  ervas usam `growBack = 2` (`server/Farming/farming_vegetableconf_herbs.lua:24`).
- **Achar a semente no inventário**: `seedTypes or { seedName }` (`client/Farming/ISUI/ISFarmingMenu.lua:1035`,
  `client/Farming/CFarming_Interact.lua:118`). `seedTypes` aceita mais de um item, e o tomate usa
  o próprio fruto como semente (`seedName = "Base.Tomato"`, `server/Farming/farming_vegetableconf_vegetables.lua:757`).
- **Nome da planta na UI** = `getText("Farming_" .. chave)` (`ISFarmingMenu.lua:479`, `:1029`;
  `CFarming_Interact.lua:113`). A chave fica em `Translate/<IDIOMA>/Farming.json`
  (`shared/Translate/EN/Farming.json:8`, `"Farming_Tobacco"`). Chave de `props` sem essa tradução
  mostra o identificador cru.
- **`seasonRecipe`** não é bloco `.txt`: é uma string que o jogador aprende (pela revista de semente
  via `LearnedRecipes`, ou pelo Farming 10, que ensina todas as de `props`,
  `server/XpSystem/XpUpdate.lua:242-249`). Sem ela conhecida, o tooltip de época só aparece com
  Farming ≥ 6 (`ISFarmingMenu.lua:474`). O nome visível sai de `Recipes.json`
  (`shared/Translate/EN/Recipes.json:119`).

## Pesca

Peixe **não é bloco `.txt`**: `scripts/generated/models_fish.txt` é modelo 3D e
`scripts/generated/recipes/recipes_fishing.txt` é receita. A definição é 100% Lua, por uma
**classe-construtor**, não por tabela literal — é o único dos seis assim.

`Fishing.FishConfig` é declarada em `shared/Fishing/fishing_properties.lua:86`, com `:new(itemType)`
em `:89` e os setters logo abaixo (`setLocation` `:102`, `setMaxLength` `:107`, `setTrophyLength`
`:111`, `setMaxWeight` `:115`, `setTrophyWeight` `:119`). A entrada canônica está em `:218`:

```lua
local LargemouthBass = Fishing.FishConfig:new("Base.LargemouthBass")
LargemouthBass:setLocation(true, true)    -- River, Lake
LargemouthBass:setMaxLength(51) -- CM
LargemouthBass:setTrophyLength(75)
LargemouthBass:setMaxWeight(2.8) -- KG
LargemouthBass:setTrophyWeight(10)
LargemouthBass:setWeightFactor(2)
LargemouthBass:initFishSizeData()

LargemouthBass:addLures(Fishing.lure.Insect, 0.3)
...
LargemouthBass.lure["Base.JigLure"] = 0.5
LargemouthBass.lure["Base.Maggots"] = 0.9

table.insert(Fishing.fishes, LargemouthBass)
```

Três coisas que só se vê olhando: `initFishSizeData()` é chamado **depois** dos setters de tamanho e
**antes** das iscas; `addLures` recebe uma **categoria inteira** com um multiplicador; e
`.lure["Base.X"] = n` sobrescreve item a item. A lista termina em `table.insert(Fishing.fishes, ...)`
— sem isso o peixe não existe.

**Iscas por categoria** ficam em `:6`–`:63`: `Fishing.lure.Insect` (`:8`), `Minnows` (`:25`),
`Leeches` (`:29`), `Worms` (`:35`), `Flesh` (`:39`), `Plant` (`:50`), `ArtificalLure` (`:59`),
`All` (`:63`). Cada entrada é `{ chanceModifier = 1.0, amountOfFoodHunger = -1 }`.

`Fishing.lure.All` **não é escrita à mão**: `Fishing.IndexAllLures` (`:65`) a reconstrói varrendo
`pairs(Fishing.lure)` e copiando toda categoria que não seja ela mesma, e está registrada em
`Events.OnGameStart` (`:75`) **e** `Events.OnServerStarted` (`:76`). Duas consequências práticas:

- **Categoria de isca nova é indexada sozinha.** Como a varredura é `pairs` sobre `Fishing.lure`,
  um mod que crie `Fishing.lure.MinhaCategoria = { ... }` entra em `All` sem tocar em `IndexAllLures`
  — e `Fishing.IsLure(item)` (`:78`) passa a responder `true` para ela.
- **A indexação roda em `OnGameStart`/`OnServerStarted`**, ou seja, depois da carga dos `.lua`. Esse
  é o ponto do arquivo em que ordem de carga deixa de importar — ao contrário das tabelas de fazenda
  e armadilha, que são consumidas do jeito que ficaram.

`Fishing.IsArtificalLure` (`:82`) consulta `ArtificalLure` direto, não `All`.

`Fish.lua`, `FishingRod.lua` e `Bobber.lua` são **classes de runtime**, não dados —
`Fishing.Fish = {}` em `shared/Fishing/Fish.lua:3` com `Fish:new(character, lure, isReel, x, y)`
em `:7`.

**Zona de pesca é coordenada crua**, em `shared/Fishing/FishingZones.lua`: `Fishing.RiverZones`
(`:4`) e `Fishing.NoFishZones` (`:13`), ambas arrays de `{x1=, y1=, x2=, y2=}`. Mapa novo que
queira pesca de rio precisa somar a `RiverZones`.

Evento próprio: `Events.OnFishingActionMPUpdate`, escutado em `shared/Fishing/Bobber.lua:301` e em
`client/Fishing/FishingManager.lua:117`.

## Armadilha

`server/Traps/TrapDefinition.lua` carrega **duas** tabelas independentes, e é o par que importa:
`Traps` (o equipamento) e `TrapAnimals` (o que se pega).

Armadilha, `:2`–`:8` — campos `type`, `sprite`, `closedSprite`, `trapStrength`, `destroyItem`; os
opcionais `northSprite` (`:12`) e `northClosedSprite` (`:14`) aparecem no bloco seguinte:

```lua
local crateTrap = {};
crateTrap.type = "Base.TrapCrate";
crateTrap.sprite = "constructedobjects_01_3";
crateTrap.closedSprite = "constructedobjects_01_2";
crateTrap.trapStrength = 15;
crateTrap.destroyItem = { "Base.UnusableWood", "Base.Nails" };
table.insert(Traps, crateTrap);
```

Animal capturável, a partir de `:51` (`rabbit`) — o arquivo comenta cada campo em linha. Os três que
amarram tudo são tabelas de **peso por chave**:

- `rabbit.zone` (`:73`) — chance por zona (`TownZone`, `Forest`, …).
- `rabbit.traps` (`:88`) — chance **por `type` de armadilha**, ou seja, casa com o campo `type` de
  `Traps`.
- `rabbit.baits` (`:94`) — chance por item de isca.

Um animal novo que não apareça em `.traps` de nenhuma armadilha nunca é capturado, e o inverso também
vale: armadilha nova só pega algo se algum `TrapAnimals[*].traps` citar o `type` dela. **É o erro
silencioso da área.**

`canBeAlive`/`aliveAnimals`/`aliveBreed` (`:63`–`:71`) ligam a armadilha ao sistema de animais vivos
do B42 — ver [animais.md](animais.md), que já cobre o lado do `instanceItem`
(`server/Traps/STrapGlobalObject.lua:248`).

Registro de sprite no mapa: `server/Map/MapObjects/MOTrap.lua:3`, que **requer** `Traps/TrapDefinition`
e `Traps/STrapSystem` (`:4`) — o contrário do que Farming faz.

## Acampamento — a área mais desatualizada

Aqui o levantamento contradiz o que a maior parte do material de modding diz. `camping_fuel.lua`
declara **no próprio cabeçalho** que suas tabelas são legado:

- `PZ/media/lua/server/Camping/camping_fuel.lua:7` — *"Items should use the `IsFireFuel` to dictate
  that an item can be used as fuel"*
- `:13` — *"this is the old system and shouldn't be continued to be used to define fire fuels or
  tinders"*

As tabelas seguem existindo como rede de segurança — `campingFuelType` (`:14`),
`campingFuelCategory` (`:87`) — mas **o caminho do B42 é a tag no `.txt` do item**, e o Lua lê por
tag: `shared/Camping/ISCampingMenu.lua:51` faz
`item:hasTag(ItemTag.IS_FIRE_FUEL) or item:getFireFuelRatio() > 0`.

`camping_text.lua:1` é só um dicionário de `getText(...)` para o menu de contexto; `camping_tent.lua:1`
declara `camping = {}` com os sprites e funções de barraca.

O `entity` da fogueira é declarativo e aponta para Lua pelo nome —
`PZ/media/scripts/generated/entities/outdoors/entity_campfire.txt:14`:

```
OnCreate = BuildRecipeCode.campfire.OnCreate,
OnIsValid = BuildRecipeCode.campfire.OnIsValid,
```

resolvidos em `server/BuildRecipeCode/buildRecipeCode.lua:501` (`OnIsValid`) e `:511` (`OnCreate`),
sobre `BuildRecipeCode.campfire = {}` (`:10`). O padrão `On*` do `entity` está em
[construcao.md](construcao.md).

## A ponte `.txt` ↔ Lua: as tags de item

É o mecanismo que substituiu tabela Lua em fogo e pesca, e o que mais custa grep porque **a grafia
muda dos dois lados**:

| No `.txt` (`Tags =`) | No Lua | Confirmação |
|---|---|---|
| `base:isfirefuel` | `ItemTag.IS_FIRE_FUEL` | `scripts/generated/items/drainable.txt:1531` / `shared/Camping/ISCampingMenu.lua:51` |
| `base:isfirefuelsingleuse` | `ItemTag.IS_FIRE_FUEL_SINGLE_USE` | `drainable.txt:1531` / `ISCampingMenu.lua:88` |
| `base:isfiretinder` | `ItemTag.IS_FIRE_TINDER` | `drainable.txt:1531` |
| `base:startfire` | `ItemTag.START_FIRE` | `scripts/generated/items/drainable.txt:2182` / `shared/Camping/ISCampingMenu.lua:117` |
| `base:fishingrod` | `ItemTag.FISHING_ROD` | `scripts/generated/items/weapon.txt:7525` / `client/Fishing/FishingHandler.lua:38` |
| `base:fishinghook` | `ItemTag.FISHING_HOOK` | `scripts/generated/items/normal.txt:3420` |
| `base:isseed` | `ItemTag.IS_SEED` | `scripts/generated/items/food.txt:142` |
| `base:digplow`, `base:digworms` | `ItemTag.DIG_PLOW`, `DIG_WORMS` | `scripts/generated/items/normal.txt:11366` |
| `base:uncutfish`, `base:fishmeat` | `ItemTag.UNCUT_FISH`, `FISH_MEAT` | `scripts/generated/items/food.txt:6957` |

**A regra**: `.txt` usa minúscula com prefixo `base:`; o Lua usa `UPPER_SNAKE_CASE` sob `ItemTag.`.
Grepar `IsFireFuel` no `media/scripts` devolve **zero** — a grafia literal do comentário do jogo não
é a que o arquivo usa. Lista dentro de `Tags` separa por `;`, como já registrado em
[scripts-txt.md](scripts-txt.md).

Cuidado com um falso positivo: `base:fishing` **não é tag de item** — é um
`character_trait_definition` (`PZ/media/scripts/generated/characters/character_traits.txt:347`).

**`base:startfire` é a tag com o alcance mais largo das oito, e tem um caminho que não passa por Lua
nenhum.** Além do gate do menu de fogueira (`ISCampingMenu.lua:117`) e da busca de acendedor em
`client/ISUI/ISWorldObjectContextMenu.lua:1653`, ela é consumida **como insumo de receita**, escrita
`item 1 tags[base:startfire]`: acender vela e lampião
(`PZ/media/scripts/generated/recipes/recipes_lightsources.txt:13` e `:81`), forno de cerâmica
(`generated/entities/pottery/cratRecipes/craftrecipe_kiln.txt:12`, 22 vezes no arquivo) e forja
(`generated/entities/blacksmith/craftRecipes/recipes_blacksmith_furnace_ii.txt:13`). São 34
ocorrências no `media/scripts`. Para um mod isso significa que **pôr a tag no bloco `.txt` já habilita
o item em todas essas receitas** — é o caso 2 da seção seguinte levado ao extremo. Os portadores
vanilla estão todos em `drainable.txt` (`:730` isqueiro, `:779`, `:793`, `:2182` `CandleLit`, `:2404`);
sobre item não-drainable carregar a tag, ver "Pontos a confirmar" de
[scripts-txt.md](scripts-txt.md).

`ItemTag` não está declarado em `media/lua` (`grep -rn "ItemTag *=" lua/` não acha): é enum do Java,
alcançado direto pelo Lua. Uso observado, não contrato declarado.

## Mineração — quase não existe

`client/Mining/DiggingUtil.lua` é o **único** arquivo de Mineração, tem **144 linhas** e é um helper
de UI para escavar escada — não tem tabela de minério nenhuma. Declara `DiggingUtil = {` (`:1`),
registra `Events.OnTick.Add(DiggingUtil.tick)` (`:144`) e tem um único caller fora de si:
`client/ISUI/ISWorldObjectContextMenu.lua:1621` (`DiggingUtil.excavatingStairs = true`).

**Minério não mora aqui.** Os veios são feature de geração de mundo, em
`server/WorldGen/features/ore/` (8 arquivos: `iron_ore.lua`, `copper_ore.lua`, `limestone.lua`,
`flint.lua`, `boulders*.lua`), registrados em `worldgen.features.ORE[...]`. Isso já está documentado
em [worldgen.md](worldgen.md) — inclusive o `iron_ore.lua` inteiro. Não é repetido aqui.

## Fluido — o lado Lua

O bloco `.txt` `fluid` está em [scripts-txt.md](scripts-txt.md). O que interessa aqui é como o Lua
alcança o que aquele bloco definiu, e a resposta é: **pelo nome, como campo de uma global do Java**.

- **`Fluid.<Nome>`** — `Fluid.Petrol` (`shared/Vehicles/TimedActions/ISTakeGasolineFromVehicle.lua:44`),
  `Fluid.Bleach` e `Fluid.TaintedWater` (`client/ISUI/ISInventoryPane.lua:2317`).
- **`Fluid.Get(FluidType.X)`** — forma alternativa, em
  `client/FeedingTrough/ISUI/ISFeedingTroughMenu.lua:73`.

O container vem do item: `item:getFluidContainer()`
(`client/Farming/ISUI/ISFarmingMenu.lua:61`, `client/DebugUIs/DebugMenu/Fluids/ISFluidMixerViewPanel.lua:201`).
Sobre ele, métodos Java observados: `:contains(Fluid.X)`, `:getAmount()`, `:isEmpty()`,
`:getPoisonRatio()` (`ISInventoryPane.lua:2317`), `:addFluid(Fluid.Petrol, litros)`
(`ISTakeGasolineFromVehicle.lua:44`), `:removeFluid(...)`
(`shared/FeedingTrough/TimedActions/ISAddWaterToTrough.lua:22`).

Transferência é **estática**, não método de instância: `FluidContainer.CanTransfer(from, to)`
(`client/Fluids/ISFluidTransferUI.lua:238`) e `FluidContainer.Transfer(from, to, qtd, bool)`
(`:410`, `client/DebugUIs/DebugMenu/Fluids/ISFluidMixerViewPanel.lua:204`).

O lado Lua próprio é fino: `ISFluidUtil` (`shared/Fluids/ISFluidUtil.lua:1`) tem
`validateContainer` (`:7`), `doWalkTo` (`:22`), `getContainerOwner` (`:43`),
`getTransferActionTimePerLiter` (`:51`), `getMinTransferActionTime` (`:55`) e
`getLuaFluidContainer` (`:59`) — utilitário de UI/ação, não modelo de dado.

Nenhum `Events.*` é registrado em `client/Fluids/` nem em `shared/Fluids/`.

### Fluido de mod e conversão dentro do recipiente `[levantado 2026-10-27]`

- **`Fluid.Get` tem sobrecarga `Get(String)`** além de `Get(FluidType)`, e `FluidContainer.addFluid`
  aceita `String`, `FluidType` ou `Fluid` como 1º argumento (`javap -p` sobre
  `zombie.entity.components.fluids.Fluid` e `.FluidContainer` do `projectzomboid.jar`; ver
  [../fontes-externas.md](../fontes-externas.md), "Ler o `.jar`"). O jogo, partindo de nome, converte
  antes (`FluidType.FromNameLower(nome)`, `client/ISUI/ISFluidContainerMenu.lua:76`); a forma string
  direta é vista em mod: `addFluid("RawHoney", qtd)` (`STEAM/3596827035/mods/ShelterHold_Beehive/common/media/lua/shared/TimeAction/HoneyExtractor/HE_ExtractAction.lua:141`).
- **Nome de fluido é global, não leva módulo.** O mesmo mod declara `fluid RawHoney` dentro de
  `module Hold` (`.../ShelterHold_Beehive/42.13/media/scripts/generated/items/HoldItems_Beehive.txt:145`)
  e o Lua o chama sem `Hold.` — dois mods com o mesmo nome de fluido colidem; prefixar.
- **Converter um fluido em outro dentro de um recipiente mantido na receita** — o modelo é
  `RecipeCodeOnCreate.purifyWater` (Java, desmontado com `javap -c`): pega
  `craftRecipeData.getAllKeepInputItems().getFirst()`, lê
  `getFluidContainer().getSpecificFluidAmount(Fluid.TaintedWater)`, converte `min(1.0, x)`, chama
  `adjustSpecificFluidAmount(Fluid.TaintedWater, x - convertido)` — **o 2º argumento é o novo total,
  não o delta** —, depois `addFluid(Fluid.Water, convertido)` e por fim `item.sendSyncEntity(null)`.
  A receita que o usa é `PurifyWater` (`PZ/media/scripts/generated/recipes/recipes_medical.txt:168-185`,
  item mantido com `flags[ItemIsFluid;NotEmpty]` e `outputs` vazio).

### Mistura: remoção e efeito proporcionais `[levantado 2026-10-27]`

- **`FluidContainer.removeFluid(qtd, bool, FluidConsume)`** (Java, `javap -c`) tira de **cada**
  `FluidInstance` a quantidade `qtd × getPercentage()`, ou seja, a mistura sai na proporção. O
  `FluidConsume` devolvido acumula as `Properties` de cada fluido multiplicadas pela parte removida
  (`addFromMultiplied`), e o veneno sai por `PoisonInfo.getPoisonEffect(…, porcentagem)`, que é onde
  entra o `diluteRatio` do sub-bloco `Poison`.
- **`IsoGameCharacter.DrinkFluid(FluidContainer, float, boolean)`** aplica esse `FluidConsume` em
  `THIRST`, `HUNGER`, `ENDURANCE`, `STRESS`, `FATIGUE`, `BOREDOM`/`UNHAPPINESS`, `POISON`, álcool, dor e
  resfriado. Os efeitos de beber uma mistura saem prontos na proporção, e um mod de bebida não precisa recalculá-los.
- **Beber é contínuo, não acontece no fim da ação.** `ISDrinkFluidAction:update()` chama `updateEat`
  a cada quadro em SP (`PZ/media/lua/shared/TimedActions/ISDrinkFluidAction.lua:26-30`), e em MP o
  servidor faz isso por `animEvent` (`:42-47`). Ação interrompida já bebeu uma parte. Quem precisa
  saber **quanto** foi bebido mede o conteúdo no `new` (`:126`) e de novo no `complete`/`stop`. Quem
  precisa mudar o conteúdo **antes** de beber faz isso no `new`, cujas proporções da ação
  (`startRatio`, `maxTime`) já são calculadas a partir dele.

## O par cliente/servidor — os três `GlobalObjectSystem`

Fazenda, armadilha e acampamento são objetos globais persistidos, e **cada um existe em dose dupla**,
com a **mesma string de sistema** dos dois lados:

| Sistema | Servidor | Cliente | String |
|---|---|---|---|
| Fazenda | `server/Farming/SFarmingSystem.lua:5` (`new` em `:8`) | `client/Farming/CFarmingSystem.lua:3` (`:6`) | `"farming"` |
| Armadilha | `server/Traps/STrapSystem.lua:5` (`:9`) | `client/Traps/CTrapSystem.lua:3` (`:6`) | `"trap"` |
| Fogueira | `server/Camping/SCampfireSystem.lua:5` (`:8`) | `client/Camping/CCampfireSystem.lua:3` (`:6`) | `"campfire"` |

O padrão é `SGlobalObjectSystem:derive("SXSystem")` + `SGlobalObjectSystem.new(self, "<string>")`, com
`CGlobalObjectSystem` do lado cliente. **A string tem de bater entre os dois** — é a chave que liga o
par. Pesca, mineração e fluido **não** têm `GlobalObjectSystem`.

Tick do servidor: `Events.EveryTenMinutes` em `server/Farming/SFarmingSystem.lua:586`;
`Events.EveryOneMinute` e `Events.EveryTenMinutes` em `server/Camping/SCampfireSystem.lua:183`–`:184`.
Do lado cliente, `client/Farming/CFarming_Interact.lua:312`–`:318` registra `OnKeyStartPressed`,
`OnContextKey`, `OnKeyPressed` e `OnGameStart`. Lista completa de eventos em
[eventos-lua.md](eventos-lua.md).

## Por onde um mod entra, na prática

Ordenado pelo que a evidência sustenta:

1. **Fazenda — provado.** É o único dos seis que mods reais estendem. Em `STEAM/`:
   `2937434637/mods/Sprout's  Farm&Garden-Homestead Edition/media/lua/server/Farming/SGVeg_Config.lua`
   e `SGFarmingSystem.lua` (mesmo mod, 4 variantes de pasta), além de
   `3403870858/mods/Lifestyle/common/media/lua/server/Farming/LSFarmingConf.lua`. O caminho dentro do
   mod repete o do jogo (`media/lua/server/Farming/`), o arquivo dá `require` em
   `Farming/farming_vegetableconf` e escreve em `props` + nas tabelas de sprite.
   O Lifestyle (B42, atualizado 2026-09) é o exemplo mais limpo: `LSFarmingConf.lua:12` faz o
   `require`, `:31-85` declara as cinco tabelas de sprite com chave própria (`LSScrapBush`), `:86-115`
   declara `props` com `seedName` no módulo do mod (`"Lifestyle.ScrapBushSeed"`, `:98`), `growBack = 4`
   (`:110`) e `seasonRecipe` no **namespace do mod**, `"lifestyle:scrap bush growing season"` (`:109`).
2. **Fogo/pesca por tag `.txt`** — não exige Lua nenhum: pôr `base:isfirefuel` ou `base:fishingrod`
   em `Tags` do item já é lido pelo jogo, pelos `caminho:linha` da seção de tags.
3. **Isca de pesca — mecanismo confirmado no código.** Categoria nova em `Fishing.lure` é absorvida
   por `Fishing.IndexAllLures` em `OnGameStart` (`shared/Fishing/fishing_properties.lua:65`,`:75`).
   É o único gancho desta página que o próprio jogo reindexa depois da carga, então não depende de
   ordem de arquivo. Sem exemplo em `STEAM/`, mas o caminho está no código.
4. **Pesca (peixe), armadilha, acampamento por tabela Lua** — o mecanismo existe e o idioma defensivo
   de `Fishing`/`TrapAnimals` favorece, mas **nenhum dos 89 mods de `STEAM/` faz isso**: `grep -rl` por
   `Fishing.fishes`, `Fishing.lure`, `Fishing.RiverZones`, `TrapAnimals`, `table.insert(Traps`,
   `campingFuelType` e `camping.tentSprites` em todos os `.lua` de `STEAM/` devolve **zero arquivo**.
   Ausência de exemplo não é prova de que não funcione — mas é o sinal de que não há caminho batido,
   e a área pede teste in-game antes de virar plano.
5. **Mineração** — não há por onde entrar em `client/Mining/`. O ponto de entrada é `worldgen`
   ([worldgen.md](worldgen.md)).

## Pontos a confirmar

- **Ordem de carga entre `.lua` do jogo e `.lua` de mod.** O reset duro de `Traps = {}`
  (`server/Traps/TrapDefinition.lua:1`) e de `farming_vegetableconf.props = {}` (`:392`) só é
  inofensivo se o arquivo do jogo rodar **antes** do arquivo do mod. Isso não foi confirmado:
  [carregamento-de-mods.md](carregamento-de-mods.md) não cobre ordem de carga de Lua, e a página não
  afirma nada além do idioma literal de cada arquivo. Teste in-game resolve.
- **Se `require "Farming/farming_vegetableconf"` num mod garante a ordem** ou só evita o `nil`.
  Levantado que `_herbs.lua` usa e `_vegetables.lua` não; a consequência para mod é inferência.
- **Campos obrigatórios vs. opcionais de `farming_vegetableconf.props`.** A entrada `Barley` usa 23
  campos, mas o arquivo não declara quais são exigidos — plantas diferentes usam subconjuntos. Não há
  bloco `.txt`, logo o PZ-API-Docs (que documenta parser de `.txt`) **não cobre esta área**: não há
  contraprova externa de `required`/default para nenhuma das tabelas Lua desta página.
- **`ItemTag` completo.** O PZ-API-Docs publica a lista em `java/item_tags.html` (consultado
  2026-08-08, versão 42.20.2); as 8 linhas da tabela de tags acima foram confirmadas uma a uma no
  `media/`. As demais tags que a fonte lista **não** foram conferidas e não entram aqui. A fonte
  também não lista `base:fishingnet` nem `base:fishingspear`, que existem no `media/` — outro motivo
  para não tratá-la como inventário.
- **Zonas de pesca fora do mapa base.** `Fishing.RiverZones` é coordenada absoluta do mapa vanilla;
  se mapa de mod precisa somar ali ou se há registro por célula não foi levantado.
- **`campingFuelType` ainda tem efeito?** O cabeçalho diz que é backup e que o valor usado é o menor
  entre o da tabela e o procedural (`camping_fuel.lua:12`). Onde essa comparação acontece não foi
  localizado no `media/lua` — provavelmente Java.

> Última verificação: 2026-08-26 — jogo **42.20.4** (`b0bbce05d5`), PZ buildid 24909800
> (branch public, atualizado 2026-08-26), media/.
>
> Reconferida por diff de `mtime` sobre dois patches. O primeiro (`24574865` → `24775755`) não
> reescreveu arquivo nenhum de `media/`. O segundo (`24775755` → `24909800`) tocou 23 arquivos, e
> **um** deles é citado por esta página: `client/ISUI/ISWorldObjectContextMenu.lua`. As duas
> citações a ele foram conferidas linha a linha e continuam válidas — `:1653` (busca de acendedor
> por `ItemTag.START_FIRE`) e `:1621` (`DiggingUtil.excavatingStairs = true`). Nada de
> `media/scripts` foi tocado nos dois patches, então os censos de tag e de receita seguem de pé.

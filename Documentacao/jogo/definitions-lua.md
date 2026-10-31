# `shared/Definitions/` — configuração declarativa em Lua

Os 13 `.lua` de `PZ/media/lua/shared/Definitions/`: que tabela global cada um declara, qual é a forma
de uma entrada, quem consome e como um mod acrescenta entrada sem apagar as do jogo.

Alias de caminho: `PZ/` = instalação do jogo, `STEAM/` = os 89 mods da Workshop
(ver [../index.md](../index.md)).

A subpasta `animal/` (18 arquivos) **não é coberta aqui** — ela tem página própria, com os espaços de
chave e a pilha inteira do animal: [animais.md](animais.md).

## O que a pasta é — e o que ela não é

É o padrão do jogo para "configuração que seria um `.txt` se o parser da IndieStone desse conta":
tabela Lua global, preenchida na carga, lida depois por UI, por TimedAction ou pelo Java.
[mapa-media.md](mapa-media.md) já aponta a pasta como o modelo a copiar quando um mod precisa disso;
esta página fecha o contrato de cada arquivo.

**O nome da pasta não é gancho de carregamento.** Nada em `media/lua/` faz `require` da pasta como
conjunto, e o único `require` de um arquivo dela em todo o jogo é
`PZ/media/lua/client/ISUI/ISInventoryPage.lua:10` — `require "Definitions/ContainerButtonIcons"`.
Os outros 12 entram pela varredura de `media/lua/shared/`, igual a qualquer `.lua` daquela árvore.

A evidência mais direta disso está no lado do mod: dos 60 arquivos `.lua` de `STEAM/` que mexem em
`ContainerButtonIcons`, **52 estão soltos em `media/lua/shared/`** e só 5 em
`media/lua/shared/Definitions/`. Funciona nos dois lugares — a pasta é convenção de organização, não
requisito.

```sh
# censo de onde os mods põem o arquivo (reproduzível)
cd STEAM/ && grep -rl "ContainerButtonIcons" . --include=*.lua \
  | sed 's#.*/media/lua/##; s#/[^/]*$##' | sort | uniq -c | sort -rn
```

## Os 13 arquivos

Tabela de localização, não de conteúdo — as entradas ficam no `media/`, não aqui (regra 2 da árvore).

| Arquivo | Global declarada | Configura | Consumidor Lua |
|---|---|---|---|
| `AttachedWeaponDefinitions.lua` | `AttachedWeaponDefinitions` (`:5`) | arma espetada no zumbi ao criá-lo | **nenhum** |
| `ClothingRecipesDefinitions.lua` | `ClothingRecipesDefinitions` (`:1`) | que material sai ao rasgar roupa, por `FabricType` | 2 arquivos |
| `ClothingSelectionDefinitions.lua` | `ClothingSelectionDefinitions` (`:4`) | roupa oferecida por profissão na criação de personagem | 1 arquivo |
| `ContainerButtonIcons.lua` | `ContainerButtonIcons` (`:1`) | ícone do botão de container no inventário | 19 arquivos |
| `DamageModelDefinitions.lua` | `DamageModelDefinitions` + `.list` (`:2-3`) | textura de dano no zumbi por parte do corpo | **nenhum** |
| `DefaultClothing.lua` | `DefaultClothing` (`:1`) | textura/tint default de roupa (nomes de `.xml`, não `ItemType`) | **nenhum** |
| `FitnessExercises.lua` | `FitnessExercises` + `.exercisesType` (`:1,3`) | exercícios da UI de fitness | 1 arquivo |
| `HairOutfitDefinitions.lua` | `HairOutfitDefinitions` + `.haircutDefinition` (`:5`) + `.haircutOutfitDefinition` (`:39`) | corte de cabelo permitido por outfit e por era | **nenhum** |
| `MakeUpDefinitions.lua` | `MakeUpDefinitions` + `.categories` (`:4`) + `.makeup` (`:34`) | maquiagem: categorias e itens | 2 arquivos |
| `MapSymbolDefinitions.lua` | **nenhuma** — ver abaixo | símbolos do mapa (textura + categoria) | 1 arquivo |
| `SmashedCarDefinitions.lua` | `SmashedCarDefinitions` + `.cars` (`:1,4`) | variante amassada de cada carro | **nenhum** |
| `TraitClothingSelectionDefinitions.lua` | `TraitClothingSelectionDefinitions` (`:1`) | roupa oferecida por traço | 1 arquivo |
| `UnderwearDefinition.lua` | `UnderwearDefinition` + `.baseChance` (`:2,5`) | roupa de baixo gerada em zumbi | **nenhum** |

**6 dos 13 não têm nenhum leitor em Lua** — a global existe só para o Java ler. Verificado por
varredura de `PZ/media/lua/` inteiro (client + server + shared) atrás de cada nome:

```sh
cd PZ/media/lua && grep -rl "\bAttachedWeaponDefinitions\b" . # → só o próprio arquivo
```

Para `AttachedWeaponDefinitions` o próprio arquivo diz quem lê, no comentário de cabeçalho
(`AttachedWeaponDefinitions.lua:3`): `-- this is used in IsoZombie.addRandomAttachedWeapon()`.
Para os outros 5 o consumidor Java não está nomeado em lugar nenhum do `media/` — ver
"Pontos a confirmar".

## As quatro formas de declarar — e por que a diferença importa

O idioma da primeira linha é o que decide se um mod consegue somar entrada. Censo dos 13:

```sh
cd PZ/media/lua/shared/Definitions && grep -n "^\([A-Za-z]*\) = \1 or {};\?$" *.lua   # 9
cd PZ/media/lua/shared/Definitions && grep -n "^[A-Za-z]* = {};\?$" *.lua              # 3 (na linha 1-2)
```

**1. `X = X or {}` — 9 arquivos, o caso bom.** `AttachedWeaponDefinitions.lua:5`,
`ClothingSelectionDefinitions.lua:4`, `ContainerButtonIcons.lua:1`, `DamageModelDefinitions.lua:2`,
`HairOutfitDefinitions.lua:1`, `MakeUpDefinitions.lua:1`, `SmashedCarDefinitions.lua:1`,
`TraitClothingSelectionDefinitions.lua:1`, `UnderwearDefinition.lua:2`. A tabela sobrevive a quem
já a criou, então a ordem de carga entre o jogo e o mod não destrói nada.

**2. `X = {}` cru — 3 arquivos**, e aqui a ordem de carga passa a importar:
`ClothingRecipesDefinitions.lua:1`, `DefaultClothing.lua:1`, `FitnessExercises.lua:1`. Se o arquivo
do jogo rodar **depois** do arquivo do mod, ele zera a tabela e as entradas do mod somem — sem erro
no `console.txt`. Contra esses três, o mod tem de garantir a ordem (ver a seção do `require`).

**3. Subtabela nomeada.** `FitnessExercises` não guarda entrada na raiz: quem tem as entradas é
`FitnessExercises.exercisesType` (`FitnessExercises.lua:3`). O mesmo em `DamageModelDefinitions.list`,
`MakeUpDefinitions.categories`/`.makeup`, `SmashedCarDefinitions.cars`,
`HairOutfitDefinitions.haircutDefinition`/`.haircutOutfitDefinition`. Escrever na raiz nesses casos
não faz nada.

**4. Nenhuma declaração — `MapSymbolDefinitions`.** Ver a seção dedicada.

## Chave: dicionário ou array

Não há um padrão único, e errar isso é entrada ignorada em silêncio.

**Dicionário com chave string** — a chave é o nome da entrada:
`AttachedWeaponDefinitions`, `ClothingSelectionDefinitions` (chave = nome da profissão),
`ContainerButtonIcons` (chave = `container:getType()`), `DefaultClothing`,
`FitnessExercises.exercisesType`, `SmashedCarDefinitions.cars` (chave = `ItemType` completo do carro),
`UnderwearDefinition`.

**Dicionário aninhado**: `ClothingRecipesDefinitions["FabricType"][<fabric>]`
(`ClothingRecipesDefinitions.lua:5-8`).

**Array via `table.insert`** — a chave é posicional e não tem nome:
`DamageModelDefinitions.list` (`:11`), `HairOutfitDefinitions.haircutDefinition` (`:9`),
`MakeUpDefinitions.makeup` (`:44`).

**Chave que é enum do Java**: `TraitClothingSelectionDefinitions[CharacterTrait.GARDENER]`
(`TraitClothingSelectionDefinitions.lua:3`). `CharacterTrait` não é definido em Lua nenhum —
`grep -rn "CharacterTrait *=" PZ/media/lua/` volta vazio. Vale o mesmo para `BodyPartType`
(`DamageModelDefinitions.lua:14`) e `Metabolics` (`FitnessExercises.lua:9`).

## Forma de uma entrada — o exemplo canônico

`PZ/media/lua/shared/Definitions/UnderwearDefinition.lua:7-17`, escolhido por ser curto e ter os
comentários do próprio autor explicando os campos:

```lua
-- outfit name
UnderwearDefinition.FrillyBlack = {
	chanceToSpawn = 5, -- weighted chance, can exced 100
	gender = "female",
	top = {
		{name="Bra_Straps_FrillyBlack", chance=50},
		{name="Bra_Strapless_FrillyBlack", chance=50},
		{name="Corset_Black", chance=5},
	},
	bottom = "FrillyUnderpants_Black",
}
```

O arquivo mais comentado da pasta é `AttachedWeaponDefinitions.lua:11-17`, que documenta campo a
campo (`chance`, `weaponLocation`, `bloodLocations`, `addHoles`, `daySurvived`, `weapons`) no próprio
código. `weaponLocation` aponta para `PZ/media/lua/shared/NPCs/AttachedLocations.lua`, citado no
comentário da linha 13 — **é lá que estão os nomes válidos**, não neste arquivo.

**Mas o bloco comentado não é o contrato completo — e tratá-lo como tal falha em silêncio.** Ele
documenta 6 campos; o arquivo usa pelo menos dois que não estão lá, sobre 142 definições:

| Campo | Definições que usam | O que faz |
|---|---|---|
| `outfit` | **62** | escopa a definição a uma lista de trajes; sem ele, ela não fica presa a traje nenhum |
| `id` | **57** | identificador próprio, repetindo o nome da chave |

**`weaponLocation` e `bloodLocations` parecem aceitar a mesma coisa e não aceitam.** São dois
espaços de nome distintos: `bloodLocations` usa **parte do corpo** (`"Back"`, `"Torso_Lower"`),
`weaponLocation` usa **ponto de fixação** de `AttachedLocations.lua` (`"Axe Back"`,
`"Big Weapon On Back"`, `"Rifle On Back with Bag"`). `"Back"` é válido no primeiro e **não existe**
no segundo. Escrever `weaponLocation = {"Back"}` é aceito pelo Lua, não gera linha de log e a arma
simplesmente nunca aparece — verificado em 2026-08-12 com 1000+ zumbis e zero avistamentos.

**Zumbi com mochila usa outro ponto de fixação.** As locations de costas vêm em pares — `"Pan On
Back"`/`"Pan On Back with Bag"`, `"Rifle On Back"`/`"Rifle On Back with Bag"`. Para o survivalista,
que carrega mochila, o próprio jogo desistiu do par óbvio: em `meleeInBackBag_Late`
(`AttachedWeaponDefinitions.lua:1457`) a linha `"Big Weapon On Back with Bag"` está **comentada**
(`:1462`) e a ativa é `"Rifle On Back with Bag"` (`:1463`).

**`bloodLocations = nil` + `addHoles = false` é a semântica de arma *carregada*** — 67 definições.
Sangue e furo são de arma **cravada** no corpo (`spearStomach`). Pôr os dois numa arma que só está
pendurada nas costas fura o zumbi sem motivo.

**`daySurvived` é o campo que dá progressão temporal**: `spearStomach` exige 30 dias e
`spearStomach_Special` exige 60 (`AttachedWeaponDefinitions.lua:15` e `:45`). É o mecanismo pelo qual
arma improvisada — `SpearCrafted`, `SpearCrude`, `SpearCraftedFireHardened` — só aparece depois de
tempo suficiente para alguém tê-la fabricado.

**Não é o único mecanismo de era, e os dois não se somam.** Quando a definição é escopada por
`outfit` a um traje que já carrega a era no nome (`Survivalist_Late`), a progressão vem daí e o
campo fica em zero: toda a família `meleeInBackBag_*` usa `daySurvived = 0`
(`AttachedWeaponDefinitions.lua:1466`). Exigir dias **e** traje tardio na mesma definição é gate
redundante — e o `daySurvived` alto some sem sintoma dentro do teste, porque o mundo de teste
raramente chega lá.

### A camada acima das definições: `attachedWeaponCustomOutfit`

**Para 48 trajes, o pool não é a lista geral de definições.** `AttachedWeaponDefinitions` tem uma
sub-tabela declarada em `:2266`:

```lua
AttachedWeaponDefinitions.attachedWeaponCustomOutfit = {};
```

Cada entrada é **keyed por nome de traje** e tem forma própria, diferente da de uma definição
(`:2536-2551`):

```lua
AttachedWeaponDefinitions.attachedWeaponCustomOutfit.Survivalist = {
	chance = 50;
	maxitem = 3;
	weapons = {
		AttachedWeaponDefinitions.meleeInBackBag,
		AttachedWeaponDefinitions.survivalistBedroll,
		AttachedWeaponDefinitions.handgunHolster,
		…
	},
}
```

Três diferenças que mudam como um mod entra:

- **`weapons` aqui são referências a definições, não nomes de item.** Mesmo nome de campo, conteúdo
  de outro tipo.
- **`maxitem`** — o zumbi pode receber **vários** itens do traje. Nos survivalistas: 3 na era base,
  4 no `_Mid` (`:2555`), 5 no `_Late` (`:2572`). É o que faz um zumbi ter arma nas costas *e*
  coldre *e* cantil ao mesmo tempo.
- **`chance`** aqui é do traje (50, 50 e 60 nas três eras), não da definição.

**Definição que não está na lista do traje não concorre por esse caminho**, e `chance` própria não
muda isso — verificado in-game em 2026-08-12: uma definição de mod com `chance = 10000` e `outfit`
escopado aos survivalistas rendeu 4 de 10, não os ~99% que a conta de peso relativo previa.

**As variantes 02–05 são alias da mesma tabela** (`:2587-2590`):
`attachedWeaponCustomOutfit.Survivalist02 = attachedWeaponCustomOutfit.Survivalist`. São 3 tabelas
para 15 trajes, então mutar uma alcança as cinco variantes daquela era — mesma economia de
`SurvivorItems` em [distribuicao-loot.md](distribuicao-loot.md).

**Dentro de `weapons` de uma definição, a escolha é uniforme e o peso é por repetição.** Não há
campo numérico: o `BaseballBat_Nails` aparece **duas vezes** na lista da `meleeInBackBag` da era
base. Repetir a entrada é o mecanismo de peso. Tamanhos das listas dessa família: 22 (base), 38
(`_Mid`), 38 (`_Late`).

**`ChanceOfAttachedWeapon` não governa esta camada.** Observado in-game em 2026-08-12: com a opção
em 100, todo zumbi comum nasce com arma **cravada** (tesoura, chave de fenda, garfo) — é isso que
ela controla. A arma *carregada* nas costas do traje continuou saindo pelo caminho acima. Bate com
a divisão `bloodLocations`/`addHoles` descrita antes, mas o elo é Java; ver "Pontos a confirmar".

**Duas entradas do jogo apontam para item que não existe.** `AttachedWeaponDefinitions.lua:52-53` e
`:1203-1204` listam `"Base.SpearBone"` e `"Base.SpearBone_Long"`, mas os itens reais são
`Spear_Bone` (`PZ/media/scripts/generated/items/weapon.txt:15425`) e `Spear_BoneLong` (`:15476`) — o
sublinhado está no lugar errado nos dois nomes. Grepar `item SpearBone` em `generated/items/` devolve
zero. As duas lanças de osso, portanto, **nunca nascem espetadas num zumbi**. As mesmas duas linhas
aparecem uma terceira vez já comentadas (`:1512-1513`). Vale como aviso geral: **nome de item em
tabela Lua não é validado na carga** — nem no arquivo do jogo.

## Como um mod acrescenta entrada

O idioma provado em `STEAM/` é `require` do arquivo do jogo na primeira linha, e escrita na global
depois. Exemplo real: `STEAM/2392709985/mods/tsarslib/media/lua/shared/Definitions/CommonLibrary_ContainerButtonIcons.lua:1-4`

```lua
require "Definitions/ContainerButtonIcons"

ContainerButtonIcons = ContainerButtonIcons or {}
ContainerButtonIcons.ATARoofTent = getTexture("media/ui/commonlibrary/Container_ATARoofTent.png")
```

Três coisas nesse trecho, e todas contam:

1. **`require "Definitions/<Arquivo>"`** — caminho relativo à raiz de `media/lua/`, sem extensão. É o
   que garante que o arquivo do jogo rodou **antes**. Contra os 3 arquivos que declaram `X = {}` cru,
   é a única forma de a entrada do mod sobreviver.
2. **Repetir `X = X or {}`** no mod — protege se o `require` falhar ou se a ordem mudar.
3. **Nome de arquivo próprio** (`CommonLibrary_ContainerButtonIcons.lua`, não
   `ContainerButtonIcons.lua`). Arquivo com o mesmo nome do original está em cima de terreno não
   verificado aqui — ver "Pontos a confirmar".

**Quanto disso é usado de verdade**, censo por arquivo `.lua` em `STEAM/` (89 mods; o número conta
arquivos, e mods com várias pastas de versão — `42/`, `42.13/`, `42.15/` — contam mais de uma vez):

| Global | Arquivos de mod que mexem |
|---|---|
| `ContainerButtonIcons` | 60 |
| `FitnessExercises` | 27 |
| `MakeUpDefinitions` | 10 |
| `AttachedWeaponDefinitions` | 6 |
| `HairOutfitDefinitions` | 4 |
| `MapSymbolDefinitions` | 3 |
| as outras 7 | **0** |

Só **15 arquivos** de mod usam o `require` — 6 para `ContainerButtonIcons`, 4 para
`FitnessExercises`, 4 para `AttachedWeaponDefinitions`, 1 com erro de digitação (abaixo). Os outros
**54** que mexem em `ContainerButtonIcons` (60 no total, 6 com `require`) apostam na ordem de carga, e
sobrevivem porque essa global usa `or {}`.

Nem todo uso é escrita: os 27 de `FitnessExercises` incluem leitura, como
`STEAM/2940354599/mods/FWO Fitness Workout Overhaul/42/media/lua/client/FWOScript.lua:102`
(`for k,v in pairs(FitnessExercises.exercisesType)`).

## Os dois arquivos fora do padrão

### `MapSymbolDefinitions` — a global vem do Java

É o único dos 13 que **não declara nada**. A primeira linha do arquivo já chama a API
(`MapSymbolDefinitions.lua:1`):

```lua
MapSymbolDefinitions.getInstance():addTexture("ArrowEast", "media/ui/LootableMaps/map_arroweast.png", "Locations")
```

`MapSymbolDefinitions` não é atribuída em Lua nenhum do jogo (`grep -rn "MapSymbolDefinitions *="
PZ/media/lua/` volta vazio) — o objeto já existe quando o arquivo roda, então é exposto pelo Java.
Consequência prática: **não dá para "somar à tabela"** como nos outros; o mod chama o mesmo método.

Métodos observados em uso, todos em
`PZ/media/lua/client/ISUI/Maps/ISWorldMapSymbols.lua` — `getSymbolById` (`:384`, `:1151`, `:1195`,
`:1524`), `getSymbolCount` (`:1452`), `getSymbolByIndex` (`:1454`) — mais `addTexture` no próprio
arquivo de definições. **Uso observado, não assinatura declarada** (ver "Pontos a confirmar").

### `DamageModelDefinitions` — o único que registra evento

Os outros 12 só declaram dados. Este traz lógica e se pendura num evento, na última linha do arquivo
(`DamageModelDefinitions.lua:69`):

```lua
Events.OnHitZombie.Add(DamageModelDefinitions.OnHitZombie);
```

E é o único com função de API para registrar entrada em vez de escrita direta —
`DamageModelDefinitions.addDefinition(texture, bodyPart, damageCategories, criticalHit)`
(`:5`, chamada nas linhas 14-21). Um mod que queira somar textura de dano usa essa função, não
`table.insert` na `.list`. As outras três funções (`OnHitZombie` `:24`, `checkCategory` `:50`,
`checkCrit` `:59`) são a implementação. Sobre o padrão de registro em `Events.*`, ver
[eventos-lua.md](eventos-lua.md).

## O validador que só roda com `-debug`

`ClothingSelectionDefinitions` e `TraitClothingSelectionDefinitions` têm um validador que percorre
as duas tabelas e chama `error()` em entrada malformada —
`CharacterCreationMain:debugClothingDefinitions()`
(`PZ/media/lua/client/OptionScreens/CharacterCreationMain.lua:1267-1301`). Ele checa três coisas:
`Female`/`Male` como únicas chaves de gênero (`:1273`, `:1291`), `BodyLocation` existente (`:1277`,
`:1295`) e `ItemType` existente via `ScriptManager.instance:FindItem` (`:1281`, `:1299`).

O gate está fora da função, em `CharacterCreationMain:initClothing()` (`:1330-1332`):

```lua
function CharacterCreationMain:initClothing()
	if getDebug() then
		self:debugClothingDefinitions()
	end
```

Ou seja: **sem `-debug` a entrada errada é ignorada em silêncio; com `-debug` ela estoura em
`error()`**. Para essas duas tabelas, subir o jogo em modo debug é o teste — é o validador mais
explícito que a pasta tem. Modo debug em [testar-e-debugar.md](testar-e-debugar.md).

Os consumidores de produção de `ClothingSelectionDefinitions` são outros — `:1337`, `:1344`, `:1854`,
`:1861` no mesmo arquivo (`.default` e a chave por nome de profissão); os de
`TraitClothingSelectionDefinitions` estão em `:1366-1367` e `:1879-1880`.

## Armadilhas

- **`require` com o nome errado não é pego por ninguém.** Em
  `STEAM/3262863785/mods/Perts Party Tiles/media/lua/shared/Definitions/ContainerButtonIconsPert.lua:1`
  está `require "Definitions/ContainerButtonsIcons"` — `Buttons` no plural. Não existe arquivo com
  esse nome em `PZ/media/` nem no próprio mod (`find . -iname "*ContainerButtons*"` volta vazio). É
  um mod publicado e a divergência está lá. O efeito exato do `require` de arquivo inexistente não
  foi testado aqui — ver "Pontos a confirmar".
- **Escrever na raiz quando a entrada mora em subtabela** (`FitnessExercises` em vez de
  `FitnessExercises.exercisesType`) não dá erro e não faz nada.
- **`DefaultClothing` não usa `ItemType`.** O comentário da linha 3 avisa:
  `-- These are the names of clothing xml files, not item types.` A pilha de roupa está em
  [roupa.md](roupa.md).
- **`HairOutfitDefinitions` não tem a última palavra sobre cabelo.** O comentário do arquivo
  (`:36`) diz que `ZombiesZoneDefinitions` tem precedência; o arquivo real é
  `PZ/media/lua/shared/NPCs/ZombiesZoneDefinition.lua` (singular, ao contrário do comentário).
- **`AttachedWeaponDefinitions.chanceOfAttachedWeapon` saiu do arquivo.** Está comentado na linha 8
  com a nota `-- This is now defined in the Zombie Sandbox settings`. Copiar exemplo de B41 que
  define esse campo aqui não tem efeito. **Onde ele foi parar:** `ChanceOfAttachedWeapon = 6`, no
  grupo `ZombieLore` (que abre em `:194`) dos quatro presets —
  `PZ/media/lua/shared/Sandbox/Apocalypse.lua:218`, e a mesma linha em `Extinction.lua`,
  `Outbreak.lua` e `Rising.lua`. A leitura em Lua é `SandboxVars.ZombieLore.ChanceOfAttachedWeapon`;
  o rótulo é `Sandbox_ChanceOfAttachedWeapon`, "Chance de Arma Presa ao Corpo"
  (`PZ/media/lua/shared/Translate/PTBR/Sandbox.json:953`). É gate **global**: reprova antes de
  qualquer definição ser sorteada, então mod nenhum contorna.

## Pontos a confirmar

- **Como a rota `attachedWeaponCustomOutfit` e a lista geral de definições convivem.** As duas
  estão ativas ao mesmo tempo: a definição de mod que **não** estava na lista do traje ainda assim
  saiu em 4 de 10 zumbis no teste de 2026-08-12, então a lista geral não é ignorada quando o traje
  tem entrada própria. O que decide a proporção entre as duas rotas, e se `chance` da definição
  vale alguma coisa nesse caso, não foi determinado — `addRandomAttachedWeapon()` é Java.
- **Se `ChanceOfAttachedWeapon` gateia só a arma cravada.** A observação in-game de 2026-08-12
  aponta para isso (opção em 100 encheu os zumbis comuns de tesoura e chave de fenda, sem mexer na
  arma de costas do traje), e é coerente com a divisão `bloodLocations`/`addHoles`. Mas é inferência
  de comportamento, não contrato lido: nada no `media/` liga a opção a um dos dois casos.
- **Quem lê no Java as 5 globais sem consumidor Lua e sem comentário** — `DefaultClothing`,
  `HairOutfitDefinitions`, `SmashedCarDefinitions`, `UnderwearDefinition` e a `.list` de
  `DamageModelDefinitions` fora do próprio evento. Só `AttachedWeaponDefinitions` nomeia o consumidor
  (`IsoZombie.addRandomAttachedWeapon()`, no comentário da linha 3), e nem essa foi verificada no
  `.jar` — o `.jar` não é lido aqui.
- **Assinatura de `MapSymbolDefinitions`.** `getInstance()`, `addTexture(name, path, category)`,
  `getSymbolById`, `getSymbolByIndex`, `getSymbolCount` são **uso observado** em
  `ISWorldMapSymbols.lua` e no arquivo de definições, não contrato declarado. O PZ-API-Docs
  (`pz-wiki-modding.github.io/PZ-API-Docs/java.html`, consultado 2026-08-08, 42.20.2) **não
  documenta a classe** — a seção `java` de lá cobre só ActionSoundTime, Colors, Item Tags, Magazine
  Subject, Metabolics e ItemBodyLocation. Nenhuma das 13 globais desta página aparece lá.
- **Ordem de carga entre o `.lua` do jogo e o do mod**, quando não há `require`. Os 54 arquivos de
  mod que mexem em `ContainerButtonIcons` sem `require` funcionam na prática, mas a regra que
  determina a ordem não foi levantada — nem se ela muda com `require=` no `mod.info`. Ver
  [carregamento-de-mods.md](carregamento-de-mods.md).
- **Arquivo de mod com o mesmo nome do original** (`ContainerButtonIcons.lua` em vez de um nome
  próprio): não se sabe se substitui, se coexiste, ou se depende da ordem. Os 5 arquivos de mod que
  ficam em `shared/Definitions/` usam prefixo próprio, então não há caso testável em `STEAM/`.
- **Efeito do `require` de arquivo inexistente** (o caso `ContainerButtonsIcons` acima): se estoura,
  se só loga, e se o resto do arquivo do mod continua rodando. É teste in-game com leitura de
  `USER/console.txt`, não grep.
- **Se `X = X or {}` de fato basta contra os 3 arquivos que declaram `X = {}` cru** —
  `ClothingRecipesDefinitions`, `DefaultClothing`, `FitnessExercises`. A leitura do código diz que
  não basta (o jogo zera a tabela se rodar depois), e nenhum mod de `STEAM/` escreve nessas três, o
  que é consistente com a hipótese, mas não a prova.

> Última verificação: 2026-08-08 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

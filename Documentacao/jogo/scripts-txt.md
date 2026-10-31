# Formato dos `.txt` de script (B42)

Sintaxe dos 1.004 arquivos de `PZ/media/scripts`. Não é Lua, não é JSON — é um formato próprio da
IndieStone, com parser rígido que **falha em silêncio** (o bloco simplesmente não existe no jogo) ou
derruba o carregamento do mod. Nunca invente campo; copie o exemplo canônico.

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\`,
`STEAM/` = `C:\Program Files (x86)\Steam\steamapps\workshop\content\108600\` (ver
[../index.md](../index.md)).

## O que mudou do B41 para o B42

Esta é a parte que invalida quase todo tutorial que se acha na internet.

| B41 | B42 |
|---|---|
| `recipe Make Stake { ... }` | `craftRecipe MakeStake { inputs { } outputs { } }` |
| `media/scripts/items.txt` monolítico | `generated/items/<ItemType>.txt`, um arquivo por tipo |
| `media/scripts/recipes.txt` | `generated/recipes/recipes_<tema>.txt`, 43 arquivos |
| `Type = Normal` no bloco `item` | `ItemType = base:normal` — namespace minúsculo |
| `TraitFactory.addTrait(...)` em Lua, no `OnGameBoot` | `character_trait_definition` em `.txt`; `TraitFactory` **sumiu** do `media/lua` |
| tradução em `.txt` | tradução em `.json` (ver [carregamento-de-mods.md](carregamento-de-mods.md)) |
| — | `entity` + `component` — bancadas, fornos, o sistema de estações do B42 |
| — | `xuiSkin` — aparência das janelas de entidade |

**O bloco `recipe` não existe mais.** Varredura em `PZ/media/scripts`: zero ocorrências de `recipe`
como palavra-chave de bloco. Quem escrever `recipe` num mod B42 está escrevendo sintaxe morta.

**O campo `Type` também morreu.** Varredura em `PZ/media/scripts`: **zero** ocorrências de `Type =`
em qualquer bloco — o jogo inteiro usa `ItemType`. Nos 89 mods de
`STEAM/`, só **um** ainda usa a forma antiga
(`3289531864/mods/MorePictures/media/scripts/MorePictures_Items.txt:12`). O PZ-API-Docs marca `Type`
como *deprecated, replacedBy `ItemType`*, a partir da versão 42.13.0 — a versão vem da fonte externa
([fontes-externas.md](../fontes-externas.md)); a ausência no código é levantamento local.

## Estrutura geral

```
module Base
{
    <tipoDeBloco> <Nome>
    {
        Campo = valor,
        Campo = valor,
    }
}
```

Regras que o parser cobra:

- **`module` é o namespace.** O nome do módulo vira prefixo do ID: `module Base { item SpadeHead }`
  produz `Base.SpadeHead`. Mods normalmente declaram `module Base` para somar ao módulo do jogo, ou
  um módulo próprio para isolar.
- **Cada campo termina em vírgula**, inclusive o último do bloco.
- **Blocos não levam vírgula** — `}` fecha e pronto.
- **Indentação é 4 espaços por nível** em todo o `media/` do jogo. Não é exigência conhecida do
  parser, mas é a convenção a seguir.
- **Lista dentro de um campo usa `;`**: `Tags = base:hasmetal;base:smeltableironmedium,`.
- **Referência a item é sempre `Modulo.Item`** (`Base.Plank`). Dentro do próprio módulo o prefixo
  pode ser omitido, mas o jogo qualifica sempre — faça o mesmo.
- **Comentário `/* ... */` é aceito** — visto em `PZ/media/scripts/xui/xui_config.txt:5`.

### Redeclarar em `module Base` sobrescreve o item do jogo

Um mod que declara um bloco `item` com o **mesmo nome** dentro de `module Base` está redefinindo o
item do jogo, não criando um novo. Observado em mod publicado e mantido:

O jogo tem exatamente **um** `item CandleLit` (`PZ/media/scripts/generated/items/drainable.txt:2167`).
O `B42Survival` declara um segundo em
`STEAM/3402516345/mods/B42Survival/common/media/scripts/generated/items/Items_Survival.txt:49`,
dentro de `module Base` (`:1`). O bloco dele é cópia campo a campo do vanilla — mesmos
`LightDistance`, `LightStrength`, `UseDelta`, `StaticModel`, `Tags`, `ReplaceOnExtinguish`,
`DoubleClickRecipe` — **mais duas linhas**: `primaryAnimMask = HoldingUmbrellaRight` e
`secondaryAnimMask = HoldingUmbrellaLeft`.

Ou seja: para acrescentar dois campos a um item do jogo, o autor reescreveu o item inteiro. **Não
existe sintaxe de "somar campo"** num bloco `item` — a granularidade é o bloco.

**É frágil, e os dois modos de falha são silenciosos:**

- **Dois mods que sobrescrevam o mesmo item colidem.** Qual vence não foi levantado (ver pendências).
- **Mudança da IndieStone no item vanilla é revertida** para quem tiver o mod ativo. A cópia
  congela o item na versão em que foi feita, e nada avisa quando o original muda.

É o argumento concreto a favor da prática oposta, já documentada adiante: **item de mod vai em módulo
próprio**, e só se toca `module Base` quando sobrescrever é o objetivo declarado.

## O registro de IDs — `media/registries.lua` `[novo 42.13]`

**Um mod não pode inventar identificador direto no `.txt`.** Desde 42.13, ID de namespace próprio
— tag de item, traço, profissão, `BodyLocation`, tipo de item — tem de ser **registrado em Lua
antes** de qualquer script ser lido. O arquivo tem nome fixo: **`media/registries.lua`**.

Isto é invisível no jogo base, e a página não cobria justamente por isso: **o jogo não registra nada
em Lua.** `find media -iname registries.lua` devolve **zero**, e não há uma só chamada
`<Registro>.register(` em `PZ/media/lua`. Os IDs do jogo vivem no Java. Quem prova o mecanismo são
os mods.

### Os 11 identificadores registráveis

Segundo o *Migration Guide* 42.13 da IndieStone (ver [../fontes-externas.md](../fontes-externas.md)):
`CharacterTrait`, `CharacterProfession`, **`ItemTag`**, `Brochure`, `Flier`, `ItemBodyLocation`,
`ItemType`, `MoodleType`, `WeaponCategory`, `Newspaper` e **`AmmoType`**.

**Os 11 do guia não são o conjunto completo do Java.** `zombie.scripting.objects.Registries` declara
**36** campos `Registry<…>` — um deles o meta-registro `REGISTRY`, e os outros 35:
`AMMO_TYPE`, `BOOK`, `BOOK_SUBJECT`, `BROCHURE`, `BUSINESS`, `CATALOGUE`, `CHARACTER_PROFESSION`,
`CHARACTER_TRAIT`, `COMIC_BOOK`, `DOODLE`, `DOODLE_KIDS`, `FLIER`, `GAME_MODE`, `LETTER`, `LOCKET`,
`TILE_PROPERTY_KEY`, `ITEM_BODY_LOCATION`, `ITEM_TAG`, `ITEM_TYPE`, `JOB`, `MAGAZINE`,
`MAGAZINE_SUBJECT`, `META_RECIPE`, `MOODLE_TYPE`, `NEWSPAPER`, `OLD_NEWSPAPER`, `PET_NAME`, `PHOTO`,
`POSTCARD`, `RPG_MANUAL`, `SEASON_RECIPE`, `SOUND_KEY`, `SURVIVAL_GUIDE_ENTRY`, `WEAPON_CATEGORY`,
`CONTAINER_TYPE`. Os dois desmontados até agora — `Letter` e `ItemTag` — expõem `register(String)`
**público e estático**, a mesma assinatura que os mods de `STEAM/` chamam.

**Isso é indício forte, não licença.** "Público no Java" ≠ "exposto ao Lua": o guia lista 11 e é o
único contrato declarado, e nenhum mod instalado registra fora dessa lista. Registrar, digamos, um
`Letter` novo é plausível e **não foi testado in-game** — ver "Pontos a confirmar".
`[levantado 2026-08-29]`

### O que está confirmado em mod real

**12 arquivos `registries.lua`**, em **10 mods** distribuídos por **8 uploads** de `STEAM/`
(recontado 2026-08-11 sobre 94 uploads instalados). As três contagens diferem e a distinção importa:
um upload carrega N mods (ver [carregamento-de-mods.md](carregamento-de-mods.md)), e um mod com
várias pastas de versão carrega o arquivo várias vezes — `More Traits` tem `42.13/`, `42.15/` e
`42.17/`, e o upload `2335368829` traz três mods (`Authentic Z - Current`, `- Lite`,
`- Backpacks+`), cada um com o seu.

O censo das chamadas:

| Chamada | Ocorrências | Confirmação |
|---|---|---|
| `CharacterTrait.register(` | 304 | `STEAM/3403870858/mods/Lifestyle/common/media/registries.lua` |
| `ItemBodyLocation.register(` | 25 | `STEAM/2335368829/mods/Authentic Z - Current/42/media/registries.lua:1` |
| `AmmoType.register(` | 12 | `STEAM/3775407541/mods/RadArchery/42/media/registries.lua:3-5` |
| `ItemTag.register(` | 11 | `STEAM/3414634809/mods/SpongieCharacterCustomisation/42.13/media/registries.lua` |

**Cuidado ao recontar: o censo de `STEAM/` não é protegido pelo carimbo de `buildid` do rodapé.** Ele
muda quando o usuário assina ou remove um mod, sem patch nenhum da Steam — ao contrário de tudo o
mais nesta árvore. Este bloco já nasceu defasado uma vez por isso (a contagem anterior, "9 mods",
era na verdade 9 *arquivos* sobre uma base de 89 uploads).

E use `find -print0 | xargs -0`: há mod cujo caminho tem espaço **e** colchete
(`STEAM/3776949545/mods/[SVRP] ClassicBows/`), o que quebra o word-splitting de `$(find ...)` em
silêncio e some com o mod da contagem.

**A função devolve o identificador**, e a prática é guardá-lo numa tabela para o Lua alcançar depois:

```lua
SPNCC = {}
SPNCC.ItemTag = {}
SPNCC.ItemTag.Face = ItemTag.register("SPNCC:Face")
SPNCC.ItemBodyLocation.Muscle = ItemBodyLocation.register("SPNCC:Muscle")
```

(`SpongieCharacterCustomisation/42.13/media/registries.lua`.) O `Lifestyle` faz o mesmo por cima da
tabela global: `ItemTag['LSInvention'] = ItemTag.register("Lifestyle:LSInvention")`. Registrar
ignorando o retorno também aparece — `ItemBodyLocation.register("AZ:HeadExtra")` no Authentic Z.

**O namespace preserva a caixa.** Os quatro em uso real são `SPNCC:`, `Lifestyle:`, `AZ:` e
`damnlib:` — não há normalização para minúsculo como no `base:` do jogo.

### `AmmoType` — dois argumentos, e registrar **não basta**

`AmmoType.register` é o único da lista com aridade 2, e o segundo argumento é um **item**:

```lua
AmmoType.register("radarchery:carved_arrow", "Base.CarvedArrow")
```

(`STEAM/3775407541/mods/RadArchery/42/media/registries.lua:3`.) O primeiro é o identificador
namespaced que os `.txt` vão citar em `AmmoType =`; o segundo é o item de munição solta. Mesma forma
nos três mods que usam — `ArcheryNexus/42.16/media/registries.lua:4` e
`[SVRP] ClassicBows/42/media/registries.lua:4-13`. O comentário do RadArchery (`:2`) afirma que o
namespace `base:` é **bloqueado** para tipo de mod, o que é coerente com a regra já observada de
`ItemTag`.

**A armadilha:** registrar em `registries.lua` não faz o `AmmoType` funcionar ao disparar. **Algum
item script tem de declarar o tipo estaticamente**, senão o primeiro tiro derruba o jogo. Dois mods
independentes convergiram na mesma solução — um item **registrador inerte**, que existe só para o
parser enxergar o tipo:

- `STEAM/3775407541/mods/RadArchery/42/media/scripts/ammo/RadArcheryTracerRegistrars.txt` — três
  itens `RadArcheryTracerRegistrar*` em `module Base`, nunca lootáveis nem craftáveis.
- `STEAM/3776949545/mods/[SVRP] ClassicBows/42/media/scripts/SimpleBows_Items.txt:1486` e `:1495` —
  `item SVRP_CB_arrow_dummy` / `SVRP_CB_bolt_dummy`. E **todos** os 10 arcos e bestas do mod
  declaram `AmmoType = svrpcb:SVRP_CB_arrow_dummy`, não o tipo real da flecha.

As três regras do item registrador, idênticas nos dois:

| Regra | Motivo declarado pelos autores |
|---|---|
| `Type = Normal`, **nunca** `Weapon` | um `Weapon` sem `WeaponSprite` estoura no `ModelManager` ao ser equipado |
| `DisplayCategory = Ammo` | `getLootCategory` e `ItemPickerJava` retornam cedo nessa categoria, então o item não perturba a classificação de loot |
| **nunca** `Tags = base:fake_weapon` | é a condição exata que o motor usa para *pular* o registro — a tag restaura o bug |

O padrão vale para qualquer arma de projétil de mod, não só arco: o `AmmoType` que só existe em
`registries.lua` ou que é ligado em runtime por Lua chega ao disparo sem config.

### Quem registra é quem é dono do namespace

O ID é registrado **uma vez**, pelo mod dono, e os outros declaram dependência. As 6 tags `SPNCC:`
saem de um `registries.lua` só, e os três mods que as usam nos `.txt` **não** têm `registries.lua`
próprio — todos declaram `require=\SPNCC` no `mod.info`:

| Mod | `id=` | `require=` | Tem `registries.lua`? |
|---|---|---|---|
| `SpongieCharacterCustomisation/42.13` | `SPNCC` | — | **sim** (registra as 6) |
| `SpongieCharacterCustomisation - Details Pack/42.13` | `SPNCCDetails` | `\SPNCC` | não |
| `SpongieCharacterCustomisation - Vanilla Faces Pack/42.13` | `SPNCCFaces` | `\SPNCC` | não |
| `Tomb's Player Body - Customisation/42.13` | `TombBodyCustom` | `\SPNCC` | não |

### Onde o arquivo mora, num mod com pasta de versão

O guia diz "the media folder", o que num mod B42 é ambíguo. Nos 12 arquivos reais:

- **`<versao>/media/registries.lua`** — 11 (`42/`, `42.13/`, `42.15/`, `42.16/`, `42.17/`)
- **`common/media/registries.lua`** — 1 (`Lifestyle`)

Ou seja, os dois lugares funcionam ou pelo menos convivem; a pasta de versão é a prática dominante.

### O contraexemplo que ensina

`damnlib` (`STEAM/3260996595/mods/damnlib`) usa `damnlib:` em `Tags` **sem `registries.lua` nenhum**
— e o mod não tem pasta de versão nem `versionMin` no `mod.info`, ou seja, é layout pré-B42. **Não é
evidência de que tag sem registro funcione**; é evidência de mod legado. Vale a regra geral desta
árvore: copie o jogo, não o mod.

## Censo de blocos

Todos os tipos de bloco de 2º nível que existem hoje em `media/scripts`, por frequência. Censo
reproduzível — não confie em memória nem em amostragem:

```
rg -o --no-filename '^    [a-zA-Z_]+' . | sed 's/^ *//' | sort | uniq -c | sort -rn
```

| Bloco | Ocorrências | Onde vive |
|---|---|---|
| `item` | 5.105 | `generated/items/` — **e em nenhum outro lugar** |
| `model` | 3.835 | `generated/models_*.txt` e `generated/vehicles/*_model.txt` — ver [arte-e-modelos.md](arte-e-modelos.md) |
| `sound` | 3.038 | `generated/sounds/` |
| `craftRecipe` | 969 | `generated/recipes/` |
| `xuiSkin` | 254 | `entities/`, `xui/` |
| `vehicle` | 241 | `generated/vehicles/` |
| `entity` | 239 | `generated/entities/` |
| `timedAction` | 119 | `generated/timedactions.txt` |
| `character_trait_definition` | 97 | `generated/characters/character_traits.txt` |
| `physicsShape` | 90 | `generated/models_isoobject_physicsShape.txt` |
| `template` | 77 | `generated/vehicles/` — só veículo |
| `animationsMesh` | 75 | |
| `ragdoll` | 66 | `ragdolls/` |
| `evolvedrecipe` | 63 | `generated/evolvedrecipes.txt` |
| `fluid` | 61 | `generated/fluids*.txt` |
| `mannequin` | 30 | |
| `fixing` | 29 | `generated/fixing.txt` |
| `character_profession_definition` | 25 | `generated/characters/character_professions.txt` |
| `physicsHitReaction` | 10 | |
| `clock` | 8 | `generated/clocks.txt` |
| `energy` | 7 | `generated/energies.txt` |
| `soundTimeline` | 5 | |
| `vehicleEngineRPM` | 4 | |
| `animation` | 2 | |
| `xuiConfig` | 1 | `xui/xui_config.txt` |

## `item`

Bloco canônico — `PZ/media/scripts/generated/items/weapon.txt:3`:

```
module Base
{
    item SpadeHead
    {
        DisplayCategory = JunkWeapon,
        ItemType = base:weapon,
        Weight = 1.0,
        Icon = ShovelHead_Forged,
        BaseSpeed = 1.2,
        Categories = base:blunt,
        ConditionMax = 10,
        DamageCategory = Slash,
        MaxDamage = 0.8,
        MinDamage = 0.4,
        MaxRange = 1.1,
        MinRange = 0.61,
        SwingAnim = Bat,
        SubCategory = Swinging,
        WeaponSpritesByIndex = SpadeHead2,
        Tags = base:hasmetal;base:smeltableironmedium,
        Researchablerecipes = MakeSpadeHeadCudgel;Forge_Spade_Head;Forge_Gardening_Trowel,
    }
}
```

Pontos de contrato:

- **`ItemType` é o campo que define o tipo** e usa namespace minúsculo: `base:weapon`, `base:food`.
  São **15 valores**, e o casamento com `generated/items/` é exato nos dois sentidos: cada valor tem
  arquivo homônimo, cada arquivo tem valor correspondente, sem sobra de nenhum lado. Os **5.105**
  blocos `item` do jogo declaram o campo — **nenhum** o omite, o que na prática o torna obrigatório
  (o PZ-API-Docs também o marca `required`). Ordem alfabética: `base:alarmclock`,
  `base:alarmclockclothing`, `base:animal`, `base:clothing`, `base:container`, `base:drainable`,
  `base:food`, `base:key`, `base:literature`, `base:map`, `base:moveable`, `base:normal`,
  `base:radio`, `base:weapon`, `base:weaponpart`.
- **`Tags`** é como o B42 amarra item a receita. Uma receita pede `tags[base:sharpknife]` em vez de
  listar itens. Tags são minúsculas com namespace (`base:hasmetal`).
- **`Categories`** (arma) e **`DisplayCategory`** (UI) são coisas diferentes: a primeira é mecânica,
  a segunda é a aba que o jogador vê.
- **`Icon`** aponta para uma textura em `media/textures/` sem extensão e sem o prefixo `Item_`
  (o jogo procura `Item_<Icon>.png`).
- **`Researchablerecipes`** — note o `r` minúsculo no meio. O parser é sensível a caixa.
- **`DisplayName` não existe em bloco `item` do jogo, e foi *removido* do bloco em 42.13.** Zero
  ocorrências em `PZ/media/scripts/generated/items/` (reconferido 2026-08-10) — o nome do item vem
  sempre de `ItemName.json`. O campo continua existindo em `media/scripts`, mas em **outros** blocos:
  `xuiSkin` (183 arquivos), `entity` (a maior concentração — 66 arquivos em `scripts/entities/walls`,
  52 em `entities/furniture`, 23 em `entities/outdoors`), `energy` e `fluid`
  (`PZ/media/scripts/generated/energies.txt`, `fluids.txt`). Ver as seções desses blocos nesta página.

  **[mudou 42.13: `DisplayName` saiu do bloco `item`]** O *Migration Guide* oficial da IndieStone diz,
  textualmente: *"Item Script: DisplayName has been removed. Now translation is taken only from
  `Module.ItemId`."* Ver [../fontes-externas.md](../fontes-externas.md).

  **Esta página afirmava o contrário até 2026-08-10** — que o campo funcionava como fallback para
  mod. A evidência daquela afirmação era o teste in-game de 2026-08-07: com a tradução do
  `WS/SiddigoWeapons` inerte, o item apareceu como "Skull Crusher". **A inferência estava errada por
  não ter concorrente considerado**: o `id` do item é `SkullCrusher`, e "Skull Crusher" é exatamente
  o que um fallback que separa `CamelCase` produziria. As duas explicações davam a mesma tela, e o
  teste não distinguia entre elas.

  O censo do uso em mod reforça a remoção: dos arquivos `.txt` de `STEAM/` com `DisplayName`,
  **286 estão em mod de layout B41** (sem pasta de versão) contra **19 em pasta de versão B42** — e
  destes, um só é de mod com `versionMin` ≥ 42.13 (`66pontiacLeMans/42.13`, `versionMin=42.13.0`),
  o que é compatível com resíduo de cópia, não com uso deliberado.

  **Consequência prática para mod:** não use `DisplayName` em `item`. Um item sem entrada em
  `ItemName.json` fica dependendo de um fallback cujo formato não está confirmado. O que decide o
  nome é a chave `Modulo.ItemId` no `.json` — ver
  [carregamento-de-mods.md](carregamento-de-mods.md).

**A caixa dos campos de `item`, medida.** O parser descarta campo com caixa errada **sem emitir
linha no `console.txt`** — o item carrega com o default do motor. Censo em `generated/items/`:

| O jogo escreve | Ocorrências | Forma "lógica" que não existe | Ocorrências |
|---|---|---|---|
| `Swingtime` | 409 | `SwingTime` | **0** |
| `MaxHitcount` | 409 | `MaxHitCount` | **0** |
| `Researchablerecipes` | 955 | `ResearchableRecipes` | **0** |

Os três erram no mesmo ponto: a segunda palavra do nome composto é minúscula. Na dúvida, copie a
caixa do arquivo do jogo — nunca a de um mod.

Comida — `PZ/media/scripts/generated/items/food.txt:3`: mesma forma, campos próprios
(`Calories`, `Carbohydrates`, `Lipids`, `Proteins`, `DaysFresh`, `DaysTotallyRotten`, `HungerChange`,
`ReplaceOnUse`, `StaticModel`, `WorldStaticModel`).

### Fonte de luz — a família de campos e o par apagado/aceso

Canônico: `item Torch` (`PZ/media/scripts/generated/items/drainable.txt:1058`).

| Campo | O que faz |
|---|---|
| `ActivatedItem` | o item liga/desliga por ação do jogador. É `false` no que já nasce aceso (`CandleLit`, `drainable.txt:2173`) |
| `LightDistance` / `LightStrength` | alcance e intensidade |
| `TorchCone` / `TorchDot` | facho cônico (lanterna, `TorchCone = true`) vs. luz radial (vela, `false`); `TorchDot` é a abertura do cone |
| `UseDelta` | consumo por tick — é o que faz bateria/cera acabarem |
| `UseWhileEquipped` / `UseWhileUnequipped` | se gasta só na mão ou também guardado |
| `KeepOnDeplete` | o item continua existindo com 0 usos em vez de sumir |
| `ReplaceOnExtinguish` | em que item se transforma quando **o jogador apaga** (`Base.Candle`, `drainable.txt:2183`) — 6 ocorrências |
| `ReplaceOnDeplete` | em que item se transforma quando **o combustível acaba sozinho** (`Base.CeramicCrucible`, `drainable.txt:21`) — 42 ocorrências |
| `DoubleClickRecipe` | receita disparada por duplo clique no inventário |
| `cantBeConsolided` | não empilha com outro igual — note a grafia, `i` onde se esperaria `a` |

**`ReplaceOnDeplete` e `ReplaceOnExtinguish` são dois finais diferentes, não sinônimos** — e o menos
conhecido é o mais usado, 7× mais. Eles **coexistem no mesmo item**, apontando para itens distintos:
`item TorchLit` de `STEAM/3402516345/mods/B42Survival/common/media/scripts/generated/items/Items_Survival.txt:254`
declara `ReplaceOnDeplete = Base.Branch_Broken` (queimou até o fim, sobra o graveto) e
`ReplaceOnExtinguish = Base.TorchBurnt` (você apagou, sobra a tocha usada, re-acendível). Quem
declara só `ReplaceOnExtinguish` deixa o caso "acabou sozinho" no default do motor.

Dois valores da família que não são óbvios por grep de nome:

- **`DisplayCategory = FireSource`** existe e é distinto de `LightSource` (`drainable.txt:714`,
  `:738`, `:785`). O B42Survival usa `LightSource` na tocha apagada e `FireSource` na acesa.
- **`Tags = base:litlantern`** (`drainable.txt:1142`) e o par **`base:unlitlantern`** (`:1163`)
  classificam lampião por estado, ao lado de `base:startfire`.

**`Base.Torch` não é tocha de fogo — é lanterna.** `PZ/media/lua/shared/Translate/EN/ItemName.json:4460`
traduz para "Flashlight - Heavy Duty", e `Base.HandTorch` (`:1855`) para "Flashlight". **Não existe
tocha acesa no jogo base**, o que libera o nome para mod.

**Feixe (pacote que se desfaz com duplo clique) tem dois moldes.** `[levantado 2026-10-31]`

- **Uma receita por tipo**: `LogStacks2/3/4` (`PZ/media/scripts/generated/items/normal.txt:9309-9340`)
  com `MakeTwoLogStack`…`UnbundleFirewood` (`PZ/media/scripts/generated/recipes/recipes_carpentry.txt:135-273`),
  montando com `tags[base:rope]`; a corda **não volta** ao desfazer. O `OnCreate =
  RecipeCodeOnCreate.createLogStack`/`splitLogStack` é Java (zero ocorrência em `media/lua`).
- **Uma receita para N tipos**: `stack_items`/`unstack_items`
  (`PZ/media/scripts/generated/recipes/recipes_packing.txt:762-810`), com `itemMapper` ligando
  unidade a pacote; os itens apontam `DoubleClickRecipe = unstack_items` (`normal.txt:9390`).

O peso do pacote não segue regra: `LogStacks` pesa 1/3 da soma das toras, `TwigsBundle` (`:9381`)
~83% da soma dos gravetos.

**O par apagado/aceso é o padrão canônico, e são dois itens, não um.** `item Candle`
(`drainable.txt:2153`) declara `DoubleClickRecipe = LightCandle`; `item CandleLit` (`:2167`) declara
`DoubleClickRecipe = ExtinguishCandle` e `ReplaceOnExtinguish = Base.Candle`. As duas receitas ficam
em `PZ/media/scripts/generated/recipes/recipes_lightsources.txt:3` e `:21`. O estado do item
atravessa a troca pelos flags da entrada:

```
inputs
{
    item 1 [Base.Candle] mode:destroy flags[InheritUses;InheritCondition;ItemCount;AllowFavorite;InheritFavorite],
    item 1 tags[base:startfire],
}
outputs
{
    item 1 Base.CandleLit flags[EquipSecondary;SetActivated],
}
```

`base:startfire` na entrada é o que exige um acendedor; `EquipSecondary`/`SetActivated` na saída são
o que põe o item aceso na mão secundária já ligado (as duas flags estão na tabela das 57, adiante).
Quando existem N variantes da mesma lâmpada, o par não vira 2N receitas: vira duas receitas com
`itemMapper` — `LightHurricaneLantern` (`recipes_lightsources.txt:71`) e `ExtinguishHurricaneLantern`
(`:98`), cada uma com seu bloco `itemMapper LampMapper` (`:87` e `:112`).

### Arma à distância — e os quatro tetos fechados

Canônico: `item Pistol` (`PZ/media/scripts/generated/items/weapon.txt:10996`). A família própria é
`Ranged`, `IsAimedFirearm`, `AmmoType`, `AmmoBox`, `MagazineType`, `MaxAmmo`, `ClipSize`,
`Projectilecount`, `WeaponReloadType`, `Aimingtime`, `MinSightRange`/`MaxSightRange`, `HitChance`,
`StopPower`, `JamGunChance`, `RecoilDelay`, `MuzzleFlashModelKey`, `ModelWeaponPart`, mais
`SoundRadius`/`SoundVolume`/`SoundGain` — que é o que atrai zumbi, e portanto o campo que define se
a arma é silenciosa.

**Arma à distância sem pólvora (arco, besta, estilingue): cuidado com o par `NoMuzzleFlash`.** Quem
copia um mod de arco herda duas linhas que o jogo nunca escreve:

```
NoMuzzleFlash = TRUE,
MuzzleFlashModelKey = ,
```

**`NoMuzzleFlash` tem zero ocorrências em `PZ/media/scripts`**, e `MuzzleFlashModelKey` nunca aparece
ali com valor vazio — as 22 ocorrências do jogo apontam todas para um modelo real
(`PZ/media/scripts/generated/items/weapon.txt:10610`). Em `STEAM/` o par sai de **um único mod**,
`[SVRP] ClassicBows` (11 ocorrências, `.../42/media/scripts/SimpleBows_Items.txt:211-212`), e o
bloco em volta desqualifica o exemplo como prova: ele declara `Type = Weapon` **e**
`ItemType = base:weapon` no mesmo `item` (`:210` e `:213`), ou seja, é migração B41→B42 com resíduo,
e as duas linhas ainda estão na indentação do arquivo antigo. Como o parser ignora campo
desconhecido em silêncio, elas sobreviveriam mesmo mortas.

Não confunda com silêncio de verdade: quem decide se a arma atrai zumbi é o trio
`SoundRadius`/`SoundVolume`/`SoundGain`, acima. Se o par acima faz algo, é só o efeito visual.
`WS/SiddigoWeapons` (`item Slingshot`) carrega as duas linhas pela mesma cópia — ver "Pontos a
confirmar".

**`AmmoType` é identificador registrado, não item** (`AmmoType = base:bullets_9mm`). A munição em si
é item comum: `item Bullets9mm` é `ItemType = base:normal` com `Tags = base:ammo` e `count = 5`
(`PZ/media/scripts/generated/items/normal.txt:13438`) — nenhum campo especial. Os campos irmãos é que
apontam para item de verdade: `AmmoBox = Base.Bullets9mmBox` e `MagazineType = Base.9mmClip`.

**Munição própria de mod exige registro** (ver a seção do registro de IDs, acima). É a única dos 11
chamadas de registro a receber um segundo argumento — e **as duas formas desse argumento não são
intercambiáveis nesta build**.

A forma do *Migration Guide*, confirmada no exemplo oficial da IndieStone vendorado neste repo (fora
de `STEAM/`): `Documentacao/oficial/testmod_registries` (**42.13**) traz o bloco literal em
`42/media/registries.lua:13-14`, e `item_key` aponta para `item bullets_666`
(`42/media/scripts/testmod/items.txt:172-183`, `module Base` do mesmo mod — munição comum, sem nada
de especial):

```lua
local item_key = ItemKey.new("bullets_666", ItemType.NORMAL)
AmmoType.register("testmod:duck_bullets", item_key)
```

Isso fecha as duas dúvidas que a página deixava em aberto sobre a forma: o 1º argumento de
`ItemKey.new` é o **id cru do item, sem módulo**, e `ItemType.NORMAL` é a grafia exata da constante.

**Correção (2026-08-16): essa forma derruba o jogo em 42.20.2.** A página afirmava que
`WS/SiddigoWeapons` tinha sido corrigido para bater com o exemplo oficial e que o resultado estava
sem teste in-game. O teste aconteceu, e o resultado é o oposto: ativar o mod com `ItemKey.new` mata
o carregamento do Lua no `registries.lua`
(`USER/Logs/logs_2026-08-15/2026-08-15_21-31_DebugLog.txt:190-207`):

```
expected argument of type String, got ItemKey.
	java.lang.RuntimeException: ... at MethodArguments.assertValid(MethodArguments.java:128)
	Lua((MOD:Survivor Weapons)).registries.lua(registries.lua:15)
```

O binding Java de `AmmoType.register` nesta build declara o 2º parâmetro como **String**, e
`MethodArguments.assertValid` rejeita o `ItemKey` antes de qualquer coisa acontecer. **A forma que
funciona é a string `"Modulo.Item"`** — `WS/SiddigoWeapons/Contents/mods/SiddigoWeapons/42/media/registries.lua:17`
(na branch `v2.0-novos-itens` do repo do mod, commit `933b631`; a `main` não tem `registries.lua`,
então o arquivo some do disco quando a `main` está em checkout — conferido 2026-10-27):

```lua
SiddigoWeapons.AmmoType.SlingAmmo = AmmoType.register("siddigoweapons:slingammo", "SiddigoWeapons.SlingStone")
```

O par de logs é o que fecha a prova: o run das 21:31 quebra com `ItemKey`, e o das 21:36 — cinco
minutos depois, já com a string — carrega o mod sem a rejeição
(`USER/Logs/logs_2026-08-15/2026-08-15_21-36_DebugLog.txt:183`).

O exemplo oficial é **42.13** e o install é **42.20.2**: ou a API mudou entre as duas, ou o exemplo
nunca valeu aqui. Não dá para separar as duas hipóteses sem o `.jar` de 42.13 — ver "Pontos a
confirmar". **A regra prática que sobra vale para todo o registro de IDs: copie o jogo instalado, não
o exemplo, quando os dois divergirem.** `STEAM/` não desempata neste caso — continua em zero
exemplos da forma `ItemKey.new`.

**O exemplo oficial também não usa item registrador** — `item BirdRifle`
(`Documentacao/oficial/testmod_registries/42/media/scripts/testmod/items.txt:45-137`) declara `AmmoType =
testmod:duck_bullets` direto no próprio bloco, sem nenhum item `Type = Normal` inerte ao lado. Isso
é o caso que o parágrafo acima ("o `AmmoType` que só existe em `registries.lua` ou que é ligado em
runtime por Lua chega ao disparo sem config") já previa como seguro: uma arma que declara `AmmoType`
fixo no próprio script, sem rebind, já alimenta o `Item.resolveItemTypes()` que popula o mapa de
tracer — o item registrador de `RadArchery`/`[SVRP] ClassicBows` é workaround para o caso deles
(munição trocada em runtime, nunca declarada em nenhum `.txt`), não parte do contrato geral.

Cuidado com a forma antiga: `Authentic Z` escreve `AmmoType = AuthenticZClothing.Flare12GaugeShot`
dentro de uma pasta `42/` — é a sintaxe **B41** (`Modulo.Item`), e não bate com nenhuma das 28
ocorrências do jogo, que são todas `base:algo`.

O que decide viabilidade aqui não são os campos, são **quatro enums fechados** — censo do
`media/scripts` inteiro, não de um arquivo:

| Campo | Valores que existem no jogo |
|---|---|
| `SubCategory` | **4**: `Swinging` (262), `Stab` (69), `Spear` (22), `Firearm` (22) |
| `SwingAnim` | **9**: `Bat` (214), `Stab` (69), `Heavy` (39), `Throw` (33), `Spear` (29), `Rifle` (11), `Handgun` (7), `Stone` (2), `Shove` (1) |
| `WeaponReloadType` | **8**: `boltaction` (4), `boltactionnomag` (4), `revolver` (4), `handgun` (3), `shotgun` (3), `leveraction` (2), `doublebarrelshotgun` (1), `doublebarrelshotgunsawn` (1) |
| `ItemType` | **15**, listados acima — não existe `base:ranged` |

**`Ranged = true` aparece 22 vezes, e são exatamente os 22 `SubCategory = Firearm`** (idem
`IsAimedFirearm = true`, 22). No B42, "à distância" e "arma de fogo" são o mesmo conjunto: **não
existe categoria de arco, besta ou estilingue**, e nenhuma animação de saque/disparo fora de `Rifle`
e `Handgun`. Arma de projétil não-pólvora em mod é, no `.txt`, uma arma de fogo travestida — a
aparência depende de animação própria em `anims_X/` + `AnimSets/` (ver [animacao.md](animacao.md)).

**`SwingAnim = Throw` não é sistema de arma de arremesso.** A contagem sugere isso e está errada: os
33 são explosivo e armadilha (`Aerosolbomb`, `FlameTrap`, `NoiseTrap`, `PipeBomb`, `SmokeBomb`, cada
um com variantes `Remote`/`SensorV1-3`/`Triggered`), mais `Molotov`, `Firecracker`,
`Firecracker_Crafted` e `Toothbrush_Shiv` — todos em `weapon.txt`. Não há machadinha de arremesso
nem faca de arremesso a copiar.

**`boltactionnomag` nunca vem com `ClipSize`, e sempre vem com `FireMode = Single`.** Censo dos 4
itens que usam esse `WeaponReloadType` em `weapon.txt` — `HuntingRifle` (`:10906`), `VarmintRifle`
(`:11663`), `Rifle_CapGun` (`:19132`) e `MSR7T_Rifle` (`:19566`): **nenhum** declara `ClipSize` nem
`MagazineType` — só `MaxAmmo` governa a capacidade — e **todos** declaram `FireMode = Single`. Isso
inverte o padrão do `item Pistol` citado acima, que é `ClipSize`+`MagazineType` (magazine-fed) e
**não** declara `FireMode`. Os quatro também declaram os campos
`AimingPerkCritModifier`/`AimingPerkHitChanceModifier`/`AimingPerkMinAngleModifier`/
`AimingPerkRangeModifier` — presentes em todo exemplo de arma à distância visto até aqui (`Pistol`,
`Pistol2`, os quatro `boltactionnomag`), nunca omitidos.

**[indício 2026-08-15]** `WS/SiddigoWeapons` publicou `item Slingshot` (`WeaponReloadType =
boltactionnomag`) misturando o padrão errado — `ClipSize = 1` presente, `FireMode` e os quatro
`AimingPerk*` ausentes — e testou in-game: o jogador reportou "não atira" e "não foca mira". Corrigido
para o padrão dos quatro itens vanilla (`ClipSize` removido, `FireMode = Single` e os quatro
`AimingPerk*` acrescentados). Como no achado da tocha acima, é correlação de uma sessão, não teste
isolado por campo — mas é o único padrão com `caminho:linha` vanilla a favor, contra um item que
não tinha nenhum precedente para a combinação que usava.

**Nem todo `boltactionnomag` vanilla tem ferrolho de verdade.** `Rifle_CapGun` — o rifle de espoleta
de brinquedo — declara `HaveChamber = false` (`PZ/media/scripts/generated/items/weapon.txt:19160`) e
`RackAfterShoot = false` (`:19189`) junto do `WeaponReloadType = boltactionnomag` (`:19212`). É o
análogo vanilla de **arma de tiro único sem carregador e sem rack**, que é o caso em que um mod de
estilingue/besta cai; os outros três `boltactionnomag` são rifle de ferrolho e usam
`RackAfterShoot = true`. Quem procura precedente para "carrega um projétil na mão" deve olhar o
`Rifle_CapGun`, não o `HuntingRifle`. `[levantado 2026-08-16]`

Censo de caixa dos três campos, em `media/scripts` inteiro: **`HaveChamber` 7, `haveChamber` 0** — a
grafia minúscula que aparece em mod da Workshop não tem respaldo vanilla; `RackAfterShoot` 11;
`InsertAllBulletsReload` **2**, só as duas espingardas de cano duplo (`weapon.txt:10770` e `:10855`)
— o `Rifle_CapGun` **não** declara. Valores vanilla são `false`/`true` minúsculo.

### Dois campos de fx de tiro que falham em silêncio

- **`NoMuzzleFlash` não existe.** Zero ocorrências em todo o `media/scripts`. É campo inventado que
  aparece em mod; o parser descarta sem log, então ele **não desliga muzzle flash nenhum**. Para não
  ter clarão, o caminho é não declarar `MuzzleFlashModelKey` — não declarar um campo negativo que o
  jogo nunca leu. `[levantado 2026-08-16]`
- **`MuzzleFlashModelKey` com valor vazio não tem precedente.** As 20 ocorrências vanilla têm valor
  real (`muzzle_flash_handgun`, `weapon.txt:11050`; `muzzle_flash_rifle_cap_gun`, `:19184`). Escrever
  `MuzzleFlashModelKey = ,` é forma sem exemplo no jogo — o efeito de uma chave de modelo vazia
  resolvida no instante do tiro **não foi levantado**; ver "Pontos a confirmar". O campo em si está
  descrito em [arte-e-modelos.md](arte-e-modelos.md).

### Transformar item pelo cozimento: `ReplaceOnCooked` `[levantado 2026-10-29]`

Comida com `IsCookable = true` + `MinutesToCook` + `ReplaceOnCooked = <fullType>` é **trocada** pelo
item indicado quando cozinha. Canônico: `Base.BreadSlices` → `Base.Toast`
(`PZ/media/scripts/generated/items/food.txt:2131-2133`). São só três usos no `media/scripts`
(`food.txt:2132`, `:2816`, `:10914`), todos apontando para `Base.*`, e nenhum em `media/lua`: a troca
é Java. Para queimar, o item resultante precisa ser cozinhável por conta própria: `Base.Toast` declara
`IsCookable = true`, `MinutesToCook = 0`, `MinutesToBurn = 20` (`food.txt:6407-6409`). Apontar para
item de outro módulo é "a confirmar".

### `OnCreate` do `item` — o namespace `ItemCodeOnCreate`

`[levantado 2026-08-29]` — `OnCreate = Arquivo.funcao` no bloco `item` aponta para **Java**, não
para Lua, ao contrário do `OnCreate` do `craftRecipe`, que resolve em
`PZ/media/lua/server/CraftRecipeCode/`.
`ItemCodeOnCreate` tem **zero** ocorrências em `PZ/media/lua` e **296** só em
`generated/items/literature.txt`; a classe é `zombie/scripting/logic/ItemCodeOnCreate`, com **72**
métodos, dentro de `PZ/projectzomboid.jar`.

**O `.jar` é legível nesta máquina.** Há um JDK completo em
`C:\Program Files\Eclipse Adoptium\jdk-21.0.5.11-hotspot\`, então
`javap -p -c -cp <dir> zombie.scripting.logic.ItemCodeOnCreate` desmonta qualquer classe do jogo
(o `jre64/` que acompanha o PZ **não** traz `javap` — extraia a `.class` do `.jar` primeiro). Isso
encolhe o que precisa virar "a confirmar": contrato que vive no Java deixa de ser inverificável.
Continua sendo **bytecode lido**, não assinatura publicada — cite a classe e o método, e nunca uma
linha do `media/` que não existe.

O vocabulário tem dois idiomas, e **nenhum dos dois escreve texto de página**:

1. **Sortear o nome do item.** O método tira um elemento de um `WeightedList` de
   `zombie.inventory.ItemGenerationConstants` ou de um `Registry` de
   `zombie.scripting.objects.Registries`, lê o `getTranslationKey()` dele e chama
   `InventoryItem.setName()`. Consequência que engana quem procura no `media/`: **o nome que aparece
   no inventário não é o `Base.<Item>` de `ItemName.json`** — é uma chave `IGUI_*` de `IG_UI.json`.
   `Letter`, por exemplo, monta a chave no próprio construtor, concatenando o prefixo literal
   `IGUI_` com o nome registrado (bootstrap `makeConcatWithConstants` com o argumento `IGUI_\u0001`).
   Quem usa esse idioma: `onCreateLetterHandwritten`, `onCreateGenericMail`, `onCreateDoodle`,
   `onCreateDoodleKids`, `onCreatePostcard`, `onCreateLocket`, `onCreatePhoto` e a família de
   jornal/revista.
2. **Carimbar `modData`.** `literatureTitle` (`onCreateRecipeMagazine`, `setLiteratureNameBasic`) ou
   `collectibleKey` (`onCreateLocket`). `literatureTitle` é a chave que o jogo usa para saber que o
   item **já foi lido** — `PZ/media/lua/shared/TimedActions/ISReadABook.lua:205-207`
   (`isLiteratureRead` / `addReadLiterature`),
   `PZ/media/lua/client/ISUI/ISInventoryPaneContextMenu.lua:1079` e
   `PZ/media/lua/client/ISUI/ISInventoryPane.lua:2590`.

**O que isso custa a um mod que omita o `OnCreate`.** Item de literatura de mod sem `OnCreate`
funciona: as receitas continuam vindo de `LearnedRecipes` e o texto, de `Print_Text.json`. O que se
perde é o carimbo `literatureTitle` — sem ele o jogo nunca marca a revista como lida, então não
aparece "Reler" nem o tooltip `ContextMenu_RecentlyRead`, e o item fica sempre com cara de inédito.

**O jornal datado sorteia a edição sem olhar a data do jogo.** `[levantado 2026-10-31]` Os
`onCreate*NewNewspaper` e `onCreateRecentNewspaper` (`PZ/media/scripts/generated/items/literature.txt:4174-4249`)
chamam `nameNewspaper(item, Newspaper.X)`, herdado de `zombie.scripting.logic.RecipeCodeHelper`
(superclasse de `ItemCodeOnCreate`). O método faz `Rand.Next` sobre `paper:getIssues()`, ou pega a
**última** edição se o item tem `ItemTag.NEWSPAPER_NEW`, e não compara com `GameTime` em ponto
nenhum. As edições são strings `<Jornal>_<Mês><Dia>` em inglês (`KentuckyHerald_July16`, no
`static {}` de `zombie.scripting.objects.Newspaper`), então jornal com data posterior ao início do
jogo nasce no dia 1. O que fica no item, pelo `setPrintMediaInfo`: `setName(getText(paper:getTitle(issue)))`;
`modData.printMedia = { title = getTitle(issue), info = getTranslationInfoKey(issue), text = getTranslationTextKey(issue), id = paper:toString() }`;
`modData.literatureTitle = getTitle(issue)`. **A edição não é gravada**: recupera-se comparando
`printMedia.title` com `getTitle` de cada edição. `Newspaper` aparece no `LuaManager$Exposer`, mas
`RecipeCodeHelper` não — ver "Pontos a confirmar".

**A exceção é o *schematic*.** `setSchematicLearnedRecipes` (privado, chamado por
`onCreateMeleeWeaponSchematic`, `onCreateSurvivalSchematic` e os outros seis) sorteia com
`Rand.Next` sobre uma `List<CraftRecipeKey>` e chama `Literature.setLearnedRecipes()`. Aí o
`OnCreate` **é** a fonte das receitas, e omiti-lo entrega um papel que não ensina nada.

## `craftRecipe`

O formato central do B42. Canônico — `PZ/media/scripts/generated/recipes/recipes_carving.txt:3`:

```
module Base
{
    craftRecipe MakeStake
    {
        timedAction = SharpenStakeWood,
        time = 100,
        OnCreate = RecipeCodeOnCreate.minorCondition,
        Tags = InHandCraft,
        xpAward = Carving:5,
        category = Carving,
        inputs
        {
            item 1 tags[base:sharpknife;base:meatcleaver] mode:keep flags[MayDegrade;IsNotDull],
            item 1 [Base.TreeBranch2;Base.Handle;Base.LongStick] flags[AllowDestroyedItem],
        }
        outputs
        {
            item 1 Base.Stake,
        }
    }
}
```

Contrato dos blocos `inputs`/`outputs` — a parte com sintaxe própria:

A linha começa com o **tipo de recurso**, seguido da quantidade. Dois tipos existem:

| Forma | Onde | Significado |
|---|---|---|
| `item <n> ...` | `inputs` e `outputs` | n unidades de item |
| `-fluid <float> ...` | só `inputs`, 55 ocorrências | fluido, com **hífen literal** no início e quantidade fracionária — `-fluid 5.0 [CowMilk;SheepMilk] mode:mixture,` (`PZ/media/scripts/generated/entities/animals/craftRecipes/recipes_butter_churn.txt:11`) |

O **seletor** diz *quais* itens servem. Quatro formas:

| Seletor | Exemplo |
|---|---|
| lista literal | `item 1 [Base.TreeBranch2;Base.Handle]` |
| `tags[...]` | `item 1 tags[base:sharpknife;base:meatcleaver]` |
| `categories[...]` | `-fluid 0.25 categories[Water]` (`PZ/media/scripts/generated/entities/pottery/cratRecipes/craftrecipe_potterywheel.txt:88`) |
| curinga `[*]` | `item 1 [*]` — qualquer item (`recipes_butter_churn.txt:10`) |

`categories[Water]` casa por **categoria do fluido**, e `TaintedWater` declara `Water` entre as dele
(`PZ/media/scripts/generated/fluids.txt:20-27`), ao lado de `Hazardous`. Pelo script, então, as
receitas de cimento/concreto com `-fluid 10.0 categories[Water] mode:mixture`
(`PZ/media/scripts/generated/recipes/recipes_buckets.txt:12`, `:36`, `:60`) aceitam água
contaminada. `[levantado 2026-10-31]` — se o motor recusa `Hazardous` na hora do craft está em
"Pontos a confirmar".

Os **modificadores** vêm depois do seletor:

- **`mode:`** tem três valores, não um: `keep` (1.502 usos — o recurso não é consumido), `destroy`
  (244) e `mixture` (26, visto só em linhas `-fluid`).
- **`mappers[...]`** — 216 usos, mapeia o item escolhido no input para o output correspondente:
  `item 1 [Base.Bullets9mmBox;Base.Bullets45Box;...] mappers[ammoTypes] flags[Prop2;AllowFavorite;InheritFavorite]`
  (`PZ/media/scripts/generated/recipes/recipes_ammunition.txt:29`). Os mapas mais usados são
  `metalType`, `fabricType`, `SmeltMapper`, `ragType`, `itemType`.
- **`itemMapper <Nome> { }`** é o bloco que *declara* o mapa que `mappers[...]` consome, e mora
  dentro do próprio `craftRecipe`, depois de `outputs` — `itemMapper LampMapper` em
  `PZ/media/scripts/generated/recipes/recipes_lightsources.txt:87`. Cada linha é
  `<itemDeSaída> = <itemDeEntrada>,` e a última é `default = <item>,` (`:89`–`:94`). O par completo é
  `mappers[LampMapper]` no `inputs` (`:80`) e `item 1 mapper:LampMapper` no `outputs` (`:85`) — note
  que o `inputs` usa o plural entre colchetes e o `outputs`, o prefixo `mapper:`.
- **`flags[...]`** — modificadores separados por `;`.

### As 57 flags

Censo do `media/scripts` inteiro — **57 valores únicos**, não os 9 de um arquivo só. Reproduzível
com `rg -o 'flags\[[^]]*\]' | tr ';' '\n' | sort -u`. O agrupamento abaixo é **por nome**, para
achar; a semântica de cada uma não foi confirmada no motor.

| Grupo (por nome) | Flags |
|---|---|
| Desgaste (4) | `MayDegrade`, `MayDegradeLight` (1.016 usos, a mais comum de todas), `MayDegradeVeryLight`, `MayDegradeHeavy` |
| Herança input→output (17) | `InheritCondition`, `DontInheritCondition`, `InheritColor`, `InheritSharpness`, `InheritFood`, `InheritFoodAge`, `InheritCooked`, `InheritFreezingTime`, `InheritUses`, `InheritUsesAndEmpty`, `InheritEquipped`, `InheritFavorite`, `InheritModelVariation`, `InheritHeadCondition`, `InheritWeight`, `InheritName`, `InheritAmmunition` |
| Condição exigida (19) | `IsNotDull`, `IsBlunt`, `IsSharpenable`, `SharpnessCheck`, `IsDamaged`, `IsUndamaged`, `IsEmpty`, `IsFull`, `IsSealed`, `IsNotWorn`, `IsExclusive`, `IsHeadPart`, `IsCookedFoodItem`, `IsUncookedFoodItem`, `NotFull`, `NotEmpty`, `NoBrokenItems`, `HasOneUse`, `HasNoUses` |
| Permissão (4) | `AllowDestroyedItem`, `AllowRottenItem`, `AllowFrozenItem`, `AllowFavorite` |
| Animação/mão (3) | `Prop1`, `Prop2`, `EquipSecondary` |
| Consumo e retorno (10) | `DontReplace`, `DontPutBack`, `DontRecordInput`, `ItemCount`, `ItemIsFluid`, `CopyClothing`, `SetActivated`, `Unseal`, `HandcraftOnly`, `ResearchInput` |

`Prop1`/`Prop2` controlam em qual mão a animação segura o quê.

Campos de topo:

- `time` — duração base.
- `timedAction` — qual animação/ação usar (`SharpenStakeWood`, `Making`).
- `category` — aba do menu de craft; a chave de tradução é `IGUI_CraftingCategories_<category>`
  (`PZ/media/lua/shared/Translate/EN/IG_UI.json:6858`). **O valor é livre**: a lista de abas é
  montada a partir das receitas presentes, não de uma lista fechada, e a chave é o valor com a
  primeira letra forçada a maiúscula
  (`PZ/media/lua/client/Entity/ISUI/CraftRecipe/ISWidgetRecipeCategories.lua:98-101`). Categoria
  nova de mod = escrever o valor + declarar a chave no `IG_UI.json` do mod. `[levantado 2026-10-06]`
- `xpAward` — `Perícia:pontos`, ex. `Carving:5`.
- `Tags = InHandCraft` — receita disponível sem bancada.
- `OnCreate` — callback Lua, no formato `Arquivo.funcao`. O código correspondente vive em
  `PZ/media/lua/server/CraftRecipeCode/`.
- `NeedToBeLearn` — se precisa de aprendizado prévio (visto em `craftRecipe CarveTrowel`). 260
  ocorrências em `generated/recipes/`, **417 em todo o `media/scripts`** (as outras 157 estão em
  `generated/entities/`, nas receitas de construção); a forma `needTobeLearn` tem **0**.
- **`OnTest`** — irmão de `OnCreate`, mas roda **antes**: decide se a receita sequer aparece
  disponível, em vez de agir sobre o resultado. Mesmo formato `Arquivo.funcao`. O vocabulário fechado
  são **14** funções `RecipeCodeOnTest.*` no jogo: `breakGlass`, `canAddToPack`, `copyKey`,
  `cutFillet`, `cutFish`, `genericPacking`, `haveFilter`, `haveOxygenTank`, `hotFluidContainer`,
  `noFilter`, `noOxygenTank`, `openFire`, `purifyWater`, `scratchTicket`.
  `[levantado 2026-10-27]` "Fechado" vale para o namespace `RecipeCodeOnTest`, não para o campo:
  **mod aponta `OnTest` para função global Lua própria**, assinatura `(inventoryItem, character)` →
  boolean (`STEAM/3775407541/mods/RadArchery/42/media/lua/shared/RadArcheryRegistry.lua:151`). O
  teste roda **por item de entrada**, não uma vez por receita: `RecipeCodeOnTest.hotFluidContainer`
  (Java, `javap -c`) recebe um `InventoryItem`, deixa passar item sem componente `FluidContainer` e,
  com ele, exige `getItemHeat() > 1.6`. Função de mod que imite um teste do jogo precisa da mesma
  forma — devolver `true` para os itens que ela não julga. O `OnCreate` Lua de mod tem assinatura
  `(craftRecipeData, character)`
  (`STEAM/2335368829/mods/Authentic Z - Backpacks+/42/media/lua/server/AuthenticZBackpacks+_RecipeCode.lua:165`).
  `[levantado 2026-10-31]` Os itens chegam por `craftRecipeData:getAllConsumedItems()` e
  `craftRecipeData:getAllCreatedItems()` (mesmo arquivo, `:212`; são os dois acessores mais usados em
  `STEAM/`), `ArrayList` Java. O jogo, no `OnCreate` de construção, usa `getAllInputItems()`
  (`PZ/media/lua/server/BuildRecipeCode/buildRecipeCode.lua:562`). Uso observado, não contrato.
  `OnTest = RecipeCodeOnTest.openFire` (`PZ/media/scripts/generated/recipes/recipes_spears.txt:27`) é
  a condição "há fogo aceso por perto" — é como se acende algo numa fogueira existente sem gastar
  isqueiro. Um mod reusa isso sem escrever Lua: `STEAM/3402516345/mods/B42Survival/.../recipes_Survival.txt:350`
  duplica a receita de acender tocha só para ganhar essa variante.
- **`RightClickOnly`** — tag de `craftRecipe` que tira a receita do menu de criação e a deixa só no
  menu de contexto (`PZ/media/scripts/generated/recipes/recipes.txt:106`, `:145`, `:168`). Combina
  com `InHandCraft` e `CanBeDoneInDark`.

### Os quatro caminhos para aprender uma receita

`NeedToBeLearn = true` não é um portão único. São **quatro** rotas independentes, e quem quiser
controlar a disponibilidade de uma receita — um mod com opção de ligar/desligar, por exemplo —
precisa fechar todas. Três delas não ficam no bloco `craftRecipe`:

| Rota | Onde se declara | Ocorrências |
|---|---|---|
| **Aprendizado explícito** (Lua chama `learnRecipe`) | — | — |
| **`AutoLearnAll` / `AutoLearnAny`** | no `craftRecipe` | 160 / 126 (**286**; 179 em `generated/recipes/`) |
| **`LearnedRecipes`** | no **item de literatura** | **199**, e **só** em `generated/items/literature.txt` |
| **`Researchablerecipes`** | no **item resultante** | 955 |

- **`AutoLearnAll`/`AutoLearnAny`** dão a receita ao atingir perícia, no formato `Perícia:nível` —
  `AutoLearnAny = Maintenance:10` (`PZ/media/scripts/generated/recipes/recipes.txt:350`). `Any`
  basta uma das perícias listadas; `All` exige todas. **Convivem com `NeedToBeLearn = true` no mesmo
  bloco**: `craftRecipe MakeHollowBook` declara os dois. É a rota que mais surpreende, porque a
  receita parece travada e destrava sozinha.
- **`LearnedRecipes`** é a revista de receitas — campo do item de literatura, não da receita.
  **Vive exclusivamente em `generated/items/literature.txt`**; nenhum outro arquivo de `media/scripts`
  o declara.
- **`Researchablerecipes`** é o inverso: fica no **item**, e significa "desmontar/pesquisar este item
  ensina estas receitas". Como exige ter o item em mãos, ele só é rota de aprendizado se o item
  chegar ao jogador por algum caminho — loot, outro mod, spawn de debug.

**Para mod, a leitura prática é:** travar por `NeedToBeLearn` só funciona se a receita **não** tiver
`AutoLearn*`, se nenhum item de literatura a listar em `LearnedRecipes`, e se o `Researchablerecipes`
do item resultante for coerente com a política — este último normalmente é, porque depende de o
jogador já possuir o item.

`learnRecipe` recebe **string**, o nome da receita: o jogo chama
`playerObj:learnRecipe("Generator")` (`PZ/media/lua/server/XpSystem/XpUpdate.lua:270` e `:285`), e o
par para checar antes é `playerObj:isRecipeActuallyKnown(nome)` (`:283`). Uso observado, não
assinatura declarada.

#### `AutoLearnAll` vs `AutoLearnAny`

Os dois usam o formato `Perícia:nível`, separado por `;`. A diferença é o quantificador: **`All`
exige todas** as perícias listadas no nível dado; **`Any` basta uma**. Censo das formas reais:

- `AutoLearnAll` aparece com uma e com várias — `AutoLearnAll = Blacksmith:4`,
  `AutoLearnAll = Blacksmith:4;Cooking:1`, `AutoLearnAll = Blacksmith:10;LongBlade:5`.
- `AutoLearnAny` idem — `AutoLearnAny = Carving:5`, `AutoLearnAny = Carving:10;Blunt:10`.

Com **uma só** perícia os dois são equivalentes; a escolha só muda algo a partir de duas.

#### A revista de receita, campo a campo

O bloco canônico é `item SmithingMag1` (`PZ/media/scripts/generated/items/literature.txt:3`):

```
    item SmithingMag1
    {
        DisplayCategory = RecipeResource,
        ItemType = base:literature,
        Weight = 0.5,
        Icon = MagazineBlacksmith1,
        BoredomChange = -20,
        StressChange = -15,
        LearnedRecipes = Forge_Tongs;Forge_Heading_Tool;…,
        StaticModel = Magazine,
        WorldStaticModel = MagazineGround,
        Tags = base:magazine,
        OnCreate = ItemCodeOnCreate.onCreateRecipeMagazine,
    }
```

Pontos que economizam trabalho em mod:

- **`StaticModel = Magazine` e `WorldStaticModel = MagazineGround` são do jogo** — uma revista de mod
  não precisa de modelo 3D próprio, só de ícone.
- **`LearnedRecipes` aceita tag de receita, não só nome.** `literature.txt:26` começa com
  `base:kitchentools` antes dos nomes — é a mesma lista, com as duas formas misturadas.
- **`OnCreate = ItemCodeOnCreate.onCreateRecipeMagazine`** aparece em **84** revistas. `ItemCodeOnCreate`
  **não existe em `PZ/media/lua`** (zero ocorrências) — é namespace Java, alcançável do `.txt`. O
  método faz **uma linha só**: `getModData().rawset("literatureTitle", getFullType())`. Não
  distribui receita nenhuma e não sorteia condição — as receitas da revista vêm de `LearnedRecipes`,
  no `.txt`. Ver "[`OnCreate` do `item`](#oncreate-do-item--o-namespace-itemcodeoncreate)".
  `[levantado 2026-08-29]`
- `DisplayCategory = RecipeResource` e `Tags = base:magazine` são o par que põe a revista na aba certa
  e a marca como revista para o resto do jogo.

**Onde revista nasce**: as 23 listas de `ProceduralDistributions` que carregam `SmithingMag1` são
`BinSpiffos`, `BookstoreBlueCollar`, `BookstoreMisc`, `CrateBlacksmithing`, `CrateMagazines`,
`GunStoreLiterature`, `GunStoreMagazineRack`, `Hobbies`, `Homesteading`, `LivingRoomShelf`
(+ `Classy`/`Redneck`), `LivingRoomSideTable` (+ `Classy`/`Redneck`), `LivingRoomWardrobe`,
`MagazineRackMixed`, `PostOfficeMagazines`, `RecRoomShelf`, `SafehouseBookShelf`, `ShelfGeneric`,
`SurvivalGear` e `ToolStoreBooks`. Ver [distribuicao-loot.md](distribuicao-loot.md).

**Família vizinha, que não é a mesma coisa:** `MeleeWeaponSchematic` (`literature.txt:6258`),
`SurvivalSchematic` (`:6270`) e os outros *schematics* têm `DisplayCategory = RecipeResource` como a
revista, mas **não declaram `LearnedRecipes`** — as receitas deles são sorteadas pelo `OnCreate`
correspondente, no Java (`setSchematicLearnedRecipes`, confirmado no bytecode; ver
"[`OnCreate` do `item`](#oncreate-do-item--o-namespace-itemcodeoncreate)"). Serve para "papel que
ensina uma receita sorteada", não para uma lista fixa — e aqui, ao contrário da revista, **omitir o
`OnCreate` entrega um papel que não ensina nada**.

**`Tags` e `tags[…]` são coisas diferentes, e convivem no mesmo bloco.** `Tags` (T maiúsculo) é campo
do `craftRecipe`; `tags[…]` (t minúsculo) é o seletor dentro de uma linha `item` de `inputs`. Censo em
`generated/recipes/`: `Tags` 623 ocorrências e `tags` como campo **0**; `SkillRequired` 297. A
assimetria é proposital — no bloco `MakeStake` acima as duas formas aparecem juntas. Errar a caixa
aqui tem o mesmo efeito de errar em `item`: o campo some sem aviso, e a receita fica sem a restrição
que se pensava ter escrito.

**Nome da receita = chave de tradução, sem prefixo.** `craftRecipe MakeStake` é traduzido pela chave
`"MakeStake"` em `Recipes.json` (`PZ/media/lua/shared/Translate/EN/Recipes.json:203`). No B41 a chave
levava prefixo `Recipe_`; hoje `EN/Recipes.json` tem **zero** chaves `Recipe_`.

### Reescrever a receita em runtime — o caminho com opção de sandbox `[levantado 2026-10-31]`

Redeclarar o bloco em `module Base` troca a receita para sempre, sem como desligar. Para condicionar
a uma opção, o mod reescreve a receita já carregada:
`ScriptManager.instance:getCraftRecipe(nome)` (ou `getScriptManager():getCraftRecipe`), depois
`:getInputs():clear()` / `:getOutputs():clear()` e `:Load(nome, "{ … }")` com um bloco no formato
do `.txt`. Só `Load` **mescla**: `"{ Time = 30, }"` sozinho troca o tempo e mantém o resto, e por
isso as listas precisam do `clear()` antes. `Load(String, String)` e `getInputs()`/`getOutputs()`
estão em `zombie.scripting.entity.components.crafting.CraftRecipe` (bytecode). O jogo não tem
exemplo. O precedente é mod publicado e atualizado em 2026
(`STEAM/2788256295/mods/AmmoMaker/42.20/media/lua/shared/ammomaker_recipeManager.lua:172`, `:902-905`),
que chama tudo em `Events.OnInitGlobalModData` (`:1052`) a partir de `shared/`, lendo `SandboxVars`
dentro do handler. Receita de **construção** (`entity`) sai por `getBuildableRecipe(nome)` — ver
[construcao.md](construcao.md).

## `entity` — o sistema de estações do B42

Novidade do B42: bancada, forno, fogueira etc. são `entity` com `component`. Canônico —
`PZ/media/scripts/generated/entities/admin/entity_piano.txt:3`:

```
module Base
{
    entity Piano
    {
        component SpriteConfig
        {
            face E
            {
                layer
                {
                    row = recreational_01_13,
                    row = recreational_01_12,
                }
            }
            face S { layer { row = recreational_01_8 recreational_01_9, } }
        }
        component CraftRecipe
        {
            OnAddToMenu = debugTest,
            time = 10,
            category = Debug,
            Tooltip = Tooltip_craft_debugModeDesc,
            inputs
            {
                item 1 tags[base:hammer] mode:keep flags[Prop1;MayDegradeVeryLight],
                item 2 [Base.Plank],
                item 4 [Base.Nails],
            }
        }
    }
}
```

Note o aninhamento de 4 níveis (`entity` → `component` → `face` → `layer`) e que dentro de `layer`
**vários sprites na mesma linha, separados por espaço,** formam uma linha horizontal, enquanto `row`
repetido empilha na vertical.

O `component CraftRecipe` aqui é a *receita de construção da própria entidade* — usa a mesma sintaxe
de `inputs` do `craftRecipe`, sem `outputs` (a saída é a entidade).

### Bancada de receita: `CraftBench` + `Tags` `[levantado 2026-10-06]`

Uma entidade vira bancada pelo `component CraftBench`, e a receita se liga a ela **por tag**, não
por nome. Canônico — a torradeira:

- `PZ/media/scripts/generated/entities/appliances/workstations/entity_toaster.txt:11-14` —
  `component CraftBench { Recipes = Toaster, }`, ao lado de `UiConfig` e `SpriteConfig`
  (`appliances_cooking_01_32` face S, `_33` face E, `:15-31`).
- `…/workstations/entity_toaster_craftRecipe.txt:3-8` — `craftRecipe MakeToast` com
  `Tags = Toaster`, sem `InHandCraft`.

O par é `Recipes = <Tag>` na bancada e `Tags = <Tag>` no `craftRecipe`. A torradeira **não tem**
`component CraftRecipe` de construção: é móvel de mapa, e o que a torna bancada é só o
`SpriteConfig` apontar o sprite dela. O mesmo padrão aparece com quatro faces (`N`/`W` também) em
`entity_coffeemachine.txt` e `entity_waterdispenser.txt`. `MakeToast` não declara nada de energia no
`.txt`. Ver "Pontos a confirmar".

O par vale também para estação que processa sozinha. As duas variantes do secador declaram
`Recipes = DryingRackGrain` (`PZ/media/scripts/generated/entities/agricultural/workstations/entity_Drying_Rack.txt:24`
e `:521`), e `DryTobacco` entra com `Tags = DryingRackGrain`, sem `timedAction`
(`…/entity_Drying_Rack_craftRecipe.txt:67-81`). O moinho de pedra manual declara
`Recipes = Stone_Quern` (`…/entity_stone_quern.txt:13`). Um `craftRecipe` de **outro módulo** (o do mod)
com a mesma tag entrar na estação vanilla é inferência: o caso observado abaixo é de entidade do mod.

**Mod consegue fazer o mesmo sobre sprite vanilla** — observado in-game em 2026-10-06 (mod
de teste): um `entity` em `module Base` com `CraftBench` e `SpriteConfig` apontando o
computador de mesa (`appliances_com_01_72..75`, as quatro faces) transformou o computador **já
colocado no mapa** em bancada, e o `craftRecipe` com `Tags` igual ao `Recipes` apareceu ao lado dele.
O tile manteve `CustomName`/`GroupName` (um menu de contexto do mod que casa por essas propriedades
continuou funcionando). O nome da janela veio de `DisplayName = EC_<…>` no `xuiSkin`, com a chave em
`Translate/<IDIOMA>/Entity.json` — o precedente em `STEAM/` usa o mesmo prefixo, ainda no formato
`.txt` (`STEAM/3596827035/mods/ShelterHold_Beehive/42/media/scripts/entities/ShelterHold/entity_honeyextractor_xuiSkin.txt:8`).

## `xuiSkin` — aparência da entidade

Duas metades do mesmo assunto. A skin de uma entidade específica vive em `entities/<tema>/` —
`PZ/media/scripts/entities/misc/entity_haybundles_xuiSkin.txt:3`:

```
module Base
{
    xuiSkin default
    {
        entity ES_HayBundle
        {
            LuaWindowClass = ISEntityWindow,
            DisplayName = HayBundle,
        }
    }
}
```

`LuaWindowClass` é o gancho para a UI: aponta para uma classe Lua (`ISEntityWindow`, em
`PZ/media/lua/client/Entity/`). É por aí que um mod dá janela própria a uma estação.

Skins podem herdar via `imports` — `PZ/media/scripts/xui/xui_skin_electric_common.txt:5`:

```
    xuiSkin electric_common
    {
        imports
        {
            default,
        }

        ISButton S_Button_Craft
        {
            title               = "Start",
        }
    }
```

## `fixing`

`PZ/media/scripts/generated/fixing.txt:3`:

```
    fixing Fix Pistol
    {
        Require = Base.Pistol,
        Fixer = Base.Pistol; Aiming=3,
    }
```

**O nome do bloco contém espaço** (`Fix Pistol`) — é o único tipo de bloco em que isso aparece no
`media/`, e o parser aceita. `Fixer` usa `;` para separar o item da exigência de perícia, com `=`
interno — sintaxe que não se repete em nenhum outro bloco.

## `evolvedrecipe`

Receita "vai acumulando ingrediente" (sopa, sanduíche) —
`PZ/media/scripts/generated/evolvedrecipes.txt:3`:

```
    evolvedrecipe Soup
    {
        BaseItem = Base.Pot,
        MaxItems = 6,
        ResultItem = Base.PotOfSoupRecipe,
        Cookable = true,
        Name = Prepare Soup,
        Template = Soup,
        MinimumWater = 0.9,
    }
```

Sobreviveu ao B42 sem mudar de nome, ao contrário do `recipe`. Chave de tradução em
`EvolvedRecipeName.json`.

## `character_trait_definition` / `character_profession_definition`

**Trait e profissão viraram `.txt` no B42.** É a mudança que mais quebra tutorial antigo depois do
`recipe`, porque no B41 se registrava trait em Lua com `TraitFactory.addTrait(...)` dentro de um
callback de `OnGameBoot`. Esse caminho **não existe mais**: `TraitFactory.` e `ProfessionFactory.`
têm **zero** ocorrências em todo o `PZ/media/lua`. Ver
[eventos-lua.md](eventos-lua.md).

Dois arquivos, em `PZ/media/scripts/generated/characters/`. Traits —
`character_traits.txt:3`:

```
    character_trait_definition base:adrenalinejunkie
    {
        IsProfessionTrait = false,
        DisabledInMultiplayer = false,
        CharacterTrait = base:adrenalinejunkie,
        Cost = 4,
        UIName = UI_trait_AdrenalineJunkie,
        UIDescription = UI_trait_AdrenalineJunkieDesc,
        MutuallyExclusiveTraits = base:agoraphobic;base:claustrophobic;base:cowardly;base:desensitized,
    }
```

Profissões — `character_professions.txt:3`:

```
    character_profession_definition base:burglar
    {
        CharacterProfession = base:burglar,
        Cost = -6,
        UIName = UI_prof_Burglar,
        IconPathName = profession_burglar2,
        GrantedTraits = base:burglar,
        XPBoosts = Nimble=2;Sneak=2;Lightfoot=2,
        GrantedRecipes = MakeForearmMagazineArmor;MakeBodyMagazineArmor;MakeGlassShiv,
    }
```

Contrato, com a contagem de quantos dos 97 traits / 25 profissões usam cada campo:

| Campo | Trait | Profissão | Observação |
|---|---|---|---|
| `CharacterTrait` / `CharacterProfession` | 97 | 25 | **repete o nome do bloco**, com o `base:` |
| `Cost` | 97 | 25 | negativo = trait de desvantagem, dá pontos |
| `UIName` | 97 | 25 | chave de tradução, não texto |
| `UIDescription` | 84 | 8 | opcional |
| `MutuallyExclusiveTraits` | 70 | — | lista com `;` |
| `XPBoosts` | 35 | 24 | `Perícia=nível`, itens separados por `;` |
| `GrantedRecipes` | 18 | 15 | nome de `craftRecipe`, sem `base:` |
| `GrantedTraits` | 2 | 12 | profissão que concede trait |
| `IsProfessionTrait`, `DisabledInMultiplayer` | 97 | — | só trait |
| `IconPathName` | — | 24 | só profissão |

Duas coisas fogem do padrão do resto do `media/scripts`:

- **O nome do bloco leva o namespace**: `character_trait_definition base:adrenalinejunkie`, não
  `AdrenalineJunkie`. É o único par de blocos onde o ID é minúsculo com `base:`.
- **`XPBoosts` mistura os dois separadores**: `;` entre itens e `=` dentro de cada um —
  `XPBoosts = Nimble=2;Sneak=2;Lightfoot=2,`. Compare com `xpAward = Carving:5` do `craftRecipe`,
  que usa `:`. Não há um separador único no formato; confira o campo, não presuma.

### Profissão que concede traço — o padrão do Mecânico `[levantado 2026-10-06]`

`GrantedTraits` coloca o traço em "Traços Escolhidos" ao selecionar a profissão
(`PZ/media/lua/client/OptionScreens/CharacterCreationProfession.lua:459-468`). Dois fatos do mesmo
arquivo decidem como desenhar o par profissão + traço comprável da mesma perícia:

- **`XPBoosts` do traço concedido soma com o da profissão** — `checkXPBoost` acumula traços
  escolhidos e profissão no mesmo mapa, com teto 10 (`:405-432`). Conceder o traço comprável que
  já dá +1 empilha nível.
- **Exclusão mútua com o traço concedido tira o comprável da lista**, e `onSelectProf` remove o
  comprável se ele já estava escolhido (`:448-457`).

O jogo resolve com um traço só de profissão, sem XP, exclusivo com o comprável — a profissão
`base:mechanics` (`PZ/media/scripts/generated/characters/character_professions.txt:135-145`) dá
`GrantedTraits = base:mechanics2` (`IsProfessionTrait = true`, `Cost = 0`, sem `XPBoosts`), e
`base:mechanics`/`base:mechanics2` se excluem nos dois sentidos
(`PZ/media/scripts/generated/characters/character_traits.txt:655-677`). O nível vem todo da
profissão. Traço e profissão podem ter o **mesmo ID** — `base:burglar` é os dois
(`character_traits.txt:137`, `character_professions.txt:3`).

### Ícones — traço por convenção de nome, profissão por `IconPathName` `[levantado 2026-10-06]`

- **Traço não tem campo de ícone.** O arquivo é `media/ui/Traits/trait_<ID sem namespace, em
  minúsculo>.png`, 18×18: `base:mechanics2` → `PZ/media/ui/Traits/trait_mechanics2.png`;
  `ToadTraits:actionhero` → `STEAM/1299328280/mods/More Traits/common/media/ui/Traits/trait_actionhero.png`;
  `Lifestyle:Artistic` → `STEAM/3403870858/mods/Lifestyle/common/media/ui/Traits/trait_artistic.png`.
  Os dois mods põem em `common/`. (Só 16 ícones do jogo estão soltos em `PZ/media/ui/Traits/`; o
  resto vem de pack.)
- **Profissão usa `IconPathName`, nome de textura sem caminho nem extensão.** Nenhum
  `profession_*.png` do jogo está solto em `media/` — vêm de pack. Ver "Pontos a confirmar" para o
  caminho do arquivo num mod.

### Traço de mod usa o namespace do mod, não `base:`

O jogo declara tudo em `module Base` com ID `base:<nome>`, o que deixa em aberto o que um mod deve
escrever. Dois mods publicados respondem, e os dois fazem igual — **módulo próprio e ID prefixado
pelo módulo**:

```
module Lifestyle
{
    character_trait_definition Lifestyle:Artistic
    {
        IsProfessionTrait = false,
        DisabledInMultiplayer = false,
        CharacterTrait = Lifestyle:Artistic,
        Cost = 3,
        UIName = UI_trait_artistic,
        UIDescription = UI_trait_artisticdesc,
        XPBoosts = Art=1;Pottery=1,
    }
```

(`STEAM/3403870858/mods/Lifestyle/common/media/scripts/generated/characters/LS_character_traits.txt:1-12`.)
O outro é *More Traits* (`STEAM/1299328280`), com `module ToadTraits { character_trait_definition
ToadTraits:actionhero`.

Três detalhes que só aparecem lendo os dois juntos:

- **O prefixo do ID é o nome do módulo, não `base:`** — e a caixa segue a do módulo (`Lifestyle:`,
  `ToadTraits:`), então o "ID minúsculo" do jogo é consequência de o módulo dele se chamar `base`, e
  não uma regra do bloco.
- **`CharacterTrait` repete o ID inteiro, com namespace.** É autorreferência, e a forma curta não
  aparece em nenhum dos dois.
- **O *More Traits* mantém três pastas de versão** (`42.13/`, `42.15/`, `42.17/`) com o mesmo arquivo
  — ver a pasta de versão em [carregamento-de-mods.md](carregamento-de-mods.md). O *Lifestyle* põe o
  seu em `common/`, apesar de `.txt` de script normalmente ir na pasta de versão.

Isso confirma que o bloco funciona vindo de mod. **Não** confirma o caminho de tradução: os dois
apontam `UIName` para uma chave (`UI_trait_artistic`) que precisa existir no `.json` de tradução do
mod — ver [carregamento-de-mods.md](carregamento-de-mods.md).

## `timedAction` — a ação que o `craftRecipe` executa

Todos os 119 num arquivo só: `PZ/media/scripts/generated/timedactions.txt:3`.

```
    timedAction ApplyAlcohol
    {
        metabolics = SedentaryActivity,
        actionAnim = ApplyAlcohol,
        sound = FirstAidApplyAlcohol,
        soundTime = animation_event,
        prop1 = Base.WhiskeyBottle,
        prop2 = Base.DishCloth_Hand,
    }
```

É o alvo do campo `timedAction = X,` do `craftRecipe` e do `component CraftRecipe` — por exemplo
`timedAction = Making,` em `entity_toaster_craftRecipe.txt:5` resolve para `timedactions.txt:148`.
Definir uma ação nova é escrever um bloco aqui e apontar a receita para ele.

- `metabolics` e `actionAnim` aparecem em praticamente todos os blocos, mas **nenhum parâmetro é
  `required`** segundo o PZ-API-Docs — a frequência é convenção, não contrato.
- `muscleStrainParts` usa **`;`** como separador: `muscleStrainParts = Hand_R;ForeArm_R;UpperArm_R,`.
- `animVarKey`/`animVarVal` andam em par.
- `soundTime` tem default `action_start`, e a fonte externa o marca como **"useless — requires Lua
  implementation"**. Não confirmado no `media/`; não conte com ele.

## `template` — só veículo

Os 77 blocos vivem em `PZ/media/scripts/generated/vehicles/` e **todos** têm a forma
`template vehicle <Nome>` — o segundo token é keyword fixa, não parte do nome. Não é mecanismo
genérico de herança de script: não existe `template item` nem `template craftRecipe`.

`PZ/media/scripts/generated/vehicles/template_glovebox.txt:3`:

```
    template vehicle GloveBox
    {
        part GloveBox
        {
            mechanicArea = Interior,
            area = SeatFrontRight,
            itemType = Base.GloveBox,
            mechanicRequireKey = true,
            durability = 3,
            container
            {
                test = Vehicles.ContainerAccess.GloveBox,
                soundMap = ContainerClose VehicleGloveboxClose,
                soundMap = ContainerOpen VehicleGloveboxOpen,
            }
            lua
            {
                create = Vehicles.Create.Default,
            }
        }
    }
```

Consumo, em `PZ/media/scripts/generated/vehicles/vehicle_car_sports.txt:87-100`:

```
        template = GloveBox,
        template = Seat/part/SeatFrontLeft,
```

Duas coisas não-óbvias: o campo `template =` **repete** dentro do mesmo `vehicle` (um por template
incluído) e aceita **sub-path** (`Template/part/NomeDaParte`) para puxar só um pedaço. O nome de
`part` também aceita **curinga** — `part Seat*` (`template_seat.txt:59`) vale para toda parte com
aquele prefixo.

`soundMap` é outro campo repetível, e sua forma é `soundMap = <Evento> <Som>` — dois tokens
separados por espaço, sem `=` entre eles.

## `physicsShape`, `energy`, `clock` — os três órfãos

Os três são pequenos, ficam cada um em seu arquivo, e têm em comum um detalhe que importa para modar:
**nada em `media/scripts` aponta para eles.** A ligação é feita do lado Java/Lua, então não dá para
descobrir o consumidor grepando script.

**`physicsShape`** — 90 blocos em `PZ/media/scripts/generated/models_isoobject_physicsShape.txt:3`:

```
    physicsShape ramp10segment1n
    {
        mesh = physics/ramp10|Segment1,
        translate = 0.0 0.0 0.5,
        rotate = 0.0 180.0 0.0,
    }
```

`mesh` é o único campo obrigatório; o caminho é relativo a `media/models_X` e o **`|` separa o
arquivo do segmento nomeado** dentro dele. `translate`/`rotate` são três floats separados por
**espaço**, não por vírgula.

**`energy`** — 7 blocos em `PZ/media/scripts/generated/energies.txt:3`, com os mesmos 5 campos cada:

```
    energy Electric
    {
        DisplayName = EC_Energy_Electric,
        Color = 0.63:0.78:0.6,
        iconTexture = media/ui/Entity/Energy/icon_energy_electric.png,
        horizontalBarTexture = media/ui/Entity/Bars/bars_horz_green.png,
        verticalBarTexture = media/ui/Entity/Bars/bars_vert_green.png,
    }
```

`Color` é RGB em floats separados por **`:`** — sintaxe que não se repete em nenhum outro bloco.
`DisplayName` é chave de tradução (prefixo `EC_Energy_`), não texto. O consumo aparece na UI de
entidade: `PZ/media/lua/client/Entity/ISUI/Controls/ISEnergySlot.lua` e
`ISEnergySlotPanel.lua`, com a skin em `PZ/media/scripts/xui/defaultskin/xs_ISEnergySlotPanel.txt`.

**`clock`** — 8 blocos em `PZ/media/scripts/generated/clocks.txt:3`, indexados por nome de sprite:

```
    clock location_community_school_01_32
    {
        replacementSprite = animated_clock_01_0,
        north = true,
        handOffset = 0.5 0.175 0.775,
        hand hour
        {
            length = 0.14,
            thickness = 0.019,
            texture = IsoObject/ClockHandHourRed,
            rgba = 1.0 1.0 1.0 1.0,
        }
        hand minute { ... }
    }
```

`hand hour` / `hand minute` é sub-bloco com nome, **sem `=`** (não é `hand = hour`). Só
`replacementSprite` aparece em todos os 8 — dois blocos (`walls_detailing_02_57`, `_59`) têm apenas
ele, sem `north`, `handOffset` nem `hand`, o que mostra que o resto é opcional.

## Os seis blocos restantes

Fecham o censo: com estes, todo bloco de `media/scripts` tem descrição — aqui ou numa página
dedicada.

**`fluid`** — 61 blocos em `PZ/media/scripts/generated/fluids.txt:3` e nos dois arquivos temáticos
(`fluids_Alcoholic.txt`, `fluids_Beverages.txt`). É o único destes seis que um mod de conteúdo
normal encostaria:

```
    fluid Water
    {
        ColorReference = LightSkyBlue,
        DisplayName = Fluid_Name_Water,
        Categories
        {
            Beverage,
            Water,
        }
        Properties
        {
            ThirstChange = -50.0,
        }
    }
```

Dois sub-blocos, e ambos usam **lista sem `=`**: `Categories` enumera rótulos soltos separados por
vírgula; `Properties` é que leva `chave = valor`. `ColorReference` e `DisplayName` aparecem nos 61
(o segundo é chave de tradução, prefixo `Fluid_Name_`). Campos de `Properties` por frequência:
`ThirstChange` (47), `Proteins`/`Lipids`/`Carbohydrates`/`Calories` (44 cada), `HungerChange` (43),
`UnhappyChange` (40), `fatigueChange` e `StressChange` (39) — note `fatigueChange` em **minúscula
inicial**, sozinho contra o padrão dos vizinhos. `whitelist` (56) fica fora dos dois sub-blocos.

`[levantado 2026-10-27]` Há um terceiro sub-bloco, **`Poison`**, com `chave = valor`:
`maxEffect`, `minAmount`, `diluteRatio` (`PZ/media/scripts/generated/fluids.txt:32-37`, no
`TaintedWater`). 10 ocorrências em `fluids.txt`; `maxEffect` só aparece com `Medium` (6) e `Deadly`
(4) em `generated/`. **Fluido não estraga:** `DaysFresh`, `DaysTotallyRotten` e afins têm zero
ocorrência em `fluids.txt`, `fluids_Alcoholic.txt` e `fluids_Beverages.txt`, e também em
`items/normal.txt`, onde moram os recipientes. Leite líquido (`CowMilk` em `Base.Milk`,
`normal.txt:6046-6066`) dura para sempre, e só o leite que é **comida** (`Base.CannedMilkOpen`,
`items/food.txt:3949-3976`) estraga. `[levantado 2026-10-31]` O fluido de mod com nome global e a conversão de fluido por `OnCreate` estão em
[fazenda-e-pesca.md](fazenda-e-pesca.md), "Fluido de mod e conversão dentro do recipiente".

**`fluid Coffee` existe e nada o produz.** Está declarado em
`PZ/media/scripts/generated/fluids_Beverages.txt:381`, mas nenhum `item` nasce com ele e nenhuma
receita o cria (grep por `Coffee` em `media/scripts` e `media/lua`). O café do jogo é comida: a
cafeteira (`PZ/media/scripts/generated/entities/appliances/workstations/entity_coffeemachine_craftRecipe.txt:3`)
devolve `Base.HotDrink*` e o `OnCreate = RecipeCodeOnCreate.makeCoffee` (Java) só grava
`Base.Coffee2` nos `extraItems` da caneca e aquece a comida (`javap -c`). Mod que quiser café como
fluido transferível usa esse `Coffee` do jogo em vez de declarar outro.

**`mannequin`** — 30 blocos em `PZ/media/scripts/generated/mannequins.txt:3`:

```
    mannequin FemaleBlack01
    {
        female = true,
        model = FemaleBody,
        texture = F_Mannequin_Black,
        animSet = mannequin,
        animState = female,
        pose = pose01,
        outfit = ,
    }
```

Amarra as três áreas: `model` aponta para bloco `model` ([arte-e-modelos.md](arte-e-modelos.md)),
`animSet`/`animState` para [animacao.md](animacao.md) (existe `AnimSets/mannequin/` e
`mannequin.xml`), `outfit` para o traje de [roupa.md](roupa.md). Repare em **`outfit = ,`** — campo
declarado vazio, com a vírgula. O parser aceita valor ausente.

**`ragdoll`** — 66 blocos, e é o único bloco com **uma pasta própria**:
`PZ/media/scripts/ragdolls/` (4 arquivos — `ragdoll_anchors.txt`, `ragdoll_bodydynamics.txt`,
`ragdoll_bodypartinfo.txt`, `ragdoll_constraints.txt`). O nome do bloco carrega o osso
(`PZ/media/scripts/ragdolls/ragdoll_anchors.txt:3`):

```
    ragdoll Bip01_R_Finger0_anchor
    {
        bone = 17,
        bodyPart = 10,
        reverse = false,
        original = false,
        enabled = false,
    }
```

`bone` e `bodyPart` são **índices numéricos**, não nomes — a tabela que os traduz não está em
`media/scripts`. Os nomes `Bip01_*` são os mesmos ossos de `m_AttachBone` em [roupa.md](roupa.md).

**`physicsHitReaction`** — 10 blocos em `PZ/media/scripts/generated/physics/physics_hit_reactions.txt:3`,
um por calibre (`bullets_44`, `bullets_45`, `bullets_223`, …):

```
    physicsHitReaction bullets_44
    {
        impulse_pelvis = 40.0,
        impulse_spine = 40.0,
        impulse_head = 30.0,
        …
        upwardImpulse_pelvis = 40.0,
```

Bloco plano, sem sub-bloco: dois prefixos (`impulse_`, `upwardImpulse_`) × parte do corpo. É o
empurrão do ragdoll ao levar tiro.

**`vehicleEngineRPM`** — 4 blocos em
`PZ/media/scripts/generated/sounds/vehicles/vehicle_engine_rpm.txt`. Sub-bloco `data` **repetido e
anônimo**, um por marcha:

```
    vehicleEngineRPM generic
    {
        VERSION = 1,
        data
        {
            gearChange = 3500,
            afterGearChange = 2000,
        }
        data
        {
            gearChange = 4000,
            afterGearChange = 2500,
        }
```

O campo `VERSION` aqui é o mesmo idioma da segunda família de sintaxe descrita em
[mapa-media.md](mapa-media.md) — dentro de `media/scripts` ele é raro.

**`xuiConfig`** — **1** bloco, `project_zomboid`, em `PZ/media/scripts/xui/xui_config.txt:3`. É o
esquema do sistema XUI: declara quais nomes de propriedade existem, agrupados por tipo, cada grupo
uma lista sem `=`:

```
    xuiConfig project_zomboid
    {
        /* normal String, no auto translation */
        String
        {
            styleBar,
            styleBtnClear,
            …
        }

        StringList
        {
            animationList,
        }

        /* String values gets auto passed through Translator */
        TranslateString
```

Dois pontos: o arquivo usa **comentário `/* */`**, o único visto em `media/scripts`; e a distinção
`String` vs `TranslateString` é o que decide se o valor passa pelo tradutor. Ver a seção `xuiSkin`
acima.

O sétimo da lista antiga, **`animation`**, saiu para [animacao.md](animacao.md) junto com
`animationsMesh`.

## Pontos a confirmar

- **`DoubleClickRecipe` apontando para receita de módulo que não é `Base`.** Todo uso observado, no
  jogo e em `STEAM/` (`3402516345/.../Items_Survival.txt:22`, `module Base`), está em `module Base`;
  não se sabe se o nome sem módulo resolve dentro do módulo do mod nem se a forma `Modulo.Receita` é
  aceita. *A confirmar in-game.* `[aberto 2026-10-31]`
- **`ReplaceOnCooked` com fullType de mod** (`ReplaceOnCooked = <Mod>.X`). Os três usos vanilla
  apontam para `Base.*`. Também não foi levantado em quais fontes de calor a troca acontece (forno,
  fogueira, churrasqueira, panela). *A confirmar in-game.* `[aberto 2026-10-29]`
- **`craftRecipe` de módulo de mod com `Tags` de estação vanilla** (`DryingRackGrain`, `Stone_Quern`).
  O par `Recipes`/`Tags` está provado (ver "Bancada de receita"), mas o caso observado in-game é de
  entidade do mod. `[aberto 2026-10-29]`
- ~~**Se tile pré-colocado no mapa vira `entity` de mod sobre sprite vanilla**~~ — **RESOLVIDO em
  2026-10-06** in-game: vira, e preserva as propriedades do tile. Ver "Bancada de receita". Continua
  em aberto se a bancada exige energia (`MakeToast` não declara nada no `.txt`).
- **O que o motor faz com `MuzzleFlashModelKey` de valor vazio** (`MuzzleFlashModelKey = ,`). Sem
  precedente vanilla — as 20 ocorrências têm valor real. Em aberto: se é descartado como campo
  ausente, se resolve para modelo nulo e aborta o disparo, ou se é inofensivo. O caso apareceu em
  `WS/SiddigoWeapons` (`item Slingshot`, que não dispara) e **não foi isolado por teste**, então não
  há como afirmar que é a causa. `[aberto 2026-08-16]`
- **Qual bloco vence quando dois declaram o mesmo `Base.X`.** A sobrescrita de item vanilla por
  redeclaração em `module Base` está observada (ver "Redeclarar em `module Base`"), mas a regra de
  precedência não: se é o último a carregar, se é a ordem da tela de seleção, ou se o motor tem
  outro critério. Nem o efeito de dois mods sobrescreverem o mesmo item ao mesmo tempo foi testado.
- **O mecanismo por trás do item registrador de `AmmoType`.** O que está **provado** aqui é a
  convergência de dois mods publicados e mantidos, que resolvem a mesma coisa do mesmo jeito. O
  *porquê* — `Item.resolveItemTypes()` sendo o único populador do mapa de tracer, e o
  desreferenciamento sem checagem de nulo que gera NPE no primeiro disparo — vem dos comentários do
  `RadArcheryTracerRegistrars.txt` e do `CLAUDE.md` do RadArchery, que citam Java **decompilado**.
  Não é verificável no `media/` e não foi cruzado com o PZ-API-Docs nesta rodada. Trate como forte
  indício com artefato confirmando, não como contrato.
- **Se o item registrador ainda é necessário quando o mod não rebinda o `AmmoType` por Lua.** Os dois
  casos observados fazem rebind em runtime; se uma arma que declara um único `AmmoType` fixo no
  próprio script já se auto-registra, o item extra seria redundante. Nenhum mod instalado testa esse
  caso isolado.
- **Se `registries.lua` alcança os registros fora dos 11 do *Migration Guide*.** `Registries` declara
  35 registros e `Letter.register(String)` é público e estático como o `ItemTag.register(String)` que
  os mods usam — mas nenhum mod de `STEAM/` registra fora da lista do guia, e "público no Java" não
  prova exposição ao Lua. Só um teste in-game decide. `[levantado 2026-08-29]`
- ~~**O que `ItemCodeOnCreate.onCreateRecipeMagazine` faz.**~~ **Resolvido em 2026-08-29** pela
  desmontagem do `projectzomboid.jar` — ver
  "[`OnCreate` do `item`](#oncreate-do-item--o-namespace-itemcodeoncreate)". O callback só carimba
  `modData.literatureTitle`; não sorteia condição nem distribui receita. Fica em aberto só a
  confirmação **in-game** de que uma revista de mod sem `OnCreate` perde apenas o "Reler" — o efeito
  foi derivado do bytecode e das três leituras de `literatureTitle` em `media/lua`, não testado.
- **Se `LearnedRecipes` de um mod pode listar receita de outro módulo**, e qual a forma — o jogo só
  lista receitas de `Base` sem prefixo. Um mod que queira ensinar `SiddigoWeapons.Algo` precisa
  descobrir se escreve o nome puro (as receitas vivem em `module Base` mesmo em mod) ou qualificado.
- **[resolvido 2026-08-16]** ~~`AmmoType.register(nome, ItemKey.new(...))` não tem um só exemplo
  real~~ — o exemplo apareceu (mod de demonstração oficial da IndieStone
  `Documentacao/oficial/testmod_registries`, 42.13, fora de `STEAM/`) e **foi reprovado por teste
  in-game**: em 42.20.2 essa forma derruba o carregamento do Lua no `registries.lua`, e a que
  funciona é a string `"Modulo.Item"`. Ver a seção "Arma à distância", correção de 2026-08-16.
- **Se a assinatura de `AmmoType.register` mudou entre 42.13 e 42.20.2, ou se o exemplo oficial
  nunca valeu nesta build.** O `MethodArguments.assertValid` de 42.20.2 exige `String` no 2º
  argumento (log citado na seção "Arma à distância"), e o exemplo da IndieStone passa `ItemKey`. As
  duas hipóteses explicam o mesmo fato e não são separáveis aqui — exigiria o `.jar` de 42.13, que
  não está instalado. O que já está decidido é a consequência prática: em divergência entre exemplo
  oficial e jogo instalado, o instalado ganha.
- **Se `ItemKey.new` tem algum uso vivo nesta build**, e qual. A chamada em si não falhou; quem
  rejeitou o valor foi o `AmmoType.register` que o recebeu. Se algum dos outros 10 registros aceita
  `ItemKey`, não foi levantado.
- **Se `NoMuzzleFlash` e `MuzzleFlashModelKey = ,` (vazio) fazem alguma coisa**, ou são campo morto
  de B41. Zero ocorrências no jogo, e o único mod que usa é migração B41→B42 com resíduo visível no
  mesmo bloco — ver a seção "Arma à distância". O parser ignora campo desconhecido em silêncio, então
  presença em mod publicado não prova efeito. Só teste in-game separa: arma sem pólvora com e sem o
  par, olhando se aparece clarão ao disparar. `WS/SiddigoWeapons` (`item Slingshot`) está com as duas
  linhas e serve de cobaia.
- **Se `ItemTag.register` é obrigatório ou só recomendado.** O guia diz *"Tags now require the
  ItemTag registry"*, mas o efeito de uma tag **não** registrada não foi medido: ela pode ser
  descartada no parse, ou apenas não existir do lado Lua. `damnlib` usa `damnlib:` sem registrar (mod
  de layout pré-B42), o que não decide a questão. **Um teste in-game de duas tags — uma registrada,
  uma não — resolve.**
- **Se `common/media/registries.lua` funciona igual a `<versao>/media/registries.lua`.** 8 dos 9 mods
  usam a pasta de versão; só `Lifestyle` usa `common/`. Nenhum dos dois foi verificado em execução.
- **A ordem de carga declarada não foi medida.** O guia afirma que `registries.lua` é lido *"before
  scripts and before any other Lua files"*. Nada em `PZ/media` mostra isso — é Java.
- **Se um item pode ser arma e fonte de luz ao mesmo tempo** — a favor: os campos de luz **não** são
  exclusivos de `base:drainable` — `item GunLight` é `ItemType = base:weaponpart` e declara
  `ActivatedItem`/`LightDistance`/`LightStrength` (`PZ/media/scripts/generated/items/weaponpart.txt:152`)
  — e o menu de luz gateia por `item:getLightStrength() > 0`, sem olhar `ItemType`
  (`PZ/media/lua/client/ISUI/ISLightSourceRadialMenu.lua:6`).

  **[indício 2026-08-15]** `WS/SiddigoWeapons` publicou `item TorchLit` (`base:weapon`) com
  `LightDistance = 12`/`LightStrength = 1.4` e testou in-game: a luz **apareceu** (o jogador só
  reclamou de intensidade/tamanho/cor, não de ausência) — a favor de que `LightDistance`/
  `LightStrength`/`TorchCone` funcionam em `base:weapon`, apesar de zero precedente vanilla. Não é
  teste isolado (o item também tinha outros campos incomuns), mas a luz aparecer não é algo que um
  campo ignorado produziria.

  **Achado relacionado, esse sim com evidência de censo:** `UseDelta` (o campo que faz o combustível
  acabar) tem **zero** ocorrências em `weapon.txt` inteiro, contra 17 em `drainable.txt` e 1 em
  `weaponpart.txt` (`item GunLight`). O mesmo `TorchLit` declarava `UseDelta = 0.0025` e, testado
  in-game por horas, não esgotou — consistente com a família de depleção (`UseDelta`,
  `ActivatedItem`, `UseWhileEquipped`/`UseWhileUnequipped`, `ReplaceOnDeplete`) não rodar em
  `base:weapon`, ainda que os campos estáticos de luz (`LightDistance`/`LightStrength`) rodem. A
  correção observada no mod foi mover a depleção para Lua (`Condition` + `Events.EveryHours`,
  convertendo o item ao esgotar via `OnBreak.HandleHandler` — o mesmo callback que os vanilla
  `OnBreak = OnBreak.*` usam quando a condição do weapon chega a 0 por desgaste de combate).
- **Se um item não-drainable consegue acender fogo** mesmo com `base:startfire`. O gate do menu de
  fogueira é `item:hasTag(ItemTag.START_FIRE) ... and (item:getCurrentUses() > 0)`
  (`PZ/media/lua/shared/Camping/ISCampingMenu.lua:117`), e todos os portadores vanilla da tag são
  `base:drainable`. O que `getCurrentUses()` devolve num `base:weapon` não está no `media/` —
  continua sem teste in-game registrado (o relato de 2026-08-15 não cobriu este ponto).
- **Onde um mod B42 põe o PNG do `IconPathName` da profissão.** Nenhum mod de `STEAM/` declara
  `character_profession_definition`. A única evidência é B41: `STEAM/2703664356` (TheOnlyCure) põe
  `media/textures/profession_surgeon.png` (64×64) e o referencia pelo nome nu
  (`media/lua/shared/NPCs/ExtraProfession.lua:6`). Se a resolução por nome ainda acha
  `media/textures/` (ou `media/ui/`) em B42, só teste in-game decide. `[aberto 2026-10-06]`
- Se o parser exige mesmo a vírgula final no último campo, ou apenas tolera. Todo o `media/` usa,
  então o seguro é usar.
- Se `module` diferente de `Base` funciona sem declaração extra **para item**. Para
  `character_trait_definition` está confirmado (seção acima); o jogo não tem exemplo de item fora de
  `Base`, e a extrapolação de um bloco para outro não é evidência.
- As 57 flags acima são as **usadas** pelo jogo, não a lista de aceitas pelo parser. O PZ-API-Docs
  documenta `craftRecipe` mas **não enumera os valores de `flags`**
  (`pz-wiki-modding.github.io/PZ-API-Docs/scripts/craftrecipe.html`), então pode haver flag válida
  sem uso no `media/`. Mesma ressalva para os 3 valores de `mode:` e os 4 seletores.
- Semântica individual de cada flag — o agrupamento por nome acima serve para achar, não afirma o
  efeito. `destroy` e `mixture` em `mode:` idem.
- Semântica de `template!` (com `!`) contra `template` no bloco `vehicle` — a forma existe, com 200
  ocorrências. Ver [veiculos.md](veiculos.md).
- Quem referencia `physicsShape` e `clock`. Zero ocorrências fora do arquivo de definição em todo o
  `media/scripts`, e uma só em `media/lua`
  (`PZ/media/lua/client/Vehicles/ISUI/EditVehicleState.lua`). A ligação é Java.
- **O censo de blocos fechou** — todo bloco de `media/scripts` tem descrição. Os últimos seis
  (`fluid`, `mannequin`, `ragdoll`, `physicsHitReaction`, `vehicleEngineRPM`, `xuiConfig`) entraram
  na seção acima; `animation` e `animationsMesh` foram para [animacao.md](animacao.md), `vehicle` e
  `template` para [veiculos.md](veiculos.md), `model` para
  [arte-e-modelos.md](arte-e-modelos.md), `sound` e `soundTimeline` para [som.md](som.md). O que
  segue aberto para os seis é a **semântica**, não a forma:
  - Os rótulos válidos de `Categories` em `fluid`, e se `whitelist` aceita lista.
  - A tabela que traduz os índices `bone` e `bodyPart` de `ragdoll` — não está em `media/scripts`.
    Pista parcial: `PZ/media/lua/shared/Translate/EN/BodyParts.json` traz 11 chaves
    `BODYPART_PELVIS`/`BODYPART_SPINE`/`BODYPART_LEFT_UPPER_ARM`… que são nome de exibição de **osso
    de ragdoll**, não as 17 partes de saúde de [saude-e-corpo.md](saude-e-corpo.md). Não é a tabela
    de índices, mas é o espaço de nomes daquele bloco, e está em `media/`.
  - Se a ordem dos sub-blocos `data` de `vehicleEngineRPM` é a ordem das marchas (é a leitura
    natural, mas nada declara) e a unidade de `gearChange`.
  - Se `outfit = ,` (valor vazio) é tolerado em qualquer campo ou só neste.
  - Se um mod pode declarar `xuiConfig` próprio, sendo bloco único no jogo inteiro. O censo já
    fechou e é **0 em 101 mods** (89 de `STEAM/` + 12 de `WS/`); o que segue em aberto é se não dá
    ou se ninguém tentou. Mecanismo e cadeia de aplicação em [xui.md](xui.md).
- `[2026-10-31]` **`categories[Water] mode:mixture` aceita `TaintedWater` na hora do craft?** O script diz que
  sim (ver "Contrato dos blocos `inputs`/`outputs`"), mas há relato de jogador de que o cimento só sai
  com água limpa. Pode ser regra do Java contra `Hazardous` ou build antigo. Resolve num teste in-game
  de `MakeBucketOfConcrete` com balde de água contaminada.
- `[2026-10-31]` **Os estáticos de `Newspaper` (`Newspaper.KENTUCKY_HERALD` etc.) são alcançáveis pelo Lua?** A
  classe está no `LuaManager$Exposer`, mas nenhum Lua do jogo a usa, e o exposer pode cobrir só
  métodos de instância. Resolve com `Newspaper.KENTUCKY_HERALD:getIssues()` no console de debug.

> Última verificação: 2026-08-07 — PZ buildid 24574865 (branch public, atualizado 2026-08-07),
> media/ + STEAM/ (89 mods) + PZ-API-Docs 42.20.0.

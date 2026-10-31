# Construção — o menu de construir do B42

Como um objeto construível existe no B42: um bloco `entity` com três `component`, mais funções Lua
nomeadas de dentro do `.txt`. Cobre também o sistema de cursor do B41, que ainda está no disco e
não é mais o caminho.

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\` (ver
[../index.md](../index.md)). **Somente leitura.**

A sintaxe geral de `entity` e `component` está em [scripts-txt.md](scripts-txt.md); aqui é o uso
específico de construção, que combina componentes que aquela página descreve separados.

## O modelo: um `entity`, três componentes

`PZ/media/scripts/generated/entities/walls/entity_wood_walllvl1.txt` é o exemplo canônico completo —
parede de madeira nível 1, do sprite à receita:

```
module Base
{
    entity WoodenWallLvl1
    {
        component UiConfig
        {
            xuiSkin = default,
            entityStyle = ES_Wood_WallLvl1,
            uiEnabled = false,
        }
        component SpriteConfig
        {
            LogicClass = WoodenWall,
            health = 450,
            skillBaseHealth = 20,
            previousStage = WoodenWallFrame;MetalWallFrame,
            BreakSound = ZombieThumpWoodCollapse,
            face W
            {
                layer
                {
                    row = walls_exterior_wooden_01_44,
                }
            }
            face N
            {
                layer
                {
                    row = walls_exterior_wooden_01_45,
                }
            }
            corner = walls_exterior_wooden_01_27,
        }
        component CraftRecipe
        {
            OnAddToMenu = woodenWallLvl1Test,
            timedAction = BuildWallHammer,
            time = 200,
            category = Carpentry,
            SkillRequired = Woodwork:2,
            xpAward = Woodwork:20,
            Tooltip = Tooltip_craft_NeedsWallframeDesc,
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

A divisão de papéis:

| Componente | Responde |
|---|---|
| `UiConfig` | aparência na janela — skin XUI e `entityStyle` |
| `SpriteConfig` | **o objeto no mundo** — sprite por orientação, vida, som de quebra, classe de lógica |
| `CraftRecipe` | **como se constrói** — ingredientes, tempo, skill, XP, quando aparece no menu |

`uiEnabled = false` é o valor de parede/piso: o objeto construído não abre janela ao clicar. Uma
bancada usa `true` — ver a seção `entity` de [scripts-txt.md](scripts-txt.md).

### `SpriteConfig` — `face` e `corner`

Cada orientação é um bloco `face <letra>` com um `layer { row = <sprite> }` dentro. As letras
observadas são `W`, `N`, `E`, `S`. Parede usa duas (`W` e `N`) mais um `corner =` solto; barricada
usa as quatro (`entity_barricade_metalbar.txt:18-40`).

`row =` aponta para um sprite de tileset — o nome vem dos `.tiles`, ver [tiles.md](tiles.md).

Outros campos de `SpriteConfig` no exemplo:

- `LogicClass = WoodenWall` — liga a uma classe de comportamento (ver "o sistema antigo" abaixo).
- `health = 450` e `skillBaseHealth = 20` — vida base e o quanto o nível de skill acrescenta.
- `previousStage = WoodenWallFrame;MetalWallFrame` — **o estágio anterior**, múltiplos separados por
  `;`. É o que faz a parede só poder ser construída sobre um frame.
- `BreakSound = ZombieThumpWoodCollapse` — ver [som.md](som.md).
- `isThumpable = false` (`entity_barricade_metalbar.txt:13`).

### `CraftRecipe` — o mesmo bloco de receita

`inputs`, `mode:`, `flags[...]`, `tags[...]` seguem exatamente a gramática de `craftRecipe`
documentada em [scripts-txt.md](scripts-txt.md), incluindo as 57 flags. `SkillRequired` e `xpAward`
usam a forma `Perk:valor` — o perk tem de existir, e criar perk novo não é possível (ver
[perks-e-xp.md](perks-e-xp.md)).

`timedAction = BuildWallHammer` referencia um bloco `timedAction` do `.txt`, **não** uma classe Lua —
a distinção está em [timedactions.md](timedactions.md).

## A ponte `.txt` → Lua: os campos `On*`

O `.txt` nomeia funções Lua diretamente. Censo em todo o `media/scripts`:

| Campo | Ocorrências |
|---|---|
| `OnCreate` | 547 |
| `OnBreak` | 193 |
| `OnAddToMenu` | 76 |
| `OnIsValid` | 24 |
| `OnEat` | 23 |
| `OnTest` | 20 |
| `OnCooked` | 11 |

O valor é um **caminho de tabela Lua global**, resolvido em tempo de carga:

```
            OnIsValid = BuildRecipeCode.barricade.OnIsValid,
            OnCreate = BuildRecipeCode.barricade.OnCreate,
            TimedActionOnIsValid = BuildRecipeCode.barricade.TimedActionOnIsValid,
```

(`entity_barricade_metalbar.txt:14-16`.) Também existe a forma de função global solta:
`OnAddToMenu = woodenWallLvl1Test` (`entity_wood_walllvl1.txt:35`) e `OnAddToMenu = debugTest`
(`entity_piano.txt:40`).

Os dois destinos ficam em `lua/server/`:

| Arquivo | Linhas | Papel |
|---|---|---|
| `lua/server/BuildRecipeCode/buildRecipeCode.lua` | 619 | tabela `BuildRecipeCode` — validação e criação por família |
| `lua/server/CraftRecipeCode/CraftRecipe_BuildMenu.lua` | 397 | funções globais de `OnAddToMenu` |

### `BuildRecipeCode` — a tabela

Declarada com o idioma defensivo `X = X or {}` (`buildRecipeCode.lua:1`), seguida das famílias
(`:2-13`):

```lua
BuildRecipeCode = BuildRecipeCode or {}
BuildRecipeCode.barricade = {}
BuildRecipeCode.canBePlastered = {}
BuildRecipeCode.stairs = {}
BuildRecipeCode.floor = {}
BuildRecipeCode.doorFrame = {}
BuildRecipeCode.butcheringHook = {}
BuildRecipeCode.chickenHutch = {}
BuildRecipeCode.feedingTrough = {}
BuildRecipeCode.campfire = {}
BuildRecipeCode.composter = {}
BuildRecipeCode.windowGlass = {};
BuildRecipeCode.woodLampPillar = {};
```

O `or {}` é o que permite a um mod acrescentar família sem depender de ordem de carga — mesma
mecânica registrada em [animais.md](animais.md) para `AnimalDefinitions`.

Os handlers recebem um único `params`:

```lua
function BuildRecipeCode.barricade.OnIsValid(params)
	local tileInfoSprite = params.tileInfo:getSpriteName() and getSprite(params.tileInfo:getSpriteName());
	local square = params.square
    if params.facing == "s" then
        square = getWorld():getCell():getGridSquare(square:getX(), square:getY()+1, square:getZ());
```

(`:15-19`.) Campos de `params` observados aqui: `tileInfo`, `square`, `facing` (`"n"`/`"s"`/`"e"`/`"w"`,
minúsculo), `north`. Retorno booleano — `true` libera a construção.

### `OnAddToMenu` — quando a opção aparece

`CraftRecipe_BuildMenu.lua` é o arquivo de gate do menu. O padrão (`:11-18`):

```lua
function woodenWallLvl1Test(param)
    if param.shouldShowAll then return true; end
    local recipe = param.recipe;
    local player = param.player;
    local perkLevel = player:getPerkLevel(Perks.Woodwork);

    return perkLevel < 4;
end

function debugTest(param)
    return isDebugEnabled();
end
```

Dois contratos:

- **`param.shouldShowAll` tem de ser respeitado** — é o modo "mostrar tudo" e sai cedo com `true`.
  Uma função de mod que ignora isso some do menu quando o jogador liga a opção.
- **A progressão por nível é escadinha de três funções** (`Lvl1Test` retorna `perkLevel < 4`,
  `Lvl2Test` retorna `>= 4 and < 6`, `Lvl3Test` retorna `>= 6`, `:11-33`), cada uma amarrada a um
  `entity` diferente. É assim que o jogo troca o sprite da parede conforme a marcenaria sobe — não
  há campo de "nível" no bloco.

O cabeçalho do arquivo diz que ele foi gerado por EmmyLua e criado por "RJ" em 14/11/2024
(`CraftRecipe_BuildMenu.lua:1-5`), o que o data como B42.

## O sistema antigo — `ISBuildingObject`

`PZ/media/lua/server/BuildingObjects/` tem 37 `.lua` e **33 derivações de `ISBuildingObject`**:
`ISWoodenWall`, `ISWoodenFloor`, `ISWoodenDoor`, `ISWoodenStairs`, `ISSimpleFurniture`,
`ISDoubleDoor`, `ISWoodenContainer`, `ISBarbedWire`, `ISCompost`, `ISHutch`, `ISLightSource`, mais os
cursores (`ISBuildCursorMouse`, `ISDestroyCursor`, `ISPaintCursor`, `ISMoveableCursor`, …).

`ISBuildingObject.lua` é a base, com o ciclo próprio: `init`, `isValid(square)`, `render(x,y,z,square)`,
`tryBuild(x,y,z)`, `walkTo`, `onTimedActionStart/Stop`, `onActionComplete`, `updateModData`,
`haveMaterial(square)`, `rotateKey`/`rotateMouse` e os `onJoypad*`.

**Não é o caminho para adicionar construção nova no B42.** A evidência: procurando quem *instancia*
essas classes em `media/lua`, os únicos usos fora da própria pasta são cenários de debug
(`DebugUIs/Scenarios/Trailer2Scenario.lua:166`, `Trailer3Scenario.lua:199`) e o tutorial
(`Tutorial/Tutorial1.lua:475`) — sempre como argumento de `IsoThumpable.new(...)`. O menu de
construir do jogo vem dos `entity` do `.txt`.

O que a pasta ainda é: **a implementação de comportamento** por trás do `LogicClass = WoodenWall` do
`SpriteConfig`, e o dono dos cursores de ação no mundo (destruir, pintar, mover móvel). Ver
pendências.

## Onde ficam os arquivos

| O quê | Caminho |
|---|---|
| `entity` de construção | `PZ/media/scripts/generated/entities/<tema>/` — 13 subpastas |
| skin XUI da entidade | `PZ/media/scripts/entities/<tema>/entity_*_xuiSkin.txt` |
| código de validação/criação | `PZ/media/lua/server/BuildRecipeCode/buildRecipeCode.lua` |
| gate de menu | `PZ/media/lua/server/CraftRecipeCode/CraftRecipe_BuildMenu.lua` |
| classes de lógica e cursores | `PZ/media/lua/server/BuildingObjects/` (37 `.lua`) |
| UI e ações do lado cliente | `PZ/media/lua/client/BuildingObjects/{ISUI,TimedActions}/` |

Os temas de `generated/entities/` são `admin`, `agricultural`, `animals`, `appliances`, `barricades`,
`blacksmith`, `fences_low`, `furniture`, `misc`, `outdoors`, `stairs`, `walls` — ver
[mapa-media.md](mapa-media.md).

## Lado do mod

- O `.txt` do `entity` vai em `media/scripts/` na pasta de versão; o `.lua` dos handlers em
  `media/lua/server/`.
- **Use `X = X or {}`** ao acrescentar família em `BuildRecipeCode`, copiando o idioma do jogo — é o
  que evita apagar a tabela se o seu arquivo carregar antes.
- Função global de `OnAddToMenu` é **global mesmo**: prefixe com o nome do mod.
- `category =` no `CraftRecipe` decide a aba do menu; `Carpentry` é do jogo.

## Pontos a confirmar

- **A lista completa de campos de `SpriteConfig` e `UiConfig`.** Esta página cobre os observados em
  dois arquivos; há 183 `.txt` em `scripts/entities/` e 13 subpastas em `generated/entities/` que não
  foram varridas campo a campo.
- **Como `LogicClass` resolve para a classe Lua.** `LogicClass = WoodenWall` e existe
  `ISWoodenWall` — a correspondência aparenta ser "prefixo `IS` + nome", mas isso não foi verificado
  contra a lista inteira, e o resolvedor é Java.
- **Se um mod pode declarar `LogicClass` própria**, apontando para classe Lua nova.
- **A lista completa de campos de `params`** nos handlers de `BuildRecipeCode`. Os observados
  (`tileInfo`, `square`, `facing`, `north`) vêm de `OnIsValid`; `OnCreate` e `TimedActionOnIsValid`
  não foram abertos e podem receber outros.
- **A assinatura de `param` em `OnAddToMenu`** — observados `shouldShowAll`, `recipe`, `player`.
- **`OnBreak` (193 usos) e `OnCooked` (11)** não foram abertos; `OnEat` (23) é de item, não de
  construção.
- **`skillBaseHealth`** — a fórmula que combina com `health` não está no `media/lua`.
- **Se `face` aceita outras letras** além de `W`/`N`/`E`/`S`, e o que `corner =` faz quando só há
  duas faces.
- **Se o sistema de cursor (`ISBuildingObject`) ainda é alcançável por mod** no B42, ou se está
  morto para construção nova. A evidência de instanciação é fraca (só debug e tutorial), mas os 37
  arquivos não foram lidos e os cursores de destruir/pintar claramente continuam vivos.
- **Nenhuma fonte da comunidade foi cruzada** nesta rodada. O PZ-API-Docs cataloga `entity` em
  `scripts/`, e é a via para fechar os campos de componente.

> Última verificação: 2026-08-07 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

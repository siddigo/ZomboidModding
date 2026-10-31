# `WorldGen/` — a geração procedural de terreno do B42

133 `.lua` em `PZ/media/lua/server/WorldGen/`, e — ao contrário de quase toda a massa grande do jogo
— é **Lua declarativo puro, legível e extensível**. Esta página abre a pendência "Conteúdo de
`WorldGen/`" que [mapas-e-zonas.md](mapas-e-zonas.md) deixou na porta.

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\` (ver
[../index.md](../index.md)). **Somente leitura.**

Cidade feita à mão, zona e metazona estão em [mapas-e-zonas.md](mapas-e-zonas.md); loot **não** está
aqui (é [distribuicao-loot.md](distribuicao-loot.md)); a zona de coleta é
[coleta-foraging.md](coleta-foraging.md).

## A tabela raiz

`PZ/media/lua/server/WorldGen/WorldGen.lua` tem 17 linhas e é o arquivo inteiro:

```lua
worldgen = {
    biomes = {},
    features = {},
    selection = {},
    prefabs = {},
    veins = {},
    roads = {},
    attachments = {},
    similar = {},
    priorities = {}
}

require("WorldGen/Features")
require("WorldGen/Biomes")
require("WorldGen/Selection")
require("WorldGen/Veins")
require("WorldGen/Roads")
require("WorldGen/attachments/Priorities")
```

Uma global `worldgen`, nove subtabelas, e os `require` na ordem de dependência. **`Features` carrega
antes de `Biomes`** porque bioma referencia feature por valor, não por nome (ver abaixo).

| Unidade de topo | Linhas | Papel |
|---|---|---|
| `WorldGen.lua` | 17 | a tabela raiz e a ordem de carga |
| `Features.lua` | 18 | declara as 6 categorias e faz o preload |
| `Biomes.lua` | 28 | preload dos três diretórios de bioma |
| `Selection.lua` | 36 | **as faixas de ruído → nome de faixa** |
| `Veins.lua` | 39 | veios de minério |
| `Roads.lua` | 18 | estrada procedural |

## O carregamento por varredura de diretório

`Features.lua` e `Biomes.lua` não listam arquivos — eles varrem a pasta via uma classe Java
(`Features.lua:12-18`):

```lua
local files = WorldGenUtils.INSTANCE:getFiles("lua/server/WorldGen/features")
for i = 1, WorldGenUtils.INSTANCE:getFilesNum() do
    local path = string.gsub(WorldGenUtils.INSTANCE:getFile(i - 1), "media/lua/server/", "")
    require(path)
end
```

Isso é o contrato mais importante da área para um mod: **arquivo novo na pasta certa é carregado
sozinho**, sem edição de índice. `Biomes.lua` repete o padrão três vezes, e a ordem é comentada no
próprio arquivo (`Biomes.lua:8`):

```
subbiomes  →  map  →  worldgen        -- "Should be loaded first because biomes need it"
```

Se `WorldGenUtils.INSTANCE:getFiles` enxerga a pasta de um mod é a pendência central desta página.

## `features/` — o átomo

90 `.lua` em 6 subpastas, que são exatamente as 6 categorias declaradas em `Features.lua:3-10`:
`GROUND`, `PLANT`, `BUSH`, `TREE`, `ORE`, `NONE`.

Cada arquivo é curto e termina se registrando. `features/ore/iron_ore.lua` inteiro:

```lua
local iron_ore = {
    main = {
        "crafting_ore_0",
        "crafting_ore_1",
        …
    }
}
worldgen.features.ORE["iron_ore"] = iron_ore
```

`main` é uma lista de **nomes de sprite** — os mesmos dos `.tiles`, ver [tiles.md](tiles.md). O motor
sorteia dentro da lista.

O idioma é sempre o mesmo: tabela `local`, registro na última linha em
`worldgen.features.<CATEGORIA>["<nome>"]`.

## `Selection.lua` — as faixas

36 linhas, e é a tradução de ruído procedural em nome legível. Seis eixos, cada um com faixas
`{ min, max }` em `[-1, 1]`:

```lua
worldgen["selection"] = {
    landscape = {
        FOREST = { 0.5, 1.0 },
        LIGHT_FOREST = { 0.0, 0.5 },
        PLAIN = { -1.0, 0.0 }
    },
    temperature = {
        HOT = { 0.25, 1.0 },
        MEDIUM = { -0.25, 0.25 },
        COLD = { -1.0, -0.25 }
    },
    ore_level = {
        VERY_HIGH = { 0.98, 1.0 },
        HIGH = { 0.94, 0.98 },
        MEDIUM = { 0.78, 0.94 },
        LOW = { 0.46, 0.78 },
        VERY_LOW = { 0.14, 0.46 },
        NONE = { -1.0, 0.14 }
    }
}
```

Os seis eixos: `landscape`, `plant`, `bush`, `temperature`, `hygrometry`, `ore_level`.

Repare que **as faixas não são uniformes**: `ore_level` concentra quase metade do domínio em `NONE`
(`-1.0` a `0.14`) e dá só 2% a `VERY_HIGH`. É aqui que se mexe para tornar minério mais comum, não no
bioma.

## `biomes/` — três diretórios, três papéis

| Pasta | Arquivos | Registra em |
|---|---|---|
| `biomes/worldgen/` | 10 | `worldgen.biomes` |
| `biomes/map/` | 17 | `worldgen.biomes_map` |
| `biomes/subbiomes/` | 7 | `worldgen.subbiomes` |

Os 10 de `worldgen/` são os biomas de verdade: `birch_forest`, `pine_forest`, `maple_forest`, as três
variantes `light_*`, `grass_plain`, `flower_plain`, `sand_bank`, `water`.

### A forma de um bioma

`biomes/worldgen/birch_forest.lua` — `features` por categoria com peso, e `params`:

```lua
local birch_forest = {
    features = {
        GROUND = {
            { f = worldgen.features.GROUND.light_grass, p = 1.0 }
        },
        TREE = {
            { f = worldgen.features.TREE.birch_jumbo_xxl, p = 0.1 },
            { f = worldgen.features.TREE.birch_jumbo, p = 0.0125 },
            { f = worldgen.features.TREE.hawthorn_jumbo_xxl, p = 0.005 },
            { f = worldgen.features.TREE.stumps, p = 0.001 },
        }
    },
    params = {
        subbiomes = {
            TREE = { TREE = { worldgen.subbiomes.grass } },
        },
        landscape = { "FOREST" },
        temperature = { "MEDIUM" },
        hygrometry = { "DRY", "RAIN" },
        zombies = 0.001,
        generate = false
    }
}
```

- **`f` é a tabela da feature, não o nome** — `worldgen.features.TREE.birch_jumbo`, valor direto. É
  por isso que a ordem de carga importa: `Features` antes de `Biomes`.
- **`p` é probabilidade por tile**, e os valores são minúsculos (0.1 a 0.001).
- **`params` casa o bioma com as faixas de `Selection.lua`** — `landscape = { "FOREST" }`,
  `temperature = { "MEDIUM" }`, `hygrometry = { "DRY", "RAIN" }`. Múltiplos valores = o bioma
  aceita qualquer um deles. **É essa a ligação entre ruído e bioma**, e ela é por string.
- `zombies = 0.001` — densidade de zumbi do bioma.
- `generate = false` — ver pendências.

### Herança por `parent`

O mesmo arquivo declara seis variantes que só diferem no nível de minério (`birch_forest.lua:50-70`):

```lua
local birch_forest_boulder_low = {
    parent = "birch_forest",
    features = { ORE = { { f = worldgen.features.ORE.boulders, p = 0.01 } } },
    params = { ore_level = { "LOW" } }
}
```

**`parent` é string** (nome do bioma), ao contrário de `f`, que é valor. A variante declara só o
delta. É o mecanismo natural para um mod ajustar um bioma do jogo sem copiá-lo inteiro — com a
ressalva de ordem de carga.

Cada uma se registra na sua linha (`:85-91`), então um arquivo produz sete entradas em
`worldgen.biomes`.

### `subbiomes/` e `placements`

Sete arquivos (`bushes`, `bushes_dry`, `bushes_regular`, `dense_bushes`, `grass`, `no_tree`,
`small_trees`). Trazem um campo que os biomas não têm — `params.placements`
(`biomes/subbiomes/bushes.lua:13-18`):

```lua
    params = {
        placements = {
            GENERIC = {
                "blends_natural_01_*",

                "!blends_natural_01_0",
```

**Glob com `*` e negação com `!`** sobre nome de sprite. É a única sintaxe de padrão vista nesta área.

## `veins/`, `roads/` e `prefabs/`

**`Veins.lua`** (39 linhas) define `iron` e `copper`, os dois com a mesma forma geométrica:

```lua
    iron = {
        feature = { f = worldgen.features.ORE.iron_ore },
        arms = {
            amount_min = 3, amount_max = 6,
            distance_min = 100, distance_max = 400,
            delta_angle = 5,
            p = 0.25
        },
        center = { radius = 5, p = 0.5 },
        p = 0.01
    },
```

Um veio é um centro com raio mais 3 a 6 "braços" de 100 a 400 de comprimento. `delta_angle = 5`
controla a curvatura.

**`Roads.lua`** (18 linhas) tem uma entrada só, `small_road`, com `filter_edge = 5e8` e `p = 0.0005`.
Repare na linha comentada preservada no arquivo (`:5`) — o sprite anterior.

**`prefabs/`** tem **2** arquivos (`highway_NS_00.lua`, `normal_road_WE_00.lua`). O formato é
dimensão + lista de tiles + esquema:

```lua
local highway_NS_00 = {
    dimensions = { 20, 3 },
    zombies = 0.01,
    tiles = { "blends_street_01_86", "street_curbs_01_9", … },
    schematic = {
        Floor = {
```

**`attachments/`** tem 1 arquivo, `Priorities.lua`, que é uma lista ordenada de camadas de terreno:
`Water`, `Clay`, `Grass_Light`, `Grass_Dark`, `Sand`, `Dirt`, `Dirt_Grass`, `Grass_Medium`, `Burnt`,
`Road_01`…`Road_07`. **A ordem é a prioridade de sobreposição.**

Note que `worldgen.similar` é declarada em `WorldGen.lua:9` e **nenhum arquivo a preenche** — não há
`require` correspondente na lista de `:13-18`.

## Lado do mod

O caminho aparente, por ordem de facilidade:

1. **Feature nova** — um `.lua` em `media/lua/server/WorldGen/features/<categoria>/`, terminando em
   `worldgen.features.<CAT>["nome"] = t`.
2. **Ajustar densidade** — variante com `parent = "<bioma do jogo>"` e só o delta.
3. **Bioma novo** — arquivo em `biomes/worldgen/`, com `params` casando as faixas de `Selection.lua`.
4. **Mexer nas faixas** — reescrever entrada de `worldgen.selection` (afeta o mundo todo).

Tudo em `media/lua/server/` — geração de mundo é autoritativa, ver
[persistencia-e-multiplayer.md](persistencia-e-multiplayer.md).

## Pontos a confirmar

- **Se `WorldGenUtils.INSTANCE:getFiles("lua/server/WorldGen/features")` enxerga a pasta de um mod.**
  É a pergunta que decide se a área é moddável por arquivo novo ou se só dá para escrever na tabela
  `worldgen.*` de fora. O caminho passado é relativo e o `gsub` remove `media/lua/server/`, o que
  sugere resolução contra a raiz do jogo — mas `WorldGenUtils` é Java e não foi lido. **Nenhum dos 89
  mods de `STEAM/` foi cruzado** para isso nesta rodada.
- **Ordem de carga de mod contra `WorldGen.lua`.** Se o `.lua` do mod roda antes, `worldgen` ainda
  não existe; se depois, `Features`/`Biomes` já varreram. `require("WorldGen/WorldGen")` no topo (o
  idioma de todos os arquivos da pasta) resolve a primeira metade, não a segunda.
- **`generate = false`** aparece em `params` de `birch_forest` (`:47`). O nome sugere "não gerar
  sozinho, só como variante", mas nenhum arquivo em `media/lua` lê o campo — é Java.
- **`worldgen.similar`** é declarada e nunca preenchida. Se é resíduo ou se o Java a popula, não foi
  determinado.
- **A unidade de `p`.** Tratada aqui como probabilidade por tile pelos valores observados
  (0.0005 a 1.0), mas nada declara. `filter_edge = 5e8` em `Roads.lua` não tem unidade inferível.
- **A sintaxe completa de `placements`** — `*` e `!` foram observados; se há mais operadores, e se o
  padrão vale em outros campos, não foi levantado.
- **O formato de `schematic`** nos 2 prefabs (chaves `Floor` e possivelmente outras) não foi aberto
  além do cabeçalho.
- **A relação com a imagem de bioma do `biome_map_config`**, que [coleta-foraging.md](coleta-foraging.md)
  e [mapas-e-zonas.md](mapas-e-zonas.md) registram como não localizada. `biomes/map/` (17 arquivos,
  `worldgen.biomes_map`) é candidato natural a ter relação com ela — os nomes de bioma coincidem —,
  mas **a ligação não foi provada** e os dois sistemas podem ser independentes.
- **Como o terreno gerado se combina com as cidades feitas à mão** de `media/maps/`. Ver
  [mapas-e-zonas.md](mapas-e-zonas.md).
- **Nenhuma fonte da comunidade foi cruzada** nesta rodada.

> Última verificação: 2026-08-07 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

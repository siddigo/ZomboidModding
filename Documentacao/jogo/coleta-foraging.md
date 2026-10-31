# Coleta (foraging) — o sistema de busca do B42

O B42 reescreveu a busca por itens no chão. Esta página existe sobretudo para apontar duas coisas que
a IndieStone documentou dentro do próprio código e que ninguém acha por acaso.

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\`.

## Leia isto antes de qualquer coisa

**`PZ/media/lua/shared/Foraging/forageSystem.lua:1-38` é uma "MODDING FAQ" escrita pela IndieStone**,
em comentário de bloco no topo do arquivo. Responde como adicionar item à coleta, qual helper usar e
qual a precedência entre definições. Não é doc de terceiro — é o autor do sistema. Nenhuma outra área
do `media/lua` tem coisa parecida.

O que ela estabelece, e que muda como se escreve um mod de coleta:

- Um item precisa de **duas** coisas para ser encontrável: uma **categoria** com chance numa zona, e
  uma **itemDef** com chance nessa zona. Só a itemDef não basta.
- As definições têm de entrar **antes de `generateLootTable()`**. Depois disso, item novo não aparece.
- Dois caminhos de inserção, com **precedência invertida entre eles**: `addItemDef()` — *a primeira*
  definição vence; `populateItemDefs()` — *a última* vence. Os demais `populate<x>Defs` **pulam**
  entrada existente em vez de sobrescrever.
- Sobre escrever direto na tabela em vez de usar os helpers, o texto original responde:
  *"Short answer: No. You can put data directly into the forage definition tables. — If it breaks,
  you may keep both halves."*

A FAQ termina com um aviso que vale registrar: o autor **não garante** que dois mods mexendo nas
mesmas definições convivam.

## `forageDefinitions.lua` — o contrato campo a campo

`PZ/media/lua/shared/Foraging/forageDefinitions.lua:3` abre `forageSystem.defaultDefinitions` com
três tabelas de valores-padrão, **cada campo comentado na própria linha**:

| Tabela | Linha | O que define |
|---|---|---|
| `defaultItemDef` | `:4-55` | um item coletável — perícia, xp, zonas, meses, veneno, clima |
| `defaultZoneDef` | `:57-64` | uma zona — densidade de ícones, recarga, opção de sandbox |
| `defaultCatDef` | `:66-104` | uma categoria — chance, perícia para identificar, pisos válidos |

Como todo campo já vem comentado no arquivo, **não reproduzo a lista aqui** — abra o arquivo. O que
esta página acrescenta é o que se perde ao ler rápido:

- **`zones` e `chance` não são porcentagem.** O comentário grita: `--/!\ it is NOT a percent chance /!\`
  (`:25` e `:87`). É **número de rolagens** naquela zona. Tratar como porcentagem é o erro clássico —
  `zones = { Forest = 1 }` não é "1% no bosque".
- **`canBeAboveFloor` não faz nada.** Marcado `--does nothing, ignored` (`:44`). Está lá, aceita
  valor, e é ignorado.
- **`months` e `validMonths` coexistem em `defaultItemDef`** (`:35` e `:36`) com o mesmo comentário
  *"months when the item can be found"* — mas **não são dois campos que você escolhe**. Em item,
  `validMonths` é **derivado** de `months` e o que você escrever nele é descartado:

  ```lua
  def.validMonths = {};
  for _, thisMonth in ipairs(def.months) do
      def.validMonths[thisMonth] = 1;
  end;
  ```

  (`PZ/media/lua/shared/Foraging/forageSystem.lua:1290-1293`, dentro de `addItemDef`.) O `months` é
  uma **lista** (default: os 12 meses, `:35`); o `validMonths` resultante é um **conjunto**
  `mês → peso`, e é sobre esse peso que `bonusMonths`/`malusMonths` aplicam os multiplicadores logo
  em seguida (`:1294-1304`). Escrever `validMonths` numa itemDef é erro silencioso: a atribuição
  acontece, e a linha 1290 apaga.
- **Em categoria a regra é a oposta.** `defaultCatDef` tem `validMonths` (`:76`) e **não tem**
  `months` — ali você escreve `validMonths` direto. Os dois blocos têm campo de mesmo nome com
  contratos invertidos.
- `bonusMonths`/`malusMonths` exigem que o mês **também** esteja em `months`.
- Só `defaultCatDef` tem `spriteAffinities`, `chanceToMoveIcon` e `chanceToCreateIcon` (`:99-101`) —
  é o mecanismo que faz o ícone de coleta grudar num sprite específico do mundo (pedra, galho).

## Onde estão as definições reais

- **`PZ/media/lua/shared/Foraging/Categories/`** — 23 arquivos, um por categoria (`Berries.lua`,
  `Mushrooms.lua`, `Insects.lua`, `Stones.lua`, `Ammo.lua`, `Artifacts.lua`…).
- **`PZ/media/lua/shared/Foraging/`** (30 `.lua`) — `forageSystem.lua` (o motor),
  `forageDefinitions.lua`, `forageZones.lua`, `forageCategories.lua`, `forageSkills.lua`,
  `scavenges.lua`, `ISForageAction.lua`.
- **`PZ/media/lua/client/Foraging/`** (11 `.lua`) — só UI: `ISSearchWindow.lua`,
  `ISSearchManager.lua`, os ícones, `ISZoneDisplay.lua`.

O padrão de um arquivo de categoria, em `Categories/Berries.lua`: monta uma tabela local com
`generic`/`specific`, e uma função `generateBerryDefs()` percorre e chama
`forageSystem.addForageDef(...)` (`:66`). A função é **invocada na última linha do arquivo**, no
carregamento — não há evento envolvido. Um mod que copie esse formato deve chamar sua função
equivalente respeitando a ordem que a FAQ descreve.

`spawnFuncs` recebe uma lista de callbacks aplicados no momento da coleta —
`{ forageSystem.doPoisonItemSpawn, forageSystem.doWildFoodSpawn, forageSystem.doRandomAgeSpawn }`
(`Categories/Berries.lua:13`). É por aí que se faz item nascer envenenado ou com idade aleatória.

## As zonas do mapa — onde o `objects.lua` mora

O comentário de `defaultItemDef` manda conferir as zonas válidas em `objects.lua`. O arquivo fica em
**`PZ/media/maps/<Cidade>/objects.lua`**, e no build 42.20.2 existe **um só**:
`PZ/media/maps/Muldraugh, KY/objects.lua` (40.831 linhas). As demais cidades não têm — o jogo diz
isso no boot, uma linha por cidade (`USER/console.txt:465-471`):

```
WARN : Lua  at Lua(Vanilla).doMapZones > can't find map objects file: media/maps/West Point, KY/objects.lua
```

Cada linha é uma tabela plana com `type` como campo de zona
(`PZ/media/maps/Muldraugh, KY/objects.lua:2`):

```lua
{ name = "", type = "Nav", x = 12592, y = 966, z = 0, width = 8, height = 234 },
```

São **21 valores distintos de `type`** nesse arquivo. Censo com:

```sh
grep -o 'type = "[A-Za-z]*"' "media/maps/Muldraugh, KY/objects.lua" | sort | uniq -c | sort -rn
```

**Os nomes de zona de foraging não são todos `type` de mapa.** `Nav`, `Forest`, `DeepForest`,
`TrailerPark`, `FarmLand` e `Farm` existem no `objects.lua`; `ForagingNav`, `PHForest`, `PRForest`,
`OrganicForest` e `BirchForest` **não aparecem nenhuma vez**. Há duas pontes, e só uma delas é o
`containsBiomes` da seção seguinte.

### O `objects.lua` **descarta** os tipos de foraging

Quem lê o `objects.lua` é `doMapZones()`, em `PZ/media/lua/server/metazones/metazoneHandler.lua:82`.
A primeira coisa que ele faz com cada objeto é uma exclusão nominal (`:93`):

```lua
if v.type ~= "Vegitation" and v.type ~= "DeepForest" and v.type ~= "Forest" and v.type ~= "TownZone"
   and v.type ~= "Farm" and v.type ~= "FarmLand" and v.type ~= "TrailerPark" then
```

Os **sete tipos pulados são exatamente os nomes de zona de coleta** que existem no `objects.lua`.
Eles não viram metazona (`registerZone`, `registerVehiclesZone`, …) — o handler os ignora, e quem os
consome é outro subsistema, no Java. Ou seja: o `objects.lua` é a **fonte** desses nomes, mas não o
consumidor deles, e procurar o efeito de uma zona de coleta no `metazoneHandler` não leva a lugar
nenhum de propósito.

### A segunda fonte: o mapa de biomas por pixel

O que dá dono a `PRForest`, `OrganicForest`, `PHForest`, `BirchForest` e `ForagingNav` é um arquivo
que não fica em `maps/` nem tem "forage" no nome: **`PZ/media/lua/server/metazones/BiomeMapConfig.lua`**,
24 linhas, uma tabela global `biome_map_config` de 23 entradas:

```lua
biome_map_config = {
    { pixel = 0, zone = "Water" },
    { pixel = 64, zone = "ForagingNav" },
    { pixel = 179, biome = "pr_forest", ore = "map_forest", zone = "PRForest" },
    { pixel = 243, biome = "organic_forest", ore = "map_forest", zone = "OrganicForest" },
    { pixel = 254, biome = "dirt", ore = "dirt", zone = "ForagingNav" }, -- Dirt, will not spawn anything, but need to be here to validate spawns
    { pixel = 255, biome = "primary_forest", ore = "map_deep_forest", zone = "DeepForest" },
}
```

(`BiomeMapConfig.lua:1-24`, recorte.) O contrato de cada linha é
**`pixel` → `biome` / `ore` / `zone`**: um valor de cinza numa imagem de bioma do mapa resolve para
um nome de zona — o **mesmo espaço de nomes** de `zoneDefinitions`. Isso fecha os cinco órfãos: eles
são zona de bioma, pintada em imagem, não retângulo declarado em `objects.lua`.

Três detalhes que mudam como se lê a tabela:

- **`zone` não é único.** `ForagingNav` aparece em duas linhas (pixel 64 e 254) e `DeepForest` em
  duas (96 e 255) — vários pixels podem cair na mesma zona de coleta.
- **`biome` e `ore` são opcionais**: `{ pixel = 0, zone = "Water" }` tem só a zona. E `biome` aceita
  o valor especial `$random` (pixel 96).
- **O comentário do pixel 254 é a armadilha**: `"Dirt, will not spawn anything, but need to be here
  to validate spawns"` — uma entrada existe só para validar, sem gerar item. Presença na tabela não
  implica loot.

Quatro linhas estão **comentadas** no arquivo (pixels 34, 45, 166, 171 — `Water`, `WaterNoFish`,
`PHMixForest`, `Vegitation`). `Vegitation` é justamente um dos sete tipos pulados pelo
`metazoneHandler`, o que sugere zona legada mantida nos dois lados.

**Nada em `media/lua` lê `biome_map_config`** — a única ocorrência do nome em todo o `media/` é a
atribuição da linha 1. É global cru consumido pelo Java, o mesmo padrão de `AnimalDefinitions`
(ver [animais.md](animais.md)) e de `animals_path_config`, seu vizinho de pasta.

## `forageZones.lua` e o `containsBiomes` — zona de mapa vs bioma

`PZ/media/lua/shared/Foraging/forageZones.lua` define `forageSystem.zoneDefinitions` (`:1`), 17
zonas, cada uma no formato de `defaultZoneDef`. O comentário do campo `name` é o que amarra tudo:

```lua
name = "Unknown",  --zone type to attach this definition to - see objects.lua for possible zones
```

(`PZ/media/lua/shared/Foraging/forageDefinitions.lua:58`.) Ou seja, **a chave da `zoneDefinitions`
é o `type` do `objects.lua`** — não há tabela de tradução, é o mesmo espaço de nomes.

O que resolve os 5 nomes órfãos é o outro campo:

```lua
containsBiomes = {},  --loot tables contained within this zone. must be a valid loot table from another zone
```

(`forageDefinitions.lua:63`.) Uma zona pode **importar a tabela de loot de outra**, com um peso:

```lua
Nav = {
    name = "Nav", densityMin = 3, densityMax = 5, refillPercent = 3,
    abundanceSetting = "NatureAbundance",
    containsBiomes = {
        ["ForagingNav"] = 1
    };
},
```

(`forageZones.lua:39-48`.) `Nav` é a zona real do mapa; `ForagingNav` é uma **tabela de loot pura**,
que nunca precisa existir como `type` no `objects.lua`. Mesmo padrão em `Farm` ← `FarmLand`
(`:16-25`), `PHMixForest` ← `PHForest`/`Forest`/`DeepForest` (`:78-88`), `BirchMixForest` ←
`BirchForest` (`:126-135`), `FarmMixForest` e `FarmForest` (`:96-118`).

A injeção acontece em `addItemDef`: para cada zona que a itemDef **não** declara, se a zona tem
`containsBiomes`, o sistema calcula a média das chances das zonas contidas ponderada pelo
`chanceRatio` e grava o `math.ceil` disso (`forageSystem.lua:1275-1289`). Consequência prática:
**declarar chance só no bioma já faz o item aparecer na zona que o contém** — não é preciso repetir
a chance nas duas.

`PRForest` e `OrganicForest` continuam sem aparecer nem como `type` nem em `containsBiomes` de
ninguém — ver "Pontos a confirmar".

## `addItemDef` vs `addForageDef` — dois níveis, não sinônimos

São funções diferentes, sobre tabelas diferentes:

| Função | Linha | Grava em | Comportamento em colisão |
|---|---|---|---|
| `forageSystem.addItemDef(_itemDef)` | `:1262` | `forageSystem.itemDefs[type]` | ignora o novo (`if not ... then`, `:1313-1314`) |
| `forageSystem.addForageDef(_itemType, _forageDef)` | `:2153` | `forageSystem.forageDefinitions[type]` | ignora o novo e **loga** (`:2162`) |

(Ambas em `PZ/media/lua/shared/Foraging/forageSystem.lua`.) As duas honram "a primeira definição
vence", como a FAQ diz — mas só `addForageDef` avisa.

A diferença real é o **trabalho**: `addItemDef` é o caminho completo — valida que o item existe e que
o script é válido, checa a blacklist, aplica os defaults por `importDef`, calcula `itemSize`, injeta
as chances de bioma e deriva `validMonths` (`:1265-1304`). `addForageDef` é registro cru: duas
atribuições e nada mais. Elas alimentam tabelas distintas, consumidas em pontos distintos
(`forageDefinitions` em `:1380`, dentro de `populateItemDefs`).

## O boot: `forageSystem.init()` e a última janela segura

`PZ/media/lua/shared/Foraging/forageSystem.lua:705-730` é uma sequência fixa, cada evento disparado
**imediatamente antes** do passo que consome as definições:

| # | Evento | Passo que vem logo depois |
|---|---|---|
| 1 | `preAddForageDefs` | `setOptionValues()` |
| 2 | `preAddSkillDefs` | `populateSkillDefs()` |
| 3 | `preAddCatDefs` | `populateCatDefs()` |
| 4 | `preAddZoneDefs` | `populateZoneDefs()` + `populateMixedZoneCategories()` |
| 5 | `preAddItemDefs` | `populateScavengeDefs()` + `populateItemDefs()` |
| 6 | `onAddForageDefs` | **`generateLootTable()`** (`:730`) |

**`onAddForageDefs` é o evento mais tardio ainda seguro.** Ele dispara na linha 729; a geração da
tabela é a 730. Qualquer coisa depois disso não entra — é o "items will not be findable" da FAQ.

A escolha do evento não é livre: quem for mexer em categoria tem de fazê-lo em `preAddCatDefs` ou
antes, porque `populateCatDefs()` já rodou nos seguintes. O evento certo é **o anterior ao passo que
você quer influenciar**, não o último.

Dois detalhes que mudam como um mod se registra:

- `init()` sai cedo se já rodou (`isInitialised`, `:707`) e **limpa todas as tabelas** antes de
  começar (`clearTables()`, `:710`) — definição gravada fora do ciclo, antes do `init()`, é apagada.
- Os seis são `triggerEvent` de nome próprio, **não** eventos do `LuaEventManager`: os únicos
  `AddEvent` da área são `OnForagePool` (`client/Foraging/forageClient.lua:47`),
  `OnForageRequestZone` e `OnForageSpot` (`server/Foraging/forageServer.lua:497-498`). Nenhum
  arquivo do `media/lua` escuta os seis — ver "Pontos a confirmar".

## Pontos a confirmar

- **Onde está a imagem de bioma que o `biome_map_config` indexa.** A tabela mapeia valor de pixel
  para zona, mas não diz de qual arquivo. Nenhum nome em `maps/<Cidade>/` se anuncia como mapa de
  bioma, e as 4.928 `.png` de `maps/` não foram inspecionadas por conteúdo. Sem isso não dá para
  saber se um mod de mapa pinta biomas nem em que resolução.
- **Se um mod pode acrescentar linha a `biome_map_config`.** Sendo global Lua cru, `table.insert`
  funciona sintaticamente; se o Java lê a tabela depois do carregamento dos mods, e o que acontece
  com um `pixel` duplicado, não é decidível aqui.
- **Como um mod escuta os 6 eventos de `init()`.** São `triggerEvent` de nome próprio sem
  `LuaEventManager.AddEvent` correspondente em todo o `media/lua`, e nenhum arquivo do jogo os
  escuta — os 6 só existem no lado de quem dispara. Se `Events.onAddForageDefs.Add(...)` funciona
  mesmo assim, se é preciso o mod registrar o evento antes, ou se o registro está no Java, não é
  decidível aqui. **É a pergunta que bloqueia escrever mod de coleta pelo caminho recomendado pela
  própria FAQ.**
- **Quem chama `forageSystem.init()`.** Nenhuma chamada em `media/lua` — só a definição (`:705`) e
  duas menções em comentário (`:9`, `:33`). A invocação é Java, e com ela o ponto do boot em que a
  sequência inteira roda.
- Se `containsBiomes` aceita cadeia (zona A contém B, que contém C) e como o peso se compõe. O
  cálculo em `:1275-1289` percorre um nível só.

> Última verificação: 2026-08-07 — jogo **42.20.2** (`ffe7a8a4b1`), PZ buildid 24574865, media/
> + sessão in-game (`USER/console.txt` de 2026-08-07 18:46).

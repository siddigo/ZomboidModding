# Animais — a pilha de definição do B42

O sistema de animais do Build 42: onde a definição mora, quais tabelas precisam concordar e por que
**não existe bloco `.txt` de animal**. Aliases de caminho: `PZ/`, `WS/` (ver
[../index.md](../index.md)).

## Animal não é um bloco `.txt`

Todo o resto do conteúdo do jogo se declara em `media/scripts` (ver
[scripts-txt.md](scripts-txt.md)). Animal, não. Não há bloco `animal` no censo, e a varredura direta
confirma:

```
rg '^\s*animal\s+[A-Za-z]' PZ/media/scripts/     # nenhum resultado
```

A definição é **Lua**: 18 arquivos em `PZ/media/lua/shared/Definitions/animal/` que preenchem **seis
tabelas globais**. Quem procurar animal por analogia com item ou receita não acha nada — é a primeira
coisa que esta página existe para evitar.

O `.txt` só aparece **em volta** do animal (modelo, som, item derivado, entidade de estação); nunca
para declará-lo. Ver "Ao redor" no fim.

## As seis tabelas globais

Cada arquivo abre com o idioma `X = X or {}` e escreve por atribuição direta — não há função de
registro (ver "Quem lê"). Um mesmo arquivo costuma preencher quatro tabelas diferentes:
`ChickenDefinitions.lua` toca `stages` (linha 4), `breeds` (20), `genome` (61) e `animals` (79).

| Tabela global | Onde nasce | O que declara |
|---|---|---|
| `AnimalDefinitions.stages` | `ChickenDefinitions.lua:4` | ciclo de vida: `ageToGrow`, `nextStage`, `nextStageMale` |
| `AnimalDefinitions.breeds` | `ChickenDefinitions.lua:20` | raça: texturas, ícones de inventário, item de pluma/lã |
| `AnimalDefinitions.genome` | `ChickenDefinitions.lua:61` | quais genes a espécie tem (o catálogo está em `AnimalGenomeDefinitions.lua`) |
| `AnimalDefinitions.animals` | `ChickenDefinitions.lua:79` | **o animal em si** — modelo, animset, tamanho, fome, comportamento |
| `AnimalPartsDefinitions.animals` | `AnimalPartsDefinitions.lua:3-4` | o que sai ao abater: `parts`, `bones`, `head`, `skull`, `xpPerItem` |
| `AnimalTracksDefinitions` | `AnimalTracksDefinitions.lua:4` e `:50` | `trackType` (tipos de rastro) e `animallist` (quais rastros cada animal deixa) |

Mais três tabelas de sistemas acoplados, cada uma no seu arquivo:

| Tabela | Arquivo | Papel |
|---|---|---|
| `RanchZoneDefinitions.type` | `RanchZoneDefinitions.lua:3` | spawn de animal **domesticado** por zona de rancho |
| `MigrationGroupDefinitions` | `MigrationGroupDefinitions.lua:1` | spawn e comportamento de animal **selvagem** |
| `HutchDefinitions.hutchs` | `HutchDefinitions.lua:4` | galinheiros: custo de construção, sprites, capacidade |
| `AnimalAvatarDefinition` | `AnimalAvatarDefinition.lua:3` | enquadramento do avatar nas UIs (`zoom`, `avatarDir`, `hook`) |

`ButcheringUtil.lua` é o único arquivo da pasta que **não** define nada: é consumidor, lê
`AnimalPartsDefinitions` (`:79`, `:524`).

**Os arquivos são comentados pela IndieStone**, campo a campo — `RanchZoneDefinitions.lua:5-16` e
`MigrationGroupDefinitions.lua:7-29` são os melhores exemplos. Esta página não repete esses
comentários (regra 2 de [../index.md](../index.md)): o contrato de campo se lê no arquivo. O que não
se lê em lugar nenhum é a arquitetura — que é o resto daqui.

## Os seis espaços de chave

É o que custa grep e o que falha em silêncio. As tabelas **não usam a mesma chave**, e uma chave
errada não dá erro: o animal simplesmente não nasce, não rende parte nenhuma ou não deixa rastro.

| Tabela | Chave | Exemplo | Precisa bater com |
|---|---|---|---|
| `stages` / `breeds` / `genome` | **grupo** | `"chicken"` | o campo `group` do animal (`ChickenDefinitions.lua:125`) |
| `animals` | **tipo** (= estágio + sexo) | `"chick"`, `"hen"`, `"cockerel"` | `femaleType`/`maleType` da ranch zone; `male`/`female`/`baby` do grupo de migração |
| `AnimalPartsDefinitions.animals` | **tipo + raça, concatenados sem separador** | `"henrhodeisland"` | tipo × raça, uma entrada por combinação |
| `RanchZoneDefinitions.type` | nome do tipo de zona | `"chicken"`, `"chickensmall"`, `"chickenbig"` | o nome da zona no mapa (`RanchZoneDefinitions.lua:5`) |
| `MigrationGroupDefinitions` | grupo selvagem | `"deer"`, `"rabbit"` | `AnimalTracksDefinitions.animallist[...]` (`AnimalTracksDefinitions.lua:51`) |
| `HutchDefinitions.hutchs` | nome do hutch | `"hutchhen"` | a lista `hutches` do animal (`ChickenDefinitions.lua:103`) |

Duas consequências práticas:

- **Grupo ≠ tipo.** `"chicken"` é grupo; o que existe no mundo é `"hen"`. As duas chaves convivem no
  mesmo arquivo, e trocá-las é o erro fácil.
- **Raça nova multiplica trabalho.** Como `AnimalPartsDefinitions` é chaveada por tipo+raça, uma raça
  nova de galinha exige três entradas (`hen…`, `cockerel…`, `chick…`), não uma. É o que explica as 63
  entradas de butchering contra 30 tipos.

Censo medido nesta rodada, com o comando ao lado para reconferir:

| O que | Nº | Comando |
|---|---|---|
| grupos (`stages`/`breeds`/`genome`) | 10 | `rg -o 'AnimalDefinitions\.stages\["[a-z]+"\] = \{' \| sort -u` |
| tipos (`animals`) | 30 | `rg -o 'AnimalDefinitions\.animals\["[a-z0-9_]+"\]\s*=\s*\{ ?\}' \| sort -u` |
| raças | 21 | `rg -o 'breeds\["[a-z]+"\]\.breeds\["[a-z]+"\] = \{\}' \| wc -l` |
| entradas de butchering | 63 | `rg -c 'AnimalPartsDefinitions\.animals\["[a-z]+"\] = [a-z]'` |
| tipos de zona de rancho | 21 | `rg -c 'RanchZoneDefinitions\.type\["[a-z]+"\] = \{\}'` |
| grupos de migração | 5 | `deer`, `rabbit`, `small`, `large`, `predator` |
| hutches | 2 | `hutchhen`, `hutchturkey` |

Os 30 tipos não são 30 espécies: são estágio × sexo de 10 grupos (galinha rende `chick`, `hen`,
`cockerel`). A lista de nomes está nos arquivos — não se copia dado do jogo para cá.

## Como uma definição é escrita

Atribuição plana, uma linha por campo, sem tabela literal. Do arquivo canônico
(`PZ/media/lua/shared/Definitions/animal/ChickenDefinitions.lua:79-97`):

```lua
AnimalDefinitions.animals = AnimalDefinitions.animals or {};
AnimalDefinitions.animals["chick"] = {};
AnimalDefinitions.animals["chick"].bodyModel = "Chicken_Chick";
AnimalDefinitions.animals["chick"].animset = "chick";
AnimalDefinitions.animals["chick"].minSize = 0.9;
AnimalDefinitions.animals["chick"].maxSize = 1;
AnimalDefinitions.animals["chick"].genes = AnimalDefinitions.genome["chicken"].genes;
AnimalDefinitions.animals["chick"].stages = AnimalDefinitions.stages["chicken"].stages;
AnimalDefinitions.animals["chick"].breeds = copyTable(AnimalDefinitions.breeds["chicken"].breeds);
```

Repare no aninhamento duplo: a entrada de grupo tem um campo com o **mesmo nome da tabela** —
`AnimalDefinitions.stages["chicken"].stages` (`ChickenDefinitions.lua:5-6`), idem para `breeds`
(`:21-22`) e `genome`/`genes` (`:62-63`). Errar um nível aqui devolve `nil` em silêncio.

### Referência vs cópia — a linha que mais engana

Nas três últimas linhas acima, `genes` e `stages` entram **por referência**; `breeds`, por
`copyTable`. A diferença é comportamento em runtime:

- mexer em `animals["chick"].genes` ou `.stages` altera o grupo inteiro — todos os estágios de
  galinha veem a mudança;
- mexer em `animals["chick"].breeds` altera só aquele tipo.

O jogo faz isso de propósito (estágio e genoma são do grupo; raça é ajustada por tipo), mas para quem
edita de fora é uma pegadinha assimétrica.

## Quem lê as tabelas

**Não é Lua.** `AnimalDefinitions.getDef()` é chamada em cinco pontos — `ButcheringUtil.lua:79`,
`ISHutchUI.lua:176` e `:492`, `ClientCommands.lua:728` e `:812` — e **não existe `function
AnimalDefinitions.*` em `PZ/media/lua`** inteiro. O objeto devolvido responde a `:getBreedByName(...)`
(`ClientCommands.lua:728`), sintaxe de método Java. Ou seja: o Lua escreve, o motor lê e devolve
objeto próprio.

Ao mesmo tempo, parte dessas tabelas é percorrida com `pairs()` a partir do Lua —
`AnimalPartsDefinitions.animals` em `ButcheringUtil.lua:524`, `HutchDefinitions.hutchs` em
`buildRecipeCode.lua:461` —, o que só funciona sobre tabela Lua comum.

Os dois fatos convivem, mas **não determinam o mecanismo**: se o global Lua e a classe Java de mesmo
nome são o mesmo objeto, e em que ponto do boot o motor consome as tabelas, o `media/` não responde.
É a pendência que decide se dá para adicionar animal por mod — ver "Pontos a confirmar".

O que **é** certo: não existe `addAnimalDefinition()`, nem callback de "definições carregadas", nem
qualquer função de registro. O padrão do jogo é escrever direto no global, de um arquivo em
`lua/shared/`.

## Como o animal aparece no mundo

Duas vias independentes, e **nenhuma é padrão** — mesma estrutura de loot vs coleta
([distribuicao-loot.md](distribuicao-loot.md), [coleta-foraging.md](coleta-foraging.md)):

| | Domesticado | Selvagem |
|---|---|---|
| Tabela | `RanchZoneDefinitions.type` | `MigrationGroupDefinitions` |
| Amarra por | zona de rancho no mapa (`RanchZoneDefinitions.lua:5`) | grupo de migração |
| Aponta o tipo em | `femaleType` / `maleType` (`:8-9`) | `male` / `female` / `baby` (`MigrationGroupDefinitions.lua:4-6`) |
| Raça | `forcedBreed`, ou sorteio se `nil` (`:14`) | `possibleBreed`, lista separada por `,` (`:11`) |
| Filhote | `chanceForBaby` (`:15`) | `babyChance` (`:10`) |
| Extra | peso `chance` entre as zonas (`:7`) | ritmo de comer/dormir, velocidade, chance de rastro (`:12-28`) |

Um tipo definido em `animals` e ausente das duas tabelas existe para o motor e **não aparece em lugar
nenhum** — o modo clássico de falhar, igual ao item sem distribuição.

Rastro é sistema à parte, acoplado à migração: `AnimalTracksDefinitions.animallist` é chaveada pelo
mesmo nome do grupo de migração (`AnimalTracksDefinitions.lua:51`) e monta os rastros copiando os
tipos de `trackType` (`:53`), com `minskill` de rastreamento por tipo (`:11`).

## As camadas de um animal

| # | Camada | Onde | Observação |
|---|---|---|---|
| L1 | definição | as 6 tabelas globais | única camada obrigatória para o motor conhecer o animal |
| L2 | arte | `model` + textura + animset + ícone | quatro artefatos distintos, abaixo |
| L3 | mundo | ranch zone e/ou grupo de migração | nenhum é padrão |
| L4 | tradução | `IG_UI.json` | três padrões de chave distintos |
| L5 | uso | butchering, hutch, rastro, som, sandbox | o que faz o animal render algo |

É a mesma matriz de item, com L1 em Lua no lugar de `.txt` e L5 muito mais pesada.

### L2 — arte

Quatro artefatos, cada um com sua convenção:

| Campo | Valor de exemplo | Resolve em |
|---|---|---|
| `bodyModel` (`ChickenDefinitions.lua:81`) | `Chicken_Chick` | bloco `model` em `PZ/media/scripts/generated/models_animals.txt` (73 blocos) |
| `animset` (`:86`) | `chick` | **duas** pastas: `PZ/media/AnimSets/<animset>/` e `PZ/media/actiongroups/<animset>/` |
| `texture` da raça (`:26`) | `chicken` | `PZ/media/textures/Body/Chicken.png` |
| `invIcon*` da raça (`:29-37`) | `Item_Chicken_HenBrown` | ícone de inventário, prefixo `Item_` — ver [arte-e-modelos.md](arte-e-modelos.md) |

O bloco `model` de animal difere do de item: usa `mesh = Skinned/<nome>`, `shader = animalEffect` e
`animationsMesh` (`models_animals.txt:52-57`). Os 20 valores de `animset` usados pelas definições têm
**todos** pasta correspondente em `AnimSets/` — a pasta é por animset (portanto por estágio/sexo), não
por espécie; vários tipos compartilham a mesma.

**Animação de animal são duas pastas, não uma.** Os mesmos 20 valores de `animset` têm, também
**todos**, pasta homônima em `PZ/media/actiongroups/` (cruzamento de 20 contra as 28 subpastas de
`actiongroups/`: 20 batem, nenhum falta). São artefatos distintos: `AnimSets/` traz os clipes, e
`actiongroups/<nome>/` traz a **máquina de estados** que decide qual clipe roda — um
`actionGroup.xml` com o estado inicial, um `defaultTransitions.xml`, e uma pasta por estado
(`idle`, `walk`, `eating`, `alerted`, `falldown`, `onground`, `death`, `hitreaction`, `pathfind`,
`followwall`, `onhook`, `trailer` no caso do `buck`) com um `to_<destino>.xml` por saída. As
condições são declarativas sobre flags do motor
(`PZ/media/actiongroups/buck/defaultTransitions.xml:2-14`):

```xml
<transition>
    <transitionTo>falldown</transitionTo>
    <conditions>
        <isTrue>bDead</isTrue>
        <isFalse>bOnFloor</isFalse>
    </conditions>
</transition>
```

É a maior massa de dado de animal do jogo — 3.203 `.xml` em `actiongroups/`, dos quais 21 das 28
subpastas são de animal. Espécie nova precisa das duas pastas, não só de `AnimSets/`. Ver
[mapa-media.md](mapa-media.md).

Os ícones `Item_*` do jogo **não** estão soltos em `textures/`: estão dentro de `.pack`
(`PZ/media/texturepacks/`), mesma situação descrita em [arte-e-modelos.md](arte-e-modelos.md). Mod
usa PNG solto.

### L4 — tradução

Tudo em `PZ/media/lua/shared/Translate/EN/IG_UI.json`, em três padrões:

| Padrão | Exemplo | Linha |
|---|---|---|
| `IGUI_AnimalType_<tipo>` | `"IGUI_AnimalType_chick"` | `IG_UI.json:1900` |
| `IGUI_AnimalType_Global_<grupo>` | `"IGUI_AnimalType_Global_chicken"` | `IG_UI.json:1895` |
| `IGUI_Breed_<raça>` | `"IGUI_Breed_rhodeisland"` | `IG_UI.json:1884` |

São 207 chaves `IGUI_*Animal*` no total (`rg -o '"IGUI_[A-Za-z_]*[Aa]nimal[A-Za-z_]*"' | sort -u |
wc -l`), incluindo idade, corte de carne e rastro. Formato e localização do `.json` de mod:
[carregamento-de-mods.md](carregamento-de-mods.md).

### L5 — o que o animal rende

- **Butchering**: `AnimalPartsDefinitions.animals[<tipo><raça>]` com `parts`, `bones`, `head`,
  `skull`, `feather`, `xpPerItem` (`AnimalPartsDefinitions.lua:6-17`). `noSkeleton = true` (`:12`)
  troca esqueleto no chão por item inteiro.
- **Hutch**: `HutchDefinitions.hutchs` traz custo (`planks`, `nails`, `skill`), capacidade e sprites
  (`HutchDefinitions.lua:5-12`); o animal declara em quais entra (`ChickenDefinitions.lua:103`).
- **Som**: 22 arquivos em `PZ/media/scripts/generated/sounds/animals/`, um por espécie, no formato
  `sound` normal ([som.md](som.md)). O `event` segue `Animal/<Espécie>/<Categoria>/<Tipo>`
  (`sounds_animal_chicken.txt:8`).
- **Sandbox**: 14 opções `Animal*` — de `AnimalStatsModifier` a `AnimalPathChance`
  (`PZ/media/lua/shared/Sandbox/Rising.lua:130-143`), repetidas em `Apocalypse`, `Extinction` e
  `Outbreak`. `SixMonthsLater.lua` não as sobrescreve.

## Ao redor: o `.txt`, a UI e as ações

O `.txt` de animal existe, mas nunca define o animal:

| Artefato | Conteúdo |
|---|---|
| `generated/models_animals.txt` | 73 blocos `model` das malhas vivas e esqueletos |
| `generated/models_items_animals.txt` | modelos de **item** derivado (crânio, pena) |
| `generated/items/animal.txt` | **um único** `item Animal`, `ItemType = base:animal` (`:3`, `:6`) |
| `generated/sounds/animals/` | 22 arquivos de `sound` |
| `entities/animals/` + `generated/entities/animals/` | estações do B42 — 26 `entity`, 83 `item`, 14 `craftRecipe`, 26 `xuiSkin` |

`Base.Animal` é o item genérico de "animal capturado no inventário"; o único uso encontrado é a
armadilha (`PZ/media/lua/server/Traps/STrapGlobalObject.lua:248`, via `instanceItem`).

Runtime em Lua, para localizar rápido: 32 timed actions em
`PZ/media/lua/shared/TimedActions/Animals/` (ordenhar, tosquiar, abater, hutch, reboque), 10 painéis
em `lua/client/ISUI/Animal/`, mais `lua/client/FeedingTrough/` e os map objects
`lua/server/Map/MapObjects/MO{Hutch,FeedingTrough,ButcherHook}.lua`.

**Eventos**: só dois em todo o `media/lua` — `Events.OnAnimalTracks`
(`lua/client/Foraging/ISAnimalTracksFinder.lua:85`) e `Events.OnClickedAnimalForContext`
(`lua/client/ISUI/Animal/ISAnimalContextMenu.lua:1235`). Ambos já catalogados em
[eventos-lua.md](eventos-lua.md).

## O que isso significa para um mod

Levantado, não testado in-game (ver [testar-e-debugar.md](testar-e-debugar.md)):

- Não há API de extensão. O caminho aparente é um `.lua` em `<Mod>/media/lua/shared/` repetindo o
  idioma `AnimalDefinitions = AnimalDefinitions or {}` e escrevendo nas mesmas tabelas.
- **Nenhum dos 89 mods da Workshop instalados nesta máquina toca `AnimalDefinitions`**
  (`rg -l 'AnimalDefinitions' STEAM/` → zero). Não há, aqui, um só exemplo
  real de mod de animal para copiar — ao contrário de item, receita ou tradução. Isso é a amostra
  local, não a Workshop inteira.
- Raça nova é o pedido mais barato (uma entrada em `breeds` + as de `AnimalPartsDefinitions` + a
  chave `IGUI_Breed_*` + texturas); espécie nova é o mais caro, porque puxa modelo *skinned*, animset
  completo e as duas tabelas de spawn.

## Pontos a confirmar

- **Se, e quando, dá para adicionar animal por mod.** As tabelas são escritas como Lua cru e
  percorridas com `pairs()` (`ButcheringUtil.lua:524`, `buildRecipeCode.lua:461`), mas `getDef` vem do
  motor sob o mesmo nome do global (`ButcheringUtil.lua:79`) e não existe em `media/lua`. Os JavaDocs
  não-oficiais listam `AnimalDefinitions`, `AnimalGenomeDefinitions`, `AnimalPartsDefinitions`,
  `AnimalTracksDefinitions` e `MigrationGroupDefinitions` como classes Java em
  `zombie.characters.animals` — mesmos nomes dos globais Lua
  (`albion.codeberg.page/PZ-JavaDocs/zombie/characters/animals/package-summary.html`, consultado
  2026-08-06). Se são o mesmo objeto, e em que ponto do boot o motor lê, **não é decidível pelo
  `media/`**. É a pergunta que precede qualquer skill de animal.
- **Ordem de carga dentro de `Definitions/animal/`.** O idioma `or {}` sugere independência de ordem,
  mas nenhum arquivo agregador ou `require` foi encontrado. Mesma pendência aberta em
  [mapa-media.md](mapa-media.md) sobre a varredura de `lua/`.
- **Tipo, default e faixa das opções de sandbox de animal.** *Onde elas são agrupadas* fechou: a
  página `"Animal"` de `PZ/media/lua/client/OptionScreens/ServerSettingsScreen.lua:5061-5078` lista
  **13** — `AnimalStatsModifier`, `AnimalPregnancyTime`, `AnimalEggHatch`, `AnimalAgeModifier`,
  `AnimalMilkIncModifier`, `AnimalWoolIncModifier`, `AnimalRanchChance`, `AnimalGrassRegrowTime`,
  `AnimalMetaPredator`, `AnimalMatingSeason`, `AnimalSoundAttractZombies`, `AnimalTrackChance`,
  `AnimalPathChance`. Mas ali só há o **nome**: tipo, default e tooltip vêm do motor, via
  `serverOptions:getOptionByName(...)` e `option:getType()` (`:5091-5096`) — é `ServerOptions`, do
  Java, que declara. Ver [sandbox-options.md](sandbox-options.md).
- **`AnimalMetaStatsModifier` está nos presets e não na tela.** Os presets atribuem
  `SandboxVars.AnimalMetaStatsModifier` (`client/LastStand/28MinutesLater.lua:131`), mas o nome
  **não** aparece na página `"Animal"` da tela de servidor — 13 na tela contra 14 em uso. Ou é opção
  sem UI, ou é resíduo de preset; o `error('unknown server option …')` da tela (`:5092`) só pega o
  caso inverso e não ajuda aqui.
- **Qual sandbox option governa `animals_path_config`.** O comentário de
  `lua/server/metazones/AnimalsPathConfig.lua:5` diz `-- Defined by SandboxOption.AnimalPathChance`,
  mas o campo comentado é `chance = 0.2` e o preset grava `AnimalPathChance = 4`
  (`shared/Sandbox/Apocalypse.lua:143`) — escalas diferentes. Como um vira o outro é Java.
- **Como `Base.Animal` traduz o animal em ícone e nome.** *Por onde ele recebe o animal* fechou: os
  quatro pontos que criam o item fazem sempre o mesmo par —
  `local invItem = instanceItem("Base.Animal")` seguido de **`invItem:setAnimal(self.animal)`**
  (`shared/TimedActions/Animals/ISPickupAnimal.lua:45-46`; idem `ISHutchGrabAnimal.lua:43`,
  `ISRemoveAnimalFromTrailer.lua:42`, `server/Traps/STrapGlobalObject.lua:248`). O item é um
  **portador genérico**: o `Icon = WoolRaw` do script (`generated/items/animal.txt:3-8`) é só o
  default, e `setAnimal` é o que amarra a instância. O que resta é o lado de dentro — se o ícone sai
  do `invIcon*` da definição da raça, e por qual chave. **`invIcon` não tem nenhum consumidor em
  `media/lua`**, então essa metade é Java.
- **Quando o sistema entrou.** Não há material B41 no install para cruzar; a ausência de mods de
  animal entre os 89 instalados é indício, não prova.
- **Se `AnimalDefinitions` aceita `module`/namespace de mod**, como acontece no `.txt`. Sendo tabela
  Lua global, aparentemente não há namespace — dois mods que declarem o mesmo tipo se sobrescrevem em
  silêncio. Não testado.
- **Por qual campo o motor indexa `actiongroups/`.** Os 20 valores de `animset` batem com pastas de
  `actiongroups/`, mas os nomes de animset coincidem com os de tipo de animal, então o cruzamento não
  distingue "indexado por `animset`" de "indexado por tipo". Não há nenhuma citação a `actiongroups`
  em todo o `media/lua` — a leitura é Java. Importa para espécie nova cujo `animset` seja
  compartilhado com outro tipo.

> Última verificação: 2026-08-07 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

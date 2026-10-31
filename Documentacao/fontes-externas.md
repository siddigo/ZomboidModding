# Fontes externas — doc da comunidade

Quais fontes públicas de doc de modding existem, o que cada uma cobre, e quanto peso cada uma tem
contra o `media/`. Página **meta**: não documenta o jogo, documenta de onde vem informação sobre o
jogo. Baseline próprio (ver rodapé), não o `buildid`.

## Hierarquia de verdade

1. **`PZ/media/`** — o que o parser da IndieStone realmente lê. Ganha de tudo, sempre.
1b. **O bytecode de `PZ/projectzomboid.jar`** — o parser em si. É o próprio jogo, então ganha de
   qualquer doc; fica abaixo do `media/` só porque responde outra pergunta (o motor, não o dado). Ver
   "Ler o `.jar`", abaixo.
2. **Doc oficial da IndieStone** (ver "Documentos oficiais" abaixo) — escrita por quem fez o motor.
   Ganha da comunidade, mas **não** do `media/`: ela descreve a intenção, e o que está instalado é o
   que roda. Vale para o que o `media/` **não consegue mostrar** — o que foi *removido*, o que o Java
   exige, e a razão de uma mudança.
3. **Doc da comunidade auto-gerada** (as três primeiras da tabela) — parser rodado sobre o jogo.
   Serve para *descobrir* que algo existe; não serve de prova.
4. **Wiki e tutoriais editados à mão** — maioria B41, errada hoje (ver
   [jogo/scripts-txt.md](jogo/scripts-txt.md)). Só como pista.

A doc oficial entrou como nível próprio em 2026-08-10, quando o *Migration Guide* de 42.13 resolveu
uma pergunta que o `media/` **não podia responder**: o jogo base não usa o registro de IDs em Lua
(ele registra os seus no Java), então "como um mod declara identificador próprio" era invisível no
código do jogo. A confirmação veio dos mods da Workshop — ver
[jogo/scripts-txt.md](jogo/scripts-txt.md), seção do registro de IDs.

**A regra de confirmação não muda para ela.** Afirmação da doc oficial também só entra no corpo de
uma página com `caminho:linha` — no `media/` ou em `STEAM/`. O que não fechar vai para "Pontos a
confirmar" citando o documento. E em divergência com o `media/`, **o código continua ganhando**.

Afirmação que só existe na comunidade e **não** foi confirmada em `caminho:linha` no `media/` entra
em "Pontos a confirmar" com a URL — nunca no corpo da página como afirmação. Confirmada, é citada
pelo `caminho:linha` do jogo, não pela URL: a fonte da verdade passou a ser o código.

## As fontes

| Fonte | URL | Cobre | Versão | Geração |
|---|---|---|---|---|
| **PZ-API-Docs** | `pz-wiki-modding.github.io/PZ-API-Docs/` | Hub. `scripts` (100+ blocos, parâmetro a parâmetro), `mapping`, `translations`, `java`, `xml` | **42.20.2** (07/08) | Sphinx sobre `pz-scripts-data`, `pz-translation-data`, `pz-lua-parser`, `pz-java-parser` |
| **PZ JavaDocs** (Albion) | `albion.codeberg.page/PZ-JavaDocs/` | Assinaturas de classe/método do Java decompilado (`zombie.*`) | 42.20.0 | Decompilação; método não declarado |
| **PZ Lua Docs** (DemiurgeQuantified) | `demiurgequantified.github.io/ProjectZomboidLuaDocs/` | API Lua. **Tipos por inferência** — o próprio site avisa "heavily WIP" e que pode errar | 42.13.0 | Doxygen 1.14.0 |
| **ZedScripts** (PZwiki) | `pzwiki.net/wiki/ZedScripts` | Sintaxe de scripts, prosa | — | Editada à mão |

### Ler o `.jar` — a fonte que não é externa

Não é fonte da comunidade, mas está aqui porque muda a hierarquia acima: **dá para ler o Java do jogo
nesta máquina**, sem depender de decompilação de terceiro. `PZ/projectzomboid.jar` tem 62 MB e 26.020
entradas; `unzip` extrai e o `javap` da JDK 21 instalada lê classe por classe — `-p` para as
assinaturas (incluindo campo e método privados), `-c` para o bytecode, onde nome de método chamado,
constante literal e ordem das chamadas ficam legíveis.

Isso responde o que o `media/` não pode: o que o motor faz com o dado que ele lê. Foi assim que a
seção "Item em cima da mesa" de [jogo/distribuicao-loot.md](jogo/distribuicao-loot.md) fechou —
`ContainerOverlays`, `RandomizedBuildingBase`, `RBBasic` e o pacote `TableStories` não têm uma linha
sequer em `media/lua`.

Três limites, e nenhum é pequeno:

- **Não é código-fonte.** Assinatura e sequência de chamadas se leem; a lógica de um corpo de método
  se infere. Inferência vai para "Pontos a confirmar", como qualquer outra.
- **Baseline diferente do resto da árvore.** O rodapé de cada página carimba o `buildid` porque o
  `media/` muda com patch — mas patch que mexe **só** no `.jar` deixa todo o `media/` intacto e
  invalida silenciosamente uma afirmação vinda de bytecode. Foi exatamente o caso do patch de
  2026-08-22 ([index.md](index.md)). Marque na página de onde veio a afirmação.
- **Nomes obfuscados não aparecem aqui**, mas classe anônima e `$1` sim; e o que é `private` pode
  sumir entre builds sem aviso, porque não é contrato público.

### Documentos oficiais da IndieStone

PDFs distribuídos pela IndieStone, não publicados em site indexável — chegaram ao workspace pelo
usuário em **2026-08-10** (o download original é de **2025-12-15**). Desde **2026-08-24** estão
**vendorados no repositório**, em `oficial/`, pela exceção da regra 6 de [index.md](index.md).

| Documento | Versão | Arquivo local | Cobre |
|---|---|---|---|
| **Migration Guide** | 42.13 | `oficial/MigrationGuide-42.13.pdf` (129.237 B, md5 `0ca57998a09c26e108fd98c885df5c31`) | O registro de IDs (`media/registries.lua`) e os 11 identificadores registráveis; a remoção de `DisplayName` do bloco `item`; a renomeação de `Type` para `ItemType` |
| **API for Inventory Items** | doc v1.0, **42.13** | `oficial/API-for-Inventory-Items-v1.0.pdf` (311.189 B, md5 `1b4d1d5d14e302e7b4adea950c6a2558`) | A arquitetura de `ISBaseTimedAction` para multiplayer: `perform` dividido em `perform`+`complete`, `getDuration`, os nomes de argumento de `new` que o servidor usa para restaurar o objeto, ação longa (`serverStart`/`emulateAnimEvent`/`animEvent`), `sendClientCommand` e as 10 funções de sincronização |

O `API for Inventory Items` **não carimba versão de jogo no próprio arquivo** — só "Document version
1.0". A atribuição a **42.13** é do usuário, que forneceu os dois documentos como o mesmo pacote
(2026-08-24). O par de datas é consistente: os dois foram baixados juntos em 2025-12-15, e o
*Migration Guide* declara 42.13.

O acompanhante do primeiro é o mod de exemplo oficial, também vendorado em
`oficial/testmod_registries/`.

**Os dois já foram cruzados com o `media/`:**

| Documento | Cruzado em | Resultado |
|---|---|---|
| Migration Guide | 2026-08-10 | [jogo/scripts-txt.md](jogo/scripts-txt.md) |
| API for Inventory Items | **2026-08-24** | [jogo/timedactions.md](jogo/timedactions.md) (seção "A arquitetura multiplayer", ~215 linhas novas) e [jogo/persistencia-e-multiplayer.md](jogo/persistencia-e-multiplayer.md) |

**O cruzamento de 24/08 não achou divergência com o código** — caso raro nesta página, e vale
registrar por quê. Dois dos exemplos do PDF (`ISAddFuelAction`, `ISPlaceTrap`) são **literalmente** o
código instalado, e todos os símbolos que ele cita existem em `media/lua` com uso amplo
(`serverStart` 52, `animEvent` 51, `emulateAnimEvent` 42, as 10 funções de sync de 1 a 64 arquivos
cada). É doc oficial descrevendo o que está rodando, não intenção — o oposto do que a hierarquia
supõe por precaução.

Os dois são **primários**: descrevem decisões de quem escreveu o motor, incluindo coisas que o
`media/` não mostra — em particular **o que foi removido**, que por definição não aparece no código
instalado.

Seções do PZ-API-Docs, para saber quando vale abrir:

- **scripts** — o mais valioso. 100+ blocos (`item`, `craftRecipe`, `entity`, `fixing`,
  `evolvedrecipe`, `component *`, `vehicle`, `sound`, `physicsShape`…) mais 11 arquivos-raiz
  (`Blends`, `Default`, `MapBaseXML`, `MapInfo`, `ModInfo`, `Rules`, `SandboxOptions`, `Scripts`,
  `SpriteModels`, `TileGeometry`, `TMXconfig`).
- **java** — **não** é a API Java. É dado parseado: `ActionSoundTime`, `Colors`, `Item Tags`,
  `Magazine Subject`, `Metabolics`, `ItemBodyLocation`. Para assinatura, o link é o JavaDocs.
- **xml** — `animNode`, `clothing`, `clothingDecals`, `clothingItem`, `fileGuidTable`.
- **mapping** — seis páginas (`mapping/rooms.html`, `rooms_distributions.html`,
  `procedural_distributions.html`, `item_picker_container_properties.html`,
  `procedural_distributions_properties.html`, `tile_properties.html`). **Cruzada em 2026-08-07**, e é
  a seção mais útil depois de `scripts`, porque enumera *allowed values* de tile e as propriedades de
  distribuição procedural — nenhum dos dois legível no `media/`. Resultado do cruzamento em
  [jogo/distribuicao-loot.md](jogo/distribuicao-loot.md) e [jogo/tiles.md](jogo/tiles.md); é também
  onde está a divergência de `Facing` citada abaixo.
- **translations** — códigos de idioma e arquivos de tradução.

## O que a comunidade dá e o `media/` não dá

É o motivo do passo existir. Ler `media/scripts/*.txt` mostra os campos **usados**; não mostra o
**contrato do parser**, que mora no Java. Por parâmetro, o PZ-API-Docs publica:

- tipo (`string`, `float`, `integer`, `boolean`), `required`, se aceita vazio, `deprecated`;
- **default** — `item.Capacity` default `-1`;
- **min/max** — `item.Capacity` máximo `50`;
- **allowed values** — `item.ItemType` com 15 valores `base:*` (`base:alarmclock` … `base:weaponpart`),
  confirmados um a um contra `generated/items/` (ver [jogo/scripts-txt.md](jogo/scripts-txt.md));
- **campo `deprecated` com versão e substituto** — `item.Type` marcado *replacedBy `ItemType`* em
  42.13.0. É o dado que mais rende: identifica sintaxe morta que ainda circula em tutorial;
- fórmulas de gameplay e chaves de config (ex.: `CombatConfigKey.MAXIMUM_START_TO_HIT_CHANCE` em
  `HitChance`);
- hierarquia do bloco (pai/filho) e se aceita *soft override*.

Nada disso é legível no `media/` — e é exatamente a classe de erro que **falha em silêncio**.

O inverso também vale: a doc da comunidade não diz **onde está o exemplo canônico no install
local**, que é metade do valor de [jogo/mapa-media.md](jogo/mapa-media.md). As duas se complementam;
nenhuma substitui a outra.

## Padrão de URL — PZ-API-Docs

| O que | Caminho |
|---|---|
| Índice de blocos | `scripts.html` |
| Um bloco | `scripts/<nome-em-minúsculas>.html` |
| Um componente | `scripts/component/component-<nome>.html` |
| Um arquivo-raiz | `scripts/roots/<nome-em-minúsculas>.html` |
| Outras seções | `java.html`, `xml.html`, `translations.html`, `mapping.html` |

Os 11 arquivos-raiz (`Blends`, `Default`, `MapBaseXML`, `MapInfo`, `ModInfo`, `Rules`,
`SandboxOptions`, `Scripts`, `SpriteModels`, `TileGeometry`, `TMXconfig`) ficam sob `scripts/roots/`,
**não** sob `scripts/`: `scripts/roots/sandboxoptions.html` responde, `scripts/sandboxoptions.html` dá
**404** (verificado 2026-08-07). Cada um traz o campo *Root Pattern* — a regex do caminho de arquivo
que o parser casa —, que é dado que não existe em `PZ/media/`.

**O nome do bloco na URL é minúsculo**, mesmo quando é camelCase no `.txt`:
`scripts/craftrecipe.html` responde, `scripts/craftRecipe.html` dá **404** (verificado 2026-08-04).

## Baseline — por que não dá para comparar com o `buildid`

As fontes publicam versão semântica (42.20.0); o install local é rastreado por `buildid`
(`24775755` desde o patch de 2026-08-22, ver [index.md](index.md)). **Não há mapeamento mecânico entre os dois.** Pior: o número
de versão do install não está em nenhum arquivo — `appmanifest_108600.acf` só traz `buildid`, e não
existe arquivo de versão em `PZ/`. A única leitura é o `USER/console.txt`, que é **sobrescrito a
cada sessão do jogo**.

O formato da linha é (`console.txt:59-60`), aqui na leitura de 2026-08-07 — sessão das 18:46,
posterior ao patch das 11:50 e portanto válida para o `buildid` atual:

```
version=42.20.2 ffe7a8a4b1 demo=false
revision=ffe7a8a4b1 pzbullet=1.0.0.28
```

Consequência para esta página, **revista em 2026-08-07**: o PZ-API-Docs agora carimba **42.20.2** no
cabeçalho — a mesma versão do install *daquele dia*. Ele **alcançou** o código local; a defasagem de
dois patches registrada em 04/08 não existe mais. O JavaDocs e o LuaDocs não foram reverificados
nesta rodada.

**Em 2026-08-24 o install passou à frente de novo:** o patch de 22/08 levou o jogo a **42.20.3**
(`buildid 24775755`), e as três fontes não foram reconsultadas desde 07/08. A defasagem é de um
patch — que, no `media/`, é de **zero arquivo** (ver [index.md](index.md)); ela só pode afetar o que
as fontes derivam do `.jar`.

**Alcançar a versão não promoveu a fonte a prova.** Na mesma consulta, a seção `mapping` foi cruzada
com o `media/` e **errou num campo de alta frequência**: declara que `Facing` de tile aceita
`North`/`East`/`South`/`West`, quando o jogo escreve letra única (`S`, `E`, `N`, `W`) em 6.196
ocorrências, sem exceção — evidência em [jogo/tiles.md](jogo/tiles.md). Ou seja, o erro não era
defasagem de versão: é do parser ou da redação da fonte, e sobrevive ao alinhamento de versão.

Isso reforça a hierarquia em vez de amolecê-la: **versão igual não é motivo para confiar mais**. A
regra continua sendo confirmar cada achado no `media/` e citar `caminho:linha`.

Consequência prática: trate a doc da comunidade como podendo estar **à frente ou atrás** do install.
Isso não muda a hierarquia — divergência entre fonte externa e `media/` resolve-se sempre pelo
`media/`, e a diferença de versão é só mais um motivo pelo qual ela aparece.

## Pontos a confirmar

- **[resolvido 2026-08-24]** Vendoring completo. `Documentacao/oficial/` guarda os três artefatos
  primários: `testmod_registries/` (mod de exemplo do registro de IDs, desde 2026-08-15) e os dois
  PDFs, copiados de `~/Downloads` — que é onde estavam desde 2025-12-15, não perdidos como a
  pendência anterior supunha. Os md5 estão na tabela acima; confira-os antes de tratar uma cópia
  como a mesma fonte.
- **Se existem outros documentos oficiais** além destes dois, e por qual canal a IndieStone os
  distribui. Os dois em mãos se referem a "mod example" e a "new API documentation will gradually
  become available", o que sugere mais material.
- **[resolvido 2026-08-24]** A `API for Inventory Items` foi cruzada. **A premissa da pendência
  estava errada**: ela não contradizia [jogo/timedactions.md](jogo/timedactions.md) — a página já
  documentava `complete()` e `getDuration()` pelo exemplo canônico, e o que faltava era o *porquê*
  deles (a divisão por lado em multiplayer), não uma correção. Lição para as próximas: "a doc oficial
  contradiz a página" escrito sem cruzar é palpite, e este custou duas semanas de pendência falsa.
  O documento fechou quatro "a confirmar" daquela página e uma de
  [jogo/persistencia-e-multiplayer.md](jogo/persistencia-e-multiplayer.md).
- **O que o PDF afirma e o `media/` não consegue provar** ficou nas pendências das duas páginas: os
  27 tipos de argumento aceitos por `:new` (serialização em `PZNetKahluaTableImpl`, Java), e a
  garantia de que `perform` nunca roda no servidor. Nenhum dos dois é observável em `media/lua`.
- De qual build cada dataset (`pz-scripts-data`, `pz-translation-data`) foi de fato gerado. O site
  carimba **42.20.2** no cabeçalho (verificado 2026-08-07) e nomeia os quatro repositórios de origem,
  mas **não declara versão por dataset** — a página inicial foi consultada e não traz essa quebra.
- Se o **JavaDocs** e o **LuaDocs** também subiram de versão. A tabela desta página ainda registra
  42.20.0 e 42.13.0, de 04/08; só o PZ-API-Docs foi reverificado em 07/08.
- **Cobertura irregular por bloco, medida em 2026-08-04.** Onde o dataset tem dado, ele é excelente
  (`item`, `timedAction`); onde não tem, a página existe e diz *"this block has no parameters"* —
  visto em `energy`, `clock`, `template`, que no `media/` têm campos. **Página vazia da fonte não é
  prova de que o bloco não tem campo.** Também não enumera os valores de `flags` do `craftRecipe`,
  que o `media/` mostra serem 57.
- O índice `scripts.html` lista ~100 nomes **misturando níveis** — blocos de 2º nível (`item`,
  `clock`) convivem com filhos (`inputs`, `layer`, `hand`, `part`) e com blocos de outras famílias
  de arquivo, fora de `media/scripts`. Não serve de censo; para isso, a tabela de
  [jogo/scripts-txt.md](jogo/scripts-txt.md).
- Cobertura real do **LuaDocs**: o site declara tipos por inferência e status WIP; não foi medido
  quanto disso confere com `media/lua`.

> Última verificação: **PZ-API-Docs em 2026-08-07 (42.20.2)**; JavaDocs (42.20.0) e LuaDocs
> (42.13.0) em 2026-08-04, não reconsultados desde então. Doc oficial da IndieStone cruzada e
> vendorada em **2026-08-24**. Install local: jogo **42.20.3** (`70207f62e0`), PZ buildid
> **24775755** (patch de 2026-08-22).
>
> Reverificado em 2026-08-07: "Baseline", "Padrão de URL", a versão do PZ-API-Docs e a seção
> **mapping** (as seis páginas, cruzadas com o `media/`). O restante segue com a verificação de
> 2026-08-04. O baseline desta página são as fontes, não o `buildid` — elas se republicam sozinhas.

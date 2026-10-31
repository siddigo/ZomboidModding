# Documentação — referência de modding para Project Zomboid

Árvore de referência do workspace. Documenta o **jogo** (`ProjectZomboid/media`, que é código de
terceiro, somente leitura) e, opcionalmente, os **mods próprios** de quem usa o workspace (`mods/`). Não documenta a config do Claude Code
nem as convenções do workspace — isso vive em `.claude/CLAUDE.md`.

## Por que esta árvore existe

`media/lua` tem **1.395 arquivos `.lua`** (mais 1.248 `.json` de tradução) e `media/scripts` tem
**1.004 arquivos `.txt`**. Não dá para grepar isso a cada tarefa, e a IndieStone não publica
referência de API. Esta árvore existe para responder "onde fica o quê" e "qual é a sintaxe canônica"
sem varrer o jogo de novo.

O segundo motivo é mais concreto: **o B42 reestruturou `media/scripts` inteiro**. Quase todo material
de modding que se acha na internet é B41 e está errado hoje. Ver
[jogo/scripts-txt.md](jogo/scripts-txt.md) — a seção "O que mudou do B41 para o B42".

## Mapa

| Arquivo | Cobre |
|---|---|
| [jogo/mapa-media.md](jogo/mapa-media.md) | Onde fica o quê em `media/lua` e `media/scripts`; qual arquivo é o exemplo canônico de cada coisa; os arquivos soltos na raiz de `media/` e a segunda família de sintaxe `.txt` |
| [jogo/scripts-txt.md](jogo/scripts-txt.md) | Sintaxe dos `.txt`: `module`, `item`, `craftRecipe` (seletores, `mode:`, as 57 `flags`), `entity`, `xuiSkin`, `fixing`, `evolvedrecipe`, `character_trait_definition`, `character_profession_definition`, `timedAction`, `template`, `physicsShape`, `energy`, `clock`; e o `registries.lua` — incluindo o `AmmoType` de 2 argumentos, o item registrador sem o qual a munição de mod derruba o jogo no 1º tiro, e os 35 registros que o Java expõe contra os 11 do *Migration Guide*; mais o `OnCreate` do `item`, que é Java (`ItemCodeOnCreate`) e não Lua — o que ele faz, o que se perde ao omiti-lo, e o `.jar` desmontado com `javap` |
| [jogo/eventos-lua.md](jogo/eventos-lua.md) | Os 182 eventos `Events.*`, quais servem de ponto de entrada de mod, e o padrão de registro |
| [jogo/carregamento-de-mods.md](jogo/carregamento-de-mods.md) | `mod.info`, `workshop.txt`, pasta de versão vs `common/` — inclusive o contraexemplo de pasta de versão **vazia** com `mod.info` em `common/`; traduções, ordem de carga; **um upload carrega N mods** — o que "modpack" é de fato, o dedup silencioso por `id=` e o censo de mods-por-item |
| [jogo/distribuicao-loot.md](jogo/distribuicao-loot.md) | As duas tabelas de loot (`Distributions`, `ProceduralDistributions`) e o trio `On*DistributionMerge` por onde um mod entra; e **o item solto em cima de mesa/bancada**, que não é nenhuma das duas — overlay de sprite × `IsoWorldInventoryObject`, as randomized world stories, o sorteio preguiçoso do contêiner e o sandbox que limpa o chão |
| [jogo/coleta-foraging.md](jogo/coleta-foraging.md) | Busca do B42: a MODDING FAQ da IndieStone, as três tabelas de default, zona vs bioma (`containsBiomes`), os 6 eventos de `init()` e o que falha em silêncio |
| [jogo/fazenda-e-pesca.md](jogo/fazenda-e-pesca.md) | Os seis sistemas de recurso: nenhum tem bloco `.txt` nem função de registro — a definição é tabela global Lua, e o idioma da 1ª linha (reset duro vs. `X or {}`) decide se um mod sobrevive; mais as tags `base:*` ↔ `ItemTag.*` que substituíram tabela Lua em fogo e pesca |
| [jogo/tiles.md](jogo/tiles.md) | `.tiles` / `.tiles.txt` / `.pack` — três artefatos acoplados, os 5 arquivos-satélite da raiz de `media/` (geometria, assento, costura, modelo por sprite), o que um mod pode embarcar deles e os 13 `.lua` que o TileZed gera; mais o par `Surface` × `container`, que decide se o móvel se abre, recebe coisa em cima, ou os dois |
| [jogo/mapas-e-zonas.md](jogo/mapas-e-zonas.md) | A pasta `maps/`, os 4 `.lua` opcionais por cidade, `map.info`, o `doMapZones()` que registra metazona (e os 7 `type` que ele pula), a cadeia de zona de spawn e o `WorldGen/` |
| [jogo/veiculos.md](jogo/veiculos.md) | O bloco `vehicle`: os 9 sub-blocos, o `template`/`template!` que só existe aqui, os campos físicos e o bloco `lua { }` que amarra cada peça a `Vehicles.*` |
| [jogo/animais.md](jogo/animais.md) | O animal do B42: as tabelas Lua de `Definitions/animal/`, os espaços de chave que precisam bater, ranch vs migração, e por que não existe bloco `.txt` de animal |
| [jogo/definitions-lua.md](jogo/definitions-lua.md) | Os 13 `.lua` de `shared/Definitions/`: que global cada um declara, chave de entrada, os 6 sem consumidor Lua, o `X = X or {}` que decide se um mod consegue somar, e o validador que só roda com `-debug` |
| [jogo/worldgen.md](jogo/worldgen.md) | A geração procedural de terreno: a tabela `worldgen`, o carregamento por varredura de diretório, feature/bioma/subbioma, as faixas de `Selection.lua`, veios e prefabs |
| [jogo/construcao.md](jogo/construcao.md) | O menu de construir do B42: `entity` com `UiConfig`+`SpriteConfig`+`CraftRecipe`, os campos `On*` que nomeiam Lua do `.txt`, e por que `ISBuildingObject` não é mais o caminho |
| [jogo/arte-e-modelos.md](jogo/arte-e-modelos.md) | Ícone (`Icon` e o prefixo `Item_` implícito), textura, o bloco `model` campo a campo e os 6 campos de `item` que apontam para ele; e a chama animada — `AttachAnim` é o mecanismo único de fogueira **e** de personagem em chamas (que ancora o sprite num osso do modelo 3D); por que modelo 3D animado (`static = false` + `animationsMesh`) existe para animal, personagem e porta mas é fechado para item equipado, que é malha estática presa a um osso; e a cadeia real `WeaponSpritesByIndex` → `StaticModel` → `WeaponSprite` |
| [jogo/roupa.md](jogo/roupa.md) | A pilha de roupa: `ClothingItem` casa por nome de arquivo, `BodyLocation` é ordem de render, o GUID e o `fileGuidTable.xml` que soma, e o `IconsForTexture` posicional |
| [jogo/animacao.md](jogo/animacao.md) | As cinco pastas de animação, o `<animNode>` de `AnimSets/`, onde os `Blends` moram de verdade, o par `primaryAnimMask`/`secondaryAnimMask` do bloco `item` (pose de segurar, com valor que o jogo casa sem olhar a caixa), e o censo que mostra que mod mexe em `anims_X/`+`AnimSets/` e em mais nada |
| [jogo/anims-formato.md](jogo/anims-formato.md) | O arquivo de clipe: DirectX `.X` **texto** (não binário), a malha duplicada em cada um dos 2.209, por que a chave é o nome do arquivo e não o `AnimationSet` interno, o `!` de `animationPrefix`, e a inversão `.fbx` (mod) × `.X` (jogo) |
| [jogo/som.md](jogo/som.md) | O bloco `sound`, a inversão `event=` (jogo) vs `file=` (mod), os 42 campos de `item` que apontam para som, e por que `addSound` não toca nada |
| [jogo/musica-e-radio.md](jogo/musica-e-radio.md) | Os três `.lua` de config de música (intensidade assinada, `duration = -1`, valores × 0,01) e o `RadioData.xml` único, com `freq` e `day` |
| [jogo/ui-lua.md](jogo/ui-lua.md) | UI de mod: a hierarquia `ISUIElement`→`ISPanel`→`ISCollapsableWindow`, o ciclo de vida, a ponte `instantiate()` para o Java — e por que **não** copiar de `media/luaexamples/` |
| [jogo/xui.md](jogo/xui.md) | O sistema XUI de ponta a ponta: merge de `xuiSkin` por nome (não por arquivo), o esquema `xuiConfig`, a cadeia `UiConfig`→`XuiManager`→`ISXuiSkin.build`→`autoApplyTableKeys`, e por que o estilo ausente é invisível fora do `-debug` |
| [jogo/timedactions.md](jogo/timedactions.md) | A classe `ISBaseTimedAction` (≠ do bloco `timedAction` do `.txt`), os callbacks, e o `adjustMaxTime` que faz `maxTime` não ser a duração real; e a **arquitetura multiplayer** — `perform` roda no cliente e `complete` no servidor, `getDuration` em ciclos de 0,02 s, o nome do argumento de `:new` como chave de transferência (e o idioma de trocá-lo de propósito para o valor **não** atravessar), a ação longa por `serverStart`+`emulateAnimEvent`+`animEvent`, e as 10 funções de sincronização |
| [jogo/persistencia-e-multiplayer.md](jogo/persistencia-e-multiplayer.md) | `ModData` global vs `:getModData()` por objeto, `transmit`, e o par `ClientCommands`/`ServerCommands` com as assinaturas que diferem entre os dois lados; as variantes `…V`; por que em singleplayer o despachante do **servidor** está ligado e o do cliente não (e o comando é assíncrono mesmo lá); e quando a via é comando em vez de TimedAction |
| [jogo/perks-e-xp.md](jogo/perks-e-xp.md) | Skill nova **é** criável, mas só por `media/perks.txt` (arquivo que só existe em mod) e nunca por Lua — zero `addPerk` no jogo e em mod nenhum; mais `AddXP`, `SkillBook`, traço/profissão e o `parent = None` que vira cabeçalho de categoria |
| [jogo/saude-e-corpo.md](jogo/saude-e-corpo.md) | Ferimento, moodle e a UI de saúde: as duas pastas do nome têm 1 arquivo cada (uma delas morta), os 17 `BodyPartType` contra o enum irmão `BloodBodyPartType`, os 13 handlers de tratamento que são `local`, e por que não existe evento de dano |
| [jogo/testar-e-debugar.md](jogo/testar-e-debugar.md) | O ciclo de teste in-game: onde o jogo escreve, como ler o stacktrace de Lua, o modo debug e o que recarrega sem reiniciar; mais a **exceção Java pura**, que salva e volta pro menu em vez de fechar (então `GameThread exited.` não desmente um crash), e onde o log da sessão quebrada foi parar depois de reabrir o jogo — rotação no boot seguinte e a janela de 5 sessões do `logs.zip` |
| [jogo/opcoes-de-mod.md](jogo/opcoes-de-mod.md) | `PZAPI.ModOptions`: os 11 controles, a janela de registro que faz a aba sumir, o formato do `ModOptions.ini` e por que keybind é caso à parte |
| [jogo/sandbox-options.md](jogo/sandbox-options.md) | `media/sandbox-options.txt`: o arquivo que só existe em mod, os 5 `type`, o namespace que vira subtabela de `SandboxVars`, as chaves `Sandbox_*` e o gate do `page` |
| [fontes-externas.md](fontes-externas.md) | *(meta)* Doc da comunidade: o que cada fonte cobre, padrão de URL e o peso dela contra o `media/` |

`mods/` e `oficial/` podem morar aqui (gitignorados) ou na pasta pessoal descrita em
`.claude/CLAUDE.md`, com o mesmo caminho relativo — por isso as páginas citam `Documentacao/oficial/…`
e `../oficial/…` dos dois jeitos.

`mods/` é **por usuário e opcional** — não vem no repositório público. Quando existe, `mods/index.md`
é ao mesmo tempo o índice da subárvore e o inventário dos mods de `WS/` (layout, identidade,
`mod.info`/`workshop.txt`/tags, camadas presentes, divergências). O baseline ali **não é o `buildid`**:
mod próprio muda por commit, não por patch da Steam.

`oficial/` é **cópia local e opcional** — também não vem no repositório público, porque é material da
IndieStone distribuído fora de site indexável. É material primário que não é `.md` nosso. Três itens
desde 2026-08-24 — `testmod_registries/` (mod de exemplo do registro de IDs),
`MigrationGuide-42.13.pdf` e `API-for-Inventory-Items-v1.0.pdf`. Ver regra 6 abaixo. Não tem índice
próprio (poucos itens); catalogado na seção "Documentos oficiais da IndieStone" de
[fontes-externas.md](fontes-externas.md), com md5, e citado direto nas páginas de `jogo/` que o usam.

## O que falta

**Pendências pontuais** ficam em cada página, na seção "Pontos a confirmar" — é lá que elas moram, e
não são copiadas para cá para não desencontrar. Para ver todas de uma vez:

```sh
awk '/^## Pontos a confirmar/,/^> /' Documentacao/*.md Documentacao/jogo/*.md Documentacao/mods/*.md
```

O delimitador final é `^> ` e **não** `^> Última` de propósito: sob locale não-UTF8 (Git Bash no
Windows é o caso) o acento não casa e o comando devolve vazio sem erro. Para só contar:
`… | grep -c '^- '`.

**O censo de blocos `.txt` fechou.** Todo bloco de `media/scripts` tem descrição — em
[jogo/scripts-txt.md](jogo/scripts-txt.md) ou numa página dedicada. O que resta em aberto ali é
semântica de campo, não forma, e está nos "Pontos a confirmar" daquela página.

**A shortlist de áreas sem página zerou** (2026-08-08). As seis que estavam aqui — mod próprio,
fazenda e pesca, `shared/Definitions/`, saúde e corpo, formato de `anims_X/` e XUI — viraram página.
Não significa que o jogo está coberto: significa que acabou o que *já tinha aparecido* no
levantamento. A próxima entrada nasce de uma tarefa esbarrando na lacuna, como estas nasceram.

**Como montar a próxima shortlist — e o erro a não repetir.** Duas das seis linhas apontavam para o
lugar errado, e as duas foram descobertas só quando alguém foi escrever a página:

- *Saúde e corpo* mandava começar por `lua/server/HealthSystem/` e `lua/client/ISUI/BodyParts/`. São
  **1 arquivo cada**, e um deles é código morto (o registro do evento está comentado). O ponto de
  partida real era `lua/client/XpSystem/ISUI/ISHealthPanel.lua`, com 1.987 linhas.
- *`anims_X/` (formato)* dizia "2.209 arquivos **binários**". São texto — DirectX `.X` variante
  ASCII, com a gramática declarada dentro de cada arquivo.

As duas linhas foram escritas a partir do **nome da pasta**, não de ter aberto o conteúdo. É barato
o bastante para valer a regra: antes de pôr uma área nesta lista, abra um arquivo dela e conte
quantos são. Uma linha errada aqui custa mais que a lacuna, porque manda o próximo trabalho para o
lugar errado com ar de pista confiável.

## Regras da árvore

1. **Toda afirmação vem de `path:linha` real.** O parser da IndieStone falha em silêncio ou derruba o
   carregamento; sintaxe plausível não serve. Se não deu para confirmar no `media/`, escreva
   **"a confirmar"** — não escolha um lado.
2. **Não copie dado do jogo.** A árvore documenta *contrato* e *localização*, não conteúdo. Não
   existe lista de itens aqui; existe "os itens ficam em `PZ/media/scripts/generated/items/`,
   um arquivo por `ItemType`".
3. **Regra de ouro — documente o que custa um grep.** O código é legível; o que é caro é *achar*.
   Entram: onde mora cada coisa, qual é o exemplo canônico, o que mudou do B41 para o B42, e o que
   falha em silêncio. Não entra: reexplicar linha a linha o que o arquivo já diz.
4. **Doc da comunidade entra como pista, nunca como prova.** As fontes públicas
   ([fontes-externas.md](fontes-externas.md)) mostram o que ler o `media/` não mostra — default,
   min/max, valores permitidos, contrato do parser. Use para *descobrir*, depois confirme no
   `media/` e cite o `caminho:linha`. O que não confirmar vira "a confirmar" com a URL. Divergência
   entre fonte externa e código: **o código ganha**, sem exceção.
5. **Toda página declara o build de referência no rodapé** (ver abaixo).
6. **Escrita permitida:** só os `.md` desta pasta. Nunca escrever em `ProjectZomboid/` — é leitura,
   e há `deny` em `.claude/settings.json` cobrindo `**/steamapps/**`.
   **Exceção deliberada:** `oficial/` guarda cópia local de material primário da IndieStone que não
   é nosso `.md` e não é alcançável de novo por URL nem por `STEAM/` — mod de exemplo, PDF de guia
   de migração. Não é gerado pela skill `doc-pz` (que só escreve `.md`); é vendorado à mão quando o
   usuário fornece o arquivo. Citado como fonte primária nas páginas de `jogo/`, com
   `caminho:linha` normal.

## Convenção de versão — o carimbo de build

O baseline aqui **não é commit git**: o código documentado é o jogo, instalado pela Steam. O
equivalente exato é o `buildid` do manifesto da Steam, em
`C:\Program Files (x86)\Steam\steamapps\appmanifest_108600.acf` (108600 = App ID do PZ):

```
"buildid"      "24909800"
"LastUpdated"  "1787756856"     # 2026-08-26 15:07 UTC
"BetaKey"      "public"
```

Toda página de `jogo/` fecha com:

```
> Última verificação: 2026-08-26 — PZ buildid 24909800 (branch public, atualizado 2026-08-26), media/.
```

**A checagem de defasagem é uma comparação de uma linha:** ler o `buildid` do `appmanifest` e comparar
com o rodapé. Igual → a doc está válida, o jogo não mudou um byte. Diferente → reconferir. Não existe
"varredura periódica" aqui; o gatilho é o patch da Steam, e nada mais.

Páginas futuras em `mods/` usam o outro baseline — commit git do repo do próprio mod, já que ali o
código é nosso e muda sem patch. E [fontes-externas.md](fontes-externas.md) usa um terceiro: data da
consulta + a versão que cada site publica. São três baselines porque são três coisas que mudam por
motivos diferentes — patch da Steam, commit nosso, republicação de terceiro.

O `buildid` **não se compara** com a versão semântica que as fontes da comunidade carimbam. O número
de versão do install não está em arquivo nenhum: só no `USER/console.txt`, que é sobrescrito a cada
sessão do jogo — e a leitura só vale se o `console.txt` for **posterior** ao último patch.

Leitura válida em 2026-08-07 (sessão das 18:46, posterior ao patch das 11:50):

```
version=42.20.2 ffe7a8a4b1 demo=false
```

Ou seja, o buildid `24574865` correspondia a **42.20.2** — e o PZ-API-Docs passou a carimbar
**42.20.2** também (verificado 2026-08-07), tendo alcançado o install. Isso **não** promove a fonte:
na mesma consulta ela errou os valores de `Facing` de tile, que o `media/` contradiz em 6.196
ocorrências. Ver a seção "Baseline" de [fontes-externas.md](fontes-externas.md) e
[jogo/testar-e-debugar.md](jogo/testar-e-debugar.md).

Leitura seguinte, em 2026-08-24 (`console.txt:59`, sessão de 23/08, posterior ao patch de 22/08):

```
version=42.20.3 70207f62e0 demo=false
```

O buildid `24775755` corresponde a **42.20.3**.

Leitura seguinte, em 2026-08-26 (`console.txt:59`, sessão das 12:31, posterior ao patch das 12:07):

```
version=42.20.4 b0bbce05d5 demo=false
```

O buildid `24909800` corresponde a **42.20.4**.

### O patch de 2026-08-22 não tocou o `media/`

O diff por `mtime` (a técnica do passo 2 do modo RECONFERIR) devolve **zero arquivo**:

```sh
find media -type f -newermt "2026-08-08"    # 0
find media -type f -newermt "2026-07-01"    # 5.280, entao o find funciona
```

Só `projectzomboid.jar` tem mtime novo (2026-08-22 20:11). **Consequência para a árvore inteira:**
toda citação `caminho:linha` das páginas carimbadas com `24574865` continua válida — o rodapé está
atrás do buildid, o conteúdo não. Reconferir uma página por causa deste patch é gasto sem retorno; o
que ele pode ter mudado é comportamento do Java — que **é** verificável aqui, por `javap` sobre
`projectzomboid.jar`, mas exige saber o que procurar: não existe diff barato do `.jar` como o `mtime`
dá para o `media/`. Ver [fontes-externas.md](fontes-externas.md), "Ler o `.jar`".

As páginas [jogo/timedactions.md](jogo/timedactions.md) e
[jogo/persistencia-e-multiplayer.md](jogo/persistencia-e-multiplayer.md) já carregam o carimbo novo,
porque foram reconferidas em 24/08 por outro motivo (a doc oficial vendorada em `oficial/`).

### O patch de 2026-08-26 tocou 23 arquivos — e é o contraste útil

`24775755` → `24909800` (jogo 42.20.3 → 42.20.4). Aqui o diff por `mtime` **não** devolve zero, e o
que ele devolve cabe numa tela:

```sh
find . -type f -newermt "2026-08-25" -not -path "./Workshop/*"    # 23
```

`projectzomboid.jar`, quatro `.lua` — `client/ISUI/ISInventoryPaneContextMenu.lua`,
`client/ISUI/ISWorldObjectContextMenu.lua`, `client/PZAPI/ui/organisms/PrintMedia.lua`,
`shared/TimedActions/ISReadABook.lua` — e os 19 `Translate/<IDIOMA>/Print_Media.json`. **Nada de
`media/scripts`.**

Cruzando com `grep -rl <basename> Documentacao/`, só duas páginas citam arquivo tocado, e as duas
foram reconferidas nesta rodada:

| Página | Arquivo tocado que ela cita | Veredito |
|---|---|---|
| [jogo/fazenda-e-pesca.md](jogo/fazenda-e-pesca.md) | `ISWorldObjectContextMenu.lua` (`:1653`, `:1621`) | IGUAL — as duas citações continuam de pé |
| [jogo/carregamento-de-mods.md](jogo/carregamento-de-mods.md) | `EN/Print_Media.json` | **MUDOU** — 341 → 327 chaves, 339 → 325 com prefixo; corrigido |

**O que o `.jar` levou junto não é verificável aqui**, e é a parte que mais interessa a quem faz mod:
o changelog oficial anuncia a **remoção de `loadstring` e `loadstream`** da API Lua, por segurança.
Ficou registrado como pendência em
[jogo/persistencia-e-multiplayer.md](jogo/persistencia-e-multiplayer.md) — a página dona do
substituto que a própria IndieStone indica, o par `ClientCommands`/`ServerCommands`.

As demais páginas seguem com o carimbo anterior **de propósito**: o `mtime` prova que o patch não
alcançou o que elas citam, e recarimbar sem reconferir afirmaria verificação que não houve.

## Como escrever/atualizar

Use a skill `/doc-pz`. Ela gera página nova e reconfere página existente contra o `buildid` atual,
delegando a varredura ao subagente `pz-explorer`.

A skill também se invoca sozinha, no meio de outro trabalho, quando algo levantado no `media/` não
está aqui ou contradiz o que está — nesse caso ela grava só o delta e **não** mexe no rodapé, para o
carimbo não afirmar uma verificação que não houve. Página com rodapé atrás do `buildid` atual segue
pedindo um `/doc-pz` dedicado.

## Abreviação de caminho usada nas páginas

| Alias | Caminho absoluto |
|---|---|
| `PZ/` | `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\` |
| `WS/` | `~\Zomboid\Workshop\` |
| `USER/` | `~\Zomboid\` |
| `STEAM/` | `C:\Program Files (x86)\Steam\steamapps\workshop\content\108600\` |

`STEAM/` são os **94** itens da Workshop baixados pela Steam (376 `mod.info` — um item pode conter
vários mods) — código de terceiro, leitura apenas, usado como evidência de uso real. Censos escritos
nas páginas antes de 2026-08-11 falam em 89 itens e não foram refeitos. **Não fica dentro de `PZ/`**: `common\ProjectZomboid` e `workshop\content`
são pastas irmãs sob `steamapps\`, então `PZ/steamapps/...` é caminho inválido.

Specs geradas pelo `planejador` **não** usam esses aliases — lá o caminho é sempre absoluto, porque o
executor não lê esta árvore.

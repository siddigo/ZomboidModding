# Carregamento de mods — `mod.info`, layout, tradução, Workshop

Como o jogo encontra, carrega e publica um mod. Aliases:
`PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\`,
`WS/` = `~\Zomboid\Workshop\`, `USER/` = `~\Zomboid\`,
`STEAM/` = `C:\Program Files (x86)\Steam\steamapps\workshop\content\108600\`.

## Onde o jogo procura mod

Três lugares distintos, com papéis diferentes:

| Caminho | Papel |
|---|---|
| `PZ/mods/` | mods que vêm com o jogo — só `examplemod` |
| `USER/mods/` | mods instalados manualmente (não-Steam) |
| `STEAM/` | mods assinados na Steam (**94** itens instalados aqui) — **irmã** de `PZ/`, não dentro dela |
| `WS/` | **fonte em desenvolvimento** — pasta de upload, **lida pelo jogo** |

**Atenção ao número de `STEAM/` ao ler os censos desta página:** eram **89** itens quando os censos
de tradução, de tags e de `workshop.txt` foram levantados (2026-08-04 e 2026-08-07); hoje são 94
(assinaturas novas). Os censos marcados com "89" **não** foram refeitos — o número maior aparece só
onde a medição é de 2026-08-11 e diz isso.

`WS/` é o working copy do autor: cada subpasta é um pacote de upload. O jogo lê
`WS/<Mod>/Contents/mods/<Mod>/` direto, então **não é preciso copiar nada para `USER/mods/` para
testar** — desenvolve e testa na mesma pasta. `USER/mods/` continua sendo o caminho de instalação
manual de mod de terceiro. Ver [testar-e-debugar.md](testar-e-debugar.md).

## Layout do pacote (B42)

```
WS/<PastaDoUpload>/
  workshop.txt            # metadados do upload
  preview.png             # thumbnail da Workshop
  Contents/
    mods/
      <NomeDoMod>/        # nome do mod para o jogo
        42/               # pasta por versão do build
          mod.info
          poster.png
          media/{lua,scripts,...}
        common/
          media/{textures,models_X,...}
```

**A pasta de versão é o que o B42 trouxe.** Ela carrega o que é específico do build (`mod.info`,
`poster.png`, `media/lua`, `media/scripts`); `common/` carrega o que não muda entre builds
(texturas, `models_X`, tiles). O jogo só lê a pasta de versão correspondente ao build em uso.

O nome exato da pasta de versão **varia entre mods e importa**: nos 12 mods de `WS/` convivem `42` e
`42.0`. Confira no mod antes de criar arquivo — não presuma.

#### O contraexemplo: pasta de versão vazia, tudo em `common/`

A divisão acima é a prática dominante, **não uma exigência verificada**. `STEAM/3402516345/mods/B42Survival/`
inverte a regra por completo: a pasta `42/` existe e está **vazia** — zero arquivos, só os diretórios
`42/` e `42/media/` — e **tudo** vive em `common/`, inclusive o que a divisão manda pôr na pasta de
versão:

```
mods/B42Survival/
  42/media/                          <- 0 arquivos
  common/
    mod.info                         <- aqui, nao na pasta de versao
    poster.png
    icon.png
    media/registries.lua
    media/sandbox-options.txt
    media/scripts/generated/items/
    media/lua/shared/Translate/{EN,PT,PTBR,TU}/
```

Não é mod abandonado nem legado: `versionMin=42.14.0`, `modversion=1.2`, publicado e **atualizado em
2026-08-05**. É um quarto arranjo, ao lado dos três já catalogados.

**O que isso prova e o que não prova.** Prova que o arranjo existe num mod mantido; **não** foi
testado in-game aqui, então não afirme que "funciona igual". O que ele torna insustentável é a
leitura de que a pasta de versão seja *obrigatoriamente* a dona do `mod.info` — se fosse, este mod
não apareceria na tela de seleção.

Detalhe secundário do mesmo mod: ele usa `common/media/scripts/generated/items/` e
`.../generated/recipes/`, **imitando dentro do mod o caminho `generated/` do próprio jogo**. É
escolha de organização do autor, não requisito — nenhum outro mod levantado faz isso.

### Um upload carrega N mods — e não existe "formato de modpack"

`Contents/mods/` é plural de propósito. A única restrição do validador é que não haja **arquivo**
solto ali (`FileNotAllowedInMods`, ver "O que sobe") — pastas de mod, quantas quiser, cada uma com
seu `mod.info`. Um modpack **é** isto: um upload com várias pastas. Não há artefato de agrupamento.

Cada pasta vira um mod **independente na tela de seleção**, com checkbox próprio. A lista é montada
varrendo diretórios, um `mod.info` por vez —
`PZ/media/lua/client/OptionScreens/ModSelector/ModSelectorModel.lua:61-78`:

```lua
for _, directory in ipairs(getModDirectoryTable()) do
    local modInfo = getModInfo(directory)
    if modInfo and not self.mods[modInfo:getId()] then
```

Três contratos que só aparecem nesse trecho:

- **`id=` duplicado some em silêncio.** O `not self.mods[modInfo:getId()]` (`:63`) é dedup por `id`:
  o segundo mod com o mesmo `id` **não entra na lista**, sem aviso. Pasta copiada de template sem
  trocar o `id` desaparece em vez de dar erro — mais uma falha silenciosa, e a que mais ameaça
  justamente o layout multi-mod.
- **A ordem da lista é por `name=`, não por pasta nem por `id`** — `table.sort` sobre `a.name`
  (`:79-81`). É o que explica `STEAM/3260995510` (BTSE) nomear seus 20 mods `1`, `2`, `3`…: é o
  único controle de ordem que o autor tem na tela.
- **`category=` não agrupa nada** (`:70`, `:73`). Existe a entrada `modpack` → `Item_SewingBox`
  (`:10`), mas ela só escolhe **ícone** de fallback — ver a seção de `icon`/`category`. O motor não
  tem noção de pacote, só de mods soltos.

Quanto isso é usado — censo dos 94 itens de `STEAM/` (376 `mod.info`), levantado 2026-08-11:

| Mods no item | Itens |
|---|---|
| 1 | 70 |
| 2 | 8 |
| 3–5 | 10 |
| 7–9 | 3 |
| 18, 20, 58 | 3 |

**74% entrega um mod só.** O multi-mod é de pacote pesado: 58 em `STEAM/3279769341` (coleção de
veículos), 20 em `STEAM/3260995510`, 18 em `STEAM/3260996595`, 9 em `STEAM/1911132112`, 8 em
`STEAM/3262863785` (tiles).

O que amarra os sub-mods é `require=`, declarado por **158 dos 376 `mod.info`** (42%). O desenho
recorrente é core + addons dentro de **um** upload: `STEAM/3260995510` traz `1 Base` sem `require` e
os outros 19 com `require=BTSE_Base`. Variante de opt-out em `STEAM/1299328280` (More Traits), onde
sub-mods existem só para desligar parte do principal.

Nenhum dos 376 `mod.info` declara `category=modpack` — os únicos valores observados são `Vehicles`
(7), `vehicle` (2) e `features` (2).

Exemplo real completo, `WS/SiddigoWeapons/`:

```
Contents/mods/SiddigoWeapons/42/media/lua/client/mod_teste.lua
Contents/mods/SiddigoWeapons/42/media/scripts/SiddigoWeapons_Items.txt
Contents/mods/SiddigoWeapons/42/media/scripts/recipes/recipes_SiddigoWeapons.txt
Contents/mods/SiddigoWeapons/42/mod.info
Contents/mods/SiddigoWeapons/42/poster.png
Contents/mods/SiddigoWeapons/common/media/models_X/WorldItems/SkullCrusher.fbx
Contents/mods/SiddigoWeapons/common/media/textures/Item_SkullCrusher.png
preview.png
workshop.txt
```

Note que **`media/` do mod espelha `media/` do jogo**: `media/scripts/*.txt` e `media/lua/{client,
server,shared}/` seguem exatamente a mesma estrutura documentada em [mapa-media.md](mapa-media.md).
É o que faz o mod somar ao conteúdo base em vez de substituí-lo.

**A exceção é `media/registries.lua` `[novo 42.13]`** — um arquivo de nome fixo, solto na raiz de
`media/`, que **não** tem correspondente no jogo (`find media -iname registries.lua` no `PZ/` devolve
zero). É onde o mod registra identificador de namespace próprio — tag de item, traço, profissão,
`BodyLocation` — **antes** de qualquer `.txt` ser lido. Sem ele, ID próprio não existe para o parser.
Contrato completo, censo dos 9 mods que o usam e a regra de quem registra o quê:
[scripts-txt.md](scripts-txt.md), seção "O registro de IDs".

Nos mods reais ele aparece nos dois lugares — 8 em `<versao>/media/registries.lua`, 1 em
`common/media/registries.lua`.

## `mod.info`

Formato `chave=valor`, uma por linha, sem espaço em volta do `=`, sem seções. Exemplo real —
`WS/SiddigoWeapons/Contents/mods/SiddigoWeapons/42/mod.info`:

```
name=Siddigo's Weapons
id=siddigoWeapons
description=This mod adds some craftable Weapons, inspired by others games
poster=poster.png
author=siddigo
modversion=1.0
versionMin=42.8
```

| Campo | Papel |
|---|---|
| `id` | **identificador interno.** É o que outro mod referencia em `require=`. Não muda depois de publicar — quebra saves e assinaturas |
| `name` | nome exibido na lista de mods |
| `description` | uma linha só |
| `poster` | arquivo na mesma pasta do `mod.info` |
| `icon` | ícone na **linha** do mod; arquivo na mesma pasta do `mod.info`, igual ao `poster`. Ver abaixo |
| `category` | só serve de fallback do `icon` ausente; 4 valores reconhecidos. Ver abaixo |
| `author` | |
| `modversion` | versão do *mod*, livre |
| `versionMin` | build mínimo do jogo (`42.0`, `42.8`) |
| `versionMax` | build máximo — opcional |
| `require` | ids de mods dependentes |
| `incompatible` | ids de mods incompatíveis; a lista alimenta o painel de conflito (`ModSelectorModel.lua:120`, `ModInfoPanelInteractionParam.lua:58`). 18 mods de `STEAM/` declaram |
| `loadAfter` / `loadBefore` | ordem de carregamento explícita, lidos em `ModLoadOrderPanel.lua:52` e `:68`. **Zero mods de `STEAM/` declaram** — campo real, uso não observado |
| `url` | opcional; usado em `PZ/mods/examplemod/mod.info` |

**`id` não precisa ser igual ao nome da pasta**, e o jogo aceita a diferença: uma pasta de upload
`MeuMod/` com `Contents/mods/OutroNome/` e `id=outroNome` carrega normalmente (observado em
mod local). O nome da pasta em `Contents/mods/` e o `id` são independentes entre si também.

O `examplemod` do jogo (`PZ/mods/examplemod/mod.info`) é pré-B42 e **não tem** `author`,
`modversion` nem `versionMin` — não use como referência de campos, só de estrutura de pastas.

### `icon` e `category` — duas imagens diferentes, e a que falta é silenciosa

`poster` e `icon` não são o mesmo papel: o **poster** é o cartaz grande do painel de detalhes
(`ModInfoPanelDesc.lua:36-37`, via `modInfo:getPoster(0)`), o **ícone** é a miniatura na linha do mod.

A cadeia do ícone, em `PZ/media/lua/client/OptionScreens/ModSelector/`:

- `ModSelectorModel.lua:69` — `data.icon = modInfo:getIcon()`, o campo `icon=` do `mod.info`.
- `ModSelectorModel.lua:73` — `if data.icon == "" then data.icon = ModSelector.Model.categories[data.category] end`.
  É o **único** uso de `category`: sem `icon=`, ele escolhe um ícone genérico.
- `ModSelectorModel.lua:5-10` — a tabela tem só quatro entradas úteis: `map` → `Item_Map`,
  `vehicle` → `Item_CarTire`, `features` → `Item_ElectronicsScrap`, `modpack` → `Item_SewingBox`.
  A entrada `""` mapeia para `""`.

**Sem `icon=` e sem `category=`, o mod fica com um quadrado cinza vazio.** É o ramo `else` de
`ModListBox.lua:200-203`: só desenha textura quando `item.item.icon ~= ""`; caso contrário desenha
`Texture.getWhite()` com alfa `0.1`. Não há aviso no `console.txt` — é falha silenciosa de aparência,
não de carregamento.

Tamanho de desenho, que é o que decide a resolução do arquivo:

| Tela | Onde | Tamanho |
|---|---|---|
| Lista de mods | `ModListBox.lua:201` | `BUTTON_HGT` × `BUTTON_HGT`, com `BUTTON_HGT = FONT_HGT_SMALL + 6` (`ModListBox.lua:8`) — depende da fonte do jogador |
| Ordem de carregamento | `ModOrderListBox.lua:235` e `:264` | fixo **28×28** |

**O arquivo não é autodetectado — a declaração é obrigatória.** Censo dos 367 `mod.info` de
`STEAM/`: 159 declaram `icon=`, e **zero** têm um `icon.png` na pasta sem declarar o campo. A forma
dominante é `icon=icon.png` (109), depois `icon=logo.png` (16); o valor é nome de arquivo na pasta do
`mod.info`, nunca caminho dentro de `media/textures/`. Nas resoluções em uso, 64×64 (27 mods) e 32×32
(25) dominam.

Exemplo real com os dois campos: `STEAM/3446915394/mods/simbatraduz/42/mod.info` declara
`poster=poster.png` **e** `icon=icon.png`, com um `icon.png` de 64×64 ao lado.

## `workshop.txt`

Metadados do upload, na raiz da pasta de upload (irmão de `Contents/`). Exemplo — um
`workshop.txt` escrito à mão, ainda não enviado:

```
version=1
title=Siddigo's Weapons
description=This mod adds some craftable Weapons, inspired by others games
description=
description=Weapons:
description=- Skull Crusher - Stone sledgehammer inspired by "Last Day on Earth"
tags=weapon,b42
visibility=public
```

- **`description=` repete uma vez por linha** do texto da Workshop. `description=` vazio produz linha
  em branco. Não existe escape de `\n`.
- **`id=<numérico>` aparece só depois do primeiro upload** — o uploader da Steam escreve de volta no
  arquivo — ex.: `SiddigoWeapons` (`id=3612982532`).
  Apagar essa linha faz o próximo upload criar um item novo em vez de atualizar o existente.
- **`tags=` é lista separada por ponto-e-vírgula** — não vírgula. Prova: dois mods de `WS/` que já
  subiram tiveram o arquivo **reescrito pelo próprio jogo** (`writeWorkshopTxt()`, ver abaixo) e
  saíram com `tags=Build 42;Items;Weapons` (`WS/SiddigoWeapons/workshop.txt`) e
  `tags=Build 42;Language/Translation` (`WS/SiddigoTranslationPTBR/workshop.txt`). A vírgula só
  aparece no exemplo acima, escrito à mão e nunca enviado — e lá as tags (`weapon`, `b42`)
  também não existem. Os valores válidos são os 31 de `PZ/media/WorkshopTags.txt`: `Build 40`,
  `Build 41`, `Build 42`, `Animals`, `Audio`, `Balance`, `Building`, `Clothing/Armor`, `Farming`,
  `Food`, `Framework`, `Hardmode`, `Interface`, `Items`, `Language/Translation`, `Literature`, `Map`,
  `Military`, `Misc`, `Models`, `Multiplayer`, `Pop Culture`, `Realistic`, `Silly/Fun`, `Skills`,
  `Textures`, `Traits`, `Vehicles`, `QoL`, `WIP`, `Weapons`.
- **`visibility=` tem quatro valores**: `public`, `friendsOnly`, `private`, `unlisted` — nessa ordem,
  lidos em `PZ/media/lua/client/OptionScreens/WorkshopSubmitScreen.lua:300-308`. O campo é gravado a
  partir de um índice: `setVisibilityInteger(self.visibility.selected - 1)` (`:349`), ou seja
  `public`=0, `friendsOnly`=1, `private`=2, `unlisted`=3. Valor desconhecido cai em `public`
  (`:308-309`).

## O uploader é o próprio jogo

Não há ferramenta externa: a submissão para a Workshop é uma tela do menu principal, em
`PZ/media/lua/client/OptionScreens/WorkshopSubmitScreen.lua` (1.629 linhas, 8 páginas de wizard).
Isso responde três coisas que mudam como se trabalha:

- **A pasta de staging é `USER/Workshop`, e é a única.** A tela exibe literalmente
  `Core.getMyDocumentFolder() .. getFileSeparator() .. "Workshop"` como o caminho onde pôr o conteúdo
  (`:41`), e enumera o que está lá com `getSteamWorkshopStagedItems()` (`:107`). É o mesmo caminho em
  que os mods deste workspace já são desenvolvidos — **não existe passo de cópia antes de publicar**.
- **Quem escreve o `workshop.txt` é o jogo, não você.** `item:writeWorkshopTxt()` é chamado ao sair
  da página de metadados (`:351`) e de novo depois de fixar o `id` (`:650`). O arquivo à mão só serve
  para semear o primeiro upload; da primeira publicação em diante ele é sobrescrito com o que a tela
  tem. Por isso o formato dos dois mods publicados é a referência, e não o que se digitou.
- **A lista de tags vem do motor**, via `SteamWorkshopItem.getAllowedTags()` (`:312`) — a mesma que
  `PZ/media/WorkshopTags.txt` materializa. Tag fora da lista não tem como ser marcada pela tela;
  escrita à mão no `workshop.txt`, ela sobrevive só até o primeiro `writeWorkshopTxt()`.
- **Não há seletor de idioma em lugar nenhum do wizard.** O item tem **um** título
  (`self.titleEntry`, `:165`) e **uma** descrição (`self.description`, `:174`, mais o botão de editar
  em janela maior, `:183`) — e nada que escolha idioma nas 8 páginas. Ou seja: **a página da Workshop
  em mais de um idioma, se existir, é operação do site da Steam, fora do jogo.** Ver "Pontos a
  confirmar".
- **A tela sobe uma imagem só: a thumbnail.** É `self.item:getPreviewImage()` (`:318`), desenhada em
  256×256 (`:289`) sob o rótulo `UI_WorkshopSubmit_ItemPreview` (`:211`) — o `preview.png` da raiz da
  pasta de upload, irmão de `Contents/`. **Não existe no wizard nada que anexe galeria de imagens ou
  vídeo ao item**, o que faz da galeria da página, como a descrição por idioma, operação do site.
  Note que `preview.png` (thumbnail da Workshop) e `poster.png` (cartaz na lista de mods, dentro da
  pasta de versão, apontado por `poster=` no `mod.info`) são papéis diferentes, ainda que vários mods
  de `WS/` usem o mesmo arquivo nos dois.

O `id` é preenchido pelo fluxo: a página 3 pergunta se o item é novo ou existente, a 4 recebe o ID
digitado e regrava o arquivo (`:648-650`). Erro de publicação cai numa página dedicada, com o texto
vindo de `getText("UI_WorkshopError_" .. err, ...)` (`:1232`) — o código do erro é da API da Steam,
não do jogo.

**`workshop.txt` não é distribuído.** Dos 89 mods baixados em `STEAM/`, **um** traz o arquivo; a
pasta de um mod instalado começa direto em `mods/`. Ou seja: é metadado de upload, some na
publicação, e **não dá para censar `visibility` nem `tags` a partir dos mods instalados** — só pela
tela acima. O motivo geral é a fronteira abaixo.

### O que sobe: a fronteira é `Contents/`

**A raiz de conteúdo do upload é `WS/<PastaDoUpload>/Contents/`, e nada acima dela sobe.** É o texto
do próprio jogo, em `PZ/media/lua/shared/Translate/EN/UI.json:988`
(`UI_WorkshopError_MissingContents`): *"There is no Contents/ folder in the folder you chose. All the
files and folders to upload must be inside a folder called Contents/."*

Confirmado por censo: nos 89 mods de `STEAM/`, `mods/` é a **única** entrada de topo em todos —
nenhum traz `Contents/`, `workshop.txt` ou `preview.png` na raiz. O que a Steam distribui é o
conteúdo *de dentro* de `Contents/`.

`validateContents()` — chamado em `PZ/media/lua/client/OptionScreens/WorkshopSubmitScreen.lua:122` e
`:843` — é Java (`zombie/core/znet/SteamWorkshopItem.class`, com as literais `Contents`,
`getContentFolder` e `buildings/ creative/ mods/`). As mensagens de erro dele estão em
`PZ/media/lua/shared/Translate/EN/UI.json:988-998` e delimitam os dois primeiros níveis:

| Erro | Regra |
|---|---|
| `MissingContents` (`:988`) | tem que existir `Contents/` |
| `FolderNotAllowedInContents` (`:989`) | direto em `Contents/`, só `buildings/`, `creative/`, `mods/` |
| `FileNotAllowedInContents` (`:990`) | nenhum arquivo solto em `Contents/` — só pastas |
| `FileNotAllowedInMods` (`:996`) | nenhum arquivo solto em `Contents/mods/` — só pastas de mod |
| `EmptyContentsFolder` / `EmptyModsFolder` (`:997`, `:998`) | nenhuma das duas pode estar vazia |

**Abaixo desse nível não há filtro nenhum.** O que estiver dentro de `Contents/mods/<Mod>/` sobe
inteiro, seja qual for o tipo de arquivo — inclusive artefato de versionamento. Evidência real na
Workshop: `STEAM/3281755175` (VanillaVehiclesAnimated) distribui **seis repositórios `.git`
completos** (com `COMMIT_EDITMSG`, `FETCH_HEAD`, `index` de 51 KB), em
`mods/VanillaVehiclesAnimated/media/.git`, `.../common/media/.git`, `.../common/workshop/.git` e os
três equivalentes em `mods/VanillaVehiclesAnimated_SVUpatch/`, mais `.gitignore` e `.gitattributes`.
`STEAM/2313387159` (BetterSorting) traz `.gitattributes`, `README.md` e `LICENSE` dentro de
`mods/BetterSorting/`.

Duas consequências para quem versiona mod:

- **`git init` na raiz da pasta de upload é seguro** — `.git/` e `.gitignore` ficam irmãos de
  `Contents/`, fora da fronteira. `git init` *dentro* de `Contents/` publica o repositório inteiro.
- **`.gitignore` não é filtro de upload.** O uploader não lê o arquivo; a única exclusão que existe
  é a fronteira de pasta.

## Tradução — mudou de formato no B42

**O B42 usa `.json`, não `.txt`.** `PZ/media/lua/shared/Translate/` tem 29 idiomas, cada um com ~44
arquivos `.json`, num total de 1.248. Formato — `PZ/media/lua/shared/Translate/EN/ItemName.json`:

```json
{
    "Base.SpadeHead": "Spade Head",
    "Base.SpadeHead_Forged": "Spade Head"
}
```

Cada pasta de idioma **do jogo** traz também `language.json`:

```json
{
    "version": "1",
    "language_name": "Português Brasileiro"
}
```

**Mod não entrega `language.json`.** Censo direto sobre os 89 mods de `STEAM/`: **197 pastas de
idioma de mod contendo `.json`, e zero com `language.json`.** O arquivo registra um idioma no motor;
acrescentar string a idioma que já existe não precisa dele. Só faria sentido para um mod que
adicionasse idioma novo ao jogo — caso que não aparece em nenhum dos 89.

**`CH` é chinês tradicional e `CN` é simplificado** — o inverso do que a sigla sugere.
`PZ/media/lua/shared/Translate/CH/language.json` diz `"Chinese (Traditional)"` e `CN/language.json`
diz `"Chinese (Simplified)"`. `ES` é `"Español (España)"`, com `ES_CL` e `ES_MX` separados.

Arquivos por assunto (mesma lista em todos os idiomas): `ItemName.json`, `Recipes.json`,
`EvolvedRecipeName.json`, `IG_UI.json`, `ContextMenu.json`, `Tooltip.json`, `Entity.json`,
`Fluids.json`, `Farming.json`, `Moveables.json`, `Sandbox.json`, `UI.json`, `Attributes.json`,
`Moodles.json`, `Print_Media.json`, `Stash.json`, `SurvivalGuide.json`, além de um por cidade do mapa
(`Muldraugh, KY.json`, `West Point, KY.json`, …).

Convenção de chave:

| Coisa | Chave |
|---|---|
| item | `Modulo.Item` em `ItemName.json` — ex. `"Base.SpadeHead"` |
| `craftRecipe` | **o nome puro da receita** em `Recipes.json` — ex. `"MakeStake"` (`EN/Recipes.json:203`) |
| categoria de craft | `IGUI_CraftingCategories_<category>` em `IG_UI.json` (`EN/IG_UI.json:6858`) |
| perícia | `IGUI_perks_<Nome>` em `IG_UI.json` (`EN/IG_UI.json:224`) |
| `evolvedrecipe` | `EvolvedRecipeName.json` |

**A chave perdeu o prefixo no B42 — nos dois arquivos.** Censo:

| Arquivo | Chaves | Com prefixo legado |
|---|---|---|
| `EN/Recipes.json` | 1.909 | **0** com `Recipe_` |
| `EN/ItemName.json` | 4.889 | **0** com `ItemName_` |
| `PTBR/Recipes.json` | 3.170 | **1.230** com `Recipe_` |
| `PTBR/ItemName.json` | 5.187 | **24** com `ItemName_` |

`ES` e `FR` acompanham o `EN`. **O `PTBR` do jogo é a exceção, e é armadilha**: aquelas 1.230 + 24
chaves são resíduo da tradução do B41 e não existem mais em `EN`. Não copiar de lá.

A forma correta é `"Base.SpadeHead"` e `"MakeStake"` — módulo e nome puros, sem prefixo nenhum.

**Mas a regra não é geral: `Print_Text.json` e `Print_Media.json` mantiveram o prefixo.** É o
espaço de nome do texto de mídia impressa — jornal, panfleto, brochura, e o que um mod escrever em
diário ou caderno. Censo:

| Arquivo | Chaves | Com prefixo |
|---|---|---|
| `EN/Print_Text.json` | 310 | **310** com `Print_Text_` |
| `EN/Print_Media.json` | 327 | **325** com `Print_Media_` |

As duas exceções de `Print_Media.json` são fragmentos de template, não entradas de mídia:
`"maptext"` e `"wrinkles"` (`EN/Print_Media.json:327-328`).

**A contagem de `Print_Media.json` anda — o contrato não** [mudou 42.20.4: eram 341 chaves, 339 com
prefixo]. O patch de 2026-08-26 reescreveu o arquivo nos 19 idiomas e o `EN` perdeu 14 chaves. O que
a página afirma continua de pé: o prefixo segue obrigatório e as exceções seguem sendo as mesmas duas
`"maptext"` e `"wrinkles"`, agora no fim do arquivo. Trate o número como peso do arquivo, não como
contrato — reconferir a contagem a cada patch é gasto sem retorno.

Duas convenções a mais, que valem para quem for somar chave ali:

- **O par `_title` / `_info` é obrigatório na prática**: as 310 chaves de `Print_Text.json` são
  exatamente **155 `_title` + 155 `_info`**, sem nenhuma outra terminação. Ex.:
  `"Print_Text_KnoxKnews_July2_title"` (`EN/Print_Text.json:4`) e
  `"Print_Text_NationalDispatch_July13_info"` (`EN/Print_Text.json:31`).
- **A quebra de linha é `\n`, não `<br>`**: 155 linhas de `Print_Text.json` contêm `\n` e **zero**
  contêm `<br>`.

Aplicar a regra "sem prefixo" a este arquivo produz chave que `getText` não acha — e `getText`
devolve a própria chave, que vai parar escrita dentro do item. Falha silenciosa.

**`Print_Text_` é prefixo reconhecido pelo motor, e não por convenção.** `Translator.getTextInternal`
roteia a chave por prefixo (`UI_`, `Moodles_`, `SurvivalGuide_`, `Farming_`, `IGUI_`, `ContextMenu_`,
`GameSound_`, `Print_Media_`, `Print_Text_`, …) para um `Map` próprio de cada um. Chave sem prefixo
conhecido não cai em mapa nenhum, por isso volta como ela mesma.

**Cuidado com o corolário: valor vazio não é ausente.** O fallback "devolve a própria chave" só
acontece quando o `get` do mapa devolve `null`. String vazia é valor válido e volta como `""` — então
`getText("Print_Text_X")` numa chave declarada com `""` devolve `""`, **não** a chave. O idioma
comum de detectar tradução faltando não pega esse caso:

```lua
-- so pega chave AUSENTE; chave declarada com "" passa batido
if text == translationKey then ... end
```

Se o mod usar entrada vazia de propósito (página em branco, por exemplo), ela é indistinguível de
"nunca escreveu nada" pelo texto — a marca tem de ser outra, tipo `modData` no item.

**A comunidade diverge, e o código ganha.** O mod `More Traits` (`STEAM/1299328280/`, `versionMin`
42.15 e 42.17 — B42, não legado) usa a forma prefixada nos `.json` dele:
`"ItemName_MoreTraits.Bag_PackerBag"`. É conversão mecânica do `.txt` do B41, que carregava o prefixo
dentro da tabela. O jogo não usa prefixo em nenhuma das 4.889 chaves de `EN/ItemName.json`, então é
essa a forma a escrever. *A confirmar in-game* se o parser aceita as duas — o mod acima está
publicado e em uso, o que é indício de que sim, mas indício não é prova, e o fallback `DisplayName`
mascararia a diferença num teste de item.

### Alcance: quais idiomas um mod costuma atender

Número de pastas de idioma entregues pelos 89 mods de `STEAM/` — a melhor medida disponível de onde
está a audiência que consome mod traduzido:

`EN` 202, `PTBR` 86, `ES` 79, `RU` 78, `DE` 68, `FR` 67, `KO` 59, `CH` 59, `UA` 55, `CN` 55, `PL` 48,
`IT` 47, `TR` 46, `JP` 41 — depois cai para `PT` 20, `TH` 16, `CS` 11, `AR` 10, `HU` 8, `NL` 7.

`EN` aparecendo em 202 pastas contra 86 do segundo colocado é coerente com `EN` ser o fallback do
motor, e mod que traduz para uma língua só traduz para essa. Mas isso é censo de pastas de mod, não
leitura do carregador — e **no servidor o fallback não se confirmou**, ver a subseção seguinte.

### O servidor carrega um idioma só, e `getText` não resolve chave de mod lá

**Não chame `getText` em código que roda no lado servidor.** Numa sessão coop de 2026-09-09 o
servidor registrou **uma** tentativa de carga de idioma, e não foi a do jogador:

```
:: Searching for translation files:
Attempting to load translation: PT
```

`USER/Logs/2026-09-09_20-39_DebugLog-server.txt:1905-1906`. O cliente da mesma sessão estava em
`PTBR` (`USER/options.ini`, `language=PTBR`); `PT` e `PTBR` são pastas distintas, e o jogo traz as
duas.

O servidor **viu** os arquivos de tradução do mod — o log traz
`mod "<Mod>" overrides media/lua/shared/translate/en/print_text.json` e a linha
equivalente de `ptbr` (`:98-99`; nome do mod omitido aqui). Mesmo assim, `getText("Print_Text_<Mod>_01")`
devolveu ali a própria chave, e o mesmo para as outras três chaves testadas (`:1970`,
`:1978-1979`, `:1982`, via `print` de diagnóstico do próprio mod). As quatro chaves existem no `EN`
**e** no `PTBR` do mod. Ou seja: **o fallback `EN` da seção acima não alcançou chave de mod no
servidor.**

Não há como configurar o idioma de um servidor: `USER/Server/servertest1.ini` tem 149 chaves e
**nenhuma** casa com `lang`.

**Por que isso morde.** `OnFillContainer` e os handlers de `sendClientCommand` rodam no servidor em
multiplayer (ver [persistencia-e-multiplayer.md](persistencia-e-multiplayer.md)), e é lá que um mod
naturalmente sortearia ou inspecionaria texto. `getText` usado ali como sonda — "a chave existe?",
"o texto é vazio?" — dá sempre a mesma resposta errada, para todos os jogadores, e sem uma linha de
erro. Duas consequências de projeto:

- **O texto se resolve no cliente**, na hora de exibir — que é onde o idioma é o de quem lê.
- **O que o servidor precisa saber sobre a string vira campo declarado do mod**, nunca dedução da
  tradução. "Esta entrada é vazia de propósito" é dado da tabela do mod; isso fecha com o corolário
  "valor vazio não é ausente" da seção acima, que já mandava a marca ser outra coisa que não o texto.

Em singleplayer nada disso aparece: os dois lados são o mesmo processo e o idioma é o do jogador.
É mais um caso da regra de que testar só em SP não prova nada sobre MP.

### `%` literal escreve-se `%%` [novo 42.20.1]

O `%` é metacaractere no parser de tradução — `%1`, `%2` são os argumentos posicionais. Para exibir
um `%` literal, a forma correta é **`%%`**:

```json
"ContextMenu_FullPercent": "%% full",
```

`PZ/media/lua/shared/Translate/EN/ContextMenu.json:498`. Com argumento junto, o padrão é `%1%%`
(`EN/GameSound.json:5` — `"Volume: %1%%<br>Master Volume: %2 %3%%"`).

O patch que trouxe isso reescreveu a árvore de tradução inteira: **350 dos 1.248 `.json`**. Em `EN`,
os arquivos que contêm `%%` são **exatamente os 13** que o patch tocou, de 43 — 84 chaves no total.
A correspondência é exata e reproduzível:

```sh
cd PZ/media/lua/shared/Translate
grep -l '%%' EN/*.json | wc -l                     # 13
find EN -name "*.json" -newermt "2026-08-05" | wc -l  # 13
```

**Para mod: use `%%`.** As notas de 42.20.1/42.20.2 dizem que há um workaround temporário aceitando
as duas formas, que será removido, e que o log de erro passa a apontar o que precisa mudar — isso é
comportamento do parser Java, não verificável no `media/`. Ver "Pontos a confirmar".

## Tradução em `.txt` não é lida no B42

**A evidência forte é o próprio jogo.**
`PZ/media/lua/shared/Translate/` tem **1.248 `.json`** e exatamente **2 `.txt`** —
`TH/language.txt` e `TH/credits.txt`, e os dois têm o `.json` equivalente
(`TH/language.json`, `TH/Credits.json`) na mesma pasta. São resíduo legado num único idioma; `EN/`
e os outros 27 só têm `.json`. O B42 não usa `.txt` para tabela de strings.

**[corrigido 2026-08-07]** Uma versão anterior desta página afirmava que **zero** mods `.txt`
declaram `versionMin=42`. Está errado. Censo refeito sobre todos os `mod.info` de `STEAM/`,
ignorando `language.txt`/`credits.txt`:

| `versionMin` | só `.txt` | só `.json` | ambos |
|---|---|---|---|
| 42.x | 22 | 10 | 2 |
| 41.x | 19 | 0 | 4 |
| ausente | 142 | 7 | 14 |

São **17 mods distintos** com `versionMin=42.x` entregando tradução só em `.txt`, entre eles
`More Traits - Dynamic` (42.17), `Project_Cook` (42.10) e a série `Pillows Many Spawns` (42.13).

```sh
find . -name mod.info   # versionMin x extensão em Translate/, ver a página de sandbox-options
```

O caso que mais informa é `More Traits` (42.15 e 42.17), que entrega os **dois** formatos lado a
lado — `Sandbox.json` e `Sandbox_EN.txt`, mesmo par em `ItemName`, `Moodles`, `Tooltip` e `UI`.
Migrou para `.json` e não apagou o `.txt`.

**Resolvido in-game em 2026-08-07, jogo 42.20.2: o B42 não lê `.txt`, e não avisa.**

Teste com o jogo em PT-BR e `SiddigoWeapons` (ainda com tradução `.txt`) ativo. O `.txt` declarava
`ItemName_SiddigoWeapons.SkullCrusher = "Racha Cuca"`; o item aparece no jogo como
**"Skull Crusher"** — o `DisplayName` do bloco de script, não a tradução. O mesmo com
`SkateboardMod`: as opções de sandbox aparecem como **chave crua**
(`Sandbox_Skateboard_skateboardWalkSpeedMultiplier`), inclusive o nome da página no menu lateral,
em vez dos rótulos de `Sandbox_EN.txt`.

O silêncio é a parte perigosa: no `console.txt` da sessão inteira não há **uma linha** sobre
tradução além de `Loading Translations` (`:97`) e `Attempting to load translation: PTBR` (`:445`).
Nenhum `WARN`, nenhum `ERROR`. O mod carrega, o console fica limpo, e a string não aparece — a
assinatura clássica de falha silenciosa do parser da IndieStone. Um mod de tradução em `.txt` está
inerte por inteiro; migrar para `Translate/<IDIOMA>/*.json` é a única saída.

Migrar o formato não prova que as chaves estão certas: o fallback `DisplayName` mascara chave
errada exatamente como mascarou o `.txt`. Confira in-game com o cliente no idioma traduzido.

## Sobrescrever arquivo do jogo

Um mod que entrega um arquivo no **mesmo caminho relativo** de `media/` substitui o do jogo em vez de
somar — e o motor **loga a substituição**, no canal `Mod`:

```
LOG : Mod  f:0> loading SkateboardMod
LOG : Mod  f:0> mod "SkateboardMod" overrides media/fileguidtable.xml
```

(`USER/console.txt:992-993`.) A linha é o jeito barato de descobrir sobrescrita não intencional:
se dois mods declararem o mesmo caminho, os dois aparecem aqui, e o último a carregar vence.

**O log é geral — o efeito não.** Quem escreve a linha é `zombie.ZomboidFileSystem`, que mantém um
único `activeFileMap` chaveado pelo caminho relativo **em minúsculas** e faz `put()` do arquivo do
mod por cima do que já estava; ele loga qualquer caminho, com duas exceções que ele cala de
propósito, `mod.info` e `poster.png`. Mas o mapa só decide o resultado para quem **lê pelo mapa** —
e nem todo subsistema lê.

**Tradução é o contraexemplo, e é o que mais assusta:** um mod que entrega
`Translate/EN/Print_Text.json` — nome que o jogo também tem — dispara

```
LOG : Mod  f:0> mod "<Mod>" overrides media/lua/shared/translate/en/print_text.json
```

e **não perde uma chave sequer do jogo**. `Translator.loadFiles` chama, para cada arquivo de
tradução, `tryFillMapFromFile(...)` com o caminho da **instalação** (`ZomboidFileSystem.base`) e só
depois `tryFillMapFromMods(...)`, sem limpar o mapa entre os dois: o arquivo do jogo é lido direto do
disco, passando por fora do `activeFileMap`, e o do mod entra por cima **chave a chave**. Ou seja, um
mod pode usar o nome de arquivo canônico de tradução sem apagar nada — a linha "overrides" ali é
ruído, não aviso.

Para os demais subsistemas o efeito continua sendo substituição de arquivo inteiro; qual deles lê
pelo mapa e qual repete o truque do `Translator` não foi levantado além da tradução.

*(As afirmações sobre `ZomboidFileSystem` e `Translator` vieram de `javap` sobre
`PZ/projectzomboid.jar` — é código Java, sem `caminho:linha` no `media/`, e envelhece a cada patch
que toca o `.jar`. Ver [distribuicao-loot.md](distribuicao-loot.md), "Como isto foi levantado —
bytecode do `.jar`".)*

## Debug

**Página dedicada: [testar-e-debugar.md](testar-e-debugar.md)** — formato das linhas de log, como ler
o stacktrace de Lua, o modo debug e o que recarrega sem reiniciar.

O essencial: `USER/console.txt` é o primeiro lugar a olhar quando um mod não carrega, e é
**sobrescrito a cada sessão** — confira a data antes de tirar conclusão dele. Histórico por sessão em
`USER/Logs/`. Erro de metadado de mod aparece no canal `Mod`, citando o método Java que reclamou
(`ERROR: Mod ... at ChooseGameInfo.readModInfoAux > ...`, `console.txt:177`).

Não há toolchain Lua nesta máquina (`lua`/`luac`/`luacheck` ausentes): a única validação real de
sintaxe é carregar o jogo.

## Pontos a confirmar

- **Se um mod enxerga a arte (`media/textures`, `models_X`) de outro mod que ele declara em
  `require=`.** É o que decide se o desenho core + addons da seção "Um upload carrega N mods"
  consegue ter um `common/` só no core, ou se cada sub-mod precisa duplicar textura e modelo.
  Indício a favor: `Icon =` resolve por **nome global**, sem caminho, com o prefixo `Item_`
  implícito (ver [arte-e-modelos.md](arte-e-modelos.md)) — o que sugere pool único de texturas
  depois que todos os mods ativos carregam. Mas isso é inferência do formato do campo, não medição,
  e quem monta o pool é Java. Testar in-game antes de planejar um core+addon em cima disso.
- **Ordem de carregamento entre mods — se o `require=` garante ordem, ou se só `loadAfter`/`loadBefore`
  garantem.** Os três campos existem e a tela de ordem os lê junto:
  `ModLoadOrderPanel.lua:256-258` (`getLoadAfterAndRequire`) mistura `loadAfter` com `require` num só
  conjunto, o que sugere que `require` também pesa na ordem — mas isso é a **UI** de ordenação, não a
  carga. Quem aplica a ordem em runtime está no `projectzomboid.jar` e não é legível aqui. Agrava:
  **zero** dos 367 `mod.info` de `STEAM/` declaram `loadAfter=` ou `loadBefore=`, então não há uso
  real para observar.
  `[2026-11-01]` Confirmado no Lua do seletor, ainda do lado da UI: ativar um mod **ativa os requeridos
  em cascata** — `forceActivateMods` percorre `getRequire()` e chama a si mesmo para cada id
  (`PZ/media/lua/client/OptionScreens/ModSelector/ModSelectorModel.lua:397-416`); desativar derruba
  quem depende dele (`:418-425`). O lookup é `self.mods[reqId]` (`:412`): id que não casa exatamente
  com o `id=` do outro mod é **ignorado em silêncio**. E `correctAndSaveModOrder` (`:138-163`) grava a
  lista ativa pondo os ids de `getRequire()` antes do mod — um nível só, sem recursão. Se a carga em
  runtime respeita essa lista continua no `.jar`.
- `[2026-11-01]` **O que significam as barras em `require=`.** Censo de `STEAM/`: além do id simples
  (`require=damnlib`, 40 `mod.info`), aparecem `require=\Bandits2` e
  `require=\1299328280/ToadTraits,\KillCount` — barra invertida antes do id, e às vezes um id
  numérico de item da Workshop com `/` antes do id do mod; listas separadas por vírgula nas três
  formas. O mesmo mod aparece nas duas grafias em itens diferentes (`fhqMotoriusZone` e
  `\fhqMotoriousZone`, `VanillaVehiclesAnimated` e `\VanillaVehiclesAnimated`). Como o seletor busca
  `self.mods[reqId]` direto, a forma com barra só funciona se o Java normalizar o valor (ou a chave
  de `self.mods`) — não verificado. A forma sem barra funciona: observado in-game em 2026-11-01, mod
  de teste com `require=<id>` simples carregando em MP dedicado.
- **Se `dependencies=`, `modLink=` e `zomboidversion=` são campos lidos ou lixo tolerado.** Aparecem
  em `STEAM/3446915394/mods/simbatraduz/42/mod.info`, que usa um conjunto de campos divergente do
  nosso — tem `version=` e `zomboidversion=42` no lugar de `modversion=`/`versionMin=`. **Nenhum dos
  três tem acessor `modInfo:get*` em `media/lua`** (os 19 usados estão em
  `client/OptionScreens/ModSelector/`), e no censo de `STEAM/` os valores são vazios ou únicos:
  `dependencies=` 0, `modLink=` 0, `zomboidversion=` 1. O parser do `mod.info` está no Java, então
  "sem acessor Lua" não prova "ignorado" — mas não há evidência de que façam algo. Não copiar esse
  conjunto de campos para mod nosso enquanto não se confirmar.
- **Se a Steam aceita descrição por idioma no mesmo item da Workshop.** O uploader do jogo não faz
  (seção acima), então a operação só poderia ser no site. **Não é verificável a partir daqui**: o
  `workshop.txt` não é distribuído com o mod — dos 89 de `STEAM/`, **um** traz o arquivo —, então
  nem os mods de terceiro servem de evidência. Checar no painel de administração de um item próprio
  antes de planejar em cima disso.
- **Se a descrição do item aceita BBCode** (`[h1]`, `[b]`, `[list]`, `[hr]`, `[img]`). Mesma barreira
  da pendência acima, e por três caminhos independentes: o `workshop.txt` não é distribuído, os 10
  arquivos de `WS/` não usam marcação nenhuma, e quem interpreta (ou não) o texto é o site, não o
  jogo — o `writeWorkshopTxt()` grava a linha `description=` literal, seja lá o que ela contenha.
  Enquanto não se confirmar, texto de página deve continuar legível com as marcas removidas. Checar
  publicando e olhando a página.
- **Por que o servidor escolheu `PT`.** A hipótese é o locale da máquina (Windows pt-BR → Java
  `Locale.getDefault().getLanguage()` = `"pt"` → `"PT"`), mas quem escolhe está no
  `projectzomboid.jar` e não foi lido. Importa porque decide se entregar uma pasta `PT` resolveria o
  caso, ou se o idioma do servidor é imprevisível e a única saída é mesmo não depender de `getText`
  daquele lado.
- **Se o servidor carrega `EN` como base e o fallback só não alcança chave de mod, ou se não carrega
  base nenhuma.** O log da sessão só registra a tentativa de `PT` — o que não prova ausência de uma
  carga de base anterior, apenas que ela não apareceu no log.
- **Se chave *vanilla* resolve no servidor.** A observação de 2026-09-09 só cobriu chave de mod. Se
  vanilla resolver e mod não, o problema não é o idioma escolhido e sim o momento em que a tradução
  de mod entra no mapa do `Translator`.
- **Se o parser de tradução aceita a chave com prefixo (`"ItemName_Mod.Item"`) além da forma sem
  prefixo.** O jogo só usa a forma sem prefixo; `More Traits` (42.15/42.17, publicado) usa a
  prefixada. Ver a seção de tradução.
- Se `versionMax` ausente significa "sem limite". Uso observado: **20 dos 368 `mod.info` de
  `STEAM/`** declaram o campo, ou seja a esmagadora maioria o omite e funciona — coerente com "sem
  limite", mas isso é inferência sobre o comportamento default, não leitura do parser.
- **Até quando o `%` sozinho continua funcionando.** As notas de 42.20.2 descrevem um workaround
  temporário que aceita as duas formas e será removido "num unstable futuro". A regra `%%` está
  confirmada nos `.json` do jogo (seção acima); o workaround e seu prazo são changelog, e o código
  que decide está no `projectzomboid.jar`. Um mod que ainda use `%` não quebra hoje — e não há como
  medir aqui quando quebra.
- **Se o log de erro do `%` sai em canal próprio.** As notas dizem que o jogo passa a apontar no log
  o que precisa ser atualizado; formato e canal não foram observados. A sessão de 2026-08-07 **não
  produziu nenhuma linha** com `%%` ou `percent` no `console.txt` — mas nenhum dos mods ativos usa
  `%` em tradução, então é ausência de gatilho, não prova de ausência do log. Ver
  [testar-e-debugar.md](testar-e-debugar.md).

> Última verificação: 2026-08-26 — jogo **42.20.4** (`b0bbce05d5`), PZ buildid 24909800
> (branch public, atualizado 2026-08-26), media/ + `USER/console.txt:59` (sessão de 12:31,
> posterior ao patch das 12:07).
>
> Verificado nesta rodada **só o que o patch `24775755` → `24909800` tocou**: o censo de
> `EN/Print_Media.json`, que ele reescreveu nos 19 idiomas — corrigido, ver `[mudou 42.20.4]` na
> seção de tradução. O diff por `mtime` desse patch não alcança mais nada citado por esta página.
>
> Camadas anteriores, não reconferidas: a seção de tradução, "Sobrescrever arquivo do jogo" e
> "Debug" foram verificadas em 2026-08-07 contra o buildid 24574865; o restante da página foi
> levantado em 2026-08-04, contra o buildid 24449119.

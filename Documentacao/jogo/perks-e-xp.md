# Perk, skill e XP — o que um mod consegue e o que não consegue

O sistema de habilidade do PZ visto do lado do mod. A conclusão principal cabe numa frase e é o
motivo da página existir: **dá para dar XP, dá para multiplicar ganho, mas não dá para criar skill
nova por Lua.**

**O "por Lua" é literal, e a página já foi mais pessimista do que devia.** Skill nova **é** criável
por mod — pelo arquivo `media/perks.txt`, levantado em 2026-08-11 e descrito na primeira seção. Se
você veio aqui por uma citação antiga desta página concluindo "não dá", é essa a correção.

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\`,
`STEAM/` = `…\steamapps\workshop\content\108600\` (ver [../index.md](../index.md)).
**Somente leitura.**

Traço e profissão — que **são** criáveis por mod, via bloco `.txt` desde o B42 — estão em
[scripts-txt.md](scripts-txt.md), na seção `character_trait_definition`. Não confunda: profissão
concede bônus de skill, mas não define skill.

## Skill nova: não por Lua — mas **sim** por `media/perks.txt` `[novo: levantado 2026-08-11]`

Esta seção documentava a metade Lua e concluía "não dá". **A metade que faltava existe**, e era
exatamente o que a primeira pendência desta página previa: um bloco `.txt`. Leia as duas partes na
ordem — a evidência Lua abaixo continua válida e é o que explica *por que* a via `.txt` é a única.

O arquivo é **`media/perks.txt`**, solto na raiz de `media/`, da mesma classe de
`media/sandbox-options.txt`: **só existe em mod**. `find media -name perks.txt` no `PZ/` devolve
zero — ver [sandbox-options.md](sandbox-options.md) para o outro membro dessa família.

Formato: um cabeçalho `VERSION = 1,` e blocos `perk`:

```
perk Archery
{
    parent      = Firearm,
    translation = Archery,
    passive     = false,
    xp1  = 50,
    ...
    xp10 = 6000,
}
```

(`STEAM/3775407541/mods/RadArchery/42/media/perks.txt`.) **Quatro mods de `STEAM/` trazem o
arquivo**, com o mesmo formato:

| Mod | Perks declarados |
|---|---|
| `STEAM/3775407541/mods/RadArchery/42/` | `Archery`, com `parent = Firearm` |
| `STEAM/3403870858/mods/Lifestyle/common/` | `Lifestyle` (`parent = None`) + filhos `Art`, `Cleaning`, … |
| `STEAM/2997342681/mods/Lifestyle/` | idem, versão pré-B42 do mesmo mod |
| `STEAM/2703664356/mods/TheOnlyCure/` | `Prosthesis` (`parent = None`) + `Left_Hand`, `Right_Hand` |

**`parent = None` é cabeçalho de categoria, não skill visível** — e isso é confirmável no código do
jogo, não só nos mods. `ISCharacterInfo.loadPerk` (`PZ/media/lua/client/XpSystem/ISUI/ISCharacterInfo.lua:265-284`)
itera `PerkFactory.PerkList`, **pula** quem tem `perk:getParent() == Perks.None` e agrupa o resto
por pai. Daí o padrão dos quatro mods: um perk raiz sem pai para criar a seção, e os que aparecem na
tela pendurados nele. `parent = Firearm` do RadArchery põe a skill ao lado de Aiming e Reloading.

**O elo do meio está fechado** `[levantado 2026-09-30]`, por duas fontes que a rodada anterior não
tinha aberto:

- **A IndieStone publica o arquivo.** O mod de exemplo oficial vendorado traz
  `Documentacao/oficial/testmod_registries/42/media/perks.txt`, no mesmo formato — raiz
  `Miscellaneous` com `parent = None` e `Lockpicking` pendurado nela — e usa o perk criado em
  `XPBoosts` de profissão e de traço (`…/42/media/scripts/testmod/professions.txt`, `traits.txt`:
  `XPBoosts = …;Lockpicking=2`).
- **O bytecode de `zombie.characters.skills.CustomPerks`** (`javap` sobre `PZ/projectzomboid.jar`,
  buildid 25485521 — afirmação de `.jar`). `init()` percorre os mods ativos e tenta
  `<pasta de versão>/media/perks.txt` e `<common>/media/perks.txt` (`getVersionDir`/`getCommonDir`
  + a constante `media/perks.txt`); `parse` exige `VERSION` e só aceita bloco `perk`; `initLua()`
  escreve cada perk na tabela Lua `Perks`. `GameWindow.initShared` chama `PerkFactory.init`,
  `CustomPerks.init` e `CustomPerks.initLua` em sequência — antes de qualquer `.lua` de mod, então
  `Perks.<Id>` já existe em escopo de arquivo.

Se o arquivo não parsear, **`Perks.<Id>` é `nil`** e tudo que o usa estoura longe da causa
(`getPerkLevel(nil)`, `SkillBook[…].perk`). Um mod recente guarda cada uso com teste de `nil` e
`print` — `STEAM/3775407541/mods/RadArchery/42/media/lua/server/RadArcheryBooks.lua:9-14`.

**O nome exibido é `getText("IGUI_perks_" .. translation)`** (bytecode de `PerkFactory`), em
`IG_UI.json`. A descrição do tooltip tem uma pegadinha: a chave é montada com o nome **já
traduzido** — `getText("IGUI_perks_"..self.perk:getName().."_Description")`
(`PZ/media/lua/client/XpSystem/ISUI/ISSkillProgressBar.lua:78`), e `getName()` devolve o campo
`name`, que é o texto traduzido. Por isso a chave do jogo é `IGUI_perks_Electrical_Description`
(`EN/IG_UI.json:5598`) para o perk `Electricity`, cujo nome em inglês é "Electrical" (`:220`). Num
idioma em que o nome difere, a chave procurada difere junto.

Ou seja, a previsão da seção "Os outros arquivos da área" — *"uma skill nova apareceria sozinha na
tela, se fosse possível registrá-la"* — estava certa, e o registro existe. Ele só nunca passou pelo
Lua.

### A metade Lua: por que não dá por lá

`PerkFactory` é a fábrica de perks e aparece em **12 arquivos** de `media/lua`. Todo uso é de
**leitura**:

| Chamada | Onde |
|---|---|
| `PerkFactory.getPerk(perk)` | `ISPlayerStatsAddXPUI.lua:28`, `XpUpdate.lua:293`, `ISPerkLog.lua:11` |
| `PerkFactory.getPerkName(perk)` | `ISMoveableDefinitions.lua:51`, `MainCreationMethods.lua:120` |
| `PerkFactory.PerkList` (`:size()`, `:get(i)`) | `ISCharacterInfo.lua:268-269` |

**Não existe `PerkFactory.addPerk` — zero ocorrências em todo o `media/lua`.** Não há criação, só
consulta: a lista de perks é montada no Java e o Lua a lê.

A segunda metade da evidência vem dos mods. Entre os mods de `STEAM/`, o único casamento de
`addPerk` é uma função *local* de um mod chamada `addPerkXP`
(`STEAM/2997342681/mods/Lifestyle/media/lua/client/TimedActions/LSYogaAction.lua:398`), que distribui
XP para `Fitness` e `Nimble` — perks do jogo. **Nenhum mod registra perk novo por Lua** — os quatro
que registram o fazem por `media/perks.txt`, e um deles é esse mesmo `Lifestyle`, o que mostra que a
ausência de `addPerk` não era falta de interesse: era falta de API.

O enum `Perks.*` tem **37 entradas** no build atual (fora `None`, `MAX`, `FromString`, `fromIndex`),
e é Java: `Perks.Aiming`, `Perks.Blacksmith`, `Perks.Butchering`, `Perks.Carving`, `Perks.Fitness`,
`Perks.FlintKnapping`, `Perks.Glassmaking`, `Perks.Husbandry`, `Perks.Masonry`, `Perks.Pottery`,
`Perks.Tracking`, `Perks.Woodwork`, … (lista completa por `grep -rhoE "Perks\.[A-Za-z]+" media/lua`;
não se copia dado do jogo para cá).

Vários desses são B42 — `Blacksmith`, `Carving`, `FlintKnapping`, `Glassmaking`, `Masonry`,
`Pottery`, `Husbandry`, `Butchering`, `Tracking` acompanham os sistemas de artesanato e animal
introduzidos nessa build.

## Dar XP

**A via canônica é a global `addXp(character, perk, amount)`, e não
`character:getXp():AddXP(...)`.** As duas existem, e a segunda é a que a intuição escolhe por ser
método do objeto — mas o uso real no jogo não deixa dúvida: **71 chamadas de `addXp` contra 4 de
`getXp():AddXP`** em `PZ/media/lua`, descontadas as linhas comentadas.

`addXp` **não tem definição Lua nenhuma** no jogo — nem `function addXp`, nem `addXp =`. É global
exposta pelo Java, da mesma família de `addXpMultiplier`. Uso canônico:

```lua
addXp(playerObj, Perks.Woodwork, 3)     -- server/BuildingObjects/ISBuildUtil.lua:107
addXp(player, Perks.Farming, xp)        -- server/Farming/SFarmingSystem.lua:551
addXp(player, Perks.Fishing, 1)         -- server/Fishing/BuildingObjects/FishingNet.lua:164
addXp(character, Perks.Trapping, xp)    -- server/Traps/STrapGlobalObject.lua:220
```

Das 4 chamadas vivas de `getXp():AddXP`, **três são a UI de debug de XP**
(`client/ISUI/PlayerStats/ISPlayerStatsUI.lua:525`, `:543`, `:791`); a quarta é o desmonte de móvel
(`shared/Moveables/ISMoveableSpriteProps.lua:3552`). A aridade vai de 2 a 6 argumentos; os quatro
booleanos da forma longa não têm nome no Lua — são posicionais e o significado mora no Java.

> **Cuidado ao levantar essa forma por grep: metade das ocorrências no jogo é código comentado.**
> `getXp():AddXP(Perks.Woodwork, 3)` e `getXp():AddXP(perk, 5, false)` existem **só** comentadas
> (`server/XpSystem/XpUpdate.lua:114`, `:117`, `:278`), e o mesmo vale para
> `shared/TimedActions/ISChopTreeAction.lua:79`. Não são uso observado — versões anteriores desta
> página as listavam como se fossem.

`PZ/media/lua/server/XpSystem/XpUpdate.lua` (399 linhas) é o arquivo que concede XP passivo do jogo e
serve de exemplo canônico de "que ação dá que XP":

```lua
		    addXp(player, Perks.Fitness, 1)      -- :17
		    addXp(player, Perks.Sprinting, 1)    -- :20
		addXp(player, Perks.Nimble, 1)           -- :28
	    addXp(owner, Perks.Strength, owner:getLastHitCount())  -- :75
		addXp(owner, Perks.Aiming, xp)           -- :83
```

Ele se registra em nove eventos (`XpUpdate.lua:381-399`):

`EveryTenMinutes`, `OnPlayerMove`, `OnWeaponHitXp`, `OnWeaponHitTree`, `OnKeyPressed`, `AddXP`,
`LevelPerk`, `OnNewGame`, `OnLoad`.

**`Events.AddXP` e `Events.LevelPerk` são os dois ganchos que interessam a mod** — permitem reagir a
ganho de XP e a subida de nível sem substituir nada. Ver [eventos-lua.md](eventos-lua.md).

### Em multiplayer a escolha entre as duas formas deixa de ser estilo

**`addXp` atravessa a partir de código só-de-servidor.**
`PZ/media/lua/server/Traps/STrapGlobalObject.lua:1` é literalmente `if isClient() then return end` —
o arquivo inteiro só roda no servidor, e tem par de cliente explícito
(`client/Traps/CTrapGlobalObject.lua`), então não é ambiguidade de pasta. Mesmo assim ele concede XP
a um jogador conectado, em `:220`, com `addXp`.

**`getXp():AddXP` chamado do servidor, não.** Observado em 2026-09-10, num handler de
`OnClientCommand` de um mod de teste: `playerObj:getXp():AddXP(Perks.Doctor, 500)` não rendeu
XP nenhum ao jogador — `USER/Logs/2026-09-10_11-45_PerkLog.txt` registra todas as perícias em 0 —,
enquanto a recompensa de **item** do mesmo handler, que faz `sendAddItemToContainer`, funcionou. Não
houve erro de Lua em nenhum dos dois logs da sessão, e `Perks.Doctor` é chave válida
(`server/XpSystem/XPSystem_SkillBook.lua:60`). É a falha silenciosa clássica de MP: o servidor mexe
na cópia que ele tem do personagem, e o cliente nunca fica sabendo.

**A terceira razão é o evento.** Só `addXp` dispara `Events.AddXP`. O ouvinte do jogo é
`xpUpdate.addXp` (`server/XpSystem/XpUpdate.lua:176`, registrado em `:393`), e é ele que pendura o
halo de texto de PlantScavenging (`:195-198`) e mexe nos timers de Strength/Fitness (`:181-193`).
Quem usa a forma de objeto perde esses efeitos junto com o evento.

`addXpMultiplier(character, perk, multiplier, lvlSkillTrained, maxLevelTrained)` é da mesma família —
também sem definição Lua — e também é sancionada do lado servidor: `ISReadABook:complete()` a chama
em `shared/TimedActions/ISReadABook.lua:340`, e `complete` roda no servidor em MP (o próprio método
testa `if isServer() and self.forceStopped` em `:327`). Ver [timedactions.md](timedactions.md).
Observado em servidor dedicado em 2026-09-14 (mod de teste): chamada de um handler de
`OnClientCommand`, o multiplicador aparece no painel do cliente e continua lá depois do relogin.

### O que multiplica o XP — e a global que pula tudo

O valor passado a `addXp` **não** é o que entra na barra. A conta mora em
`IsoGameCharacter$XP.AddXP(perk, amount, b1, b2, b3, b4)`, e o quarto parâmetro (`b2`) liga ou
desliga a cadeia inteira de multiplicadores. Lido por `javap -c` sobre `PZ/projectzomboid.jar`
(buildid 24909800, 2026-09-10 — afirmação de **bytecode**, que um patch só do `.jar` invalida sem
tocar o `media/`; ver [../fontes-externas.md](../fontes-externas.md), "Ler o `.jar`"). A cadeia, na
ordem:

1. **Boost da perícia** — o `XPBoosts` de profissão/traço, que a UI lê com `getPerkBoost`. Perícia
   **sem entrada** no mapa leva **×0,25**; nível 0 também ×0,25; nível 1 ×1 (×1,25 se for
   `Sprinting`); nível 2 ×1,33; nível 3 ou mais ×1,66. Isenções, nos métodos privados
   `isSkillExcludedFromSpeedReduction`/`…Increase`: `Sprinting`, `Fitness` e `Strength` **não** levam
   o ×0,25; `Fitness` e `Strength` não levam os aumentos dos níveis 2 e 3.
   A UI mostra esse boost como "+75%/+100%/+125%" para os níveis 1/2/3
   (`client/XpSystem/ISUI/ISSkillProgressBar.lua:83-95`) — relativo, e não o fator.
2. **Traços** — `FAST_LEARNER` ×1,3, `SLOW_LEARNER` ×0,7, `PACIFIST` ×0,75 nas armas brancas e em
   `Aiming`, `CRAFTY` ×1,3 nas perícias cujo pai é `Crafting`.
3. **Multiplicador de livro** (`getMultiplier`) — **só se for maior que 1**. Abaixo disso o ganho não
   muda, embora a UI desenhe as setas para qualquer valor `> 0`
   (`client/XpSystem/ISUI/ISCharacterInfo.lua:155`) e o tooltip mostre o número
   (`ISSkillProgressBar.lua:71-74`).
4. **Sandbox** — `MultiplierConfig.Global` com `GlobalToggle` ligado; senão a opção
   `MultiplierConfig.<Perícia>`.

Ou seja: com sandbox em 1 e sem traço, `addXp(player, Perks.Doctor, 50)` num personagem sem boost em
Primeiros Socorros rende **12,5**.

A conta fecha na prática: observado em servidor dedicado em 2026-09-14 (mod de teste),
dividir por 0,25 antes de chamar — `addXp(player, Perks.Doctor, 200)` — pôs **50** no painel de
perícias de um personagem sem boost na perícia. O `PerkLog` não serve de prova disso: registra só o
nível, e só no login.

**Para dar XP exato, a global é `addXpNoMultiplier(character, perk, amount)`.** No bytecode, em
singleplayer ela chama `AddXP` com `b2 = false`; no servidor vai por `GameServer.addXp(…, true)`, que
repassa `b2 = false` e termina no mesmo `updateXpChecker` de `addXp` — o mesmo caminho que leva o XP
ao cliente. Uso do jogo: `PZ/media/lua/shared/TimedActions/ISBarricadeAction.lua:129`, `:141` e
`:161` (este com o comentário `--no multiplier`), e `ISUnbarricadeAction.lua:143`. Em `STEAM/`, o mod
Lifestyle usa em `LSUtil.lua:1103`.

> **Armadilha de nome:** o **método** `getXp():AddXPNoMultiplier(perk, amount)` não é a forma de
> objeto da global. No bytecode ele tira só o multiplicador de **livro** da tabela, chama o `AddXP`
> de dois argumentos — que aplica o resto da cadeia — e devolve o multiplicador. E, como toda forma
> de objeto, não atravessa do servidor.

**Não conclua nada pela raiz `server/`.** `XpUpdate.lua` mora lá, mas isso não prova que XP seja
lógica autoritativa de servidor: `server/` carrega nos dois lados, e o próprio arquivo se registra em
eventos de cliente como `OnPlayerMove` e `OnKeyPressed` (`XpUpdate.lua:381-399`). O que o
levantamento sustenta é o desta subseção — qual forma usar, e que a global atravessa do servidor para
o jogador. Ver [persistencia-e-multiplayer.md](persistencia-e-multiplayer.md).

## Livro de skill — a tabela que um mod *pode* estender

`PZ/media/lua/server/XpSystem/XPSystem_SkillBook.lua` (197 linhas) é **Lua cru**, no mesmo idioma
declarativo de `shared/Definitions/`:

```lua
SkillBook = {};

SkillBook["Blacksmith"] = {};
SkillBook["Blacksmith"].perk = Perks.Blacksmith;
SkillBook["Blacksmith"].maxMultiplier1 = 3;
SkillBook["Blacksmith"].maxMultiplier2 = 5;
SkillBook["Blacksmith"].maxMultiplier3 = 8;
SkillBook["Blacksmith"].maxMultiplier4 = 12;
SkillBook["Blacksmith"].maxMultiplier5 = 16;
```

24 entradas no build atual. Dois pontos de contrato:

- **A chave não é o perk.** `SkillBook["Carpentry"].perk = Perks.Woodwork` — o nome do livro e o nome
  do perk divergem, e essa é a única ligação entre os dois.
- **Os cinco `maxMultiplier` são os cinco volumes** do livro (Vol. 1 a 5). A progressão 3/5/8/12/16 é
  idêntica em todas as 24 entradas observadas.

Dois contratos de quem mexe em página lida por Lua, fora do `ISReadABook`:

- **O multiplicador sobe em degraus de 10% do livro, arredondado para baixo.**
  `ISReadABook.checkMultiplier` (`PZ/media/lua/shared/TimedActions/ISReadABook.lua:103-118`) calcula
  `math.floor(readPercent/10) * (maxMultiplier/10)` (`:113`) e só chama `addXpMultiplier` se o
  resultado passar do multiplicador atual (`:114`). Abaixo de 10% das páginas a conta dá **0** e nada
  acontece, sem erro e sem log. Quem soma páginas por conta própria tem de medir contra o
  `NumberOfPages` **do volume** (`PZ/media/scripts/generated/items/literature.txt`), que muda de um
  volume para o outro. Observado em 2026-09-10 num mod de teste: somar 10 páginas ao livro
  do nível atual não rendeu multiplicador nenhum. E passar o degrau não basta: o ganho de XP só usa
  multiplicador **acima de 1** (seção "O que multiplica o XP"), então com `maxMultiplier` 3 os 10%
  dão 0,3 — setas na tela e ritmo de XP inalterado.
- **A ficha do livro tem lastro só no `InventoryItem`.** `getLvlSkillTrained`/`getMaxLevelTrained`
  aparecem sempre sobre item instanciado — `ISReadABook.lua:39`, `:50`, `:115`,
  `client/ISUI/ISInventoryPaneContextMenu.lua:1061`, `:1068`, `client/ISUI/ISInventoryPane.lua:2595`,
  `client/ISUI/ISLiteratureUI.lua:92` — e nunca sobre o retorno de `getScriptManager():FindItem`. Ver
  "Pontos a confirmar".

Sendo tabela global montada em tempo de carga, é o ponto natural para um mod acrescentar — mesma
mecânica e mesma ressalva de ordem de carga de `Definitions/` (ver
[mapa-media.md](mapa-media.md)).

### O livro é um `item` — e o elo com o perk é uma string `[levantado 2026-09-30]`

O bloco canônico é `BookElectrician1`, em `PZ/media/scripts/generated/items/literature.txt:6540`:
`ItemType = base:literature`, `DisplayCategory = SkillBook`, e quatro campos que fazem dele livro de
habilidade — `SkillTrained`, `LvlSkillTrained`, `NumLevelsTrained`, `NumberOfPages`. Os cinco
volumes de uma família só variam em `LvlSkillTrained` (1, 3, 5, 7, 9) e `NumberOfPages`;
`NumLevelsTrained` é sempre 2.

**Os dois campos de nível são a faixa do volume, não a habilidade.** O teto é derivado:
`Literature.getMaxLevelTrained()` devolve `LvlSkillTrained + NumLevelsTrained - 1` (bytecode,
buildid 25485521) — o volume II cobre 3 e 4. A faixa decide se dá para ler
(`shared/TimedActions/ISReadABook.lua:39` "avançado demais", `:50` "já sabe") e limita o
multiplicador (`addXpMultiplier(…, LvlSkillTrained, MaxLevelTrained)`, `:339`).

**`LvlSkillTrained` só aceita 1, 3, 5, 7 ou 9**, porque é ele que escolhe `maxMultiplier1..5`
(`ISReadABook.lua:491-503`). Outro valor cai no `else`: multiplicador 1 e
`print('ERROR: book has unhandled skill level …')` — e multiplicador 1 não acelera nada (seção
"O que multiplica o XP").

**`SkillTrained` não é nome de perk: é a chave de `SkillBook`.** Todo consumidor faz
`SkillBook[item:getSkillTrained()]` (`shared/TimedActions/ISReadABook.lua:38`,
`client/ISUI/ISInventoryPane.lua:2608`). Um livro cuja chave não existe na tabela **dá erro de Lua
no clique direito**: `client/ISUI/ISInventoryPaneContextMenu.lua:1061` indexa `.perk` sem testar
`nil`.

Dois mods de `STEAM/` registram entrada própria, para perk criado por `perks.txt`, de um arquivo em
`lua/server/` que roda em escopo de arquivo:
`STEAM/3403870858/mods/Lifestyle/common/media/lua/server/XpSystem/XPSystem_LSSkillBooks.lua:1-7` e
`STEAM/3775407541/mods/RadArchery/42/media/lua/server/RadArcheryBooks.lua:16-23` (este com
`require "XpSystem/XPSystem_SkillBook"` no topo, que é o que garante a ordem).

Livro novo não aparece no loot sozinho — ver [distribuicao-loot.md](distribuicao-loot.md).

## Os outros arquivos da área

| Arquivo | Linhas | Papel |
|---|---|---|
| `lua/server/XpSystem/XpUpdate.lua` | 399 | concessão passiva de XP; 9 eventos |
| `lua/server/XpSystem/XPSystem_SkillBook.lua` | 197 | multiplicadores por livro |
| `lua/server/XpSystem/XpSystem_text.lua` | 10 | |
| `lua/client/XpSystem/ISUI/` | 7 `.lua` | tela de personagem, barra de progresso de skill |
| `lua/shared/Logs/ISPerkLog.lua` | | log de perk |

A UI (`ISCharacterInfo.lua`, `ISCharacterInfoWindow.lua`, `ISSkillProgressBar.lua`) itera
`PerkFactory.PerkList` para se montar — ou seja, **uma skill nova apareceria sozinha na tela**, se
fosse possível registrá-la. Isso reforça que o bloqueio está no registro, não na apresentação.

## Onde o XP encontra profissão e traço

`PZ/media/lua/shared/NPCs/MainCreationMethods.lua` é onde a criação de personagem lê os perks
(`:120`, `:172` usam `PerkFactory.getPerkName`). O bônus de skill de uma profissão é declarado no
bloco `character_profession_definition` do `.txt` — ver
[scripts-txt.md](scripts-txt.md). `CharacterCreationProfession.lua:429` monta a lista de
"XP boost" a partir daí.

Ou seja, o caminho **suportado** para um mod mexer em skill é:

1. **Criar skill nova em `media/perks.txt`** (ver a primeira seção) — o único jeito, e não passa por
   Lua.
2. Criar traço/profissão no `.txt` que dá nível inicial ou boost de XP num perk **existente**.
3. Dar XP por Lua com `addXp(...)` — ou `addXpNoMultiplier(...)` para valor exato — na sua ação — inclusive para o perk que você criou no
   passo 1.
4. Acrescentar entrada em `SkillBook` para um livro novo de um perk existente.

## Pontos a confirmar

- ~~**Se existe alguma via não-Lua para registrar perk**~~ — **RESOLVIDO em 2026-08-11**: é
  `media/perks.txt`, descrito na primeira seção. A previsão estava certa (*"se houver bloco `.txt`
  de perk, é lá que apareceria"*); só faltava o arquivo aparecer num mod instalado.
- ~~**Que o motor de fato lê `media/perks.txt`**~~ — **RESOLVIDO em 2026-09-30** pelo bytecode de
  `CustomPerks` e pelo mod de exemplo oficial; ver "O elo do meio está fechado". O texto original
  fica abaixo como registro. O que estava
  provado é que **quatro mods publicados enviam o arquivo** no mesmo formato, e que a UI do jogo
  exibe qualquer coisa que esteja em `PerkList` (`ISCharacterInfo.lua:265-284`). O elo do meio —
  quem lê o arquivo — é Java: as citações de `CustomPerks.java` e `PerkFactory.java` vêm do
  `CLAUDE.md` do mod RadArchery, que é **decompilado de terceiro**, e não são verificáveis no
  `media/`. Não foi cruzado com o PZ-API-Docs nesta rodada.
- **Se `xp1..xp10` são acumulados ou por nível**, e o que `passive = false` muda. O comentário do
  RadArchery afirma que o motor multiplica os valores por 1,5 internamente e que por isso **não** se
  deve pré-aplicar o fator — não confirmado.
- **Se `parent` aceita um perk criado pelo próprio mod** ou só os do enum `Perks.*` do jogo. Os
  quatro mods usam as duas formas (`parent = Firearm` do jogo; `parent = Lifestyle`/`Prosthesis`
  criados pelo mod no mesmo arquivo), o que sugere que sim — mas a ordem de resolução dentro do
  arquivo não foi levantada.
- **Se `getXp():AddXP` no servidor não faz nada em MP, ou se faz e só não sincroniza.** Pista forte
  pelo bytecode (2026-09-10): o `AddXP(perk, amount)` de dois argumentos só age quando o personagem é
  `IsoPlayer` com `isLocalPlayer()` verdadeiro, e retorna sem fazer nada no resto. Se o jogador
  conectado é não-local do lado servidor — o que o nome sugere e não foi aberto —, a resposta é "não
  faz nada". Para o lado prático dá no mesmo: use a global.
- ~~**Se `character:setAlreadyReadPages(...)` chamado do servidor chega ao cliente.**~~ —
  **RESOLVIDO em 2026-09-14, por observação:** chamado de um handler de `OnClientCommand` em servidor
  dedicado, sem nenhum `sendSyncPlayerFields` depois, pôs 22/220 páginas em `Base.BookFirstAid1`
  (`USER/Logs/logs_2026-09-14/2026-09-14_12-49_DebugLog-server.txt:2243`), e o cliente mostrava o
  valor depois do relogin, conferido em duas sessões. Se chega **ao vivo**, antes do relogin, não
  foi isolado. Segue sem explicação o guarda `if not isClient()` que `ISReadABook:update()` põe em
  volta dele (`shared/TimedActions/ISReadABook.lua:35`) enquanto o chama solto em `:46` e `:57`.
- **Se o `ScriptItem` expõe `getLvlSkillTrained`/`getMaxLevelTrained`/`getNumberOfPages`** como o
  `InventoryItem`. Nenhum uso em `media/lua`; `instanceItem` do livro é a via com lastro.
- **Os booleanos de `AddXP(perk, amount, b1, b2, b3, b4)`** — **`b2` resolvido** pelo bytecode
  (2026-09-10): liga a cadeia de multiplicadores (seção "O que multiplica o XP"). `b1`, `b3` e `b4`
  seguem sem nome; os candidatos pelo uso são disparar o evento Lua, marcar como vindo da rede e
  mostrar o halo (`AddXPHaloText` passa `b4 = true`), não confirmados. A UI de debug
  (`ISPlayerStatsAddXPUI.lua`) chama com `false` nos quatro — ou seja, sem multiplicador.
- ~~**Quais perícias `isSkillExcludedFromSpeedReduction`/`isSkillExcludedFromSpeedIncrease`
  isentam**~~ — **RESOLVIDO em 2026-09-10** pelo bytecode: redução isenta `Sprinting`, `Fitness`,
  `Strength`; aumento isenta `Fitness`, `Strength`. Ver a seção "O que multiplica o XP". Método
  privado — pode mudar entre builds sem aviso.
- ~~**Se `SkillBook` aceita entrada de mod**~~ — **RESOLVIDO em 2026-09-30**: dois mods de `STEAM/`
  o fazem; ver "O livro é um `item`".
- **Se a descrição do perk de mod aparece em idioma cujo nome traduzido difere do inglês.** A chave
  é montada com o nome traduzido (`ISSkillProgressBar.lua:78`); se é preciso declarar a chave com o
  nome traduzido dentro dela, ou se o motor cai para a inglesa, é teste in-game.
- **O que `maxMultiplier1..5` multiplicam exatamente** — se o ganho bruto de XP ou um limite por
  nível. O nome sugere teto; `XpUpdate.lua` não lê `SkillBook` diretamente em nenhuma das linhas
  levantadas.
- **`Perks.MAX`** — se é sentinela de contagem e se um índice além dela é válido.
- **Assinatura de `PerkFactory`, `Perks` e `IsoGameCharacter:getXp()`** — Java. Uso observado, não
  contrato declarado. Os JavaDocs não-oficiais de [../fontes-externas.md](../fontes-externas.md) são
  a via para cruzar `getTotalXpForLevel` (`XpUpdate.lua:293`) e `perk:getParent()`
  (`ISPlayerStatsAddXPUI.lua:41`), que sugerem hierarquia de perk pai/filho não levantada aqui.
- **Nenhuma fonte da comunidade foi cruzada** nesta rodada.

> Última verificação: 2026-08-07 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

# Testar e debugar — o ciclo in-game

Onde o jogo escreve, como ler o erro que ele escreveu, o que o modo debug dá, e o que recarrega sem
fechar o jogo. Esta página existe porque **carregar o jogo é a única validação real**: não há checagem
de sintaxe de Lua nem do `.txt` fora dele, e o parser da IndieStone falha em silêncio.

Aliases: `PZ/` = install do jogo, `USER/` = `~\Zomboid\`, `WS/` = `USER/Workshop/`.
Ver [../index.md](../index.md).

## O mod chega ao jogo por dois caminhos

**1. `USER/mods/<Mod>/`** — instalação manual. O nível é o do `mod.info`: `USER/mods/examplemod/`
contém `mod.info`, `poster.png` e `media/` na raiz. Ou seja, o que se copia para cá é a pasta que
está **dentro** de `Contents/mods/`, não a pasta do upload. Ver
[carregamento-de-mods.md](carregamento-de-mods.md) para o layout completo do pacote.

**2. `USER/Workshop/<Pasta>/Contents/mods/<Mod>/`** — a pasta de desenvolvimento, lida direto.

**O segundo é o caminho de desenvolvimento, e ele dispensa a cópia manual** — desenvolve e testa na
mesma pasta. É o modo em uso neste workspace (confirmado em 2026-08-06).

Evidência de runtime: nos logs, 149 linhas `Loading:` têm raiz `USER/Workshop/`, contra **zero** com
raiz `USER/mods/`:

```
[09-12-24 19:38:00.448] LOG  : Lua , 1733783880448> Loading: C:/Users/<usuario>/Zomboid/Workshop/ModTeste/Contents/mods/ModTeste/media/lua/client/mod_teste.lua.
```

`USER/Logs/logs_9-12/09-12-24_18-52-46_DebugLog.txt:45300`. Mods locais (ex.: `ModTeste`) carregam
assim.

**Não há motivo para copiar nada para `USER/mods/`, nem para criar link simbólico.** O mod continua
precisando ser ativado na tela de seleção de mods como qualquer outro — ser lido não é o mesmo que
estar ativo.

Censo, reproduzível a partir de `USER/Logs/`:

```
grep -rhoE "Loading: [A-Za-z]:/[^ ]*" . --include=*.txt | sed -E 's|(Loading: [A-Za-z]:/([^/]*/){3}).*|\1|' | sort | uniq -c
```

A lista de mods ativos é lida por `getModDirectoryTable()` + `getModInfo()`
(`PZ/media/lua/client/OptionScreens/ModSelector/ModSelectorModel.lua:61-62`) e o conjunto ativo é
manipulado por `ActiveMods.getById("default")` / `ActiveMods.getById("currentGame")`
(`MainScreen.lua:1163`, `:1167`). O `"default"` corresponde ao arquivo `USER/mods/default.txt`, que
tem blocos `mods { }` e `maps { }`.

## Onde o jogo escreve

| Arquivo | O que é |
|---|---|
| `USER/console.txt` | a sessão **atual**. Sobrescrito a cada execução |
| `USER/Logs/` | histórico por sessão, preservado |
| `USER/logs.zip` | janela rolante das **5 últimas** sessões, reescrita durante a partida |

`console.txt` é o primeiro lugar a olhar. Ele é curto (194 linhas na sessão de 04/08/2026), começa
com a data (`console.txt:1`) e termina em `GameThread exited.` (`console.txt:194`) quando o jogo
fecha limpo — se a última linha não é essa, o jogo morreu no meio.

**Confira a data antes de tirar conclusão dele.** Por ser sobrescrito, um `console.txt` antigo
descreve uma sessão que não é a que você acabou de rodar.

O cabeçalho carrega a versão exata do install, que não existe em arquivo nenhum do `PZ/`:

```
LOG  : General      f:0> version=42.20.2 ffe7a8a4b1 demo=false
LOG  : General      f:0> revision=ffe7a8a4b1 pzbullet=1.0.0.28
```

`console.txt:59-60`. É a única leitura possível da versão semântica — ver
[../fontes-externas.md](../fontes-externas.md). Como o arquivo é sobrescrito, **a leitura só vale se
a sessão for posterior ao último patch da Steam**: depois de um patch, o `console.txt` antigo segue
mostrando a versão anterior sem qualquer sinal de que está vencido.

**O jogo tem tecla de captura de tela própria: F10.** `bind.value = "Take screenshot"` com
`bind.key = Keyboard.KEY_F10` em `PZ/media/lua/shared/keyBinding.lua:190-191` — remapeável pela tela
de controles, como qualquer outro bind. Serve para material de divulgação (página da Workshop) sem
depender da sobreposição da Steam. **Onde o arquivo é gravado não foi confirmado**: `USER/Screenshots/`
não existe nesta máquina, o que é coerente com a tecla nunca ter sido usada aqui. Ver "Pontos a
confirmar".

`USER/Logs/` acumula (1.475 arquivos hoje), em pastas `logs_<D-MM>` ou `logs_<AAAA-MM-DD>`, com
arquivos `<DD-MM-AA>_<HH-MM-SS>_<tipo>.txt`. Os tipos mais frequentes: `DebugLog.txt` (507),
`client chat <nome>.txt`, `ZombieSpawn.txt` (90), `DebugLog-server.txt` (47). **O `DebugLog.txt` é
mais verboso que o `console.txt`** — é onde está o stacktrace completo.

### A rotação — o arquivo muda de lugar no boot *seguinte*

Enquanto a sessão roda, o `DebugLog.txt` dela fica **solto na raiz de `USER/Logs/`**. Ele só desce
para `logs_<AAAA-MM-DD>/` quando o **próximo** processo sobe — não quando o anterior morre. Medido
em 2026-08-29: a sessão das 09:58 gravou sua última linha às **10:10:48** (`GameThread exited.`,
`logs_2026-08-29/2026-08-29_09-58_DebugLog.txt:1088`) e a pasta `USER/Logs/logs_2026-08-29/` foi
criada às **10:11:16** — o instante em que a sessão seguinte (`2026-08-29_10-11_DebugLog.txt`)
começou, 28 s depois.

Consequência para quem só foi debugar depois de reabrir o jogo: **o log da sessão que quebrou não se
perde, ele muda de lugar.** Se não está mais na raiz de `USER/Logs/`, está na pasta do dia. É o
oposto do `console.txt`, que é sobrescrito de verdade.

E mesmo o `console.txt` sobrescrito é recuperável: `USER/logs.zip` guarda uma **janela rolante das 5
últimas** sessões, em `console/log_1.txt` … `log_5.txt` e `debug-log/log_1.txt` … `log_5.txt`, com
**`log_1` = a mais recente**. O zip é reescrito **durante** a partida, não só no boot — leitura de
2026-08-29 10:13, com o jogo aberto: `debug-log/log_2.txt` tinha 96.805 bytes, exatamente o tamanho
do `2026-08-29_09-58_DebugLog.txt` da sessão anterior, enquanto `log_1` acompanhava a sessão em
curso. Ele leva ainda `save/`, `save_old/`, `configs/`, `lua/`, `server/`, `db/` e um `meta/` com
`.md5` por arquivo; para que a IndieStone usa esse pacote, ver "Pontos a confirmar".

```sh
unzip -l ~/Zomboid/logs.zip | grep -E "console/log|debug-log/"
```

## Os canais de log

O próprio jogo imprime a configuração no boot (`console.txt:61-67`):

```
LOG  : General      f:0> Logs configuration:
LOG  : General      f:0>      General: General
LOG  : General      f:0>      Network: General
LOG  : General      f:0>          Lua: General
LOG  : General      f:0>          Mod: General
LOG  : General      f:0>  Multiplayer: General
LOG  : General      f:0>      Default: General
```

Seis canais, **todos** apontando para o destino `General`. O canal **`Mod`** é o que reporta
carregamento e sobrescrita de mod (`loading siddigoWeapons`, `mod "SkateboardMod" overrides
media/fileguidtable.xml`); o **`Lua`**, o carregamento de arquivo `.lua`.

*O `Default` já foi observado como `Off`* — leitura de 2026-08-04, sessão sem `-debug`. Na sessão de
2026-08-07, com `-debug`, ele aparece como `General`. Se quem muda é a flag ou o patch 42.20.2 não
foi isolado; para saber, basta comparar um boot sem a flag.

Do lado do Lua há mais canais que esses seis — censo dos usados em `PZ/media/lua`
(`grep -ro "DebugType\.[A-Za-z]*" media/lua --include=*.lua | sed 's/.*://' | sort | uniq -c`):

```
75 Foraging   42 CraftLogic   32 ISUI   19 Lua   14 Action
12 Grapple     8 Animal        7 GameOption  6 General   3 LuaObject
```

Como os dois conjuntos não batem, a relação entre `DebugType.*` e os canais do bloco de
configuração fica em "Pontos a confirmar".

## Formato das linhas — os dois são diferentes

**`console.txt`** usa `f:<frame>`:

```
LOG  : General      f:0> ===== System specs =====
ERROR: Mod          f:0 at ChooseGameInfo.readModInfoAux       > tiledef=fe_def 15000 file number must be from 100 to 8189
```

`console.txt:3` e `console.txt:177`. A linha de erro traz a classe e o método Java que reclamaram —
`ChooseGameInfo.readModInfoAux` é leitura de `mod.info`, então esse erro é de **metadado de mod**,
não de Lua.

**`USER/Logs/*_DebugLog.txt`** usa timestamp + epoch em ms:

```
[04-12-24 22:44:36.943] LOG  : General     , 1733363076943> -----------------------------------------
```

Mesma informação, cabeçalho diferente. Não tente casar um `grep` nos dois com um padrão só.

## Ler o stacktrace de Lua

O bloco é delimitado e **cada frame declara a origem**:

```
-----------------------------------------
STACK TRACE
-----------------------------------------
function: ModTeste_Distributions.lua -- file: ModTeste_Distributions.lua line # 14 | MOD: Mod Teste.
attempted index of non-table.
```

`USER/Logs/logs_14-12/14-12-24_18-11-48_DebugLog.txt`. O formato de cada frame é
`function: <nome> -- file: <arquivo>.lua line # <N> | <origem>`, e a **origem é `Vanilla` ou
`MOD: <name>`** — o `name=` do `mod.info`, não o `id=`. Censo em `USER/Logs/`: 17.695 `Vanilla`
contra 453 `MOD`.

```
grep -rhoE "line # [0-9]+ \| [A-Za-z0-9_' -]+" . --include=*.txt | sed -E 's/line # [0-9]+ \| //' | sort | uniq -c
```

**É a primeira coisa a olhar num stacktrace**: se todos os frames dizem `Vanilla`, o erro não é do
seu mod — ou é do seu mod causando erro em código do jogo, o que aparece como um frame `MOD` no meio
da pilha. Quando o erro vem do Java, um segundo bloco `ExceptionLogger.logException> Exception
thrown` segue o trace do Lua com a pilha Java (`logs_04-12/04-12-24_22-35-19_DebugLog.txt:4201` em
diante).

## Exceção Java pura — o "crash" que volta pro menu

O bloco `STACK TRACE` acima é o formato do erro que **passou pelo Lua**. Quando a exceção nasce e
morre no Java, não há bloco delimitado nenhum: vem a linha de erro, a mensagem, e um `Stack trace:`
seguido dos frames indentados.

```
ERROR: General      f:29376> IngameState.updateInternal> Exception thrown
	java.lang.NullPointerException: Cannot invoke "zombie.core.skinnedmodel.visual.HumanVisual.setHole(zombie.characterTextures.BloodBodyPartType)" because "humanVisual" is null at BloodClothingType.addHole(BloodClothingType.java:203).
	Stack trace:
		zombie.characterTextures.BloodClothingType.addHole(BloodClothingType.java:203)
		zombie.characters.IsoGameCharacter.fallenOnKnees(IsoGameCharacter.java:14826)
		[…]
		zombie.MainThread.mainLoop(MainThread.java:69)
		java.base/java.lang.Thread.run(Unknown Source)
```

`USER/Logs/logs_2026-08-29/2026-08-29_09-58_DebugLog.txt:626-658` (30 frames, elididos aqui), sessão
**sem nenhum mod ativo** no 42.20.4 (`b0bbce05d5`, `:58`). Cada frame é
`pacote.Classe.método(Arquivo.java:linha)` do `projectzomboid.jar`, que não é lido aqui: servem para
nomear o sistema culpado, não para ler o código. `BloodBodyPartType` é o enum irmão de
`BodyPartType` — ver [saude-e-corpo.md](saude-e-corpo.md).

**A exceção não fecha o jogo.** O que vem logo depois, no mesmo frame:

```
[29-08-26 10:07:59.720] LOG  : General      f:29376> Saving worldgen params.
[29-08-26 10:08:00.075] LOG  : General      f:29376> Saving GlobalModData.
[29-08-26 10:08:00.084] LOG  : General      f:29376> STATE: exit zombie.gameStates.IngameState.
```

`:659-661`. O jogo **salva** e sai do estado de partida para o menu principal; o processo continua
vivo e recarrega a partida dali. Três consequências para diagnóstico:

- **"O jogo crashou" pode ser volta-pro-menu, não fechamento.** São sintomas diferentes com logs
  diferentes — pergunte qual dos dois foi antes de procurar.
- **O save não se perde**: `Saving worldgen params` e `Saving GlobalModData` rodam *antes* da saída
  de estado.
- **`GameThread exited.` no fim do arquivo não desmente o crash.** A regra de "Onde o jogo escreve"
  (última linha diferente dessa = o jogo morreu no meio) vale para o fechamento **do processo**, e
  uma sessão pode ter tido um crash de estado no meio e ainda assim terminar limpa. No mesmo
  arquivo, o `GameThread exited.` do `:1088` é da **segunda** partida, carregada depois do erro.

## "Meu Lua chegou a carregar?"

O jogo registra **um `Loading:` por arquivo `.lua`**, com caminho completo:

```
LOG  : Lua         , 1734210775290> Loading: C:/Users/<usuario>/Zomboid/Workshop/ModTeste/Contents/mods/ModTeste/media/lua/server/Items/ModTeste_Distributions.lua.
```

Grepar o nome do seu arquivo nessas linhas é o teste mais barato que existe para separar dois
diagnósticos que parecem iguais in-game: **arquivo não carregou** (não aparece) × **carregou e não
fez efeito** (aparece, e o bug é de lógica ou de camada faltando — ver a matriz de camadas da skill
`criar-conteudo`).

## Modo debug

### Como o Lua detecta

Três formas convivem no `media/`:

| Chamada | Ocorrências | Exemplo |
|---|---|---|
| `isDebugEnabled()` | 42 | `PZ/media/lua/client/DebugUIs/DebugContextMenu.lua:30` |
| `getCore():getDebug()` | 36 | `PZ/media/lua/client/DebugUIs/DebugMenu/ISDebugMenu.lua:85` |
| `getDebug()` | — | `PZ/media/lua/client/BuildingObjects/ISUI/ISBuildMenu.lua:2` |

`isDebugEnabled()` é a forma que aparece no código novo do B42 (`Entity/ISUI/*`); `getDebug()` é a
global e `getCore():getDebug()` a mesma coisa pelo objeto `Core`. Não há evidência no `media/` de que
difiram — a confirmar.

Há ainda um bypass declarado em Lua: `ISDebugMenu.forceEnable`, inicializado `false` em
`ISDebugMenu.lua:8` e testado junto do modo debug em `ISDebugMenu.lua:85` e
`PZ/media/lua/client/ISUI/ISEquippedItem.lua:453` e `:873`.

### Opções de debug nomeadas

Independente do menu, o jogo guarda opções por chave string, com 48 usos:

```lua
if getDebug() and getDebugOptions():getBoolean("Entity.DebugUI") then
```

`PZ/media/lua/client/Entity/ISUI/Controls/ISComponentsTabPanel.lua:19`. Escrita e persistência em
`ISEntityInstancesPanel.lua:99` (`setBoolean`) e `ISCharacterDebugUI.lua:108` (`getDebugOptions():save()`).

### Como se liga

**Argumento de inicialização `-debug`**, configurado nas *opções de inicialização* do jogo dentro da
Steam (botão direito no jogo → Propriedades). Não é opção de menu nem arquivo de config: o jogo tem
de subir já com a flag.

O mecanismo confere com o install: `PZ/ProjectZomboid64.bat:7` termina a linha do `java` com
`%1 %2`, então argumento de linha de comando **chega** ao jogo, e `PZ/ProjectZomboidOpenGLDebug64.bat:5`
mostra o jogo consumindo uma flag desse formato (`-debuglog=Shader`).

> **Fonte:** conhecimento operacional do workspace, registrado em 2026-08-06. A string `-debug` não
> aparece em `PZ/media/` nem nos `.bat` — o parsing de argumento é Java, dentro de
> `PZ/projectzomboid.jar`, que não é lido aqui. É a única afirmação desta página sem `caminho:linha`,
> e está aqui porque o custo de não registrá-la é a próxima sessão refazer a busca e não achar de novo.

### Em servidor nada disso vale — são três travas diferentes

Tudo acima é singleplayer. Ligar debug contra um servidor dedicado falha por três motivos
independentes, e cada um tem cara de "o mod não funciona em MP":

**1. O servidor não tem flag `-debug`.** `zombie.network.GameServer` liga o modo debug por
**propriedade de sistema da JVM**, não por argumento de jogo:

```java
if (System.getProperty("debug") != null) { GameServer.debug = true; Core.debug = true; }
```

Ou seja `-Ddebug` **antes** do `-cp`, na linha do `java`. Os argumentos que o `GameServer` de fato
aceita são `-servername -adminusername -adminpassword -cachedir -ip -port -udpport -nosteam -coop
-debuglog -disablelog -console -gui -seed`; `-debug` não está entre eles e é ignorado em silêncio.
Detalhe operacional: `PZ/ProjectZomboidServer.bat` **não** encaminha `%*` (o cliente encaminha `%1 %2`,
`PZ/ProjectZomboid64.bat:7`), então argumento nenhum passa por esse `.bat` — quem testa servidor
escreve o próprio.

**2. No cliente, o menu de contexto ignora `-debug` em MP — o botão DEBUG, não.** O gate do menu de
contexto de debug troca de eixo quando há rede (`PZ/media/lua/client/DebugUIs/DebugContextMenu.lua:25-31`):

```lua
if isClient() then
    if not playerObj:getRole():hasCapability(Capability.UseDebugContextMenu) then
        return true
    end
elseif not isDebugEnabled() then
    return true
end
```

`isDebugEnabled()` só é consultado no ramo **sem** rede. Para o clique direito, em servidor a porta é
o **role** do jogador.

O botão **DEBUG** da barra lateral (o que abre o `ISDebugMenu`) não tem esse desvio. Ele é criado com
`getCore():getDebug() or (ISDebugMenu.forceEnable and not isClient())`
(`PZ/media/lua/client/ISUI/ISEquippedItem.lua:873`): em cliente de MP só o `forceEnable` é barrado, e
o `-debug` continua ligando o botão. Na prática, **só chega a vê-lo quem passa pela trava 3**. Se os
painéis dele funcionam contra o servidor é outra questão — ver "Pontos a confirmar".

**3. Cliente com `-debug` é chutado.** `ConnectToServer:OnConnected` chama `forceDisconnect()` se o
jogo subiu em debug e a conta não tem `ConnectWithDebug`
(`PZ/media/lua/client/OptionScreens/ConnectToServer.lua:271`) — com exceção do host de coop
(`isCoopHost()`).

**"Hospedar" pelo menu é coop, e é o atalho.** O servidor sobe como processo separado, com
`DebugLog-server.txt` próprio em `USER/Logs/`, recebe `-adminpassword` na linha de comando
(`USER/Logs/logs_2026-09-14/2026-09-14_14-20_DebugLog-server.txt:91`) e é informado de quem é o
host pelo console (`set-host-user@…`, `set-host-steamid@…`, `:1960-1962`). O login do host sai
marcado `isCoopHost=true` (`:1964`) — o mesmo teste da isenção da trava 3. Então quem hospeda com o
jogo subido em `-debug` não é chutado, e pelo `ISEquippedItem.lua:873` fica com o botão DEBUG.

**Mas o host de coop entra como `user`, e por isso fica sem o clique direito de debug.** Medido na
sessão coop de 2026-09-16 (cliente em `-debug`, hospedado pelo menu): todas as linhas do host em
`USER/Logs/2026-09-16_13-33_connections.txt` saem com `role="user"`, e o pacote de `ExtraInfo` do
servidor traz `"canUseDebugContextMenu" : false` e `"canUseLootZed" : false`
(`USER/Logs/2026-09-16_13-33_DebugLog-server.txt:3983`). Isso vale mesmo o host conectando com a
senha de admin do processo — `serverConnect(CoopConnection.username, CoopServer:getAdminPassword(), ...)`
(`PZ/media/lua/client/OptionScreens/CoopOptionsScreen.lua:668`). Pela tabela abaixo, `user` não tem
`UseDebugContextMenu` (piso `observer`) nem `AddItem` (piso `gm`): o submenu `Debug` do jogo **não
aparece**, e qualquer menu de mod com o mesmo gate some junto, sem erro no `console.txt`.

A armadilha é visual. No mesmo clique continuam aparecendo opções com o ícone de inseto —
`Tile Report`, `Room Report`, `Seed` —, o ícone que `addDebugOption` põe
(`PZ/media/lua/client/ISUI/ISContextMenu.lua:904-906`, `Item_Plumpabug_Left.png`; `Tile Report` é
`addDebugOption` em `ISWorldObjectContextMenu.lua:230`, os outros dois só pelo ícone), e o gate delas
não é o role. Ver essas opções prova que o cliente está em `-debug`, **não** que o role passou. O gate
delas não está em `media/lua` (`Tile Report` é definido em `ISWorldObjectContextMenu.lua:229-230`,
mas não há chamada Lua a ele) — "Pontos a confirmar".

Consequência para teste: **coop pelo menu não serve para exercitar nada atrás de capability.** Para
isso, servidor dedicado com o role do jogador elevado pelo console (`setaccesslevel`/`grantadmin`,
abaixo); para o resto, singleplayer em `-debug`. Se o processo do servidor coop herda o modo debug
do cliente continua sem linha no log — "Pontos a confirmar".

**A porta certa é o role.** `Roles.addStatic()` semeia oito roles embutidos, em ordem crescente:

| Role | O que ganha, para efeito de teste |
|---|---|
| `banned` | nada |
| `user` | `LoginOnServer` — é o role de quem entra sem privilégio |
| `priority` | + login prioritário |
| `observer` | + **`UseDebugContextMenu`**, teleporte, godmode/invisível em si mesmo |
| `gm` | + **`AddItem`**, `AddXP`, `UseLootZed`, `UseLootLog`, `CreateStory` |
| `moderator` | `Capability.values()` **menos** `ReloadLuaFiles`, `BypassLuaChecksum`, `RolesWrite`, `ConnectWithDebug`, `SaveWorld`, `QuitWorld`, `ChangeAndReloadServerOptions`, `UseMovablesCheat` |
| `admin` | `Capability.values()` — **tudo** |

Consequência prática: **só `admin` pode conectar com o cliente em `-debug`**, porque `moderator`
perde `ConnectWithDebug` explicitamente. E para spawnar item de teste o piso é `gm`, não `observer`.

Comandos de console do servidor que substituem o menu de debug (nomes conferidos em
`zombie.commands.serverCommands.*`, cada um anotado com a `Capability` que exige):
`setaccesslevel` (`ChangeAccessLevel`), `grantadmin`, `additem`, `reloadlua` e
`reloadalllua`/`reloadluaall` (`ReloadLuaFiles` — negada ao `moderator`).

*(As afirmações sobre `GameServer`, `Roles` e `Capability` vieram de `javap` sobre
`PZ/projectzomboid.jar` — ver [distribuicao-loot.md](distribuicao-loot.md), "Como isto foi levantado
— bytecode do `.jar`", para o baseline diferente delas.)*

## Menu de debug

`ISDebugMenu.OnOpenPanel()` (`ISDebugMenu.lua:84-97`) é o ponto de entrada, e só faz algo com o modo
debug ligado:

```lua
function ISDebugMenu.OnOpenPanel()
    if getCore():getDebug() or ISDebugMenu.forceEnable then
```

Quem chama é o botão `DEBUG` da UI (`ISEquippedItem.lua:453`). Os botões são montados em
`ISDebugMenu.lua:16-49`, em duas abas:

- **MAIN** — General, Cheats, Climate, CraftRecipes, Player, **Items**, Fluids, **Entities**,
  **Scripts**, XUI, RecipeMonitor, Sandbox.
- **DEV** — Audio, IsoRegions, Population, Stash, AnimMonitor, Radio, AnimViewer, AttachmentEditor,
  ChunkDebug, GlobalObjectDebugger, MapEditor, VehicleEditor, WorldFlares, GlobalModData, NewUI,
  UnitTests, CharacterDebug, ForgetRecipes.

Os quatro destacados são os que respondem "meu conteúdo entrou?": `Items` abre
`ISItemsListViewer` (`ISDebugMenu.lua:23`), `Scripts` abre `ISScriptsDebugWindow` (`:26`), `Entities`
abre `ISEntitiesDebugWindow` (`:25`) e `CraftRecipes` abre `ISCraftRecipeDbgWindow` (`:21`). Item que
não aparece nessas listas não foi parseado — o problema é do `.txt`, não da camada de mundo.

`Cheats` abre `ISAdminPowerUI` (`ISDebugMenu.lua:19`). O menu de contexto de debug (clique direito)
é `DebugContextMenu.lua`, com a condição em `:27-30`: em cliente, exige
`Capability.UseDebugContextMenu`; fora dele, `isDebugEnabled()`.

**Trocar a gravação de uma fita ou disco** — o atalho para testar conteúdo que depende de *uma*
gravação específica, sem sortear `VHS_Retail` até sair a certa. Clique direito num item cujo script
tem `RecordedMediaCat`, **no inventário do próprio jogador**, mostra `DBG: Change recording`
(`ADMIN:` para admin), com submenu de todas as gravações da categoria por
`getAllMediaForCategory` mais `<NONE>`; a condição é `getCore():getDebug() or isAdmin()`
(`PZ/media/lua/client/Context/Inventory/InvContextMedia.lua:11-24`). Em SP a escolha vira
`item:setRecordedMediaData(other)` direto; em cliente MP vai como `sendClientCommand` `item` /
`changeRecording` (`:32-46`), que o servidor só aplica com `Capability.EditItem`, por
`setRecordedMediaIndexInteger` (`PZ/media/lua/server/ClientCommands.lua:1223-1235`).

**`ISAdminPowerUI` ("Admin Powers", botão `Cheats` — "Trapaças" no PTBR) é onde fica o LootZed**,
ferramenta que mostra a chance calculada de spawn de cada item por container — usada para diagnosticar
item que "devia aparecer no loot e não aparece". Caixa `LootZed` na coluna direita do painel
(`ISAdminPowerUI.lua:190`, `ISAdminPowerUI.AddOption("LootZed", "right", Capability.UseLootZed, ...)`).
Com ela marcada, abrir/clicar qualquer container in-game mostra um ícone extra na janela do saque
(tooltip `ContextMenu_LootZed`); clicar nele lista `Type`/`Name`/`Chance` computados por
`SpawnRateChecker.lua` (`doRollItem_CalcChances`), fórmula `chance = (peso*lootModifier)/100`
acumulada por `1-(1-chance)^rolls`. Confirmado em uso em 2026-08-10, diagnosticando uma revista de
receita do `SiddigoWeapons` que não aparecia em loot natural — a chance calculada bateu (~40%), ou
seja o registro na lista procedural estava correto e a causa era outra (poucas listas, não peso).

**Não confundir com o botão vizinho `Ferramentas gerais de debug`** (`IGUI_DebugMenu_Main_General`,
`ISDebugMenu.lua:18`, abre `ISGeneralDebug` — abas "Jogo", "Corpo", "Sangue" e "Modo de Busca" no
PTBR, nessa ordem, `ISGeneralDebug.lua:21-25`). É um painel diferente e **não tem LootZed**;
confundir os dois foi o primeiro engano ao procurar a ferramenta nesta sessão.

### Acelerar o tempo do mundo

O único controle de tempo do modo debug é o slider **"Velocidade do Jogo"**
(`IGUI_GameDebugPanel_GameSpeed`, `PZ/media/lua/shared/Translate/PTBR/IG_UI.json:5542`), na aba
"Jogo" do `ISGeneralDebug`:

```lua
local gt = getGameTime();
self:addSliderOption(gt,getText("IGUI_GameDebugPanel_GameSpeed"), 0, 1000, 0.1, "getTrueMultiplier", "setMultiplier");
```

`ISGameDebugPanel.lua:41-42`. Faixa declarada **0 a 1.000**, passo 0,1, lendo `getTrueMultiplier()` e
escrevendo `setMultiplier()` no objeto de `getGameTime()`. **O 0 não é alcançável**: o handler puxa
qualquer valor abaixo de 1 de volta para 1 (`ISGameDebugPanel.lua:162-166`), então o slider só
acelera — não pausa nem desacelera abaixo do normal.

É o mesmo `setMultiplier` que os controles de velocidade da UI normal usam
(`ISUI/SpeedControlsHandler.lua:23`); o debug só solta o teto.

**`ISGameDebugPanel.lua:41` é a única linha de todo o `DebugUIs/` que chama `getGameTime()`** — as
outras duas ocorrências de `GameTime` na pasta são leitura, em `Scenarios/FenrisScenario.lua:540`
e `:543`. Consequência: **não existe no menu de debug um "definir hora do dia" nem um "avançar um
dia"**. Censo em `media/lua` inteiro: `setTimeOfDay()` tem 3 chamadas, todas fora de ferramenta de
debug (`Tutorial/TutorialSetup.lua:24`, `LastStand/LastStandSetup.lua:63`,
`erosion/debug/DebugDemoTime.lua:235`), e `setDay()` tem 4, todas em `DebugDemoTime.lua`.

#### O outro eixo — `DayLength` e o grupo `TimeOptions`

Multiplicador de relógio não é o mesmo que **duração do dia**. `DayLength` é opção de sandbox, do
tipo enum, e o rótulo diz o que ela mede: `Sandbox_DayLength` = "Duração do Dia (em tempo real)",
com as opções nomeadas em tempo real — `option1` = 15 minutos, `option3` = 1 hora, `option7` =
4 horas (`PZ/media/lua/shared/Translate/PTBR/Sandbox.json:33-40`). Os cenários de debug e os
desafios a fixam em 3 ou 4 (`DebugUIs/Scenarios/Trailer3Scenario.lua:16`,
`LastStand/28MinutesLater.lua:18`), e os presets de dificuldade também
(`shared/Sandbox/Apocalypse.lua:8` = 4, `shared/Sandbox/SixMonthsLater.lua:5` = 3).

Ela vive no grupo `TimeOptions`, junto de `TimeSinceApo`, `StartMonth`, `StartDay` e `StartTime`
(`OptionScreens/ServerSettingsScreen.lua:4368-4376`) — é ali que se mexe na **data e hora inicial**
do mundo. O botão `Sandbox` do menu de debug abre `ISServerSandboxOptionsUI`
(`ISDebugMenu.lua:29` e `:215-219`; a classe é Lua, em
`client/ISUI/AdminPanel/ISServerSandboxOptionsUI.lua:4`), e **o painel aplica com a partida
rodando** — `onButtonApply` chama `settingsFromUI(self.options)` e só envia ao servidor quando é
cliente (`ISServerSandboxOptionsUI.lua:763-773`).

A diferença que importa: `DayLength` é `SandboxVars`; "Velocidade do Jogo" escreve direto no
`GameTime`, sem passar por `SandboxVars`.

### Spawnar zumbi específico — o Gerenciador de Hordas

Com o modo debug ligado, botão direito no chão → **`Debug` → `Principal` → `Gerenciador de Hordas`**
(`ContextMenu_Debug`, `IGUI_DebugContext_Main`, `IGUI_DebugContext_HordeManager`;
`DebugContextMenu.lua:54-65`). O handler abre a janela `ISSpawnHordeUI` no quadrado clicado
(`DebugContextMenu.lua:1084-1085`). O gate é o mesmo do resto do menu de contexto
(`DebugContextMenu.lua:26-32`).

É essa janela que dá o **zumbi específico**, não só a quantidade. Controles, em
`ISSpawnHordeUI.lua:32-111`:

| Controle | O que define | Linha |
|---|---|---|
| Número de Zumbis | quantidade; **teto rígido de 500** por spawn | `:35-39`, `:292-295` |
| Raio | dispersão em torno do quadrado, sorteada com `ZombRand` | `:46-50`, `:272-275` |
| Deslocamento de Altura | offset vertical do spawn | `:56-60` |
| Traje do Zumbi | combo populado por `getAllOutfits(false)` e `getAllOutfits(true)`, com sufixo "Apenas Zumbis Masculinos/Femininos" quando o traje só existe para um sexo | `:71-85` |
| 9 tickboxes | Caído, Rastejante, Fingindo de Morto, Cair de Bruços, Invulnerável, Sentado, Gravação de Animações, Em Ragdoll, Em Chamas | `:93-101` |
| Saúde | slider 0 a 2, passo 0,1, default 1,0 | `:105-111` |

Os tickboxes se amarram entre si em `:164-185`: marcar Rastejante ou Fingindo de Morto força Caído, e
Rastejante força também Cair de Bruços.

**O traje sobrepõe o sexo do zumbi.** Se o traje só existe na lista masculina, `femaleChance` vira 0;
se só na feminina, 100 (`:219-224`). Não há controle de sexo separado na janela.

Em partida local o spawn é uma chamada por zumbi:

```lua
addZombiesInOutfit(x, y, z, 1, outfit, femaleChance, crawler, isFallOnFront, isFakeDead, knockedDown, isInvulnerable, isSitting, health, isRecordingAnims, heightOffset, isRagdolling, onFire);
```

`ISSpawnHordeUI.lua:276`. **É a assinatura completa de 17 argumentos** — a janela existe basicamente
para montá-la, então ela é a melhor referência de uso da função. Em cliente de multiplayer o caminho
é outro: a mesma configuração vira o comando `/createhorde2` enviado ao servidor (`:255-269`).

A função é global e há variantes usadas nos cenários do próprio jogo:
`addZombiesInOutfitArea` (`Scenarios/Trailer3Scenario_Roadtrip.lua:166`), `addZombiesInBuilding`,
`addZombiesEating` e `addZombieSitting` (`Scenarios/Trailer2_PoliceScenario.lua:108`,
`Scenarios/Trailer2_LimpWPScenario.lua:115` e `:118`). Assinaturas dessas variantes: a confirmar.

A mesma janela remove: **Remover Zumbis** e **Remover Cadáveres** agem no raio, e segurar **Shift**
no primeiro remove todos os zumbis carregados (`:304-317`, tooltip em `:147`).

Dois vizinhos que **não** fazem a mesma coisa:

- `Debug → UIs → Gerar Horda de Sobreviventes` (`IGUI_DebugContext_SpawnSurvivorHorde`,
  `DebugContextMenu.lua:92`) chama `getChunk():addSurvivorInHorde(true)` (`:1221-1222`) — sem
  parâmetro nenhum.
- `Add Zombie` (`DebugContextMenu.lua:526`, handler em `:629`) só é montado no ramo de
  cliente/admin de multiplayer.

## Ferramentas de Lua

Todas penduradas no `DebugToolstrip`, que é criado por `LuaDebugger.lua:127` — a barra não é
independente, vem com o debugger.

| Ferramenta | O que faz | Onde |
|---|---|---|
| `LuaFileBrowser` | lista os `.lua` carregados (`getLoadedLuaCount()` / `getLoadedLua(i)`) com filtro por nome, e um botão **Reload** por linha | `LuaFileBrowser.lua:60-71`, `:93-102` |
| `SourceWindow` | mostra o fonte do arquivo e recarrega | `SourceWindow.lua:28` |
| `DebugErrorsWindow` | acumula os erros de Lua da sessão, via `getLuaDebuggerErrors()`; atualiza quando `getLuaDebuggerErrorCount()` muda | `DebugErrorsWindow.lua:21-38` |
| `DebugLogSettings` | severidade mínima por `DebugType`, em perfis | `DebugToolstrip.lua:21-26` |
| Break on error | `UIManager.setShowLuaDebuggerOnError(selected)` | `DebugToolstrip.lua:28-30` |
| Step Into / Step Over / Resume | `doLuaDebuggerAction("StepInto")` etc. | `DebugToolstrip.lua:42-52` |

## Recarregar sem reiniciar

Existem dois níveis, e é a diferença que importa.

**Um arquivo** — `reloadLuaFile(<caminho>)`, 15 usos no `media/`. O caminho é relativo à raiz do
jogo:

```lua
reloadLuaFile("media/lua/client/Music/MusicIntensityConfig.lua")
```

`PZ/media/lua/client/DebugUIs/DebugMenu/Audio/ISMusicIntensityEventsPanel.lua:78`. É o que o botão
Reload do `LuaFileBrowser` chama (`LuaFileBrowser.lua:100`).

**O ambiente inteiro** — `getCore():ResetLua(<id>, <motivo>)`. É o mecanismo que o próprio jogo usa
quando a seleção de mods muda:

```lua
function MainScreen.resetLuaIfNeeded()
    local defaultMods = ActiveMods.getById("default")
    if ActiveMods.requiresResetLua(defaultMods) then
        local currentMods = ActiveMods.getById("currentGame")
        currentMods:copyFrom(defaultMods)
        getCore():ResetLua("default", "modsChanged")
    end
end
```

`MainScreen.lua:1162-1171`. Outros pontos de disparo: `ModSelectorModel.lua:296` e `:299` (ao
confirmar a tela de mods), `MainScreen.lua:1237` (ao continuar um save cuja lista de mods difere) e
`MainOptions.lua:3404`, que usa a variante `DelayResetLua`. A condição em todos é
`ActiveMods.requiresResetLua(...)`.

**Consequência prática:** mexer na seleção de mods na tela de seleção força o jogo a reler o Lua sem
fechar. Não é hot-reload de arquivo salvo em disco — é o ciclo suportado que chega mais perto.

**As tabelas de loot também recarregam sem reiniciar**, de carona no painel `Sandbox`: o
`onButtonApply` do `ISServerSandboxOptionsUI` chama `IsoWorld.parseDistributions()` e
`StoryClutter.Init()` logo depois de aplicar as opções, com o comentário do próprio jogo dizendo que
é *"so mod stuff distribution stuff can get applied"* (`ISServerSandboxOptionsUI.lua:768-771`).
Aplicar o painel sem mudar nada é, portanto, o jeito de reprocessar distribuição de loot com a
partida rodando. Ver [distribuicao-loot.md](distribuicao-loot.md).

### Com servidor no ar, o fonte do mod é imutável — editar derruba o cliente

Tudo acima é singleplayer. Em multiplayer, cliente e servidor comparam os arquivos de mod, e um
`.lua` salvo no disco durante a sessão faz o cliente ser recusado com:

```
File doesn't match the one on the server:
media/lua/server/<caminho relativo, em minúsculas>.lua
<caminho local, com a caixa real>
```

Quem faz é `zombie.network.packets.service.ChecksumPacket`, e o que o `javap` sobre ele mostra:

- **Três escopos, checados em separado** — os campos `okLua`, `okScript` e `okAnim`. Não é só Lua:
  `.txt` de `media/scripts` e animação entram no mesmo aperto.
- **A comparação afunila** — `PacketTotalChecksum` → `PacketGroupChecksum` → `PacketFileChecksums`.
  É por isso que a mensagem nomeia o arquivo exato em vez de só dizer que os mods diferem.
- **Três motivos de recusa**, os bytes `FileDifferent`, `FileNotOnServer` e `FileNotOnClient`, que
  viram "File doesn't match the one on the server", "File doesn't exist on the server" e "File
  doesn't exist on the client". **Acrescentar** arquivo quebra igual a editar um existente.
- **O checksum é alimentado no carregamento dos assets**, por `LuaManager`, `ScriptManager`,
  `AdvancedAnimator` e `IsoWorld`, todos escrevendo em `zombie.network.NetChecksum.checksummer`.

Consequência para o ciclo de teste: **não existe o equivalente do `reloadLuaFile` aqui.** Para trocar
uma linha, derruba-se o servidor, edita e sobe de novo. Editar durante o teste não é uma mudança que
"não pega" — é o cliente perdendo a sessão, e a mensagem aparece na tela preta de conexão, sem passar
pelo `console.txt` do jogo.

Observado em 09/09/2026 nesta máquina, editando um `.lua` de `server/` do mod com a partida
em andamento.

## Log do próprio mod

Duas formas, ambas usadas pelo jogo:

```lua
print("mensagem")                                  -- forma simples
log(DebugType.Lua, "mensagem")                     -- 150 usos
DebugType.General:warn("mensagem")                 -- 67 usos somando os métodos
```

`PZ/media/lua/client/DebugUIs/SourceWindow.lua:254` e
`PZ/media/lua/client/gamepadBinding.lua:81`. Os métodos do canal são `debugln` (24), `trace` (16),
`warn` (15), `printStackTrace` (6), `error` (4) e `noise` (2). A forma com método aceita argumentos
de formatação:

```lua
DebugType.Lua:error("Malformed EntityLayout.ini, unexpected line before player %s and window %s values were read.", currentPlayer, currentWindowKey)
```

`PZ/media/lua/client/Entity/ISEntityUI.lua:666`.

### Duas armadilhas verificadas

**Acento sai corrompido no log.** Um `print("Esse é meu primeiro mod!")` de um mod do workspace saiu
como `Esse ? meu primeiro mod!` — observado em `USER/Logs/` (02/12/2024) e de novo em
`USER/console.txt:885` (07/08/2026), ou seja, é estável, não foi um acidente de sessão. O boot declara
`sun.jnu.encoding=Cp1252` e `native.encoding=Cp1252` (`console.txt:15` e `:50`) contra
`file.encoding=UTF-8` (`:41`) — o descasamento entre os dois é a causa provável.

**Isso é corrupção de *log*, não necessariamente de *jogo*.** O que se provou é que o texto chega
mastigado ao arquivo; se a mesma string renderiza certo na tela do jogo não foi verificado. Não
conclua pelo `console.txt` que sua string acentuada está quebrada in-game. Para mensagem de debug,
use ASCII — o acento não quebra nada e ainda atrapalha o `grep` que você vai fazer depois.

**Em que canal cai o `print()` de um mod.** Na sessão de 07/08/2026 caiu em `LOG  : Lua`
(`console.txt:885`). Numa observação anterior o mesmo `print()` foi registrado como `LOG  : General`,
o que não se sustentou. Como nessa sessão os seis canais apontam todos para o destino `General` (ver
"Os canais de log"), é possível que o rótulo à esquerda seja a **origem** e não o destino — o que
explicaria as duas leituras. Não isolado; ver "Pontos a confirmar".

## Pontos a confirmar

- **Host de coop: se o servidor herda o debug, e se dá para elevar o role do host.** O role já está
  medido (`user`, ver "Hospedar pelo menu é coop"). Falta: uma linha que diga se o processo coop subiu
  com `-Ddebug` (quem lança está no `projectzomboid.jar`); e um caminho para promover o host sem
  servidor dedicado — ele não tem console, e `setaccesslevel` exige `ChangeAccessLevel`, que `user`
  não tem. `CoopServer:sendMessage(tag, payload)` escreve no `System.in` do processo
  (`CoopOptionsScreen.lua:658` vira `"set-host-user@…"` em
  `USER/Logs/2026-09-16_13-33_DebugLog-server.txt:2457`), mas se o servidor aceita comando de console
  comum por esse canal não foi testado.
- **O gate de `Tile Report`, `Room Report` e `Seed` no clique direito.** Aparecem em cliente coop
  `-debug` com role `user`; `addDebugOption` só as esconde por `UI.HideDebugContextMenuOptions`
  (`ISContextMenu.lua:908`), e a chamada de `ISWorldObjectContextMenu.addTileDebugInfo` não está em
  `media/lua`. Provavelmente `getCore():getDebug()` do lado Java; não levantado.
- **Se os painéis do `ISDebugMenu` funcionam em cliente de MP.** O botão aparece com `-debug`
  (`ISEquippedItem.lua:873`), mas os painéis foram escritos para o singleplayer; quais mexem só no
  estado local, quais mandam comando ao servidor e quais não fazem nada não foi levantado.

- **Em que momento o checksum de rede é calculado, e se ele é refeito depois.** Está provado que
  `LuaManager`, `ScriptManager`, `AdvancedAnimator` e `IsoWorld` alimentam
  `zombie.network.NetChecksum.checksummer`; a lista de métodos não diz se isso acontece só no
  carregamento nem se a checagem roda de novo no meio de uma sessão já estabelecida. O caso
  observado foi na conexão. Importa para saber se editar o arquivo com o servidor no ar quebra
  **agora** ou só no próximo login.

- **Assinatura das variantes de `addZombiesInOutfit`.** Só a de 17 argumentos está provada, pelo uso
  em `ISSpawnHordeUI.lua:276`. `addZombiesInOutfitArea`, `addZombiesInBuilding`, `addZombiesEating` e
  `addZombieSitting` aparecem só em `DebugUIs/Scenarios/` com literais posicionais
  (`Trailer3Scenario_Roadtrip.lua:166`, `Trailer2_PoliceScenario.lua:108`,
  `Trailer2_LimpWPScenario.lua:115` e `:118`) — dá para inferir a ordem, não o contrato. São globais
  Java, não definidas em `media/lua`.
- **Se a "Velocidade do Jogo" persiste no save.** O slider escreve em `GameTime` via `setMultiplier`
  (`ISGameDebugPanel.lua:42`) e não toca `SandboxVars`; se o valor sobrevive a sair e recarregar a
  partida não foi verificado — é um teste in-game de dois minutos.
- **Onde o F10 grava a captura de tela.** O bind existe (`keyBinding.lua:190-191`), mas
  `USER/Screenshots/` não existe nesta máquina e nada no `media/lua` nomeia o destino — quem escreve
  o arquivo está no `projectzomboid.jar`. Resolver é barato: apertar a tecla uma vez e procurar o
  arquivo novo em `USER/`.
- **Confirmação em código do `-debug`.** A flag está registrada acima como conhecimento operacional;
  provar pelo código exige ler `PZ/projectzomboid.jar`. A doc da comunidade não ajuda: o PZ-API-Docs
  não tem seção de debug/log (índice consultado em 2026-08-06) e `pzwiki.net/wiki/Debug_mode`
  responde HTTP 403.
- **Se `-debug` muda `isDebugEnabled()`, `getDebug()` ou os dois.** As três formas de detecção
  convivem e nada no `media/` diz se respondem à mesma flag.
- **A relação entre `DebugType.*` (10 canais no Lua) e os 6 canais do bloco "Logs configuration".**
  Os conjuntos não batem e o mapeamento não está no `media/lua`.
- **Se `isDebugEnabled()`, `getDebug()` e `getCore():getDebug()` diferem.** Convivem no mesmo build;
  nada no `media/` distingue.
- **Qual canal recebe um `print()`** e por quê. A sessão de 2026-08-07 mostra `print()` de **mod**
  caindo no canal `Lua` (`LOG : Lua f:0> Esse ? meu primeiro mod!`, `console.txt:885`), o que
  contradiz a observação anterior de `General` para mod. Como nessa sessão os seis canais apontam
  todos para o destino `General`, pode ser que o rótulo à esquerda seja a origem e não o destino —
  não isolado.
- **Se `DebugErrorsWindow` chega a aparecer sem modo debug.** O arquivo não tem condição própria; ela
  é aberta pelo `DebugToolstrip`, que vem do `LuaDebugger`. Não foi possível determinar o gate final.
- **O que o jogador vê quando a exceção Java derruba o `IngameState`.** O log prova a volta ao menu
  (`STATE: exit zombie.gameStates.IngameState`), não se houve janela de erro na tela — quem estava
  jogando em 2026-08-29 não registrou. Resolver não custa nada: da próxima vez, olhar a tela.
- **Para que serve `USER/logs.zip`.** O conteúdo está levantado (janela de 5 sessões + `save/`,
  `configs/`, `lua/`, `server/`, `db/`, `meta/` com `.md5`), mas quem o consome não: o formato é de
  pacote de suporte, e a hipótese óbvia é anexo de report de bug para a IndieStone. Nada no `media/`
  nomeia o arquivo — quem escreve está no `projectzomboid.jar`.
- **Se `reloadLuaFile` reexecuta o arquivo de um mod.** Todo caminho observado é literal e relativo à
  raiz do jogo, mas o uso mais informativo é montado: `doMapZones()` faz
  `reloadLuaFile('media/maps/'..dirName..'/objects.lua')` com `dirName` vindo de
  `getLotDirectories()` (`lua/server/metazones/metazoneHandler.lua:86-90`, ver
  [mapas-e-zonas.md](mapas-e-zonas.md)). Para um mod de mapa funcionar, essa lista tem de incluir a
  pasta do mod — o que implicaria `reloadLuaFile` resolvendo pelo `media/` **mesclado**, e não só
  pelo do install. É a melhor pista disponível, e continua sendo inferência: nada prova que
  `getLotDirectories()` inclui mod.
- **O log de erro de `%` em tradução** [novo 42.20.2]. As notas dizem que o jogo passa a popular o
  log apontando a chave que ainda usa `%` em vez de `%%`. A sessão de 2026-08-07 rodou já no 42.20.2 e
  **não produziu nenhuma linha** com `%%` ou `percent` — mas nenhum mod ativo usava `%` em tradução,
  então é ausência de gatilho, não prova de ausência. Contrato do `%%`:
  [carregamento-de-mods.md](carregamento-de-mods.md).
- **Informação de memória junto do debug de FPS** [novo 42.20.2]. Anunciado nas notas; o
  levantamento não achou o toggle no `media/lua` — presumivelmente é Java, como o resto do overlay
  de FPS. O overlay observado em 2026-08-07 mostra versão, coordenadas e resolução, **sem** linha de
  memória; se depende de outro toggle, não foi localizado.

> Última verificação: 2026-08-07 — jogo **42.20.2** (`ffe7a8a4b1`), PZ buildid 24574865,
> media/ + USER/ (console.txt de 2026-08-07 18:46, sessão com `-debug`; Logs/ com 1.475 arquivos).

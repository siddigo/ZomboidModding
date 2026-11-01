# Persistência e multiplayer — `ModData` e o canal cliente↔servidor

Onde um mod guarda estado que sobrevive ao save, e como as duas metades conversam quando o jogo é
multiplayer. É a área onde um mod funciona perfeitamente em singleplayer e quebra em servidor.

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\` (ver
[../index.md](../index.md)). **Somente leitura.**

Os eventos citados aqui estão catalogados em [eventos-lua.md](eventos-lua.md); a separação
`client/`/`server/`/`shared/` está em [mapa-media.md](mapa-media.md).

## As duas formas de persistir

| | `ModData` global | `:getModData()` por objeto |
|---|---|---|
| Escopo | o save inteiro | um item, um `IsoObject`, um `IsoGridSquare`, um personagem |
| Chave | string que você escolhe | a própria instância |
| Criação | `ModData.getOrCreate("nome")` | `obj:getModData()` |
| Sincroniza | `ModData.transmit("nome")` | junto com o objeto |

A segunda é de longe a mais usada no jogo. Censo de `:getModData()` em `media/lua`, por tipo de dono:

```
41  item      36  isoObject   33  player
32  carcass   32  body        26  square
21  object    13  globalObject
```

Ela não pede registro nem evento: `item:getModData().meuCampo = 1` já persiste com o item. É a via
default para estado ligado a **uma coisa**.

`ModData` global existe para estado que não pertence a objeto nenhum — o exemplo do jogo é o mapa de
zonas de coleta.

### A terceira forma, que parece existir e não persiste: `getGameTime():getModData()`

`GameTime` também expõe `getModData()`, e a chamada funciona — devolve uma `KahluaTable` normal, que
aceita escrita e sobrevive a sessão inteira. Parece a via óbvia para estado do save que não pertence
a objeto nenhum. **Não é: essa tabela nunca é gravada.**

- `GameTime.getModData()` só cria o campo `table` sob demanda e o devolve.
- Nenhum dos `GameTime.save(...)` toca esse campo — as duas únicas referências a ele em toda a classe
  são o próprio getter e o `saveToPacket`.
- `GameTime.saveToPacket(ByteBufferWriter)` não serializa a tabela: ele faz `rawget` de **três chaves
  fixas** — `camping`, `farming`, `trapping` — e manda só isso.

Ou seja, o que um mod escrever ali some no próximo boot, sem erro nenhum, e em multiplayer não chega
ao outro lado a não ser que a chave seja uma daquelas três. O uso vanilla é coerente com isso: as
únicas três ocorrências no `media/lua` gravam `isRaining`
(`PZ/media/lua/server/Seasons/season.lua:207`, `:283`, `:304`) — estado **de sessão**, não de save.

**Para estado de save que não é de objeto, a via é `ModData.getOrCreate(nome)`**, que grava em
`global_mod_data.bin` (`zombie.world.moddata.GlobalModData`, constante `SAVE_FILE`) e existe no
servidor dedicado — `zombie.network.ServerMap` referencia a classe, e o vanilla a usa em código de
servidor (`PZ/media/lua/server/Foraging/forageServer.lua:26`,
`PZ/media/lua/server/Vehicles/ProfessionVehicles.lua:18`).

E sobrevive a restart do servidor dedicado — observado em 2026-09-14 (mod de teste): uma
marca gravada nessa tabela às 12:57 continuava valendo depois do restart das 13:01. O comando das
13:16 (`USER/Logs/2026-09-14_13-01_cmd.txt:7`) entregou a parte da recompensa que a marca não
bloqueia (`USER/Logs/2026-09-14_13-01_DebugLog-server.txt:2668-2671`) e pulou a que ela bloqueia.

*(As afirmações sobre `GameTime` e `GlobalModData` vieram de `javap` sobre `PZ/projectzomboid.jar` —
ver [distribuicao-loot.md](distribuicao-loot.md), "Como isto foi levantado — bytecode do `.jar`".)*

## `ModData` global — a API

Só seis funções aparecem em todo o `media/lua`:

| Função | Usos | Onde |
|---|---|---|
| `ModData.getOrCreate(nome)` | 7 | `forageClient.lua:7`, `forageServer.lua:26`, `ProfessionVehicles.lua:18` |
| `ModData.remove(nome)` | 2 | `forageClient.lua:16`, `forageServer.lua:33` |
| `ModData.Add(...)` | 2 | |
| `ModData.transmit(nome)` | **1** | `forageServer.lua:49` |
| `ModData.getTableNames()` | 1 | `DebugUIs/DebugMenu/GlobalModData/GlobalModData.lua:82` |
| `ModData.get(nome)` | 1 | `GlobalModData.lua:144` |

Repare no `Add` maiúsculo — a API não é uniforme na caixa.

`ModData.getTableNames()` e `ModData.get()` só aparecem no painel de debug, que é justamente a
ferramenta para inspecionar isso em runtime (canal `GlobalModData` da lista de
[testar-e-debugar.md](testar-e-debugar.md)).

### O padrão canônico

`PZ/media/lua/server/Foraging/forageServer.lua` e o par em `client/Foraging/forageClient.lua` são o
exemplo completo — a mesma tabela nos dois lados, criada no mesmo evento:

```lua
-- client/Foraging/forageClient.lua:7-9
	forageData = ModData.getOrCreate("forageData");
…
Events.OnInitGlobalModData.Add(forageClient.init)
```

```lua
-- server/Foraging/forageServer.lua:26
forageData = ModData.getOrCreate("forageData");
```

E a sincronização, que é uma linha só (`forageServer.lua:48-50`):

```lua
function forageServer.syncForageData()
    ModData.transmit("forageData");
end
```

Três contratos aí:

1. **`getOrCreate` é chamado nos dois lados**, com a mesma string. Não há "declarar no servidor e
   ler no cliente" — cada lado obtém a sua referência.
2. **`OnInitGlobalModData` é o evento de entrada.** Antes dele a tabela não existe. Ver
   [eventos-lua.md](eventos-lua.md).
3. **`transmit` é explícito e só do servidor para o cliente.** Escrever na tabela **não** propaga
   nada sozinho — este é o erro clássico: funciona em singleplayer (onde os dois lados são o mesmo
   processo) e some em servidor.

`ProfessionVehicles.lua:344` mostra a variante de inicialização única:

```lua
	if isNewGame then ModData.getOrCreate("UniqueVehiclesSpawned") end
```

## O canal de comando

O par `sendClientCommand` / `sendServerCommand` é o RPC do PZ. Os dois despachantes ficam em
arquivos de nome **cruzado**, o que confunde:

| Arquivo | Raiz | Trata |
|---|---|---|
| `PZ/media/lua/server/ClientCommands.lua` | `server/` | o que o **cliente enviou** |
| `PZ/media/lua/client/ServerCommands.lua` | `client/` | o que o **servidor enviou** |

O nome descreve a **origem** da mensagem, não onde o arquivo roda.

### A guarda da primeira linha

Cada um começa se auto-desligando do lado errado:

```lua
-- lua/server/ClientCommands.lua:1
if isClient() then return end
```

```lua
-- lua/client/ServerCommands.lua:1
if not isClient() then return end
```

Esse idioma de guarda é onipresente: `isClient()` aparece **614 vezes** em `media/lua` e `isServer()`
**281**. `isCoopHost()` (2 usos) e `isDedicated()` (5) são raros.

### O despacho

Os dois arquivos montam uma tabela `Commands[módulo][comando]` e registram um único listener no
final. Servidor (`ClientCommands.lua`, últimas linhas):

```lua
ClientCommands.OnClientCommand = function(module, command, player, args)
	if Commands[module] and Commands[module][command] then
		…
		Commands[module][command](player, args)
	end
end

Events.OnClientCommand.Add(ClientCommands.OnClientCommand)
```

Cliente (`ServerCommands.lua`, últimas linhas):

```lua
ServerCommands.OnServerCommand = function(module, command, args)
    if Commands[module] and Commands[module][command] then
        …
        Commands[module][command](args)
    end
end
Events.OnServerCommand.Add(ServerCommands.OnServerCommand)
```

**As assinaturas dos handlers diferem.** No servidor o handler recebe `(player, args)`; no cliente,
só `(args)` — não há "de quem veio", porque só pode ter vindo do servidor. Escrever o handler de
cliente com `(player, args)` faz `player` receber a tabela de argumentos, silenciosamente.

O `if Commands[module] and Commands[module][command]` é a outra falha calada: comando não registrado
é **ignorado sem erro**. Nada aparece no `console.txt`.

### Enviar

Uso observado em `media/lua`:

```lua
sendClientCommand(playerObj, "item", "changeRecording", { itemID = _item:getID() })
sendClientCommand(self.player, 'object', 'addFireOnSquare', args)
```

`sendServerCommand` aparece em **duas aridades**:

```lua
sendServerCommand(chr, 'ui', 'dirtyUI', { })          -- para um jogador
sendServerCommand('erosion', 'disableForSquare', args) -- sem jogador
```

A forma de 3 argumentos omite o destinatário — compatível com difusão para todos os clientes, mas
isso não está declarado em lugar nenhum do `media/lua` (ver pendências).

Os argumentos vão numa **tabela**, e os dois despachantes iteram com `pairs(args)` só para log, o
que indica tabela plana de valores simples. `ServerCommands.lua` traz o comentário
`-- Can be nil if sending an empty table`, ou seja, **tabela vazia chega como `nil`** do outro lado —
todo handler precisa tolerar `args == nil`.

#### As variantes `…V`

Existe um segundo par, que troca a tabela por pares chave/valor variádicos:

| Função | Ocorrências | Arquivos |
|---|---|---|
| `sendClientCommand` | 70 | 35 |
| `sendClientCommandV` | 43 | 8 |
| `sendServerCommand` | 24 | 20 |
| `sendServerCommandV` | 6 | 3 |

```lua
-- PZ/media/lua/shared/Fishing/FishingRod.lua:322
sendClientCommandV(self.player, "fishing", "brokeRodLine", "itemID", self.rodItem:getID())
-- e sem argumento nenhum, :344
sendClientCommandV(self.player, "fishing", "missFish")
```

O handler do outro lado continua recebendo `args` como tabela — a variante só evita montar a tabela
no chamador. Se ela aceita valor aninhado, não foi levantado.

### Em singleplayer o despachante do servidor **está ligado**

Esta página afirmava o contrário como pendência. Está resolvido, e a resposta importa porque decide
se um mod baseado em comando funciona fora de servidor.

Em singleplayer **`isClient()` e `isServer()` são os dois falsos**. Quem nomeia isso é o próprio
jogo, em `PZ/media/lua/shared/TimedActions/ISFitnessAction.lua:158`:

```lua
	local isSinglePlayerMode = (not isClient() and not isServer());
```

Aplicando isso às guardas de topo da seção anterior, o resultado é **assimétrico**:

| Arquivo | Guarda | Em singleplayer |
|---|---|---|
| `server/ClientCommands.lua` | `if isClient() then return end` | **carrega e registra** o handler |
| `client/ServerCommands.lua` | `if not isClient() then return end` | **retorna na linha 1** |

Ou seja: `sendClientCommand` funciona em SP e o handler roda; `sendServerCommand` não tem para quem
entregar. O comentário de `PZ/media/lua/server/Map/SGlobalObjectSystem.lua:36` diz o mesmo em prosa —
*"server-side systems are created in singleplayer"*.

E há a confirmação direta de que a entrega acontece, com o detalhe que pega quem testa só em SP
(`PZ/media/lua/shared/Vehicles/TimedActions/ISWashVehicle.lua:110`):

```lua
        -- Don't forceComplete(); there is a delay before the client command is processed (even in singleplayer).
```

**O comando é assíncrono mesmo em singleplayer.** Não é chamada de função: quem depende do efeito
não pode assumir que ele já ocorreu na linha seguinte.

Isso bate com o PDF oficial `API for Inventory Items` (seção 4), vendorado em
`../oficial/API-for-Inventory-Items-v1.0.pdf`, que declara o mesmo para `sendClientCommand`.

### Autorização é do handler

O servidor não valida nada por você. O jogo checa capacidade dentro do próprio comando
(`ClientCommands.lua`, `Commands.debugScenario.addEnclosure`):

```lua
    if not player:getRole():hasCapability(Capability.UseDebugContextMenu) then
        print("debugScenario.addEnclosure denied for "..tostring(player:getUsername()))
        return
    end
```

Um comando de mod sem essa checagem é executável por qualquer cliente com os argumentos que ele
quiser. Vale para qualquer coisa que dê item, XP ou altere o mundo.

### `getRole()` é `null` em singleplayer — copiar aquela linha derruba o handler

O bloco acima é o idioma do **jogo**, e o jogo só chega nele em multiplayer. Copiado cru para o
handler de um mod, ele estoura assim que o comando chega em SP:

```
attempted index: hasCapability of non-table: null
```

(`KahluaThread.tableget`; observado em `USER/console.txt`, sessão de 2026-09-16, no handler de
`OnClientCommand` de um mod de teste.)

Quem é `null` é o retorno de `player:getRole()`, **não** o `player`: o `player` chega válido e o
`getRole()` é chamado nele sem erro — o que falta em SP é o *role*, não o jogador.

Por que o jogo nunca cai nisso: `PZ/media/lua/server/ClientCommands.lua:640`
(`debugAction.getBuildingKey`) chama `getRole()` sem guarda nenhuma, mas **só é alcançável em MP**.
Quem o dispara é `PZ/media/lua/client/DebugUIs/DebugContextMenu.lua:696-700`, que só manda o comando
dentro de `if isClient()` e, fora disso, faz o trabalho localmente e retorna:

```lua
function DebugContextMenu.OnGetBuildingKey(worldobjects, player)
	if isClient() then
		sendClientCommand(getSpecificPlayer(player), 'debugAction', 'getBuildingKey', {})
		return
	end
```

Um mod que mande o comando **incondicionalmente** — o caminho natural, já que o despachante do
servidor está ligado em SP (seção acima) — alcança aquele handler em SP e morre na primeira linha.

**O idioma canônico é curto-circuito atrás de `isMultiplayer()`, nunca nil-check de `getRole()`.** É
o que todo chamador de `shared/` faz, sempre na mesma forma:

```lua
    if isMultiplayer() and character:getRole():hasCapability(Capability.CanMedicalCheat) then
```

`PZ/media/lua/shared/TimedActions/ISCleanBurn.lua:104`, `ISComfreyCataplasm.lua:105`,
`ISRemoveGlass.lua:66` e `ISStitch.lua:114`. Não há chamada a `getRole()` fora de MP em `media/lua`.
O curto-circuito também evita tocar em `Capability`, que só é indexado no ramo de MP.

Para o fallback de singleplayer, `isDebugEnabled()` é chamável do lado servidor
(`PZ/media/lua/server/CraftRecipeCode/CraftRecipe_BuildMenu.lua:8`).

**Não troque `isMultiplayer()` por `isClient()` nesse teste.** Em servidor dedicado `isClient()` é
falso — é justamente o que faz `server/ClientCommands.lua` carregar lá, dado o
`if isClient() then return end` do topo (tabela da seção anterior). Usar `isClient()` mandaria o
servidor dedicado para o ramo de fallback e pularia a checagem de capability exatamente onde ela é a
única proteção.

### Depurar

`ClientCommands.lua` liga o log pelo modo debug:

```lua
ClientCommands.wantNoise = getDebug()
local noise = function(msg)
	if (ClientCommands.wantNoise) then print('ClientCommand: '..msg) end
end
```

O lado cliente é mais barulhento — `ServerCommands.OnServerCommand` chama `print` **sem gate**, então
todo comando recebido aparece. Ver [testar-e-debugar.md](testar-e-debugar.md).

## Sincronizar item e objeto — a via principal **não** é o comando

O canal de comando acima é a via alternativa. A via principal, segundo o PDF oficial
`API for Inventory Items` (`../oficial/API-for-Inventory-Items-v1.0.pdf`, doc v1.0, 42.13), é a
**TimedAction**: o `complete()` roda no servidor, cria/remove/altera o item ali, e chama uma função
de sincronização. O contrato completo, com o exemplo trabalhado e o censo das dez funções, está em
[timedactions.md](timedactions.md) — seção "A arquitetura multiplayer".

O que importa saber aqui é **quando usar cada uma**:

| Situação | Via |
|---|---|
| A mudança nasce de ação do jogador | `ISBaseTimedAction:complete()` + função de sync |
| A mudança **não** nasce de ação do jogador (poder de admin, tique de mundo, evento) | `sendClientCommand` + handler em `server/` |

O motivo de a segunda ser a exceção é o mesmo que justifica a primeira existir: no handler de comando
**a checagem antifraude é sua** (ver "Autorização é do handler" acima), enquanto a TimedAction já
chega ao servidor com a duração recalculada por lá.

A regra que decorre disso, e que é o erro clássico de mod de item:

> Item criado no cliente entra no inventário, é exibido, **e some no relogin**. O servidor nunca
> soube dele. Criar item é sempre do lado servidor — `complete()` ou handler de comando —, seguido de
> `sendAddItemToContainer`.

```lua
-- criacao, no lado servidor
local candle = instanceItem("Base.Candle")
self.character:getInventory():AddItem(candle);
sendAddItemToContainer(self.character:getInventory(), candle);
```

Observado em servidor dedicado (2026-09-14): item criado assim num handler de `OnClientCommand` —
`getInventory():AddItem(fullType)` seguido de `sendAddItemToContainer` — continuou no inventário
depois de restart do servidor e relogin.

`instanceItem` tem 189 ocorrências em 78 arquivos de `media/lua`; é a função de criação de item.

### Vida de porta, janela e thumpable `[levantado 2026-11-01, javap no .jar]`

`health` entra no `syncIsoObjectSend` de `IsoDoor`, `IsoThumpable` e `IsoWindow`. `IsoDoor.Thump`
e `IsoThumpable.Thump` chamam `sync()` depois do dano; `IsoWindow.Thump` **não** — só o
`GameServer.smashWindow` quando quebra. Logo, em MP, a vida intermediária de janela pode não chegar
aos outros clientes (a confirmar in-game).

## Lado do mod

- Handler de comando vindo do cliente → `media/lua/server/`. Handler do que o servidor manda →
  `media/lua/client/`. Um arquivo em `shared/` roda nos dois e precisa das guardas.
- **Escolha um nome de `module` próprio** no `sendClientCommand`. A tabela `Commands` é indexada por
  string e mods concorrem no mesmo espaço; `'object'` e `'player'` já são do jogo.
- A mesma regra vale para a chave de `ModData.getOrCreate` — é global do save.
- Em singleplayer os dois lados são o mesmo processo, então **quase tudo funciona sem `transmit` e
  sem comando**. Testar só em SP não prova nada sobre MP.
- **Nada de `getText` no lado servidor.** O servidor carrega um idioma só, escolhido sem opção de
  configuração, e chave de mod não resolveu nele — ver
  [carregamento-de-mods.md](carregamento-de-mods.md), "O servidor carrega um idioma só".

## Pontos a confirmar

- **`loadstring` e `loadstream` foram removidos da API Lua** `[removido 42.20.4]`. O changelog
  oficial da IndieStone (patch de 2026-08-26, buildid 24909800) anuncia a remoção como parte de
  correção de vulnerabilidade de segurança, e manda quem os usava para **executar código enviado
  pelo servidor** criar os métodos do lado que executa e chamá-los por comando — que é exatamente o
  par `ClientCommands`/`ServerCommands` desta página. O que tem lastro aqui é só a **ausência**:
  `grep -i` por `loadstring|loadstream` devolve **zero** ocorrência em `PZ/media/lua`, zero nos 12
  mods de `WS/` e zero nesta árvore. A remoção em si é do lado Java e **não é verificável no
  `media/`** — o `.jar` está comprimido e o `jarx/` da instalação é extração parcial, sem
  `LuaManager`. Confirmar por `javap` (ver [../fontes-externas.md](../fontes-externas.md), "Ler o
  `.jar`") antes de promover a afirmação. Que a quebra é real em código de terceiro, isso está
  medido: **6 `.lua` em 2 itens de `STEAM/`** ainda chamam essas funções (2026-08-26).
- **Se `sendServerCommand` de 3 argumentos é difusão para todos os clientes.** As duas aridades
  existem no jogo, mas a assinatura é Java e não há declaração em `media/lua`. Nenhum comentário do
  código diz.
- **Se `ModData.transmit` empurra para todos os clientes ou só para quem pediu**, e se existe o
  caminho inverso (cliente → servidor). Há **um único uso** em todo o `media/lua`
  (`forageServer.lua:49`), o que não permite generalizar.
- **`ModData.Add`** (2 usos) — a diferença para `getOrCreate` não foi determinada, e a caixa
  maiúscula sugere origem diferente na API.
- **O que persiste de `:getModData()` por tipo de dono.** Que item e `IsoObject` persistem é uso
  consolidado. O do jogador foi visto sobreviver a restart de servidor dedicado + relogin
  (2026-09-14): o personagem releu o diário e não recebeu de novo a recompensa marcada ali — relato
  do jogador, sem linha de log que prove sozinha, porque diário em branco manda o mesmo comando. Se `IsoGridSquare` e `carcass` sobrevivem a descarregar o chunk não foi verificado —
  é teste in-game, não grep.
- **Limite de tamanho/tipo de `args`** em `sendClientCommand`. Os usos observados são tabelas planas
  de números e strings; se aninhamento ou objeto Java passa, não foi levantado.
- **[resolvido 2026-08-24]** `OnClientCommand` **dispara** em singleplayer; `OnServerCommand` não.
  A pendência afirmava o oposto, por ler as duas guardas como equivalentes. Ver a seção
  "Em singleplayer o despachante do servidor está ligado".
- **[resolvido 2026-09-16]** O handler **recebe** um `player` válido em singleplayer — a pendência
  anterior dizia que nenhum uso observado dependia disso, e passou a depender. O que não existe em SP
  é o `player:getRole()`, que volta `null`. Medido in-game (`USER/console.txt`), não por grep; ver a
  seção "`getRole()` é `null` em singleplayer".
- **`isCoopHost()` e `isDedicated()`** têm 2 e 5 usos; a semântica exata (host de coop conta como
  servidor? como cliente?) não foi aberta.
- **Assinatura real de `ModData`, `sendClientCommand` e `sendServerCommand`** — todas Java. Uso
  observado, não contrato declarado. Os JavaDocs não-oficiais de
  [../fontes-externas.md](../fontes-externas.md) são a via para cruzar.
- **As variantes `sendClientCommandV`/`sendServerCommandV`** — se aceitam valor aninhado, e se o
  handler as distingue da forma com tabela. Só o uso plano foi observado.
- **A latência do comando em singleplayer.** `ISWashVehicle.lua:110` prova que há atraso; de quantos
  ticks, e se é determinístico, não foi levantado.
- **Nenhuma fonte da comunidade foi cruzada** nesta rodada; a doc oficial da IndieStone foi (ver
  [../fontes-externas.md](../fontes-externas.md)).

> Última verificação: 2026-08-24 — PZ buildid 24775755 (branch public, atualizado 2026-08-22), media/.
>
> O patch `24574865` → `24775755` (jogo 42.20.2 → 42.20.3) **não reescreveu um único arquivo de
> `media/`**; as citações anteriores, de 2026-08-07, seguem válidas. O que mudou aqui foi acréscimo,
> vindo do PDF oficial vendorado em `../oficial/` e do cruzamento dele com o `media/`.

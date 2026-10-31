# TimedAction — a ação com barra de progresso, em Lua

Como um mod cria uma ação que ocupa o personagem por um tempo: `ISBaseTimedAction`, o ciclo de
callbacks que o motor chama, e a fila `ISTimedActionQueue`.

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\` (ver
[../index.md](../index.md)). **Somente leitura.**

## Primeiro: são **duas coisas** com o mesmo nome

Esta é a confusão que a página existe para desfazer.

| | Bloco `timedAction` | Classe `ISBaseTimedAction` |
|---|---|---|
| Formato | `.txt` de `media/scripts` | `.lua` |
| Onde | `PZ/media/scripts/generated/` | `PZ/media/lua/shared/TimedActions/` (183 `.lua`) |
| Documentado em | [scripts-txt.md](scripts-txt.md) | **esta página** |
| Papel | o que um `craftRecipe` referencia | o que o seu código instancia e enfileira |

Um mod que adiciona receita mexe no **bloco**. Um mod que adiciona ação nova de menu de contexto,
ou qualquer coisa com barra de progresso fora de receita, escreve a **classe**. São sistemas
distintos; ver [scripts-txt.md](scripts-txt.md) para o lado `.txt`.

## O exemplo canônico mínimo

`PZ/media/lua/shared/TimedActions/ISToggleStoveAction.lua` tem 40 linhas e é a ação completa mais
curta do jogo — ligar/desligar um fogão:

```lua
require "TimedActions/ISBaseTimedAction"

ISToggleStoveAction = ISBaseTimedAction:derive("ISToggleStoveAction");

function ISToggleStoveAction:isValid()
	return self.object:getObjectIndex() ~= -1
end

function ISToggleStoveAction:update()
	self.character:faceThisObject(self.object)
end

function ISToggleStoveAction:start()
end

function ISToggleStoveAction:stop()
    ISBaseTimedAction.stop(self)
end

function ISToggleStoveAction:perform()
	self.object:PlayToggleSound();
	-- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self)
end

function ISToggleStoveAction:complete()
	self.object:Toggle()
	return true;
end

function ISToggleStoveAction:getDuration()
	return 1
end

function ISToggleStoveAction:new(character, object)
	local o = ISBaseTimedAction.new(self, character)
	o.object = object
	o.maxTime = o:getDuration()
	return o
end
```

Note o comentário na linha 22, que é da IndieStone: **`ISBaseTimedAction.perform(self)` não é
opcional.** Ele é quem tira a ação da fila e começa a próxima
(`ISBaseTimedAction.lua:68-72`). Esquecer trava a fila do personagem — a ação termina, e nenhuma
outra começa. É a falha silenciosa característica desta área.

## O ciclo de callbacks

`PZ/media/lua/shared/TimedActions/ISBaseTimedAction.lua` (184 linhas) define a base. Os métodos que
você sobrescreve:

| Método | Base | Papel |
|---|---|---|
| `isValidStart()` | `return true` (`:8`) | checa antes de entrar na fila |
| `isValid()` | **vazio** (`:12`) | checado a cada tick; falso → aborta |
| `waitToStart()` | `return false` (`:48`) | segura o início (ex.: andar até o objeto) |
| `start()` | vazio (`:55`) | disparado ao começar |
| `update()` | vazio (`:20`) | todo tick enquanto roda |
| `complete()` | **não existe na base** | sucesso; retorne `true` |
| `perform()` | `:68` | sempre ao terminar — **encadeie o pai** |
| `stop()` | `:63` | interrompido — **encadeie o pai** |
| `forceCancel()` | vazio (`:32`) | removido da fila sem ter começado (`:33`) |
| `getDuration()` | `return self.maxTime` (`:74`) | duração em ciclos; ver seção própria |
| `serverStart()` | **não existe na base** | só no servidor, ao começar; arma o `emulateAnimEvent` |
| `animEvent(event, parameter)` | **não existe na base** | tique de ação longa; roda nos dois lados |

**`complete()` não está declarado em `ISBaseTimedAction`** — não há `function ISBaseTimedAction:complete`
no arquivo. `ISToggleStoveAction:complete` (`:26`) existe e é chamado, logo quem chama é o motor
(Java), sobre o objeto passado a `LuaTimedActionNew.new(self, self.character)` em `:create()` (`:79`).
Consequência prática: o método é opcional e não tem `super` para encadear.

O mesmo vale para **`serverStart`, `animEvent` e o campo `self.netAction`**: nenhum dos três aparece
em `ISBaseTimedAction.lua` (184 linhas, conferido), e os três são usados pelas subclasses. São
chamados/injetados pelo motor, como o `complete`. Ver a seção de multiplayer abaixo.

`isValid()` também é vazio na base, ou seja, **retorna `nil`**. Como `nil` é falso em Lua, uma classe
que não sobrescreve `isValid` é inválida de saída.

### `stopOnWalk` e os defaults do construtor

`ISBaseTimedAction:new(character)` (`:173-184`) define:

```lua
	o.character = character;
	o.stopOnWalk = true;
	o.stopOnRun = true;
	o.stopOnAim = true;
    o.caloriesModifier = 1;
	o.maxTime = -1;
```

`maxTime = -1` é o default — **ação sem duração declarada**. Toda subclasse tem de setar `maxTime`,
como `ISToggleStoveAction:new` faz na linha 37. Os três `stopOn*` em `true` significam que andar,
correr ou mirar cancela a ação; desligá-los é opt-out explícito.

## `maxTime` **não é** a duração real

Este é o contrato menos óbvio da área. `ISBaseTimedAction:create()` (`:78-81`) passa o `maxTime` por
`adjustMaxTime()` antes de criar a ação:

```lua
function ISBaseTimedAction:create()
	self.maxTime = self:adjustMaxTime(self.maxTime);
	self.action = LuaTimedActionNew.new(self, self.character);
end
```

E `adjustMaxTime` (`:99-123`) só age **quando `maxTime > 1`**, multiplicando por quatro fatores
independentes:

| Fator | Fórmula | Fonte |
|---|---|---|
| Infelicidade | `× (1 + moodle UNHAPPY / 4)` | `:102` |
| Embriaguez | `× (1 + moodle DRUNK / 4)` | `:105` |
| Dor nas mãos | `× (1 + maxPain/300)`, somando `Hand_L`..`ForeArm_R` | `:108-116` |
| Temperatura | `× character:getTimedActionTimeModifier()` | `:120` |

Duas consequências:

- **Ação com `maxTime <= 1` escapa de todos os modificadores.** O `if maxTime > 1` da linha 100 é o
  gate. `ISToggleStoveAction` usa `getDuration() = 1`, portanto duração fixa.
- **`self.maxTime` é sobrescrito no lugar** (`:79`), não copiado. Ler `maxTime` depois de `create()`
  devolve o valor já ajustado, não o declarado.
- `ignoreHandsWounds` (`:107`) desliga só o fator de dor.

### `stop` não guarda progresso — exceto livro com páginas `[levantado 2026-10-31]`

Interromper uma ação e refazê-la recomeça do zero na quase totalidade dos casos, porque o efeito só
acontece em `perform`/`complete` e o `stop` não grava nada:

| Ação | O que o `stop` faz | Onde o efeito acontece |
|---|---|---|
| `ISHandcraftAction` (todo craft) | só limpa a barra (`PZ/media/lua/shared/Entity/TimedActions/ISHandcraftAction.lua:154-171`) | `performRecipe` em `perform`/`complete` (`:173-219`) |
| `ISResearchRecipe` | só zera o `jobDelta` (`PZ/media/lua/shared/TimedActions/ISResearchRecipe.lua:42-45`) | `researchRecipes` em `complete` (`:75-88`) |
| `ISReadABook`, literatura **sem** página | nada (`PZ/media/lua/shared/TimedActions/ISReadABook.lua:179-191`); a duração usa `numPages = 5` fixo (`:442-460`) | `addReadLiterature` em `perform` (`:206`) |
| `ISReadABook`, livro **com** página | nada; o progresso já foi gravado a cada `update` por `setAlreadyReadPages` (`:25-37`) | — |

O livro mostra o idioma de retomada que o jogo usa: `self:setCurrentTime(self.maxTime * fração)` no
`start` (`ISReadABook.lua:140-142`), com `getJobDelta()` (`ISBaseTimedAction.lua:36`) medindo a fração.
Um mod que queira manter progresso grava a fração no `stop` e a aplica no `start`.

**`ISHandcraftAction:new` calcula `maxTime` antes de saber os itens.** `o.maxTime = o:getDuration()`
(`ISHandcraftAction.lua:412`) roda antes de `o.items`/`o.recipeItem` (`:414-415`), e `getDuration` é
só `craftRecipe:getTime(character) * 5` (`:253-261`). Escalar a duração pelo estado de um insumo
(o fio da lâmina, por exemplo) dentro de `getDuration` não enxerga o insumo. O lugar é depois do
`new` original.

## A arquitetura multiplayer — `perform` no cliente, `complete` no servidor

Esta é a seção que faltava, e é o contrato que decide se a sua ação funciona em servidor. A fonte
primária é o PDF da IndieStone `API for Inventory Items` (doc v1.0, 42.13), vendorado em
`Documentacao/oficial/API-for-Inventory-Items-v1.0.pdf`. Tudo abaixo foi cruzado com o `media/`.

**A regra, em uma linha:** *item e objeto só existem de verdade quando criados no servidor.* Um mod
que cria `InventoryItem` no cliente vê o item aparecer, e ele **some no relogin** — o servidor nunca
soube dele.

Por isso o par de callbacks se divide por lado:

| | `perform()` | `complete()` |
|---|---|---|
| Cliente | roda | **não roda** |
| Servidor | **não roda** | roda |
| Singleplayer | roda, **primeiro** | roda, **depois** |
| Conteúdo | som, animação, UI, `setJobDelta` | criar/remover/alterar item e objeto |

`ISAddFuelAction` é o exemplo trabalhado do documento, e o código instalado **é exatamente** a versão
que ele apresenta como correta (`PZ/media/lua/shared/Camping/TimedActions/ISAddFuelAction.lua`,
94 linhas):

```lua
-- :53-60 -- so som e UI
function ISAddFuelAction:perform()
	self.character:stopOrTriggerSound(self.sound)
	self.item:setJobDelta(0.0);
    -- needed to remove from queue / start next.
	ISBaseTimedAction.perform(self);
end

-- :62-75 -- so item e objeto, com a sincronizacao junto
function ISAddFuelAction:complete()
	if self.item:IsDrainable() and not self.item:hasTag(ItemTag.IS_FIRE_FUEL_SINGLE_USE) then
		self.item:UseAndSync()
	else
		self.character:removeFromHands(self.item)
		self.character:getInventory():Remove(self.item)
        sendRemoveItemFromContainer(self.character:getInventory(),self.item)
	end
	local campfire = SCampfireSystem.instance:getLuaObjectAt(self.campfire.x, self.campfire.y, self.campfire.z)
    if campfire then
        campfire:addFuel(self.fuelAmt)
    end
    return true
end
```

Repare no que **sumiu** do `perform`: antes ele mandava um `CCampfireSystem.instance:sendCommand(…,
'addFuel', …)` para o servidor. Como o `complete` já roda lá, o comando virou chamada direta
(`:70-73`). `ISPlaceTrap` (`PZ/media/lua/shared/TimedActions/ISPlaceTrap.lua`, `:35-40` / `:42-52`)
tem a mesma forma.

Censo: **307** `:perform()` e **238** `:complete()` definidos em `media/lua`.

### O que isso obriga num mod

- **O arquivo tem de estar em `media/lua/shared/`.** Em `client/` o servidor não carrega a classe e
  não tem o que executar. As 51 ações do jogo com `serverStart` estão em `shared/`; a única em
  `client/` é um contraexemplo, ver abaixo.
- **Nada de item ou objeto no `perform`.** Nem `AddItem`, nem `Remove`, nem `setCondition`.
- **Nada que só existe no cliente dentro do `complete`.** Sem UI, sem som, sem `getPlayer()`.
- **O que o `complete` mudou tem de ser sincronizado à mão** — ver "Sincronizar" abaixo.
- Em singleplayer os dois lados rodam no mesmo processo, então **testar em SP não prova nada** sobre
  essa divisão.

### `getDuration()` — e a unidade de `maxTime`

O valor é em **ciclos de 0,02 s**: segundos ÷ 0,02. Portanto `50` = 1 segundo, `100` = 2 segundos.
Dois valores são especiais:

| Retorno | Significa |
|---|---|
| `1` | instantâneo — e é o que se retorna sob o cheat `TimedActionInstant` |
| `-1` | **infinita** — só termina por `forceComplete` |

Isso fecha a pendência de unidade que esta página carregava. Confere com os três exemplos:
`ISPlaceTrap:getDuration` (`:54-59`) retorna `50`, `ISAddFuelAction` (`:77-82`) retorna `100`,
`ISChopTreeAction` (`:56-58`) retorna `-1`.

O idioma completo, com o gate do cheat:

```lua
function ISPlaceTrap:getDuration()
	if self.character:isTimedActionInstant() then
		return 1;
	end
	return 50
end
```

Censo em `media/lua`: **240** `getDuration` definidos, **185** com o gate `isTimedActionInstant`,
**21** retornando `-1`. Reproduzível com um `awk` por bloco de função — contar `grep -A3` erra,
porque o corpo tem tamanho variável.

**Quem chama `getDuration` é o servidor**, e é por isso que a duração **não pode ser argumento** de
`:new` — se fosse, um cliente adulterado mandaria `1` e toda ação sairia instantânea. O `:new` chama
`o:getDuration()` para preencher o `maxTime` local; o servidor recalcula o dele.

### O nome do argumento de `:new` é uma chave de transferência

Ao enfileirar a ação, o motor a reconstrói do lado do servidor: recebe a **lista de argumentos** de
`:new` e procura, no objeto, um **campo de mesmo nome** para cada um. Argumento sem campo homônimo
não atravessa.

A prova é um comentário da própria IndieStone, em
`PZ/media/lua/shared/Entity/TimedActions/ISItemSlotAddAction.lua:109`:

```lua
-- The internalItemSlot argument has a different name from the field in the object so that in multiplayer this field is not passed to the server side.
function ISItemSlotAddAction:new(character, entity, item, resource, internalItemSlot)
	…
	o.itemSlot = internalItemSlot;
```

Ou seja, a regra tem **dois lados**, e o segundo é idioma deliberado:

1. **Precisa chegar ao servidor** → argumento e campo com o mesmo nome (`o.weapon = weapon`).
2. **Não pode chegar ao servidor** → dê nomes diferentes de propósito. É o que as sete ações de
   gancho de animal fazem com a referência de UI: `ISCutAnimalOnHook:new(character, body, hook,
   luaHookUI, bucket)` guarda em `o.luaHook`
   (`PZ/media/lua/shared/TimedActions/Animals/ISCutAnimalOnHook.lua:83,87`).

Corolário do documento: **objeto criado no cliente não pode ser argumento**, porque o servidor não
recebe o objeto — ele procura *o correspondente dele* do lado de lá. `ISPickupFishAction:new`
(`PZ/media/lua/shared/TimedActions/Fishing/TimedActions/ISPickupFishAction.lua:144-151`) escreve isso
explicitamente, redescobrindo o peixe no servidor em vez de confiar no que veio:

```lua
    if isServer() then
        o.item = getPickedUpFish(character)
    else
        o.item = fish
    end
```

Resíduo da regra da duração: `ISTakeTrap:new(character, trap, time)`
(`PZ/media/lua/shared/TimedActions/ISTakeTrap.lua:49`) ainda declara `time` e **nunca o usa** — o
corpo chama `o:getDuration()`. Parâmetro morto de quando a duração vinha do chamador.

Censo em `shared/TimedActions/` + `client/TimedActions/`: **204** `:new` definidos, **18** com ao
menos um argumento sem campo homônimo. Nem todos são idioma deliberado — ver "Pontos a confirmar".

### Ação longa — trabalho *durante* a execução

Ação que precisa produzir efeito repetidamente enquanto roda (derrubar árvore, despejar líquido, ler)
não cabe no par `perform`/`complete`, que só dispara no fim. O motor oferece um emulador de
`AnimEvent`:

| Peça | Onde roda | Papel |
|---|---|---|
| `serverStart()` | servidor | arma o emulador |
| `emulateAnimEvent(self.netAction, duracao_ms, evento, parametro)` | servidor | agenda o tique |
| `animEvent(event, parameter)` | **os dois lados** | executa uma fatia |
| `self.netAction:forceComplete()` | servidor | encerra a ação infinita |
| `self.netAction:getProgress()` | servidor | progresso, lido dentro do `animEvent` |

`ISChopTreeAction` (`PZ/media/lua/shared/TimedActions/ISChopTreeAction.lua`, 121 linhas) é o exemplo
canônico, e é o mesmo do documento:

```lua
-- :108-111
function ISChopTreeAction:serverStart()
    self.axe = self.character:getPrimaryHandItem()
    emulateAnimEvent(self.netAction, 1500, "ChopTree", nil)
end
```

O `animEvent` (`:64-94`) se divide por lado com `if not isClient()` — dano de verdade num ramo,
efeito visual no outro — e encerra a ação infinita com a assimetria que importa (`:82-86`):

```lua
if isServer() then
    self.netAction:forceComplete()
else
    self:forceComplete()
end
```

**`self.netAction` só existe no servidor**; em singleplayer o caminho é `self:forceComplete()`, o
método da base (`ISBaseTimedAction.lua:24`). Censo: **52** `serverStart`, **51** `animEvent`, **42**
chamadas de `emulateAnimEvent`, **122** usos de `self.netAction`.

**A armadilha:** `serverStart` num arquivo de `client/` nunca roda. O jogo tem exatamente um caso —
`PZ/media/lua/client/TimedActions/Animal/ISOpenAnimalInfo.lua:57,60` declara `serverStart` e
`animEvent` **vazios**, numa ação que só abre janela. Vazio não custa nada; um corpo ali seria código
morto silencioso.

### Sincronizar o que o `complete` mudou

O `complete` roda no servidor, então a mudança precisa ser empurrada para os clientes — não há
propagação automática. As dez funções que o documento lista existem todas em `media/lua`; a coluna é
o número de arquivos que usam cada uma:

| Função | Arquivos | Para |
|---|---|---|
| `sendRemoveItemFromContainer` | 64 | tirar item de container |
| `sendAddItemToContainer` | 56 | pôr item em container |
| `transmitRemoveItemFromSquare` | 46 | tirar objeto do mapa |
| `transmitCompleteItemToClients` | 45 | pôr objeto no mapa |
| `UseAndSync` | 30 | consumir carga de item *drainable* |
| `syncItemFields` | 26 | condição, `uses`, `moddata`, molhado, sujo… |
| `sendItemStats` | 15 | os campos de comida e cozimento |
| `transmitUpdatedSpriteToClients` | 14 | sprite trocado |
| `syncHandWeaponFields` | 7 | munição, `isJammed`, dano da arma |
| `syncItemModData` | **1** | só o `moddata` |

`syncItemModData` com um único uso é o número a não seguir: use `syncItemFields`, que também leva o
`moddata` e é o caminho batido. A lista de campos que cada uma cobre está no PDF, seção 5 — não é
copiada para cá pela regra 2 da árvore.

**Fora da lista do PDF: `sendSyncPlayerFields(character, bits)`**, que sincroniza campo do
**personagem**, não de item. O segundo argumento é máscara de bits, e o nome de cada bit só aparece
em `media/lua` como comentário do jogo ao lado da chamada:

| Máscara | Comentário do jogo | Onde |
|---|---|---|
| `0x00000001` | `PF_Recipes` | `PZ/media/lua/shared/TimedActions/ISResearchRecipe.lua:84-85`, depois de `researchRecipes` |
| `0x00000007` | `PF_Recipes + PF_Traits + PF_AlreadyReadBook` | `PZ/media/lua/shared/TimedActions/ISReadABook.lua:373-374`, fim do `complete` |
| `0x00000010` | `PF_Reading` | `PZ/media/lua/shared/TimedActions/ISWriteSomething.lua:70-71`, `:77-78`, `:97-98` |

São os três únicos arquivos que a chamam. A consequência para mod: `learnRecipe` do lado servidor
(num `complete` ou num handler de comando) sem o sync de `PF_Recipes` é candidato à mesma falha muda
do `getXp():AddXP` — ver [perks-e-xp.md](perks-e-xp.md), "Em multiplayer a escolha entre as duas
formas deixa de ser estilo". Ver "Pontos a confirmar". **Com** o sync, funciona: observado em
servidor dedicado em 2026-09-14 (mod de teste), `learnRecipe` +
`sendSyncPlayerFields(…, 0x00000001)` num handler de `OnClientCommand` deixou a receita aprendida, e
ela seguiu aprendida depois de restart do servidor e relogin.

Do lado de objeto do mapa o par é `obj:sync()`. Ver
[persistencia-e-multiplayer.md](persistencia-e-multiplayer.md) para o canal de comando, que é a via
alternativa quando a mudança **não** nasce de ação do jogador.

## A fila — `ISTimedActionQueue`

Fica em **`PZ/media/lua/client/TimedActions/ISTimedActionQueue.lua`** — repare na raiz: a base é
`shared/`, mas a fila é **`client/`**. Ver [mapa-media.md](mapa-media.md) para o que isso significa
em multiplayer.

É uma tabela de funções estáticas, não métodos:

| Função | Linha | Papel |
|---|---|---|
| `ISTimedActionQueue.add(action)` | `:157` | **o jeito normal de disparar uma ação** |
| `ISTimedActionQueue.addAfter(previousAction, action)` | `:203` | encadeia depois de outra |
| `ISTimedActionQueue.addGetUpAndThen(character, action)` | `:229` | levanta o personagem antes |
| `ISTimedActionQueue.queueActions(character, fn, …)` | `:224` | agrupa várias de uma vez |
| `ISTimedActionQueue.clear(character)` | `:236` | |
| `ISTimedActionQueue.hasAction(action)` / `.hasActionType(character, type)` | `:245` / `:252` | |
| `ISTimedActionQueue.isPlayerDoingAction(playerObj)` | `:268` | |
| `ISTimedActionQueue.getTimedActionQueue(character)` | `:148` | a fila daquele personagem |

O uso típico é uma linha:

```lua
ISTimedActionQueue.add(ISToggleStoveAction:new(playerObj, stoveObject))
```

Do lado da instância (`ISTimedActionQueue:` com dois-pontos) ficam `addToQueue` (`:9`),
`removeFromQueue` (`:39`), `clearQueue` (`:46`), `onCompleted` (`:60`), `resetQueue` (`:101`),
`cancelQueue` (`:107`) e `tick` (`:115`). `ISTimedActionQueue.onTick` (`:278`) é o gancho global.

Encadeamento também existe do lado da ação: `ISBaseTimedAction:addAfter(action)` (`:153`), e o par
`beginAddingActions()` / `endAddingActions()` (`:158`, `:163`) para uma ação que enfileira outras
enquanto roda.

### Ação em laço até o jogador cancelar `[levantado 2026-09-30]`

Duas peças, as duas do lado cliente:

- **Cancelar é tecla do motor.** `KeybindId.CANCEL_ACTION` nasce em `Keyboard.KEY_ESCAPE`
  (`PZ/media/lua/shared/keyBinding.lua:48-49`). O cancelamento passa por `stop()`, nunca por
  `perform()`.
- **Reenfileirar no `perform`.** `ISTimedActionQueue.addAfter(self, proxima)` **antes** de
  `ISBaseTimedAction.perform(self)` é idioma do jogo —
  `PZ/media/lua/shared/TimedActions/ISInsertMagazine.lua:135` encadeia o `ISRackFirearm` assim. Uma
  ação finita que se reenfileira vira laço que termina no ESC, e cada volta passa por `complete()`,
  então o efeito por volta cai no servidor sem precisar de `serverStart`/`emulateAnimEvent`.

`queue.queue` é array Lua com a ação corrente na posição 1
(`PZ/media/lua/client/TimedActions/ISTimedActionQueue.lua:9-18`); `#queue == 1` dentro do `perform`
significa que o jogador não enfileirou mais nada, e é o teste para não passar na frente do que ele
pediu. Com `isTimedActionInstant()` o laço gira a cada tick — corte-o nesse caso.

## Animação e modelo na mão

O bloco de métodos `:125-152` é a ponte para a animação — todos delegam para `self.action`, o objeto
Java:

- `setActionAnim(_action, _displayItemModels)` (`:125`) — qual animação tocar.
- `setOverrideHandModels(primary, secondary, reset)` (`:133`) e a variante `…String` (`:137`) —
  troca o modelo na mão durante a ação. Uso real em
  `PZ/media/lua/shared/Camping/TimedActions/ISLightFromPetrol.lua:27`, já citado em
  [arte-e-modelos.md](arte-e-modelos.md).
- `setAnimVariable(_key, _val)` (`:149`), `overrideWeaponType()` (`:141`) / `restoreWeaponType()` (`:145`).

Como todos operam sobre `self.action`, **só valem depois de `create()`** — ou seja, dentro de
`start()` em diante, nunca no `:new`.

## Lado do mod

- Onde por o arquivo: **`media/lua/shared/TimedActions/`**, e isso não é estética — o servidor
  executa o `complete` e precisa carregar a classe. As 183 do jogo estão em `shared/`; há mais 24
  em `client/TimedActions/`, que são as que nunca tocam item nem objeto.
- `require "TimedActions/ISBaseTimedAction"` — caminho relativo às raízes de `lua/`, sem extensão.
- Nome da classe é **global**: prefixe com o nome do mod para não colidir.
- `ISLogSystem.logAction(self)` roda dentro de `ISBaseTimedAction:perform` (`:69`), então toda ação
  que encadeia o pai entra no log — útil ao depurar, ver [testar-e-debugar.md](testar-e-debugar.md).

## Pontos a confirmar

- **Se `learnRecipe` chamado do servidor sem `sendSyncPlayerFields(…, 0x00000001)` chega ao
  cliente.** O jogo sempre sincroniza depois de ensinar receita do lado servidor (seção "Sincronizar o
  que o `complete` mudou"); o caso sem sync não foi observado. Os bits `PF_Traits` e
  `PF_AlreadyReadBook` nunca aparecem isolados em `media/lua`, só somados em `0x00000007`.
Quatro pendências desta lista foram **fechadas em 2026-08-24** pelo cruzamento do PDF oficial
`API for Inventory Items` com o `media/` — ordem entre `perform` e `complete`, quem chama o
`complete`, unidade de `maxTime` e comportamento em multiplayer. O que sobra:

- **O que acontece quando `complete()` retorna `false`.** Todas as implementações vistas retornam
  `true`; a semântica do `false` — repetir, cancelar, ignorar — é do Java e não aparece em `media/lua`.
- **Os 18 `:new` com argumento sem campo homônimo** (censo acima) são idioma deliberado ou defeito?
  Dois casos estão provados como deliberados pelo comentário de `ISItemSlotAddAction.lua:109`
  (`internalItemSlot`) e pelas sete de gancho de animal (`luaHookUI`). Mas
  `ISFillGrave:new(character, graves, shovel)` guarda em `o.item`
  (`PZ/media/lua/shared/TimedActions/ISFillGrave.lua:106-116`) sem comentário nenhum, e a ferramenta
  parece ser algo que o servidor precisaria. `ISDropCorpseAction:new(character, targetSquare)`
  (`…/ISDropCorpseAction.lua:54-60`) nem usa o argumento. É teste in-game em servidor, não grep.
- **Os 27 tipos de dado aceitos como argumento de `:new`.** O PDF os enumera (de `BaseVehicle` a
  `VehicleWindow`, mais `null`) e aponta a serialização para a classe Java `PZNetKahluaTableImpl`.
  Nada disso é verificável no `media/`; a lista está no PDF vendorado, seção 2.1.
- **A unidade do 2º argumento de `emulateAnimEvent`.** O PDF diz milissegundos; os valores observados
  (`1500` em `ISChopTreeAction:110`, `100` em `ISFluidEmptyAction:35`) são compatíveis, mas
  `ISAddWaterToTrough:85` passa `self.timePerUse * 20`, o que sugere conversão de outra unidade na
  origem. Não foi aberto.
- **Se `perform` de fato nunca roda no servidor.** A divisão está no PDF e o código instalado é
  consistente com ela, mas não há gate em `media/lua` que a demonstre — quem decide é o Java.
- **`isUsingTimeout()`** (`:16`, default `true`) — que timeout, e o que muda ao desligar.
- **`caloriesModifier`** (`:178`, default `1`) — onde é consumido não foi levantado; não há leitura
  dele em `ISBaseTimedAction.lua`. `ISChopTreeAction:118` seta `8`.
- **`getDeltaModifiers(deltas)`** (`:170`) é vazio na base e não tem chamador em `media/lua` — gancho
  de motor, contrato desconhecido.
- **`retriggerLastAction`** (`:84`) e `setTimedActionToRetrigger` — o mecanismo de repetir a última
  ação não foi aberto.
- **Assinatura de `LuaTimedActionNew`, `emulateAnimEvent` e `netAction`** — Java. Uso observado, não
  contrato declarado.
- **Nenhuma fonte da comunidade foi cruzada** nesta rodada. O PZ-API-Docs é gerado sobre `scripts/`,
  e esta área é Lua; a fonte útil aqui foi a doc oficial, ver
  [../fontes-externas.md](../fontes-externas.md).

> Última verificação: 2026-08-24 — PZ buildid 24775755 (branch public, atualizado 2026-08-22), media/.
>
> O patch `24574865` → `24775755` (jogo 42.20.2 → 42.20.3) **não reescreveu um único arquivo de
> `media/`** — `find media -type f -newermt "2026-08-08"` devolve 0, e só `projectzomboid.jar` tem
> mtime novo. As citações desta página vinham de 2026-08-07 e seguem válidas por isso; o que mudou
> aqui foi acréscimo, vindo do PDF oficial vendorado em `../oficial/`.

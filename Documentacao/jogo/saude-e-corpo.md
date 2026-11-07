# Saúde e corpo — ferimento, moodle e a UI de saúde

Onde vive cada camada da saúde do personagem, qual é o contrato de `BodyPart`/`BodyDamage`, e por
onde um mod entra (resposta curta: quase sempre por substituição de função, não por evento nem por
tabela).

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\`,
`STEAM/` = `C:\Program Files (x86)\Steam\steamapps\workshop\content\108600\`.

Esta página **não** repete a hierarquia `ISUIElement`→`ISPanel`, o ciclo de vida nem a ponte
`instantiate()` — isso é de [ui-lua.md](ui-lua.md), e o que segue pressupõe aquela página lida. Aqui
só entra o que é específico de saúde.

## Primeiro: as duas pastas com "Health" e "BodyParts" no nome quase não têm código

É o achado que mais economiza tempo, porque o nome das pastas promete o oposto.

| Pasta | Arquivos | Linhas | O que é de fato |
|---|---|---|---|
| `PZ/media/lua/server/HealthSystem/` | 1 (`HealthUpdate.lua`) | 45 | **código morto** — ver abaixo |
| `PZ/media/lua/client/ISUI/BodyParts/` | 1 (`ISBodyPartPanel.lua`) | 425 | painel **genérico** de corpo, não de saúde |

**`HealthUpdate.lua` não roda.** O registro do evento está comentado na última linha
(`PZ/media/lua/server/HealthSystem/HealthUpdate.lua:45`):

```lua
--Events.OnTick.Add(healthUpdate.update);
```

E o corpo de `healthUpdate.update` (`:6`) tem toda a lógica útil comentada também (`:14`–`:18`): o que
sobra é ler `getBodyDamage()` e o `GridSquare` atual, e descartar os dois. As funções
`scratchFromWindow` (`:22`) e `getBrokenWindow` (`:36`) existem, mas ninguém as chama. A tabela global
`healthUpdate` (`:1`) é criada de qualquer forma, porque o arquivo é carregado — mas não faz nada.

Consequência prática: **não procure a mecânica de saúde em `server/`.** Ela não está em Lua nenhum.

O peso real está em **`PZ/media/lua/client/XpSystem/ISUI/ISHealthPanel.lua`, 1.987 linhas** — que é a
UI, o menu de tratamento e, na falta de documentação da API, a melhor referência de `BodyPart` que
existe no install (53 métodos distintos usados; ver "A API de `BodyPart`").

## O modelo: saúde é Java; o Lua lê e comanda

A cadeia de acesso, observada em uso real:

```lua
local bodyDamage = character:getBodyDamage()              -- objeto Java
local bodyPart   = bodyDamage:getBodyPart(BodyPartType.Hand_L)
```

`PZ/media/lua/shared/Farming/TimedActions/ISPlowAction.lua:80` é um chamador canônico curto.

Três consequências que valem mais que o resto da página:

- **Não existe bloco `.txt` de ferimento.** Nada em `media/scripts` define tipo de ferimento, cura ou
  moodle. Isso separa saúde de item/receita/traço — ver [scripts-txt.md](scripts-txt.md).
- **Não existe evento de saúde.** Uma varredura por `LuaEventManager.AddEvent` em todo
  `PZ/media/lua` não devolve **nenhum** evento com `health`, `body`, `wound`, `moodle`, `damage`,
  `infect`, `heal` ou `medical` no nome. Os únicos eventos do assunto são
  `RequestMedicalCheck` / `AcceptedMedicalCheck`, que são o handshake de exame médico em multiplayer,
  não notificação de dano — os dois já estão catalogados em [eventos-lua.md](eventos-lua.md).
- **Não existe tabela Lua de ferimento** para um mod estender. Tudo é método sobre objeto Java.

Sem evento e sem tabela, o padrão que sobra é **polling**. É o que os mods instalados fazem: entre os
arquivos de `STEAM/` que chamam `getBodyDamage()`, os eventos mais frequentes no mesmo arquivo são
`Events.OnTick` e `Events.EveryOneMinute`.

**Tudo nesta página sobre métodos Java é uso observado em `PZ/media/lua`, com `caminho:linha` — não é
contrato declarado.** O `.jar` não é lido aqui e a IndieStone não publica assinatura. Um método
existir no jogo não garante que ele seja estável nem que aceite o que parece aceitar.

## As 17 partes do corpo — `BodyPartType`

O enum é fechado e indexado de 0 a 16. `ISBodyPartPanel.lua:37`–`:38` é a prova mais limpa: itera
`for i=0,16` chamando `BodyPartType.FromIndex(i)`, e a tabela `setup_table` (`:3`) tem exatamente as
chaves `[0]`..`[16]`.

As 17 constantes, todas confirmadas por uso em `PZ/media/lua`:

| | | |
|---|---|---|
| `Hand_L` | `Hand_R` | |
| `ForeArm_L` | `ForeArm_R` | |
| `UpperArm_L` | `UpperArm_R` | |
| `Torso_Upper` | `Torso_Lower` | |
| `Head` | `Neck` | `Groin` |
| `UpperLeg_L` | `UpperLeg_R` | |
| `LowerLeg_L` | `LowerLeg_R` | |
| `Foot_L` | `Foot_R` | |

Mais os membros utilitários, também observados: `BodyPartType.MAX`, `.FromIndex(i)`, `.ToIndex(bpt)`,
`.ToString(bpt)`, `.getDisplayName(bpt)`.

`PZ/media/lua/server/HealthSystem/HealthUpdate.lua:29` mostra o idioma de sorteio de parte, que
depende de `MAX` ser o teto exclusivo:

```lua
local part = healthDmg:getBodyPart(BodyPartType.FromIndex(ZombRand(BodyPartType.ToIndex(BodyPartType.MAX))));
```

**Armadilha — `Translate/EN/BodyParts.json` não é isto.** Apesar do nome, aquele arquivo tem 11
chaves `BODYPART_PELVIS`, `BODYPART_SPINE`, `BODYPART_LEFT_UPPER_LEG`… — são os ossos do **ragdoll**,
outro espaço de nomes, ligado ao `bodyPart` numérico dos blocos `ragdoll` do `.txt`
(ver [scripts-txt.md](scripts-txt.md), seção de `ragdoll`). Nenhuma das 17 partes de saúde aparece
ali. O nome de exibição das partes de saúde vem de `BodyPartType.getDisplayName()`, que é Java —
usado em `ISHealthPanel.lua:590`.

### `BloodBodyPartType` é um **segundo** enum, e não é o mesmo conjunto

Fácil de confundir por substring: um grep por `BodyPartType\.` casa `BloodBodyPartType.` também.

`BloodBodyPartType` governa a mancha de sangue / furo na roupa, não o dano. Ele tem `Back`
(`ISHealthPanel.lua:230`), que **`BodyPartType` não tem**. Ainda assim o jogo converte entre os dois
**por índice**, assumindo os espaços alinhados (`ISHealthPanel.lua:201`):

```lua
player:addHole(BloodBodyPartType.FromIndex(BodyPartType.ToIndex(bodyPart:getType())));
```

O mesmo idioma se repete em `:204` (`addBasicPatch`), `:207` (`addBlood`) e `:210`
(`getVisual():setBlood`), e no lado servidor em `PZ/media/lua/server/ClientCommands.lua:498`. Um mod
que invente índice em vez de converter assim acerta a parte errada em silêncio. O lado roupa/textura
disso é de [roupa.md](roupa.md) (campo `BloodLocation`).

## Ferimento — os estados que existem

Não há "tipo de ferimento" como entidade: há um conjunto de **flags e temporizadores independentes**
por parte do corpo, que se acumulam. A mesma parte pode estar simultaneamente arranhada, cortada,
com fratura e enfaixada.

A definição operacional de "esta parte está ferida" é uma linha só, e é o melhor resumo do sistema —
`ISHealthPanel.lua:523`:

```lua
if ISHealthPanel.cheat or bodyPart:HasInjury() or bodyPart:bandaged() or bodyPart:stitched() or bodyPart:getSplintFactor() > 0 or bodyPart:getAdditionalPain() > 10 or bodyPart:getStiffness() > 5  or (isDebug and bodyPart:getStiffness() > 0) then
```

Os estados, com o leitor usado pela UI e onde ele é lido (`ISHealthPanel.lua`):

| Estado | Leitor | Linha | Temporizador associado |
|---|---|---|---|
| Arranhão | `scratched()` | `:631` | `getScratchTime()` |
| Laceração/corte | `isCut()` | `:649` | `getCutTime()` |
| Ferida profunda | `deepWounded()` / `isDeepWounded()` | `:667` | `getDeepWoundTime()` |
| Mordida | `bitten()` | `:683` | `getBiteTime()` |
| Dor adicional | `getAdditionalPain() > 10` | `:691` | — |
| Rigidez | `getStiffness()` | `:707` | — |
| Fratura | `getFractureTime() > 0` | `:740` | `getFractureTime()` |
| Enfaixado | `bandaged()` | `:772` | `getBandageLife()`, `getBandageType()` |
| Ferida infeccionada | `isInfectedWound()` | `:802` | `getWoundInfectionLevel()` |
| Bala alojada | `haveBullet()` | `:812` | — |
| Queimadura | `getBurnTime() > 0` | `:816` | `isNeedBurnWash()`, `getLastTimeBurnWash()` |
| Costurado | `stitched()` | `:828` | `getStitchTime()` |
| Caco de vidro | `haveGlass()` | `:844` | — |
| Tala | `getSplintFactor() > 0` | `:523` | `getSplintItem()` |
| Cataplasma | `getPlantainFactor()`, `getComfreyFactor()`, `getGarlicFactor()` | `:607` | — |

**A severidade é limiar sobre o temporizador, não um campo.** `ISHealthPanel.lua:634`–`:637` mostra a
forma: `getScratchTime() > 17` → severo, `> 14` → moderado. Cada estado tem seus próprios números,
e eles vivem só na UI — não há constante nomeada.

### A API de `BodyPart`

`ISHealthPanel.lua` usa **53 métodos distintos** de `bodyPart:` — é a superfície mais completa
observável no install, e por isso o lugar para conferir a grafia antes de escrever código. Para
levantar a lista atual:

```sh
grep -ohE "bodyPart:[a-zA-Z]+\(" PZ/media/lua/client/XpSystem/ISUI/ISHealthPanel.lua | sort -u
```

**A caixa da primeira letra não é uniforme e o Lua não perdoa.** A maioria é minúscula
(`setBleedingTime`, `setDeepWounded`, `setScratched`, `setFractureTime`, `setWoundInfectionLevel`),
mas um punhado é maiúsculo: `HasInjury()`, `RestoreToFullHealth()`, `SetBitten()`, `SetInfected()`,
`SetFakeInfected()`. E existe divergência dentro do próprio jogo — `HealthUpdate.lua:30` escreve
`part:SetScratched(true, true)` enquanto `ISHealthPanel.lua` e `ClientCommands.lua:577` escrevem
`setScratched(...)`. Como `HealthUpdate.lua` é código morto, ele nunca provou que a forma maiúscula
funciona. **Copie a grafia de um chamador vivo**, não daquele arquivo.

Notar que **não existe `setBleeding()` nem `setBandaged()`**: sangramento se liga por
`setBleedingTime(n)` (`ClientCommands.lua:456`) e faixa se aplica por ação cronometrada, nunca por
setter.

`[levantado 2026-10-31]` **Queimadura também é setter, mas nenhum caminho de gameplay em Lua a
aplica.** O único `setBurnTime` com valor positivo é o toggle de debug, `setBurnTime(50)` contra
`setBurnTime(0)`, em `PZ/media/lua/server/ClientCommands.lua:544-549` e repetido no cliente em
`ISHealthPanel.lua:246-251`. Fogo e fogão queimam pelo Java. Mod que queira queimar copia o setter
desse toggle, e `50` é a única referência de magnitude no install. Proteção não tem atalho: nenhum
item tem tag de proteção contra calor, e a luva de forno `Base.OvenMitt` é `ItemType = base:normal`,
não roupa (`PZ/media/scripts/generated/items/normal.txt:4186-4194`). Ela se segura na mão, não se
veste. Para ver o que o personagem veste, use `getWornItems()` com `:get(i):getItem()`
(`ISFitnessUI.lua:295-296`).

## Curar — a pilha é ação cronometrada, e o menu é fechado

Aplicar tratamento não é chamar setter. O caminho real, do clique ao efeito:

1. **`ISHealthPanel:doBodyPartContextMenu(bodyPart, x, y)`** (`:1796`) monta a lista de handlers.
2. Cada handler decide se aparece (`addToMenu`), varrendo o inventário do médico por item elegível.
3. A opção escolhida cria uma **`HealthPanelAction`** (`:982`, deriva de `ISBaseTimedAction` — ver
   [timedactions.md](timedactions.md)), que valida e delega ao handler.
4. O handler enfileira a ação real de `PZ/media/lua/shared/TimedActions/`: `ISApplyBandage.lua`,
   `ISStitch.lua`, `ISDisinfect.lua`, `ISSplint.lua`, `ISRemoveGlass.lua`, `ISRemoveBullet.lua`,
   `ISCleanBurn.lua`, `ISCleanBandage.lua`, `ISComfreyCataplasm.lua`, `ISGarlicCataplasm.lua`,
   `ISPlantainCataplasm.lua`.
5. É a ação que mexe no `BodyPart` — `ISStitch.lua:124` faz `self.bodyPart:setInfectedWound(true)`.

**O ponto que decide o que um mod consegue fazer: os 13 handlers e a classe-base deles são `local`.**

```lua
local BaseHandler = ISBaseObject:derive("BaseHandler")   -- ISHealthPanel.lua:1020
local HApplyBandage = BaseHandler:derive("HApplyBandage") -- :1145
```

São 15 declarações `local` entre `:1020` e `:1713` (`BaseHandler`, `HApplyPoultice` e 13 handlers
concretos). E a lista não é uma tabela de módulo: ela é **construída inline** dentro de
`doBodyPartContextMenu`, com 13 `table.insert` literais em `:1801`–`:1813`.

Isso significa que **não há como um mod acrescentar um tratamento ao menu de saúde por tabela**.
Nenhum dos nomes é alcançável de fora do arquivo. A única saída é substituir a função
`ISHealthPanel:doBodyPartContextMenu` inteira — e, ao fazer isso, o mod perde acesso aos 13 handlers
originais, porque continuam `local`. Na prática: reimplementar todos, ou aceitar substituir o menu.

Evidência de que é assim que se faz na prática: entre os mods instalados em `STEAM/`, **um único**
mexe na UI de saúde — `STEAM/2703664356/mods/TheOnlyCure/media/lua/client/TOC_UI.lua`, que
sobrescreve `function ISHealthPanel:createChildren()` (`:590`) e `function ISHealthPanel:render()`
(`:608`). Nenhum acrescenta handler, porque não dá.

## Moodle

**Moodle é 100% Java.** Não existe **nenhum** `.lua` com "Moodle" no nome em `PZ/media/lua` — os 29
arquivos que o `find` devolve são todos `Translate/<IDIOMA>/Moodles.json`. Não há framework de
registro no install.

O que existe do lado Lua é leitura:

```lua
character:getMoodles():getMoodleLevel(MoodleType.PAIN)   -- ISHealthPanel.lua:467
```

O nível é um inteiro de 0 a 4 — a faixa se lê pelas chaves de tradução, que vão de `lvl1` a `lvl4`
(0 = ausente). `ISFitnessUI.lua:219` (`> 2`) e `ISBaseTimedAction.lua:102` mostram o uso típico.
`ISBaseTimedAction.lua:102`/`:105` também é onde moodle vira multiplicador de duração de ação — o
detalhe da fórmula é de [timedactions.md](timedactions.md).

`[levantado 2026-10-27]` **Os limites de nível ficam no Java, em `zombie.characters.Moodles.MoodleStat`**,
quatro floats por moodle, lidos por `Moodle` com `getLowestThreshold`/`getModerateThreshold`/
`getHighestThreshold`/`getMaximumThreshold` (`javap -c`). Para o sono, `MoodleStat.TIRED` sobre
`CharacterStat.FATIGUE`: **0,6 / 0,7 / 0,8 / 0,9**. Cuidado com o nome: `TIRED` é o cansaço de
**sono** ("Drowsy"…"Ridiculously Tired", `PZ/media/lua/shared/Translate/EN/Moodles.json:22-25`), e o
cansaço **físico** é o moodle `Endurance` ("Out of Breath"…"Exhausted", `:2-5`).

`[levantado 2026-11-02, javap, buildid 25485521]` **Infelicidade e tédio vão de 0 a 100, não de 0 a
1.** `CharacterStat` registra `"Unhappiness"` e `"Boredom"` com `(0, 100, 0)`, enquanto `"Stress"`, `"Thirst"` e
`"Sickness"` usam `(0, 1, 0)` — o mesmo `add` de 0,5 é meio estresse e um respiro de infelicidade.
Limiares em `MoodleStat`: **`UNHAPPY` 20 / 45 / 60 / 80**, **`BORED` 25 / 50 / 75 / 90**. Escrita do
lado Lua: `getStats():remove(CharacterStat.UNHAPPINESS, …)`
(`PZ/media/lua/server/Farming/SFarmingSystem.lua:339-340`), `:add(…)`
(`PZ/media/lua/shared/RadioCom/ISRadioInteractions.lua:36`), `:get`/`:set`
(`PZ/media/lua/shared/TimedActions/ISReadABook.lua:73-74`).

Além de ler, dá para **chamar atenção** para um ícone já existente:

```lua
MoodlesUI.getInstance():wiggle(MoodleType.PANIC);   -- ISReloadWeaponAction.lua:475
```

`[levantado 2026-10-31]` **O único cheiro do jogo é o moodle `NoxiousSmell`.** Os níveis vão de
"Bad Smell" a "Deadly Fumes" (`PZ/media/lua/shared/Translate/EN/Moodles.json:184-191`), e nenhum
`.lua` o referencia, então o que dispara o moodle é Java. **Não existe cheiro do próprio
personagem**, nem stat de sujeira agregado. Mod que queira esse cheiro calcula a partir da sujeira e
do sangue por parte do corpo: `getHumanVisual()`, `getBlood(part)` e `getDirt(part)`, percorrendo
`BloodBodyPartType.FromIndex(i-1)` até `BloodBodyPartType.MAX:index()` (`ISWashYourself.lua:97-99`).
Na roupa, o mesmo par se lê por parte coberta, via
`BloodClothingType.getCoveredParts(item:getBloodClothingType())` (`ISWashClothing.lua:76-84`).

### Quantos e como se chamam

**26 moodles**, contados pelas chaves de `PZ/media/lua/shared/Translate/EN/Moodles.json` (190 chaves
no total, no padrão `Moodles_<Nome>_lvl<1-4>` e `Moodles_<Nome>_desc_lvl<1-4>`; 26 nomes distintos).
Não são 26 × 8 = 208, então nem todo moodle tem os quatro níveis com descrição — a lista atual sai de:

```sh
grep -oE '"Moodles_[A-Za-z]+_' PZ/media/lua/shared/Translate/EN/Moodles.json | sort -u
```

**A grafia da chave de tradução não é a grafia da constante Lua.** O JSON usa CamelCase
(`Moodles_HeavyLoad_lvl1`, `Moodles_FoodEaten_lvl1`); o Lua usa maiúscula com underscore. As 11
grafias efetivamente observadas em `PZ/media/lua`:

`MoodleType.DRUNK` `.ENDURANCE` `.FOOD_EATEN` `.HEAVY_LOAD` `.HYPERTHERMIA` `.HYPOTHERMIA` `.PAIN`
`.PANIC` `.STRESS` `.TIRED` `.UNHAPPY`

As outras 15 **não aparecem em `media/lua`** — a constante Lua delas não é observável aqui, e chutar
a conversão CamelCase → SCREAMING_SNAKE é adivinhação. Ver "Pontos a confirmar".

### Ícones

`PZ/media/ui/Moodles/` — seis subpastas por resolução (`32`, `48`, `64`, `80`, `96`, `128`), **38
arquivos cada**, mais `moodle_guide.png` na raiz da pasta. Os nomes têm dois prefixos, `Mood_` e
`Status_` (ex.: `128/Mood_Panicked.png`, `128/Status_Bleeding.png`). São 38 e não 26 porque um moodle
pode ter arte por direção — a pasta traz também `Moodle_chevron_up/down` e
`Moodle_internal_plus/minus_green|red` soltos em `PZ/media/ui/`.

O nome do arquivo **não** é o nome da constante nem o da chave de tradução (`Mood_Panicked` para
`Panic`), então a associação é feita no Java e não é legível aqui.

## A UI de saúde

Hierarquia, ciclo de vida e a ponte Java estão em [ui-lua.md](ui-lua.md). O específico de saúde:

### Como a janela chega na tela

`Events.OnCreatePlayer` → `ISCharacterInfoWindow` → aba "Health". O elo concreto está em
`PZ/media/lua/client/XpSystem/ISUI/ISCharacterInfoWindow.lua:136`–`:139`:

```lua
self.healthView = ISHealthPanel:new(getSpecificPlayer(self.playerNum), 0, 8, tabTotalWidth, self.height-8)
self.healthView:initialise()
self.healthView.infoText = getTextOrNull("UI_HealthPanel");
self.panel:addView(xpSystemText.health, self.healthView)
```

O segundo ponto de instanciação é o exame médico em outro jogador —
`PZ/media/lua/client/TimedActions/ISMedicalCheckAction.lua:48`.

### As quatro classes de `ISHealthPanel.lua`

| Classe | Linha | Deriva de | Papel |
|---|---|---|---|
| `ISHealthPanel` | `:4` | `ISPanelJoypad` | a aba inteira |
| `ISNewHealthPanel` | `:10` | `ISUIElement` | wrapper do painel **Java** que desenha o corpo |
| `ISHealthBodyPartPanel` | `:53` | `ISBodyPartPanel` | os nós clicáveis sobre o corpo |
| `ISHealthBodyPartListBox` | `:96` | `ISScrollingListBox` | a lista de partes feridas |

`ISNewHealthPanel:instantiate()` (`:12`) é o caso raro de `instantiate()` **sobrescrito** para trocar
o objeto Java padrão por um específico:

```lua
function ISNewHealthPanel:instantiate()
    self.javaObject = NewHealthPanel.new(self.x, self.y, self.character)
    self.javaObject:setTable(self)
```

Ou seja: o desenho do boneco de saúde é `NewHealthPanel`, classe Java, **não** Lua. O que o Lua
controla é a camada de nós por cima (`ISHealthBodyPartPanel`) e a lista ao lado.

### Multiplayer: `getBodyDamage()` **não** serve para o outro jogador

`ISHealthPanel:getDamagedParts()` (`:514`) troca a fonte quando o alvo é remoto (`:517`–`:518`):

```lua
local bodyParts = self:getPatient():getBodyDamage():getBodyParts()
if isClient() and not self:getPatient():isLocalPlayer() then
    bodyParts = self:getPatient():getBodyDamageRemote():getBodyParts()
end
```

Um mod que leia `getBodyDamage()` de jogador remoto pega dado local, não o do alvo. O RPC de saúde
existente é `Commands.player.onHealthCheat` / `onHealthCheatCurrentPlayer`
(`PZ/media/lua/server/ClientCommands.lua:444` e `:451`) e é **gated por permissão de admin**
(`checkPermissions(player, Capability.UseHealthCheat)`, `:446`) — não é canal de uso geral. O
mecanismo genérico de RPC é de [persistencia-e-multiplayer.md](persistencia-e-multiplayer.md).

### `ISBodyPartPanel` — o painel de corpo reutilizável

É o único pedaço de saúde de fato reaproveitável, e não é específico de saúde: ele desenha um corpo e
colore cada parte por um valor `0..1`. O jogo o usa em três lugares — saúde
(`ISHealthPanel.lua:53`), proteção (`ISCharacterProtection.lua:30`) e isolamento de roupa
(`ISClothingInsPanel.lua:35`).

```lua
ISBodyPartPanel:new(player, x, y, target, onPartSelected)   -- :373, 123×302 fixo
```

A API pública, toda em `PZ/media/lua/client/ISUI/BodyParts/ISBodyPartPanel.lua`:

| Método | Linha | Para quê |
|---|---|---|
| `:setValue(bodyPartType, value, force)` | `:326` | define o valor `0..1` de uma parte → recalcula a cor |
| `:setColorScheme(scheme)` | `:365` | troca o gradiente; `{ {val=…, color=Color.new(…)}, … }` |
| `:getRgbForValue(val)` | `:360` | consulta a cor sem tocar no painel |
| `:getBodyPartColor(bodyPartType)` | `:316` | cor atual de uma parte |
| `:enableNodes(tex, outlineTex)` | `:289` | liga os marcadores clicáveis |
| `:overrideNodeTexture(bpType, tex, outline)` | `:296` | marcador diferente numa parte só |
| `:setAlphas(default, node, selected, deselected, background)` | `:308` | opacidades |
| `:setEnableSelectLines(b, x, y)` | `:273` | linha ligando o nó a um ponto-âncora |

O gradiente padrão é preto→branco (`:399`–`:402`); a interpolação linear entre as paradas está em
`:setColorForValue` (`:341`). O callback de seleção é `onPartSelected(functionTarget, bp)` (`:213`).

As texturas de marcador disponíveis estão listadas num comentário em `:284`–`:288`
(`bps_node`, `bps_node_a`, `bps_node_big`, `bps_node_diamond`, cada uma com `_outline`), e
`ISHealthPanel.lua:143` mostra a chamada real.

**Armadilha: `media/ui/BodyParts/` não existe no disco.** O código pede
`getTexture("media/ui/BodyParts/bps_"..sex.."_"..filename)` (`:39`), mas não há pasta nem arquivo
com esse nome no install — as texturas vivem empacotadas em
`PZ/media/texturepacks/UI2.pack`. Procurar o `.png` para copiar ou substituir não acha nada; o que
existe é o nome lógico resolvido pelo pack. O contrato de `.pack` é de [tiles.md](tiles.md).

`setup_table` (`:3`) — que amarra índice → nome de arquivo de textura — é `local`, então o conjunto
de 17 partes desenhadas não é extensível por mod.

## Por onde um mod entra

| Quero… | Dá? | Como |
|---|---|---|
| Ler estado de ferimento | sim | `getBodyDamage():getBodyPart(BodyPartType.X)` + os leitores da tabela acima |
| Ler nível de moodle | sim | `getMoodles():getMoodleLevel(MoodleType.X)`, `ISHealthPanel.lua:467` |
| Aplicar/curar ferimento | sim | setters de `BodyPart` (`setBleedingTime`, `setDeepWounded`, `setFractureTime`, `setScratched`, `setWoundInfectionLevel`, `RestoreToFullHealth`) |
| Reagir a um dano no instante em que acontece | **não** | não há evento; só polling em `OnTick`/`EveryOneMinute` |
| Adicionar tratamento ao menu de saúde | **não por tabela** | handlers são `local` (`:1020`–`:1713`); só substituindo `ISHealthPanel:doBodyPartContextMenu` (`:1796`) inteira |
| Mudar o desenho da aba de saúde | sim, por substituição | sobrescrever `ISHealthPanel:createChildren`/`:render` — padrão de `STEAM/2703664356/.../TOC_UI.lua:590` e `:608` |
| Painel de corpo próprio | sim | `ISBodyPartPanel:new(...)` + `:setColorScheme`/`:setValue` |
| Criar moodle novo | **a confirmar** | nenhum mecanismo Lua no install; ver abaixo |
| Adicionar parte do corpo nova | **não** | enum Java fechado em 17; `setup_table` é `local` |
| Ação de tratamento nova (fora do menu) | sim | `ISBaseTimedAction` própria que chame os setters — ver [timedactions.md](timedactions.md) |

Traço e profissão que afetam saúde não passam por aqui: são bloco `.txt` — ver
[scripts-txt.md](scripts-txt.md) e [perks-e-xp.md](perks-e-xp.md).

## Abstinência do Fumante `[levantado 2026-10-27]`

Toda Java. Em `PZ/media/lua` só aparece como slider de debug (`client/DebugUIs/DebugMenu/General/ISStatsAndBody.lua:61-64`:
`CharacterStat.NICOTINE_WITHDRAWAL` e `TimeSinceLastSmoke`). Levantado com `javap -c` sobre o
`projectzomboid.jar` (ver [../fontes-externas.md](../fontes-externas.md), "Ler o `.jar`"):

- **Onde roda:** fim de `BodyDamage.UpdateBoredom()`, só para quem tem `CharacterTrait.SMOKER`. O
  método **retorna no início se o `IsoPlayer` está dormindo** (`asleep`), então o contador não anda
  durante o sono.
- **Contador:** `timeSinceLastSmoke += 0.0001 × GameTime.getMultiplier()` por atualização.
- **Abstinência:** com o contador > 1, `NICOTINE_WITHDRAWAL += (StressFromBiteOrScratch / 8) × nível × multiplier`.
  `nível = floor(contador / 10) + 1`, limitado a 10. `StressFromBiteOrScratch = 0.00005`
  (`PZ/media/lua/shared/defines.lua:28`). O teto de `NICOTINE_WITHDRAWAL` é **0,51** (`CharacterStat`).
- **Efeito:** só estresse. `Stats.getNicotineStress()` devolve `STRESS + NICOTINE_WITHDRAWAL`, clampado
  pela faixa de `STRESS`. A infelicidade vem pelo caminho genérico: o mesmo `UpdateBoredom` soma
  `UNHAPPINESS` proporcional ao nível do moodle de estresse.
- **Fumar** (`RecipeCodeOnEat.consumeNicotineLogic`): soma `StressChange × fração` a `UNHAPPINESS` e
  `STRESS`, tira `0,51 × fração` de `NICOTINE_WITHDRAWAL` e põe o contador em `abstinência / 0,51`.
- **Em horas de jogo:** o jogo avança `multiplier / (120 × getMinutesPerDay())` horas por atualização
  (`GameTime.update(boolean)`). Logo o contador anda `0,012 × minutosReaisPorDia` por hora de jogo
  acordado. É proporcional ao **tempo real**: dia mais longo faz a abstinência chegar em menos horas
  de jogo. No dia de 1h30 (`DayLength = 4`, `PZ/media/lua/shared/Sandbox/Apocalypse.lua:8`), a
  abstinência começa depois de ~0,93 h acordado, cresce 0,0675 × nível por hora e chega ao teto em
  ~8,5 h com nível 1.

## Pontos a confirmar

- **O que dispara o moodle `NoxiousSmell`.** Não há chamador em Lua. A suspeita é cadáver por perto,
  e as notas da 42.22 (Pre-Release) dizem que o "Bad Smell" passa a impedir dormir, mas nenhuma das
  duas coisas está provada no `media/`. `[aberto 2026-10-31]`

- **A grafia Lua das outras 15 constantes de `MoodleType`.** Só 11 aparecem em `PZ/media/lua`. As
  chaves de tradução dão os 26 nomes em CamelCase, e as 11 observadas sugerem
  CamelCase → SCREAMING_SNAKE (`HeavyLoad` → `HEAVY_LOAD`), mas isso é inferência de 11 amostras. O
  PZ JavaDocs (`albion.codeberg.page/PZ-JavaDocs/`, consultado 2026-08-08) lista o enum em CamelCase
  (`Endurance`, `HeavyLoad`, `FoodEaten`, … `CantSprint`, `MAX`), o que **diverge** do que o Lua
  usa — pela regra da árvore o código ganha, e a fonte não resolve a dúvida. Testar in-game antes de
  usar qualquer uma das 15.
- **Se um mod consegue registrar um moodle novo.** Não há `MF`/`MoodleFramework` nem qualquer função
  de registro no install, e nenhum dos 19 mods de `STEAM/` que tocam saúde cria um. Isso prova
  ausência no `media/`, não impossibilidade no Java. É teste in-game.
- **O contrato de `setScratched(bool, bool)`** — o segundo parâmetro. Chamado como `(true, true)` em
  `ISMoveableSpriteProps.lua:1372` e `(true, false)` em `ClientCommands.lua:577`, sem comentário em
  nenhum dos dois.
- **Os limiares de severidade** (`getScratchTime() > 17`, `> 14`, etc., `ISHealthPanel.lua:635`) são
  da UI. Se o Java usa os mesmos números para decidir efeito de gameplay, não é verificável aqui.
- **A unidade dos temporizadores.** `setFractureTime(21)` (`ClientCommands.lua:539`) e
  `setBleedingTime(10)` (`:456`) são valores de debug sem unidade declarada — horas de jogo, minutos
  ou tique não dá para afirmar.
- **`getStiffness()`** entra no predicado de "parte ferida" (`ISHealthPanel.lua:523`) e tem limiares
  próprios (`:707`–`:709`), mas a UI o imprime com o texto
  `(Debug - HAS NO EFFECT ON THE PLAYER!)` (`:716`). Se afeta gameplay em 42.20.2 está em aberto.
- **`BodyPartType` vs `BloodBodyPartType`: o alinhamento de índice.** O jogo converte por
  `FromIndex(ToIndex(...))` assumindo os espaços equivalentes, mas `BloodBodyPartType` tem `Back` a
  mais. Onde a divergência começa a doer (e se `Back` é o último índice, o que salvaria a conversão)
  não é legível no `media/`.
- **Os 38 ícones por resolução para 26 moodles** — qual moodle usa mais de um arquivo, e por qual
  regra o Java escolhe entre `Mood_` e `Status_`.
- **Onde o dano é de fato aplicado.** Nenhum Lua do install faz o personagem levar dano de zumbi ou
  de queda; é tudo Java. O único candidato Lua (`HealthUpdate.lua`) está desativado.

> Última verificação: 2026-08-08 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

# Sandbox options — `media/sandbox-options.txt`

O mecanismo de opção **por save** do B42: o mod declara opções num `.txt` próprio, o jogo as mistura
com as do jogo base na tela de Sandbox (Custom Sandbox / Server Settings) e entrega o valor ao Lua
pela tabela global `SandboxVars`. É o mecanismo de opção mais usado pelos mods instalados aqui — **26
dos 89** itens da Workshop, contra os poucos que usam `PZAPI.ModOptions`.

Contraste com [opcoes-de-mod.md](opcoes-de-mod.md), que cobre o outro mecanismo: `ModOptions` é
por-máquina, muda a qualquer momento e vive na aba MODS; sandbox option é **por-save**, congela na
criação do mundo e vive na tela de Sandbox. Não são substitutos.

Alias de caminho: `PZ/` = instalação do jogo, `STEAM/` = os 89 mods da Workshop instalados
(`...\steamapps\workshop\content\108600\`), que aqui são a **única** fonte de sintaxe (ver abaixo).
Ver [../index.md](../index.md).

## A assimetria que define a página

**O jogo base não tem `media/sandbox-options.txt`.** O arquivo não existe em `PZ/media/` — é um
artefato exclusivo de mod. As opções do jogo base são declaradas no Java e chegam ao Lua já prontas;
o que existe em `PZ/media/lua/shared/Sandbox/` são só os **presets** de valores:

| Arquivo | Papel |
|---|---|
| `PZ/media/lua/shared/Sandbox/SandboxVars.lua` | 4 linhas; monta a global `SandboxVars` |
| `PZ/media/lua/shared/Sandbox/Apocalypse.lua` | preset padrão (7.992 bytes) |
| `PZ/media/lua/shared/Sandbox/Outbreak.lua`, `Rising.lua`, `Extinction.lua`, `SixMonthsLater.lua` | demais presets |

O arquivo inteiro que amarra tudo (`PZ/media/lua/shared/Sandbox/SandboxVars.lua:1-4`):

```lua
SandboxVars = require "Sandbox/Apocalypse"

-- This is needed to add custom sandbox options to the SandboxVars table.
getSandboxOptions():initSandboxVars()
```

A linha 4 é o mecanismo todo: `initSandboxVars()` é o que **enxerta as opções de mod** dentro de
`SandboxVars`. O comentário da linha 3 é do próprio jogo.

**Consequência prática:** não há exemplo canônico de `sandbox-options.txt` em `PZ/media/` para copiar.
Toda a sintaxe desta página foi levantada nos mods de `STEAM/` — **62 arquivos**, 43 nomes de mod
distintos sob 26 itens da Workshop, **1.599 blocos `option`**. Isso é uso observado em mods
publicados e funcionando, não contrato declarado pela IndieStone; onde a distinção importa, está
marcado.

## Onde o arquivo fica na árvore do mod

O caminho é sempre `media/sandbox-options.txt`, relativo à raiz da pasta que contém `media/` — ou
seja, dentro da pasta de versão no layout B42. Censo dos 62 arquivos:

| Local | Arquivos |
|---|---|
| `<Mod>/media/` (sem pasta de versão, layout pré-B42) | 41 |
| `<Mod>/42/media/` | 7 |
| `<Mod>/42.13/media/` | 6 |
| `<Mod>/42.15/media/` | 3 |
| `<Mod>/42.17/media/` | 2 |
| `<Mod>/42.0/media/` | 2 |
| `<Mod>/common/media/` | 1 |

O PZ-API-Docs publica o padrão de raiz como a regex `media\/sandbox-options\.txt$` — o parser casa
pelo **fim do caminho**, o que explica funcionar igual dentro de pasta de versão e em `common/`.
Isso é da fonte externa, não confirmado em `PZ/media/` (ver "Pontos a confirmar").

Sobre a divisão pasta-de-versão vs `common/`, ver
[carregamento-de-mods.md](carregamento-de-mods.md).

## O contrato mínimo

Exemplo canônico, arquivo real
(`STEAM/2875848298/mods/CommonSense/42.0/media/sandbox-options.txt:1-9`):

```
VERSION = 1,

option CommonSense.PryingMechanic
{
    type = boolean,
    default = true,
    page = CommonSense,
    translation = CommonSense_PryingMechanic,
}
```

### `VERSION` — a primeira linha, sem exceção

`VERSION = 1,` é a linha 1 dos **62 de 62** arquivos levantados. O PZ-API-Docs marca `VERSION` como
`required`, com valor permitido `1` e a nota *"Keep this equal to 1"*. É o único campo de nível de
arquivo; todo o resto vive dentro de blocos `option`.

### Os campos do bloco `option`

Censo por **ocorrência** (não por linha — vários mods põem os campos numa linha só), sobre os 1.599
blocos:

| Campo | Ocorrências | Papel |
|---|---|---|
| `type` | 1.602 | tipo do valor — ver tabela abaixo |
| `default` | 1.602 | valor inicial; tem de casar com `type` |
| `page` | 1.602 | agrupa as opções numa aba/categoria da tela |
| `translation` | 1.602 | chave da string do rótulo |
| `min` | 905 | só `integer` e `double` |
| `max` | 905 | só `integer` e `double` |
| `numValues` | 68 | só `enum` — quantos valores a lista tem |
| `valueTranslation` | 24 | só `enum` — base da chave dos rótulos de cada valor |
| `tooltip` | 3 | ver "O que falha em silêncio" |

Comando do censo, reproduzível:

```sh
find . -iname "sandbox-options.txt" -print0 \
  | xargs -0 grep -hoE '[A-Za-z_][A-Za-z0-9_]*[[:space:]]*=' \
  | sed 's/[[:space:]]*=$//' | sort | uniq -c | sort -rn
```

As 1.602 ocorrências contra 1.599 blocos são 3 opções comentadas com `/* */` (ver "Comentários").

O PZ-API-Docs marca `type` como `required` e `default`, `page`, `translation`, `min` e `max` como
**não** obrigatórios. Os 1.599 blocos do censo declaram `type`, `default`, `page` e `translation`
**todos** — se são opcionais de fato, nenhum mod instalado exercita isso. Não dá para provar
obrigatoriedade em `PZ/media/`, então vai para "Pontos a confirmar".

### Os 5 valores de `type`

Censo de `type = <x>` nos 62 arquivos, cruzado com os *allowed values* do PZ-API-Docs — **os dois
conjuntos batem exatamente**:

| `type` | Ocorrências | Campos que acompanham |
|---|---|---|
| `integer` | 604 | `min`, `max` |
| `boolean` | 599 | — |
| `double` | 301 | `min`, `max` |
| `enum` | 68 | `numValues`, `valueTranslation` |
| `string` | 30 | — |

**Mas o consumidor trata seis, não cinco.** Quem lê a option do motor e escolhe o controle de UI é
`PZ/media/lua/client/OptionScreens/ServerSettingsScreen.lua:5096-5121`, e a cadeia de `getType()`
tem um ramo a mais:

| `getType()` | Controle |
|---|---|
| `boolean` | `checkbox` |
| `double` | `entry` (aceita ponto flutuante) |
| `enum` | `enum`, populado por `getValueTranslationByIndex` |
| `integer` | `entry`, `onlyNumbers = true` |
| `string` | `string` |
| **`text`** | **`text`** (`:5116-5118`) |

Qualquer outro valor cai em `error("unknown server option class " .. tostring(option:getType()))`
(`:5120`) — erro duro, não silencioso.

Ou seja: **`text` existe no espaço de tipos e tem zero uso declarado** nos 1.602 blocos do censo e
zero menção na fonte externa. `spinbox` continua não existindo em lugar nenhum. A diferença importa
porque o censo mede o que foi *escrito*, e esta lista mede o que o motor *aceita* — é a mesma
distinção entre as 57 `flags` usadas e as aceitas em [scripts-txt.md](scripts-txt.md).

O mesmo trecho mostra que **a lista de options é do Java, não do Lua**: `ServerOptions.new()` e
`serverOptions:getOptionByName(...)` (`:5083`, `:5091`), com
`error('unknown server option "…"')` se o nome não existir. O `.lua` só distribui os nomes em páginas
de UI.

Exemplos reais dos dois tipos com faixa e do `enum`:

```
option WQS.DeadlineDays
{
	type = integer, min = 0, max = 180, default = 0,
	page = WQS, translation = WQS_DeadlineDays_txt,
}
```
(`STEAM/2987772693/mods/Wolf Extraction Quest/42/media/sandbox-options.txt:4-7`)

```
option SapphCooking.NonPerishableChance 
{
	type = enum,
	numValues = 7,
	default = 3,

	page = SapphCooking,
	translation = SapphCooking_NonPerishableChance,
	valueTranslation = SapphCooking_NPerishableChance,
}
```
(`STEAM/2832136889/mods/SapphCooking/media/sandbox-options.txt:3-12`)

Em `enum`, `default` é o **índice** (base 1), não o rótulo.

## O namespace — e por que ele é o que faz a opção chegar no Lua

Os **1.599** blocos do censo, sem uma exceção, nomeiam a opção como `option <Namespace>.<Campo>`; há
42 namespaces distintos. Zero opções sem ponto.

Isso não é estilo: o namespace vira **subtabela de `SandboxVars`**. É o que
`getSandboxOptions():initSandboxVars()` (`SandboxVars.lua:4`) faz. Declarando

```
option CommonSense.PryingMechanic
```

o Lua do mod lê o valor como:

```lua
if SandboxVars.CommonSense.PryingMechanic then
```

**Essa é a forma dominante de leitura, com folga.** Censo do Lua dos 62 mods que têm
`sandbox-options.txt`:

| Forma | Ocorrências |
|---|---|
| `SandboxVars.<Namespace>.<Campo>` | 2.165 |
| `SandboxVars.<Campo>` (opção do jogo base, um nível) | 247 |
| `getSandboxOptions():getOptionByName(...)` | 167 |

O nível único é para as opções **do jogo base**, que não têm namespace — o próprio jogo usa assim
(`PZ/media/lua/server/Farming/SFarmingSystem.lua:99`):

```lua
if SandboxVars.PlantResilience == 1 then -- very high
```

`getOptionByName` existe e é usado, mas é a via da API Java — necessária para ler metadado
(tradução, tipo, faixa) ou para escrever, não para simplesmente ler valor.

## Como o jogo descobre as opções de mod

O laço está em `PZ/media/lua/client/OptionScreens/ServerSettingsScreen.lua:5133-5139`:

```lua
for i=1,getSandboxOptions():getNumOptions() do
	local option = getSandboxOptions():getOptionByIndex(i-1)
	if option:isCustom() and option:getPageName() ~= nil then
		local page = pageByName[option:getPageName()]
```

Três coisas que esse trecho prova:

- **`getOptionByIndex` é base 0** (`i-1` sobre um laço `1..n`).
- **`isCustom()`** é o que separa opção de mod de opção do jogo base.
- **`getPageName() ~= nil` é um gate real**: opção sem `page` é pulada nessa listagem. É a
  explicação mais provável de "declarei a opção e ela não aparece na tela" — ver "O que falha em
  silêncio".

A tela de Sandbox propriamente dita é `PZ/media/lua/client/OptionScreens/SandboxOptions.lua`; o
painel de admin em jogo é `PZ/media/lua/client/ISUI/AdminPanel/ISServerSandboxOptionsUI.lua`.

Os métodos abaixo são **uso observado** no Lua do jogo, não assinatura publicada (a API Java não tem
doc oficial — ver a observação em [../fontes-externas.md](../fontes-externas.md)):
`getSandboxOptions():getNumOptions()`, `:getOptionByIndex(i)`, `:getOptionByName(nome)`,
`:initSandboxVars()`; e na opção, `:isCustom()`, `:getPageName()`, `:getName()`.

## Tradução

O arquivo é `media/lua/shared/Translate/<IDIOMA>/Sandbox.json` — o mesmo do jogo, que traz **1.085
chaves** em `PZ/media/lua/shared/Translate/EN/Sandbox.json` e existe em 29 idiomas.

**O prefixo `Sandbox_` é implícito**: não aparece no `.txt`, o jogo o adiciona. As quatro convenções
de chave, todas confirmadas em arquivo real:

| O que | Chave | Vem de |
|---|---|---|
| Rótulo da opção | `Sandbox_<translation>` | campo `translation` |
| Tooltip | `Sandbox_<translation>_tooltip` | — (só a chave) |
| Nome da aba | `Sandbox_<page>` | campo `page` |
| Rótulo do valor N de `enum` | `Sandbox_<valueTranslation>_option<N>` | campo `valueTranslation`, base 1 |

O jogo base exercita as três primeiras formas em
`PZ/media/lua/shared/Translate/EN/Sandbox.json:8-10`:

```json
    "Sandbox_ZombieCount": "Zombie Count",
    "Sandbox_ZombieCount_tooltip": "Changing this also sets the \"Population Multiplier\" in Advanced Zombie Options.",
    "Sandbox_ZombieCount_option1": "Insane",
```

E o par `valueTranslation` → chaves, do lado do mod: o bloco de SapphCooking acima declara
`valueTranslation = SapphCooking_NPerishableChance` e o arquivo de tradução traz
`Sandbox_SapphCooking_NPerishableChance_option1` … `_option7` — sete chaves para os `numValues = 7`.
Note que `translation` (`SapphCooking_NonPerishableChance`) e `valueTranslation`
(`SapphCooking_NPerishableChance`) são **strings diferentes** nesse mod; são campos independentes.

O nome da aba segue o mesmo padrão: `page = CommonSense` → `Sandbox_CommonSense = "Common Sense"`, e
`page = WQS` → `"Sandbox_WQS": "Wolf Extraction Quest"`.

### `.json` (B42) vs `.txt` (B41)

**Use `.json`.** O jogo não tem uma única tabela de strings em `.txt`: `PZ/media/lua/shared/Translate/`
tem **1.248 `.json`** e exatamente **2 `.txt`** — `TH/language.txt` e `TH/credits.txt`, ambos com o
`.json` equivalente (`TH/language.json`, `TH/Credits.json`) na mesma pasta. São resíduo legado num
único idioma, não formato em uso; `EN/` só tem `.json`.

Nos mods a coisa é mais bagunçada, e **isso não é sinal de que `.txt` funciona**: 47 arquivos
`Sandbox.json` contra 52 `Sandbox_EN.txt` entre os 62 levantados. O caso que mais informa é
*More Traits* (`STEAM/1299328280/mods/More Traits/42.17/media/lua/shared/Translate/EN/`), que entrega
os **dois** lado a lado — `Sandbox.json` e `Sandbox_EN.txt`, e o mesmo par em `ItemName`, `Moodles`,
`Tooltip` e `UI`. É um mod que migrou para `.json` e não apagou o `.txt`.

**Confirmado in-game em 2026-08-07 (jogo 42.20.2): o B42 não lê `.txt`.** Com `SkateboardMod` ativo,
a tela de Opções do Sandbox mostra as opções dele pela **chave crua**, não pelo rótulo:

```
Sandbox_Skateboard_skateboardWalkSpeedMultiplier      1.7
Sandbox_Skateboard_skateboardRunSpeedMultiplier       2.5
Sandbox_Skateboard_skateboardImmersive                [x]
```

O nome da página no menu lateral também sai cru (`Sandbox_Skateboard`), e o mod entrega tradução só
em `Sandbox_EN.txt`. **E não há aviso nenhum no `console.txt`** — falha totalmente silenciosa. Os
mods `versionMin=42.x` que entregam só `.txt` estão todos nessa situação; ninguém reportou porque a
opção continua *funcionando*, só aparece sem nome legível. Censo completo do formato em
[carregamento-de-mods.md](carregamento-de-mods.md).

Isso arrasta junto o `tooltip`: como o `.txt` inteiro é ignorado, não existe caminho para um tooltip
declarado nesse formato chegar à tela.

## Duas formas de abrir o bloco

A forma canônica (a do exemplo acima) põe a chave na linha seguinte. Mas **17 dos 62 arquivos**, com
**186 blocos**, usam uma variante com `=` antes da chave
(`STEAM/3118990099/mods/TrueMusicJukebox/media/sandbox-options.txt:3-8`):

```
option TrueMusicJukebox.jukeboxesAttractZombies = {
	type = boolean,
	default = true,
	page = TrueMusicJukebox,
	translation = TrueMusicJukebox.jukeboxesAttractZombies
}
```

Duas observações sobre esse trecho, além do `=`: a última linha **não** tem vírgula final (a forma
canônica põe vírgula em todas), e o `translation` usa **ponto** onde os outros mods usam sublinhado.

Todos os 17 são mods publicados na Workshop, o que sugere que o parser aceita a variante — mas isso é
inferência, não prova; nada em `PZ/media/` documenta o parser. **Para escrever mod novo, use a forma
canônica**, que é a maioria (1.413 dos 1.599 blocos).

### Comentários

`/* ... */` aparece comentando blocos inteiros em dois arquivos —
`STEAM/2703664356/mods/TheOnlyCure/media/sandbox-options.txt:4` (`/* option TOC.RollUpSleeves`) e
`STEAM/3260995510/mods/6 TileProtect/media/sandbox-options.txt:66`
(`/*option BTSE.AllowPickupFireplace = {`). São opções desativadas pelo autor, não sintaxe ativa.

## Faixa e tipo são validados na carga

Ao contrário do resto do parser, `min`/`max` e o tipo **não** falham em silêncio: o motor loga e
corrige. Da sessão de 2026-08-07 (`USER/console.txt:167-168`):

```
ERROR: IntegerConfigOption.setValue() "MaximumRatIndex" 100 is greater than max=50
ERROR  IntegerConfigOption.parse() "FirearmUseDamageChance" string="true"
```

A primeira linha é valor fora da faixa; a segunda é tipo trocado — um `boolean` entregue onde se
esperava inteiro. As duas saem no canal `General` e o jogo continua subindo, então **é erro
recuperável, não fatal**. Vale como gancho de diagnóstico: se uma opção sua não assume o valor
esperado, procure `ConfigOption` no `console.txt` antes de suspeitar do bloco.

Os dois casos observados são de opção **vanilla**, vindos de um preset. Se o mesmo validador roda
sobre opção declarada por mod não foi medido — ver "Pontos a confirmar".

## O que falha em silêncio

O parser da IndieStone não reclama — a opção simplesmente não existe, ou existe sem rótulo. Os casos
que o levantamento sustenta:

- **Sem `page`, a opção não é listada.** `ServerSettingsScreen.lua:5135` exige
  `option:getPageName() ~= nil` para montar a página. Os 1.599 blocos do censo declaram `page`.
- **Sem `translation` (ou com a chave faltando no `Sandbox.json`), o rótulo cai para a chave crua.**
  O prefixo `Sandbox_` é implícito: escrever `translation = Sandbox_Foo` no `.txt` produz
  `Sandbox_Sandbox_Foo` — errar isso é fácil e não gera erro.
- **`numValues` errado em `enum`** desencontra da quantidade de chaves `_option<N>`: sobra ou falta
  rótulo, sem aviso.
- **`tooltip =` no `.txt` não chega à tela.** Só 3 ocorrências em 1.599 blocos, todas do mesmo mod
  (`STEAM/3456675747/mods/SkateBoard/42.13/media/sandbox-options.txt:11,22,31`), e o PZ-API-Docs
  **não lista `tooltip`** entre os parâmetros de `option`. Com esse mod ativo em 2026-08-07 a tela de
  Sandbox mostrou as opções pela chave crua — o `.txt` de tradução dele é ignorado inteiro (ver
  "`.json` (B42) vs `.txt` (B41)"), então não há caminho para o tooltip aparecer. O caminho válido é
  a chave `Sandbox_<translation>_tooltip` no `.json`, que é o que o jogo base usa (`Sandbox.json:9`).
- **Namespace ausente quebraria a leitura via `SandboxVars.<NS>.<Campo>`**, que é a forma que 2.165
  usos empregam. Nenhum mod do censo omite o namespace.
- **Sandbox option é por-save.** Mudar o `.txt` não muda mundo já criado: o valor foi gravado na
  criação. Testar mudança de `default` exige save novo. Ver
  [testar-e-debugar.md](testar-e-debugar.md).
- **Em `shared/`, `SandboxVars` tem os valores DEFAULT, não os do mundo — e ler ali falha
  *aberto*.** É o pior caso desta página, porque o sintoma é o oposto do esperado: a opção
  desligada continua tendo efeito.

  A tabela **existe** no escopo de um arquivo de `media/lua/shared/` — medido por `print` em
  2026-08-12, `SandboxVars.<Namespace>` não é `nil` ali. O que ainda não aconteceu é o
  **`SandboxOptions.load()`**, que é quem sobrescreve os defaults com o que foi escolhido para
  aquele mundo. No `USER/console.txt` a ordem do boot é `triggerEvent OnInitWorld` →
  **`SandboxOptions.load() start/end`** → `OnLoadedMapZones` → `OnGameTimeLoaded`.

  Ou seja: a leitura **não quebra, ela mente**. Devolve o `default` declarado no
  `sandbox-options.txt`, e como o default costuma ser `true`, todo gate cai no ramo "ligado".
  Nenhum stacktrace, nenhuma linha de log — e o idioma defensivo usual (*"se não tenho a opção,
  assumo ligado, para não tirar conteúdo de quem já tem save"*) mascara o erro em vez de
  denunciá-lo.

  **`media/lua/server/` carrega depois do `SandboxOptions.load()` e lê o valor certo.** Verificado
  in-game em 2026-08-12 com o mesmo gate escrito igual nos dois lugares: funcionou em
  `server/Items/` e em `server/Definitions/` (o item some quando a opção é desmarcada) e falhou em
  `shared/Definitions/`.

  **Conserto: mover o arquivo para `server/`, não adiar para um evento.** Adiar para
  `Events.OnGameStart` corrige o *valor* e ainda assim não funciona quando o que se altera é
  tabela que o Java copia — medido no mesmo dia: a inserção acontecia (lista de 22 para 222) e não
  tinha efeito nenhum in-game, porque a cópia já fora tirada. Precedente de mod publicado para a
  forma correta: `STEAM/3262863785/mods/Perts Party Tiles/media/lua/server/Definitions/Perts_AttachedWeaponDefinitions.lua`,
  arquivo de uma linha que insere em `AttachedWeaponDefinitions` no escopo do arquivo, sem evento.
- **BOM e caixa de campo** valem aqui como em qualquer `.txt` da IndieStone — ver
  [scripts-txt.md](scripts-txt.md).

## Pontos a confirmar

- **Se `client/` se comporta como `shared/` ou como `server/`.** Está provado que
  `media/lua/shared/` lê o **default** e que `media/lua/server/` lê o valor do mundo (teste
  in-game de 2026-08-12, ver "O que falha em silêncio"); `client/` não foi medido. Também não foi
  isolado se a regra é a pasta em si ou a posição dela na ordem de carga do carregador.
- **Quais tabelas do jogo o Java copia, e quando.** Provado que `AttachedWeaponDefinitions` é
  copiada em algum ponto anterior a `OnGameStart` — mutação feita nesse evento não tem efeito
  in-game, embora a tabela Lua mude. Se vale para as outras globais de `shared/Definitions/`
  (ver [definitions-lua.md](definitions-lua.md)) não foi testado. Consequência prática enquanto
  não estiver: **mutação de tabela de definição pertence ao escopo do arquivo, em `server/`** — não
  a um evento.
- **`default`, `page`, `translation`, `min`, `max` são mesmo opcionais?** O PZ-API-Docs
  (`pz-wiki-modding.github.io/PZ-API-Docs/scripts/option.html`) marca só `type` como `required`, mas
  os 1.599 blocos instalados declaram os quatro primeiros sempre. Não é decidível em `PZ/media/` —
  resolve testando um bloco mínimo in-game.
- **A variante `option X = {` é suportada ou tolerada?** 17 arquivos publicados a usam; o parser mora
  no Java e não é legível aqui.
- **Se `min`/`max` valem para opção de mod, e se o valor é rejeitado ou fatiado.** A sessão de
  2026-08-07 mostra o motor validando faixa e tipo na carga, mas só em opção **vanilla**
  (`USER/console.txt:167-168`) — nenhum mod ativo tinha opção fora da faixa para comparar. Ver
  "Faixa e tipo são validados na carga" acima.
- **A regex de raiz `media\/sandbox-options\.txt$`** vem do PZ-API-Docs
  (`scripts/roots/sandboxoptions.html`), não de `PZ/media/`. Explica o arquivo funcionar em
  `common/media/`, mas não está confirmada no código.
- **Existe evento Lua para carga/mudança de sandbox option?** Não foi encontrado nenhum `Events.*`
  com `Sandbox` no nome em `PZ/media/lua`. Ausência de achado não é prova de ausência — ver
  [eventos-lua.md](eventos-lua.md).
- **Assinatura real de `SandboxOption`** (`:isCustom()`, `:getPageName()`, `:getNumValues()`,
  `:getValueTranslationByIndex()`): tudo é uso observado no Lua do jogo. O JavaDocs não-oficial
  (`albion.codeberg.page/PZ-JavaDocs/`) tem a classe, mas não foi cruzado nesta rodada.
- **Nenhum dos 12 mods de `WS/` usa `sandbox-options.txt`** — não há exemplo próprio para conferir
  contra os mods de terceiros.

> Última verificação: 2026-08-07 — jogo **42.20.2** (`ffe7a8a4b1`), PZ buildid 24574865, media/
> + sessão in-game com `SkateboardMod` ativo (`USER/console.txt` de 2026-08-07 18:46).

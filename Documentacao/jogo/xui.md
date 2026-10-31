# XUI — o sistema de skin da UI

Como um valor escrito num `.txt` de `PZ/media/scripts/xui/` vira a cor de um botão na tela: quem
carrega os arquivos, como uma skin é escolhida em runtime, o que XUI acrescenta ao `ISUI` clássico e
o que um mod consegue (e não consegue) fazer com isso.

Esta página é a **cola** entre duas que já existem e não se repetem aqui:

- **Sintaxe dos blocos** (`xuiSkin`, `xuiConfig`, `imports`, `entity`) — [scripts-txt.md](scripts-txt.md).
- **Hierarquia `ISUIElement` → `ISPanel` e ciclo de vida** — [ui-lua.md](ui-lua.md).
- **`component UiConfig` dentro de `entity`** — [construcao.md](construcao.md).
- **Ícone ausente e o aviso `XuiSkin$EntityUiStyle`** — [arte-e-modelos.md](arte-e-modelos.md).

Aliases de caminho: ver a tabela de [../index.md](../index.md) (`PZ/`, `WS/`, `STEAM/`, `USER/`).

## O que XUI é — e o que ele não é

XUI **não substitui** o `ISUI`. Ele é uma camada declarativa que, no momento da construção, preenche
campos de um objeto Lua `ISUIElement` com valores lidos de um `.txt`. O objeto continua sendo o mesmo
`ISButton`/`ISPanel` de [ui-lua.md](ui-lua.md); só chegou na tela com `backgroundColor` vindo do
script em vez de vindo do `:new()`.

A prova de que a classe-base quase não sabe de XUI está nela mesma. `ISUIElement` tem 3 pontos de
contato e nenhum campo de skin:

| Ponto | Onde | O quê |
|---|---|---|
| `ISUIElement:getStyle()` | `PZ/media/lua/client/ISUI/ISUIElement.lua:1952-1963` | devolve `self.style`, senão delega ao pai, senão `nil` |
| `o.style = nil` | `:1995` | o campo nasce vazio |
| o "Xui fix" | `:1970-1975` | `x = x or 0; y = y or 0; width = width or 0; height = height or 0;`, com o comentário `-- The following is required to make Xui work:` |

O "Xui fix" existe porque XUI constrói o elemento **sem passar dimensões** — elas vêm do script
depois. Fora isso, `ISUIElement.lua` não tem `setXui`, `getXui` nem `xuiSkin`. Toda a mecânica mora
em dois arquivos separados, `ISXuiSkin.lua` e `ISXuiBuilder.lua`, e no Java.

## Onde o sistema mora

`PZ/media/scripts/xui/` tem **64 `.txt`**: 5 na raiz e 59 em `defaultskin/`.

| Arquivo | Linhas | Papel |
|---|---|---|
| `xui_config.txt` | 272 | o **esquema** — bloco `xuiConfig project_zomboid`, único no jogo inteiro |
| `xui_skin_default.txt` | 16 | declara `xuiSkin default` **vazio**; o conteúdo está em `defaultskin/` |
| `xui_skin_electric_common.txt` | 15 | skin alternativa, herda de `default` |
| `xui_skin_fluid_separator.txt` | 135 | skin alternativa, herda de `default` |
| `xui_skin_furnace_processor.txt` | 30 | skin alternativa; declara o nome **`skin_furnace_processor`**, que não bate com o do arquivo (`:3`) |
| `defaultskin/` | 59 arquivos | 50 `xs_<ClasseLua>.txt` + 9 `x_*.txt` |

**A pasta `xui/` não é onde a skin `default` mora.** Ela é onde mora a *base* dela. No `media/`
inteiro há **251 declarações de `xuiSkin default`, em 243 arquivos**, e a maioria está fora de `xui/`:

| Onde | Arquivos que declaram `xuiSkin default` |
|---|---|
| `PZ/media/scripts/entities/**` | 183 |
| `PZ/media/scripts/xui/` (raiz + `defaultskin/`) | 60 |

Ou seja: **o caminho do arquivo é irrelevante para o XUI.** O que junta tudo é o nome do bloco. Esse
é o fato central da página e o que torna modding de XUI possível — ver "Modding" abaixo.

## As quatro peças declarativas

### 1. `xuiConfig` — o dicionário de nomes de propriedade

`PZ/media/scripts/xui/xui_config.txt:3`. Bloco único no jogo, sem par em nenhum outro `.txt`. Declara
**229 nomes de propriedade em 8 grupos**, e o grupo é o **tipo**:

| Grupo | Nomes | Primeira linha |
|---|---|---|
| `String` | 14 | `xui_config.txt:6` |
| `StringList` | 1 | `:24` |
| `TranslateString` | 10 | `:30` |
| `Double` | 56 | `:44` |
| `Boolean` | 70 | `:108` |
| `FontType` | 5 | `:182` |
| `Color` | 45 | `:191` |
| `Texture` | 28 | `:240` |

Os dois comentários do arquivo dizem o que a separação decide: `/* normal String, no auto
translation */` (`:5`) contra `/* String values gets auto passed through Translator */` (`:29`).
Escrever um rótulo no grupo errado não dá erro — ele só deixa de passar pelo tradutor.

Os nomes dos grupos reaparecem **literalmente** do lado Lua, como valores do enum `XuiVarType`
(`ISXuiBuilder.lua:517-534`: `Color`, `Texture`, `StringList`, `Function`, `Vector`). Não há grep que
prove que o parser Java lê o grupo do `xuiConfig` para popular esse enum — mas a correspondência de
nomes é 1:1 e é a leitura natural. Ver "Pontos a confirmar".

Sintaxe do bloco: [scripts-txt.md](scripts-txt.md), seção `xuiConfig`.

### 2. `xuiSkin` — o conjunto de estilos

Um bloco por skin. O jogo declara **4 nomes**: `default` (251 ocorrências), `electric_common`,
`fluid_separator`, `skin_furnace_processor` (1 cada).

### 3. Bloco de classe dentro da skin — com nome e sem nome

Dentro de um `xuiSkin`, cada bloco filho é nomeado pela **classe Lua** que ele estiliza. Há duas
formas, e a diferença importa:

```
        ISButton                          /* sem ID: é o default do tipo   */
        {
            font                        = UIFont.Small,
            backgroundColor             = C_Black,
            borderColor                 = C_BorderLight,
            ...
        }

        ISButton S_Button_Craft           /* com ID: é um estilo nomeado    */
        {
            title               = "Craft",
            width               = 150,
            isAutoFillX         = true,
        }
```

(`PZ/media/scripts/xui/defaultskin/xs_ISButton.txt:5-22` e `:45-50`.)

`defaultskin/` declara **50 tipos de classe** desse jeito, um arquivo por classe — de `ISButton`,
`ISLabel`, `ISPanel` (as clássicas de [ui-lua.md](ui-lua.md)) até as do B42 de entidade
(`ISEntityWindow`, `ISCraftBenchPanel`, `ISFluidSlotPanel`, `ISWidgetCraftProgress`).

**O casamento é pelo campo `Type` da classe Lua**, não pelo nome do arquivo. `Type` é o que
`ISBaseObject:derive(type)` grava (`PZ/media/lua/shared/ISBaseObject.lua:13`) — então
`ISButton = ISPanel:derive("ISButton")` (`PZ/media/lua/client/ISUI/ISButton.lua:3`) produz
`Type = "ISButton"`, que é exatamente o nome do bloco. O nome `xs_ISButton.txt` é convenção humana; o
parser não olha para ele.

### 4. `entity ES_*` e `colors`

Dois blocos filhos que não são classe Lua.

`entity` — o estilo de uma entidade construível. O default do tipo está em
`PZ/media/scripts/xui/defaultskin/x_entity.txt:11-20`, e é o único lugar que lista os campos
opcionais, comentados:

```
        /* default entity style */
        entity
        {
            LuaWindowClass      = ISEntityWindow,
            /*XuiStyle          = optional, */
            DisplayName         = Entity_DisplayName_Default,
            Description         = Entity_Desc_Default,
            BuildDescription    = Entity_BuildDesc_Default,
            Icon                = Item_Dice,
            /*LuaCanOpenWindow    = optional, */
            /*LuaOpenWindow       = optional, */
```

`XuiStyle` aparece comentado três vezes nesse arquivo (`:14`, `:27`, `:36`) e **não é usado em
lugar nenhum** de `media/scripts` — é o campo que amarraria um estilo nomeado a uma entidade ou a um
painel de componente. O jogo tem **238 blocos `entity ES_*`**.

`colors` — a paleta nomeada da skin, em RGBA separado por `:`
(`PZ/media/scripts/xui/defaultskin/x_colors.txt:12-30`):

```
        colors
        {
            C_MyColor           = 1.00 : 0.00 : 0.00 : 1.00,
            C_Black             = 0.00 : 0.00 : 0.00 : 1.00,
            C_BgMouseOver       = 0.30 : 0.30 : 0.30 : 1.00,
```

O comentário de `:6-10` dá um contrato que não se lê em outro lugar: *"Next to named colors that can
be defined here, the named colors from Colors.java may also be used in style scripting."* Ou seja,
`borderColor = Orange` (`xs_ISButton.txt:65`) é válido sem `Orange` estar declarado em `colors` — vem
do Java. É por isso que `C_` é prefixo de convenção, não de sintaxe.

### A convenção de nomes, escrita pela própria IndieStone

`PZ/media/scripts/xui/xui_skin_default.txt:6-9`:

```
        prepend naming convention:
        entity style    = ES
        color           = C
        style           = S_{CONTROL_NAME_MINUS_IS}
```

`ES_Kiln_Small`, `C_BgWindow`, `S_Button_Craft` (`ISButton` menos o `IS`). É convenção, não regra do
parser — mas seguir é o que faz um mod parecer com o jogo.

## Como uma skin é montada: merge por nome, não por arquivo

`xui_skin_default.txt` declara a skin `default` e **não põe nada dentro dela**:

```
    xuiSkin default
    {
        /* contents of the default skin are split into separate files in 'defaultskin' folder */
    }
```

(`:12-15`.) Os 59 arquivos de `defaultskin/` e os 183 de `entities/**` **reabrem o mesmo bloco**
`module Base { xuiSkin default { ... } }` e acrescentam o que têm. `xs_ISButton.txt:3`,
`x_colors.txt:3` e `entities/animals/workstations/entity_butcher_hook_xuiSkin.txt:3` são todos a
mesma linha.

**Essa é a única extensibilidade real do sistema, e é o que um mod usa.** Não existe campo de
"registrar skin"; existe reabrir o bloco.

O que **não** dá para provar aqui é o que acontece quando dois arquivos declaram a *mesma* chave —
último a carregar vence, primeiro vence, ou erro. O jogo não tem esse conflito no `media/`; vai para
"Pontos a confirmar". A ordem de carga entre jogo e mod está em
[carregamento-de-mods.md](carregamento-de-mods.md).

## Herança entre skins: `imports`

Uma skin nova herda outra por um bloco `imports` com o **nome da outra skin** — não de um módulo
(`PZ/media/scripts/xui/xui_skin_electric_common.txt:3-13`, arquivo inteiro menos o `module`):

```
    xuiSkin electric_common
    {
        imports
        {
            default,
        }

        ISButton S_Button_Craft
        {
            title               = "Start",
        }
    }
```

`fluid_separator` faz o mesmo e vai além: redeclara o bloco `colors` inteiro em verde
(`xui_skin_fluid_separator.txt:10-28`), o que mostra que a herança é sobrescrevível campo a campo.

**Aviso importante: as três skins alternativas são código morto no `media/` de hoje.** Nenhuma é
referenciada por arquivo nenhum — `grep -rn "electric_common|fluid_separator|furnace_processor"` em
`media/` devolve só as três linhas de declaração. As **215** ocorrências do campo que escolhe skin
(`xuiSkin = ...`, em `component UiConfig`) são **todas** `xuiSkin = default`. Elas existem como
demonstração do mecanismo, não como conteúdo em uso.

## Do `.txt` até a tela

### Passo 1 — a entidade aponta para a skin e para o estilo

`PZ/media/scripts/generated/entities/agricultural/workstations/entity_cooking_pit.txt:5-10`:

```
        component UiConfig
        {
            xuiSkin = default,
            entityStyle = ES_Cooking_Pit,
            uiEnabled = false,
        }
```

`xuiSkin` = qual skin. `entityStyle` = qual bloco `entity ES_*` dentro dela. O bloco `entity` em si é
assunto de [construcao.md](construcao.md).

### Passo 2 — o Lua resolve a skin pelo nome

O objeto global `XuiManager` é Java e é o registro das skins carregadas. Aparece **8 vezes em 5
arquivos** de `media/lua` e em nenhum mod; o par que importa está em
`PZ/media/lua/client/Entity/ISUI/ISEntityBuildMenu.lua:66-75`:

```lua
            local skinName = uiConfig:getXuiSkinName();
            local entityStyle = uiConfig:getEntityStyle();

            local skin = XuiManager.GetSkin(skinName);
            if not skin then
                skin = XuiManager.GetDefaultSkin();
            end

            if skin then
                local style = skin:getEntityUiStyle(entityStyle);
```

Nome desconhecido → cai para a skin default, sem erro. Os outros métodos vistos: `GetDefaultSkin()`
(`ISXuiSkin.lua:57`, `ISEntityUI.lua:565`), `GetLayout()` (`ISXuiBuilder.lua:369`),
`GetCombinedScripts()`, `GetStyleScript()`, `GetLayoutScript()` (`XuiDebugWindow.lua:680,765,767`).
Todos são **uso observado em Lua, não contrato declarado** — a assinatura está no `.jar`.

Pela entidade, o caminho equivalente é `PZ/media/lua/client/Entity/ISEntityUI.lua:162-180`, com
`GetEntityUiConfig` (`:162`), `GetEntityUiStyle` (`:168`) e `GetEntityUiSkin` (`:175`, que chama
`config:getSkinOrDefault()`), e o drill-down até o componente em `:195-197`
(`entityStyle:getComponentUiStyle(_componentType)`).

### Passo 3 — `ISXuiSkin.build` constrói o elemento

Entrada única do sistema: `PZ/media/lua/client/ISUI/ISXuiSkin.lua:41`.

```lua
function ISXuiSkin.build(_skin, _styleName, _luaClass, ...)
```

O que ela faz, em ordem:

| Linha | O quê |
|---|---|
| `:42-45` | aborta se `_luaClass.Type` não for string — a classe **tem** que vir de `derive()` |
| `:57` | `local skin = _skin or XuiManager.GetDefaultSkin()` — sem skin explícita, cai na default |
| `:62` | com `_styleName`: `skin:get(_luaClass.Type, _styleName)` — busca o bloco **nomeado** |
| `:64` | sem `_styleName`: `skin:getDefault(_luaClass.Type)` — busca o bloco **sem ID** |
| `:70-77` | não achou → `bApplyXui = false` e segue em frente (ver "O que falha em silêncio") |
| `:85-86` | se a classe tem entrada em `ISXuiSkin.constructors`, usa o construtor especial |
| `:87-91` | senão, `_luaClass:new(...)` com **no máximo 12 parâmetros** — o 13º só imprime aviso |
| `:98` | `ISXuiSkin.autoApplyTableKeys(...)` — a cópia dos campos |
| `:101-103` | carimba `luaObject.xuiSkin`, `.xuiStyleScript`, `.xuiStyleName` |
| `:106` | injeta `xuiRecalculateLayout` e `xuiRootElement` (`:16`, `:26`), sem sobrescrever implementação própria (`:112-118`) |

`ISXuiSkin.constructors` (`:39`) é uma tabela de **19 construtores especiais**, `:124-291` — as
classes cujo `:new()` explode com parâmetro `nil` ou que precisam de cálculo pós-construção
(`ISLabel` mede o texto, `ISScrollingListBox` recalcula `itemheight`, `ISItemSlot` puxa a cor do
canal do recurso). Classe fora dessa lista usa o caminho genérico.

### Passo 4 — a cópia campo a campo

`PZ/media/lua/client/ISUI/ISXuiBuilder.lua:492-541`. Para cada variável do script:

- `var:getLuaTableKey()` (`:497`) dá o **nome do campo Lua** — é o que faz `backgroundColor` no
  `.txt` virar `o.backgroundColor` no objeto. Variável sem chave Lua é ignorada.
- `var:getAutoApplyMode()` (`:500-514`) decide *se* copia: `Forbidden` e `No` nunca; `IfSet` só se o
  script setou; `IfSetAndKeyExists` exige também que o campo já exista no objeto.
- `var:getType()` (`:517-537`) decide *como*: `Color` vira tabela `{r,g,b,a}` (`:543-550`), `Texture`
  vira `var:getTexture()`, `StringList` vira array Lua, `Function` **não está implementado**
  (`:531-532`, imprime aviso), `Vector` é tratado só em `applySizing`, e o resto vai direto por
  `var:value()`.

O destino final é o `prerender` da classe. `ISPanel` lê `self.backgroundColor` e `self.borderColor`
diretamente (`PZ/media/lua/client/ISUI/ISPanel.lua:20-21`, dentro do `if self.background then` de
`:19`), com os defaults de `:105-106` — que o XUI sobrescreveu antes de o primeiro frame acontecer.
O nome no `.txt` é **literalmente o nome do campo Lua daquela classe**, e o par
`background`/`displayBackground` prova que não há tradução nem sinônimo: `xs_ISPanel.txt:7` escreve
`background` porque `ISPanel.lua:104` tem `o.background`; `xs_ISButton.txt:18` escreve
`displayBackground` porque `ISButton.lua:503` tem `o.displayBackground`. São dois interruptores de
fundo diferentes, e `xui_config.txt` declara os dois como nomes separados (`:121` e `:128`).
**Consequência para modding: para descobrir o que é estilizável numa classe, leia o `:new()` dela, e
não a lista de campos que o `.txt` do jogo por acaso preenche.**

### O segundo construtor: `ISXuiBuilder` (hierarquia)

`ISXuiSkin.build` monta **um** elemento. `ISXuiBuilder.build` (`ISXuiBuilder.lua:416`) e
`buildSingle` (`:432`) montam uma **árvore inteira** a partir de um script de layout, recursivamente
(`:362-380`), com `initialise()` + `instantiate()` chamados pelo próprio builder (`:406-407`) e uma
tabela privada `__xui` em cada elemento guardando `script`, `key`, `parent` e `children`
(`:450-462`).

Esse subsistema é **inerte no conteúdo que o jogo entrega**: não existe nenhum script de layout em
`PZ/media/scripts` (busca por `xuiLayout` e por bloco `layout` devolve zero), e os únicos
consumidores de `ISXuiBuilder` fora dele mesmo são `ISXuiTableLayout.lua` e o debug window. Os
layouts vêm de `XuiManager.GetLayout()` (`:369`), que é Java.

O comentário `:568-579` é a documentação da própria IndieStone sobre o ponto de extensão, e o
`ISXuiBuilder.constructors.ISMyUIClassExample` (`:581-592`) é um **exemplo escrito para modder** —
com a ressalva registrada em `:577-579` de que parâmetros de construtor (callbacks, `clicktarget`) só
chegam quando se constrói um elemento único, não uma hierarquia.

## O que falha em silêncio

O modo de falha de XUI é o pior possível: **o elemento aparece, só que sem a skin.** Nada some, nada
estoura, e fora do modo debug nada é logado.

1. **Estilo não encontrado.** `ISXuiSkin.lua:70-77`: `bApplyXui = false`, o objeto é criado com os
   defaults do `:new()` da classe, e o aviso passa por um `print` local (`:3-8`) que só escreve
   **se `getDebug()`**, e ainda deduplica por nome de estilo (`WARNED_STYLES`, `:1`, `:72-75`).
   Sem `-debug`, silêncio absoluto. Modo debug: [testar-e-debugar.md](testar-e-debugar.md).

2. **O jogo depende desse silêncio.** Das **204** chamadas a `ISXuiSkin.build` em 56 arquivos,
   **128 passam o estilo `"S_NeedsAStyle"`** — que **não existe em `media/scripts`**. É um
   placeholder que sempre erra de propósito. Compare com `"S_TableLayout_Main"` (7 chamadas), que
   resolve em `PZ/media/scripts/xui/defaultskin/xs_ISTableLayout.txt:22`. Consequência prática: **ver
   o elemento na tela não prova que a sua skin foi aplicada.**

3. **Classe sem `Type`.** `ISXuiSkin.lua:42-45` devolve `nil` — a variável fica vazia e o erro
   aparece longe, na primeira linha que usa o elemento. Uma classe criada com
   `ISPanel:derive("MinhaJanela")` tem `Type`; uma tabela Lua crua não.

4. **Ícone inexistente em `entity ES_*`.** Este avisa, e no `console.txt` normal —
   `WARN : General at XuiSkin$EntityUiStyle.Load > Could not find icon: <Icon>, script = <DisplayName>`
   (`USER/console.txt:116-123`). Contrato e formato do nome de ícone:
   [arte-e-modelos.md](arte-e-modelos.md).

## Modding — o que dá para fazer

### O censo

Os **89 mods** de `STEAM/` e os **12** de `WS/`:

| Evidência | Resultado |
|---|---|
| Mods com pasta `scripts/xui/` em `STEAM/` | **0** |
| Mods que declaram `xuiSkin` em `STEAM/` | **1** — `Lifestyle` (`3403870858`), 7 arquivos |
| Arquivos `xs_*.txt`, `x_colors.txt` ou `xui_*.txt` em `STEAM/` | **0** |
| Mods que declaram `xuiConfig` | **0** |
| Skin com nome próprio (≠ `default`) declarada por mod | **0** |
| Chamadas a `ISXuiSkin.*` / `ISXuiBuilder.*` em Lua de mod (`STEAM/` + `WS/`) | **0** |

O que o `Lifestyle` faz é exatamente o mesmo padrão do jogo, 12 linhas por entidade
(`STEAM/3403870858/mods/Lifestyle/common/media/scripts/entities/entity_ls_easel_xuiSkin.txt:1-12`):

```
module Base
{
    xuiSkin default
    {
        entity ES_LS_Easel
        {
            LuaWindowClass = ISEntityTabWindow,
            DisplayName = Build_LS_Easel,
            Icon = LS_Build_Easel,
        }
    }
}
```

Nossos próprios mods já fazem isso, nas **duas** colocações possíveis — e ambas são legítimas, porque
o caminho não importa:

- `media/scripts/xui/defaultskin/x_entity_new_bench.txt` (num mod de teste) — espelhando a árvore
  do jogo, com sub-bloco `components` incluído.
- `WS/SiddigoTutorial/Contents/mods/SiddigoTutorial/common/media/scripts/entities/fermenter/entity_siddigo_fermenter_xuiSkin.txt:3`
  — ao lado da entidade.

### O veredito

| Quero… | Dá? | Como / por quê |
|---|---|---|
| **Acrescentar `entity ES_*` à skin `default`** | **Sim, provado** | reabrir `module Base { xuiSkin default { ... } }` em qualquer `.txt` do mod. É o que 1 mod publicado e 2 dos nossos já fazem |
| **Acrescentar estilo nomeado** (`ISButton S_MeuBotao`) à `default` | **Sim, pela mesma forma** — não observado em mod nenhum | mesma reabertura; falta só o Lua chamar `ISXuiSkin.build(nil, "S_MeuBotao", ISButton, ...)`, e nenhum mod faz isso hoje |
| **Sobrescrever um estilo do jogo** (mudar `ISButton` inteiro) | **Sintaticamente sim; resultado imprevisível** | a forma é a mesma reabertura, mas quem vence num conflito de chave não está provado. Ver "Pontos a confirmar" |
| **Declarar skin própria** (`xuiSkin minha_skin` + `imports { default, }`) | **Mecanismo existe e é alcançável em runtime; ninguém usou** | o jogo declara 3 skins assim e **não usa nenhuma**; `XuiManager.GetSkin(nome)` (`ISEntityBuildMenu.lua:69`) resolve por nome; bastaria `xuiSkin = minha_skin` no `component UiConfig`. Nenhum dos 101 mods testou |
| **Declarar `xuiConfig` próprio** (nome de propriedade novo) | **Não provado, e improvável** | 1 bloco no jogo inteiro, 0 em mod. Sem isso, nome de propriedade fora dos 229 de `xui_config.txt` não tem tipo |
| **Estilizar UI *sua* com XUI** (janela de mod que não é entidade) | **Não observado** | o caminho existe (`ISXuiSkin.build` com sua classe `derive`ada), mas 0 mods chamam. Para UI de mod, o caminho batido continua sendo `ISUI` puro — [ui-lua.md](ui-lua.md) |

Resumo em uma frase: **modding de XUI existe e é seguro na camada de entidade** (`entity ES_*` na
skin `default`), e **é território inexplorado em tudo o mais** — a evidência da comunidade acaba
exatamente onde acaba o bloco `entity`.

## Como inspecionar in-game

O jogo traz um inspetor de XUI no menu de debug:
`PZ/media/lua/client/DebugUIs/DebugMenu/ISDebugMenu.lua:27` registra o botão
`IGUI_DebugMenu_Main_XUI` chamando `XuiDebugWindow.OnOpenPanel()`
(`PZ/media/lua/client/DebugUIs/DebugMenu/Xui/XuiDebugWindow.lua`, mais
`XuiDebugLayoutWindow.lua`). Ele lista os scripts carregados via `XuiManager.GetCombinedScripts()`
(`:680`) — é a única forma de ver se a sua declaração entrou. Como abrir o menu de debug:
[testar-e-debugar.md](testar-e-debugar.md).

## Pontos a confirmar

- **Quem vence quando dois arquivos declaram a mesma chave na mesma skin.** O merge de 243 arquivos
  em `xuiSkin default` está provado pela forma, mas o jogo não tem conflito para observar. Isso é o
  que decide se um mod consegue *sobrescrever* estilo do jogo ou só *acrescentar*. Teste in-game,
  não grep. O PZ-API-Docs marca `xuiSkin` como *"Soft Override: Unknown"*
  (`pz-wiki-modding.github.io/PZ-API-Docs/scripts/xuiskin.html`) — ou seja, a fonte externa também
  não sabe.
- **Divergência com o PZ-API-Docs sobre o ID de `xuiSkin`.** A fonte lista *"Forbidden values:
  `default`"* para o ID do bloco (`scripts/xuiskin.html`, versão 42.20.2). O `media/` usa
  `xuiSkin default` **251 vezes**. Pela regra 4 da árvore o código ganha; provavelmente é o gerador
  rotulando "sem valor default" como "valor proibido", mas a leitura da fonte não foi resolvida.
- **`xuiConfig` não existe no PZ-API-Docs.** `scripts/xuiconfig.html` dá **404** (verificado
  2026-08-08), e o índice `scripts.html` só lista `xuiSkin`. Não há como cruzar o contrato do bloco
  com fonte externa nenhuma.
- **Se o grupo do `xuiConfig` é mesmo o que define `XuiVarType` no Java.** Os nomes batem 1:1
  (`Color`, `Texture`, `StringList` de `xui_config.txt` × `ISXuiBuilder.lua:517-534`), mas
  `Function` e `Vector` aparecem só do lado Lua, e não há grupo correspondente no `.txt`. A ligação é
  inferência, não leitura.
- **Se um mod pode declarar `xuiConfig` próprio** — pendência herdada de
  [scripts-txt.md](scripts-txt.md), sem novidade nesta rodada: 0 ocorrências em 101 mods.
- **O campo `XuiStyle`**, comentado como opcional em `x_entity.txt:14,27,36` e usado em nenhum lugar
  do `media/`. É o que amarraria um estilo nomeado a uma entidade ou a um painel de componente — o
  atalho mais provável para skin custom, e não há um único exemplo dele preenchido.
- **Se `imports` dentro de `xuiSkin` é o mesmo bloco de `imports` dentro de `module`.** O
  PZ-API-Docs lista os dois pais no mesmo verbete (`scripts/imports.html`) e descreve só a semântica
  de módulo ("usar `ThatModItem` em vez de `ThisMod.ThatModItem`"), enquanto no `media/` o valor
  importado é nome de **skin** (`xui_skin_electric_common.txt:5-8`). São semânticas diferentes com a
  mesma palavra; qual delas o parser aplica em cada contexto é Java.
- **A assinatura de `XuiManager`, `XuiSkin`, `XuiScript` e `XuiVar`.** São Java. Tudo nesta página
  sobre eles é **uso observado em `media/lua`**, não contrato declarado — as chamadas citadas
  provam que o método existe e o que recebe naquele ponto, não a assinatura completa. Os JavaDocs
  não-oficiais de [../fontes-externas.md](../fontes-externas.md) são a via para cruzar.
- **O subsistema de layout de `ISXuiBuilder`** (`GetLayout`, `XuiScriptType.Reference`,
  `getXuiLayoutName`) não tem **nenhuma** declaração em `PZ/media/scripts`. Se os layouts vivem no
  `.jar`, se são gerados em runtime, ou se é feature incompleta, não foi possível determinar daqui.
- **`ISXuiSkin.constructors` aceita entrada de mod?** A tabela é global e Lua (`ISXuiSkin.lua:39`),
  então adicionar `ISXuiSkin.constructors.MinhaClasse = function(...)` é sintaticamente trivial — mas
  depende da ordem de carga do `.lua` do mod contra o do jogo, que não foi verificada para este
  arquivo. Ver [carregamento-de-mods.md](carregamento-de-mods.md).
- **`ISPanelJoypad`, `ISComboBox` e as demais 50 classes de `defaultskin/`** têm bloco declarado, mas
  esta página não abriu o contrato de campo de cada uma. O que cada campo faz está na classe Lua
  correspondente; o `.txt` só diz que ele é estilizável.

> Última verificação: 2026-08-08 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

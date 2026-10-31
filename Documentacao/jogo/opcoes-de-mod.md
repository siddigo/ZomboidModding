# Opções de mod — `PZAPI.ModOptions`

O jeito suportado de dar uma tela de configuração ao seu mod no B42: a aba **MODS** dentro das
opções do jogo. Cobre os 11 controles, a janela em que o registro precisa acontecer, o formato do
arquivo de persistência e os pontos que falham em silêncio.

Alias de caminho: `PZ/` = instalação do jogo, `USER/` = `C:\Users\<user>\Zomboid\`
(ver [../index.md](../index.md)).

## Onde fica

| O quê | Caminho |
|---|---|
| A API | `PZ/media/lua/client/PZAPI/ModOptions.lua` (334 linhas, arquivo inteiro) |
| O renderizador | `PZ/media/lua/client/OptionScreens/MainOptions.lua:2795-3049` (`addModOptionsPanel`) |
| O gate da aba | `MainOptions.lua:409-411` |
| A persistência | `USER/Lua/ModOptions.ini` |
| O nome da aba | `getText("UI_mainscreen_mods")` = `"MODS"` (`PZ/media/lua/shared/Translate/EN/UI.json:8`), usado em `MainOptions.lua:2798` |

`MainOptions.lua` é o **único** consumidor da API no jogo: fora dele e do próprio `ModOptions.lua`,
nenhum `.lua` de `PZ/media/` menciona `ModOptions`.

## O contrato mínimo

Exemplo real, de um mod da Workshop instalado
(`STEAM/2685168362/mods/MoreDescriptionForTraits4166/42.0/media/lua/client/MDFT_ModOptions.lua:9-35`):

```lua
local function ModOptions()
    local id = "MoreDescriptionForTraits"
    local options = PZAPI.ModOptions:create(id, getText("UI_moredesc_options_MoreDescriptionForTraits"))

    MDFT.OPTIONS.ShowMoreDescription = options:addTickBox(
        "ShowMoreDescription",
        getText("UI_moredesc_options_ShowMoreDescription"),
        true,
        getText("UI_moredesc_options_Tooltip_ShowMoreDescription")
    )
end

ModOptions()
```

Três coisas a notar, todas deliberadas:

1. O arquivo mora em `media/lua/client/` — a API é cliente, não existe em `server/`.
2. A chamada é **no topo do arquivo**, sem evento. Os 5 mods do `steamapps` que usam a API fazem
   assim; ver a próxima seção para o porquê.
3. `addX` **devolve** o option. Guardar o retorno é o jeito de ler o valor depois; a alternativa é
   `PZAPI.ModOptions:getOptions(modId):getOption(optId)` (`ModOptions.lua:255, 24`).

## A janela de registro — o que faz a aba sumir

Esta é a falha silenciosa nº 1 da área, e não aparece no `console.txt`.

A cadeia (`MainScreen.lua:177` → `MainOptions:new` → o corpo de criação):

```lua
-- MainOptions.lua:409-411
if #PZAPI.ModOptions.Data ~= 0 then
    self:addModOptionsPanel()
end
```

`MainScreen.lua:177` monta a `MainOptions` dentro da criação da `MainScreen`. Se `Data` estiver vazio
naquele instante, a aba MODS não é criada naquela instância — e registrar opções depois não a traz de
volta, porque nada reavalia a condição.

**Mas a `MainScreen` não é única.** Ela nasce em `LoadMainScreenPanelInt(ingame)`
(`MainScreen.lua:1788-1790`), que faz `MainScreen:new(ingame)` a cada chamada, e há **dois pontos de
entrada**: `LoadMainScreenPanelIngame()` (`:1784-1786`, com `ingame = true`) e a chamada com `false`
para o menu principal. **Nenhum dos dois tem chamador em `media/lua`** — quem invoca é o Java.

Duas consequências para quem escreve mod:

- Existem pelo menos **duas** `MainOptions` numa sessão que entra numa partida — a do menu e a de
  dentro do jogo —, cada uma com sua própria decisão sobre a aba MODS. As duas avaliam
  `#PZAPI.ModOptions.Data` em momentos diferentes do boot, então **a aba pode faltar no menu e
  existir em jogo**, ou o contrário.
- O `PZAPI.ModOptions:load()` de dentro de `addModOptionsPanel` roda **uma vez por instância que
  criar a aba**. Ou seja, o `.ini` pode ser lido mais de uma vez por sessão, e o valor em memória é
  substituído pelo do arquivo em cada uma.

A ordem exata em que o Java dispara os dois, e se voltar do jogo para o menu cria uma terceira,
continua não decidível aqui.

Pior, e menos óbvio: `PZAPI.ModOptions:load()` é chamado **dentro** de `addModOptionsPanel`
(`MainOptions.lua:2796`) e em nenhum outro ponto do `media/`. Sem aba, o `ModOptions.ini` nunca é
lido — `getValue()` devolve o default para sempre, sem erro nenhum.

E o terceiro efeito, que destrói dado de terceiro: `MainOptions:apply()` chama
`PZAPI.ModOptions:save()` **incondicionalmente** (`MainOptions.lua:3766`), e `save()` abre o arquivo
com truncamento (`getFileWriter("ModOptions.ini", true, false)` — 3º argumento `false` = não
apendar, `ModOptions.lua:260`). As linhas de mods não carregados só sobrevivem porque `load()` as
guardou em `OtherOptions` (`ModOptions.lua:330`) para reescrever no fim (`286-288`). Registro tardio
+ Apply = `OtherOptions` vazio = **config de todos os outros mods apagada**.

Conclusão prática: registre no topo de um `.lua` em `media/lua/client/`, sem envolver evento.

## Os 11 controles

Censo fechado no arquivo — 11 métodos `addX`, 11 valores de `type` declarados, 11 tratados no
renderizador. Reproduzível:

```sh
grep -n "^function Options:" PZ/media/lua/client/PZAPI/ModOptions.lua
grep -o 'option.type == "[a-z]*"' PZ/media/lua/client/OptionScreens/MainOptions.lua | sort -u
```

| Método (`ModOptions.lua`) | `type` | `getOption()` acha? | Vai pro `.ini`? | `getValue()` devolve |
|---|---|---|---|---|
| `addTitle(name)` :28 | `title` | não | não | — |
| `addDescription(text)` :32 | `description` | não | não | — |
| `addSeparator()` :36 | `separator` | não | não | — |
| `addTextEntry(id,name,value,tooltip)` :40 | `textentry` | sim | sim | string |
| `addTickBox(id,name,value,tooltip)` :64 | `tickbox` | sim | sim | boolean |
| `addMultipleTickBox(id,name,tooltip)` :88 | `multipletickbox` | sim | sim | `getValue(i)` → boolean do índice |
| `addComboBox(id,name,tooltip)` :121 | `combobox` | sim | sim | **índice** selecionado, não o texto |
| `addColorPicker(id,name,r,g,b,a,tooltip)` :158 | `colorpicker` | sim | sim | tabela `{r,g,b,a}` |
| `addKeyBind(id,name,key,tooltip)` :182 | `keybind` | sim | sim | keycode (número) |
| `addSlider(id,name,min,max,step,value,tooltip)` :206 | `slider` | sim | sim | número |
| `addButton(id,name,tooltip,onclick,target,arg1..arg4)` :230 | `button` | sim | **não** | — (sem `getValue`) |

Regras por trás da tabela:

- **`title`/`description`/`separator` não têm `id`** e nunca entram no `dict` (`:29, :33, :37`) —
  são decoração, inalcançáveis por `getOption`.
- **Persistência exige `getValue`**: o laço de `save()` pula qualquer option sem ele
  (`ModOptions.lua:263`). É por isso que `button` fica de fora mesmo estando no `dict` (`:243`).
- **`combobox:getValue()` devolve o índice** (`:137`), não o rótulo. Ler o texto exige
  `option.values[option:getValue()]`.
- Itens do combo entram por `option:addItem(nome, isSelected)` (`:131`), depois do `addComboBox` —
  ver o exemplo de `More Traits`
  (`STEAM/1299328280/mods/More Traits/42.17/media/lua/client/PZAPIModOptions.lua:9-15`).

## Callbacks — os três, e quando cada um roda

| Callback | Onde | Quando roda |
|---|---|---|
| `options:apply()` | stub vazio em `ModOptions.lua:21-22` | uma vez por grupo, no Apply (`MainOptions.lua:3761-3763`) |
| `option.onChange` | por option | a cada edição no controle (`MainOptions.lua:2836, 2880, 2909, 2933, 2968, 3042`) |
| `option.onChangeApply` | por option | no Apply, e **só se o valor mudou** (`MainOptions.lua:2831, 2874, 2904, 2928, 2963, 3037`) |

`Options:apply()` nasce vazio de propósito: é o gancho para o mod sobrescrever.

**A armadilha do `onChangeApply`: é um snapshot, não uma herança.** Cada `addX` copia o campo do
grupo para o option no momento da criação — `option.onChangeApply = self.onChangeApply`
(`ModOptions.lua:56-57`, e idem em todos os outros `addX`). Definir `options.onChangeApply` *depois*
de chamar os `addX` não afeta nada do que já foi adicionado. Ou defina antes de tudo, ou atribua
direto no option devolvido.

`button` não usa nenhum dos três: recebe `onclick` no próprio `addButton` (`:230`) e o
renderizador o liga sem criar `GameOption` (`MainOptions.lua:2974-2986`). A assinatura é
`onclick(target, button, arg1, arg2, arg3, arg4)` (`ISButton.lua:47`).

Detalhe que só se acha lendo: **`ISButton:setOnClick` do vanilla perde o `arg4`** — grava
`{ arg1, arg2, arg3, arg3 }` (`ISButton.lua:463`, `arg3` duplicado). `addModOptionsPanel` contorna
reatribuindo `button.onClickArgs = option.args` logo depois (`MainOptions.lua:2980`, com comentário
no código). Ou seja: os 4 argumentos funcionam **aqui**, e não funcionam num `ISButton` cru.

## O arquivo `USER/Lua/ModOptions.ini`

Uma linha por option persistido, terminador `\r\n` (`ModOptions.lua:264, 282`):

```
<type>|<modOptionsID>|<id>|<valor>
```

| `type` | Formato do valor | Onde |
|---|---|---|
| `textentry`, `tickbox`, `slider` | `tostring(value)` | `:265-266` |
| `multipletickbox` | booleanos separados por espaço, **com espaço final** | `:267-271` |
| `combobox` | índice selecionado | `:272-273` |
| `colorpicker` | `r g b a` separados por espaço | `:274-275` |
| `keybind` | keycode | `:276-280` |

O `load()` faz `luautils.split(line, "|")` (`:304`). Consequências diretas:

- **`|` em `modOptionsID`, em `id` ou num valor de `textentry` corrompe a linha.** Não há escape.
- **Valor inválido é ignorado em silêncio** e o default permanece: cada ramo do `load()` valida
  antes de atribuir (`:306-328`) — `tonumber(...) ~= nil` para slider e combobox, tabela
  `stringtoboolean` para tickbox, `#t2 == 4` para colorpicker.
- **Não há clamp em `min`/`max`** no slider (`:310-311`): o `.ini` é texto e aceita o que vier.
- **Desativar um mod não perde a config dele.** Linha cujo `modOptionsID`/`id` não está carregado vai
  para `OtherOptions` (`:329-331`) e é reescrita no fim do `save()` (`:286-288`).

O arquivo só é escrito no Apply/Accept (`MainOptions.lua:3699-3702` → `:3746` → `:3766`). Sair pelo
"Back" não grava.

## Tradução — quem chama `getText` e quando

Não é uniforme, e a assimetria importa.

| O quê | `getText` roda… | Citação |
|---|---|---|
| Nome do grupo (`create`) | no **render** | `MainOptions.lua:2806` |
| `addTitle` | no **render** | `MainOptions.lua:2809` |
| `name` e `tooltip` dos controles | no **render** | `MainOptions.lua:2815, 2817, 2887, 2890, 2916, 2940, 2946, 2975, 2982, 2990, 3002, 3025` |
| `addDescription` | no **registro** | `ModOptions.lua:33` (render usa o texto cru, `MainOptions.lua:2813`) |
| `addComboBox` → `addItem` | no **registro** | `ModOptions.lua:132` (render usa cru, `MainOptions.lua:2916`) |

Como o renderizador aplica `getText` em nome e tooltip, **basta passar a chave de tradução** — não
é preciso traduzir antes. Os mods do `steamapps` passam a string já traduzida
(`MDFT_ModOptions.lua:15`), o que funciona, mas resolve a tradução cedo demais e sem necessidade.
Para `description` e para os itens de combo é o contrário: ali o `getText` já rodou no registro, e o
render não repete.

## Keybind é caso à parte

`addKeyBind` sai do padrão dos outros dez em quatro pontos, todos verificáveis:

1. **`option.element` é sobrescrito.** O renderizador atribui o `ISButton` (`MainOptions.lua:3006`) e
   logo em seguida troca por `keyTextElement` (`:3021`), que é uma tabela Lua crua criada em `:2988`.
2. **Consequência: `option:setEnabled(bool)` quebra depois que a tela é montada.** O método chama
   `self.element:setEnable(bool)` (`ModOptions.lua:187`) e `keyTextElement` não tem `setEnable`.
   Antes da tela existir, `element` é `nil` e a chamada é inócua — o erro só aparece depois de abrir
   as opções uma vez.
3. **`shift` e `ctrl` nunca são preenchidos.** `addKeyBind` não os define (`ModOptions.lua:183`), e o
   renderizador os lê mesmo assim (`MainOptions.lua:3016-3017`) → sempre `nil`. `writeKey` absorve
   com `shift or false` (`:3742`).
4. **Destino duplo.** Além da linha no `ModOptions.ini`, o bind entra em `MainOptions.keyText`
   (`:3020`), e `MainOptions.saveKeys()` grava **todos** os `keyText` sem filtrar `isModBind`
   (`:3706-3715`) — vai também para `USER/Lua/keysB42.ini` e é registrado no motor com
   `getCore():addKeyBinding(<rótulo exibido>, ...)` (`:3742`). O caminho de *reload* faz o filtro
   oposto (`if not v.isModBind`, `:420`). A assimetria é do jogo, não erro de leitura.

Um detalhe do diálogo: o botão "Default" identifica o bind pelo **rótulo exibido**
(`v.txt:getName() == getText(self.keybindName)`, `ISSetKeybindDialog.lua:62`) — dois binds de mod com
o mesmo nome colidem ali.

## O que mudou do B41 para o B42

**`PZAPI.ModOptions` não existia no B41.** A solução da época era depender de um mod de terceiro
chamado `modoptions`. A prova está no próprio install:

```
STEAM/2619072426/mods/TheStar/mod.info
  require=modoptions
  versionMin=41.60
```

No B42 a API vem no jogo (`PZ/media/lua/client/PZAPI/ModOptions.lua`) e **não se declara `require=`
para ela** — nenhum dos 5 mods B42 que a usam declara.

Censo dos 89 itens de Workshop instalados nesta máquina, para calibrar o quanto cada mecanismo é
usado:

```sh
cd STEAM/
grep -rl "PZAPI\.ModOptions" . | sed 's|^\./||; s|/.*||' | sort -u | wc -l   # 5
find . -name "sandbox-options.txt" | sed 's|^\./||; s|/.*||' | sort -u | wc -l # 26
grep -ril "require=.*modoptions" --include="mod.info" .                        # 1 (TheStar, B41)
```

## Não confunda com sandbox options

São dois mecanismos diferentes, e o mais usado não é este.

| | `PZAPI.ModOptions` | Sandbox options |
|---|---|---|
| Escopo | cliente, por jogador | por save / servidor |
| Onde grava | `USER/Lua/ModOptions.ini` | config do save |
| Declaração | Lua, em `media/lua/client/` | `media/sandbox-options.txt` no mod |
| Leitura no mod | `option:getValue()` | `SandboxVars.<Page>.<Option>` |
| Referência no jogo | `PZ/media/lua/client/PZAPI/` | `PZ/media/lua/shared/Sandbox/SandboxVars.lua` |

Exemplo de sandbox de mod:
`STEAM/1299328280/mods/More Traits/42.17/media/sandbox-options.txt`.
Sandbox options **não têm página nesta árvore** — ver [../index.md](../index.md).

## Pontos a confirmar

- **Nenhuma fonte da comunidade cobre `PZAPI.ModOptions`** (verificado 2026-08-07). O PZ-API-Docs só
  tem as seções `scripts`, `mapping`, `translations`, `java` e `xml` — não há seção Lua
  (`pz-wiki-modding.github.io/PZ-API-Docs/`). O LuaDocs
  (`demiurgequantified.github.io/ProjectZomboidLuaDocs/`) responde com uma landing "heavily WIP" sem
  índice navegável, e a busca por `ModOptions` dá 404. `pzwiki.net/wiki/Mod_options` devolve **403**.
  Consequência: para esta área **o código é a única fonte**, e não há contraprova externa de default,
  min/max ou valores permitidos — nada nesta página vem de fora do `media/`. Ver
  [../fontes-externas.md](../fontes-externas.md).
- Se `MainOptions.loadKeys()` reconsome, na sessão seguinte, as linhas de bind de mod que
  `saveKeys()` deixou no `keysB42.ini` — e qual das duas gravações vence.
- Se `getCore():getKey("<rótulo exibido>")` devolve um bind registrado por `addKeyBind`. O uso
  observado no jogo é só com nomes vanilla (ex.: `FishingUtils.lua:40`).
- Troca de idioma com o jogo aberto: `description` e itens de `combobox` foram resolvidos por
  `getText` no registro. Não foi testado se a tela é remontada.
- **Em que ordem o Java dispara os dois `LoadMainScreenPanelInt`** (menu e in-game) em relação à
  carga dos mods, e se voltar do jogo para o menu cria uma terceira `MainScreen`. Que existem dois
  pontos de entrada está confirmado (seção acima); o momento de cada um é do motor.
- Slider carregado do `.ini` fora de `min`/`max`: o `load()` não faz clamp (`ModOptions.lua:310-311`).
  O efeito no controle não foi testado in-game.
- **Escrita de `.json` por mod** [novo 42.20.1]. As notas anunciam "ability for mods to write .json
  files". Não há rastro no `media/lua`: os 16 usos de `getFileWriter` seguem inalterados e nenhuma
  função de serialização JSON aparece. É API Java — qual é a chamada, e se ela substitui o
  `.ini` de linha `|` descrito acima como forma recomendada de persistir opção, não é decidível
  aqui.

> Última verificação: 2026-08-07 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

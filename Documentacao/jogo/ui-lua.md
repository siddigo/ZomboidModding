# UI em Lua — `ISUI`, o ciclo de vida e a ponte para o Java

Como um mod desenha janela, painel e botão. Cobre a hierarquia de classes de
`PZ/media/lua/client/ISUI/` (265 `.lua`, a maior pasta do `client/`), o ciclo de vida que o motor
chama, e a armadilha de copiar do lugar errado.

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\` (ver
[../index.md](../index.md)). **Somente leitura.**

O esquema de OO em Lua do PZ (`ISBaseObject:derive`) está descrito de passagem em
[mapa-media.md](mapa-media.md); aqui ele é o assunto.

**A estilização dessas classes não está aqui.** O XUI — que decide cor, fonte e borda de um
`ISUIElement` a partir dos `.txt` de `media/scripts/xui/` — tem página própria em
[xui.md](xui.md), incluindo a cadeia que leva do `.txt` até o elemento na tela e o comentário
`-- The following is required to make Xui work:` de `ISUIElement:new` (`:1970-1975`).

## Antes de tudo: **não copie de `media/luaexamples/`**

`PZ/media/luaexamples/ui/` (11 arquivos) parece a fonte oficial de exemplo de UI — é da IndieStone e
está na raiz de `media/`. **É código morto de uma API que não existe mais.** Ele usa
`LuaUI.createWindow` / `LuaUI.createButton` (`PZ/media/luaexamples/ui/ui.lua:57-61`), e:

- `LuaUI` tem **zero ocorrências em todo o `media/lua`** — 13 no `luaexamples/` e mais nenhuma.
- No próprio arquivo, as três chamadas estão **comentadas** (`ui.lua:57-59`), dentro de uma
  `CreateTest()` que ninguém chama.
- `luaexamples` tem **zero referências** vindas de `media/lua`.

O que ainda serve de lá é `PZ/media/luaexamples/ISTimer.lua`, que é `ISBaseObject:derive("ISTimer")`
normal (`:3`) e usa o idioma corrente. A pasta `ui/` não.

A referência viva é `PZ/media/lua/client/ISUI/`.

## A hierarquia

Quatro classes concentram tudo. O censo de `:derive(` dentro de `ISUI/*.lua`:

| Classe base | Deriva | Quando usar |
|---|---|---|
| `ISPanel` | 41 | painel comum — o default |
| `ISPanelJoypad` | 31 | painel que precisa funcionar no controle |
| `ISUIElement` | 13 | elemento cru, sem fundo/borda |
| `ISCollapsableWindow` | 11 | **janela** com barra de título, fechar e redimensionar |
| `ISBaseObject` | 12 | não é UI — lógica auxiliar |

A raiz de todos é `ISUIElement` (`PZ/media/lua/client/ISUI/ISUIElement.lua`, 226 métodos). Depois:

```
ISBaseObject                     (lua/shared/ISBaseObject.lua)
└── ISUIElement                  1.965 linhas, 226 métodos — posição, âncora, filhos, mouse
    └── ISPanel                  + fundo e borda        (ISPanel.lua:3)
        ├── ISPanelJoypad        + navegação por controle
        └── ISCollapsableWindow  + título, botão fechar, resize  (ISCollapsableWindow.lua:9)
```

`ISPanel` acrescenta pouquíssimo sobre `ISUIElement`: o `prerender` que desenha o retângulo de fundo
e a borda (`ISPanel.lua:18-23`) e o arraste com o mouse. Se o seu elemento não tem fundo, herdar de
`ISUIElement` evita o desenho.

Na raiz de `ISUI/` há 122 `.lua` e 16 subpastas (`AdminPanel/`, `Crafting/`, `Maps/`, `PlayerStats/`,
`Layout/`, `Style/`, …) — as subpastas são telas do jogo, não widgets reutilizáveis.

## O exemplo canônico mínimo

`PZ/media/lua/client/Farming/ISUI/ISFarmingWindow.lua` tem **31 linhas** e é a janela completa mais
curta do jogo. Copie a forma daqui:

```lua
require "ISUI/ISCollapsableWindow"

ISFarmingWindow = ISCollapsableWindow:derive("ISFarmingWindow");

function ISFarmingWindow:initialise()
	ISCollapsableWindow.initialise(self);
end

function ISFarmingWindow:createChildren()
	ISCollapsableWindow.createChildren(self);
	local th = self:titleBarHeight()
	self.farmingPanel = ISFarmingInfo:new(0, th, self.width, self.height-th, self.character, self.plant);
	self.farmingPanel:initialise();
	self:addChild(self.farmingPanel);
end

function ISFarmingWindow:new (x, y, width, height, character, plant)
	local width = ISFarmingInfo.RequiredWidth()
	local o = ISCollapsableWindow.new(self, x, y, width, height);
	o:setResizable(false)
	o.title = getText("Farming_Plant_Information");
	o.character = character
	o.plant = plant;
	return o
end
```

Quatro contratos estão nessas linhas, e todos falham calado quando quebrados:

1. **`require` com caminho sem extensão, relativo às raízes de `lua/`** — `"ISUI/ISCollapsableWindow"`,
   não `"client/ISUI/..."` nem `.lua`.
2. **`:new` chama `Pai.new(self, ...)` com ponto e passando `self`**, não `Pai:new(...)`. É o que
   costura a metatable — `ISUIElement:new` faz `setmetatable(o, self); self.__index = self`
   (`ISUIElement.lua:1966-1968`). Trocar por `:` quebra a herança.
3. **`initialise` e `createChildren` chamam a versão do pai com ponto** (`ISCollapsableWindow.initialise(self)`).
   Esquecer isso numa janela deixa a barra de título sem botões, porque é o
   `ISCollapsableWindow:createChildren` que os cria.
4. **Texto de UI passa por `getText(...)`**, nunca literal — é o que liga na tradução. Ver
   [carregamento-de-mods.md](carregamento-de-mods.md).

## O ciclo de vida

Os métodos que o motor chama, e a ordem:

| Método | Quando | Papel |
|---|---|---|
| `:new(x, y, w, h, …)` | você chama | cria a tabela Lua. **Não** desenha nada |
| `:initialise()` | você chama | inicialização; encadeia no pai |
| `:instantiate()` | automático | **cria o objeto Java** (`ISUIElement.lua:993-994`) |
| `:createChildren()` | após instanciar | monta os filhos com `:addChild()` |
| `:update()` | todo tick | lógica; `ISUIElement.lua:1610` é vazio |
| `:prerender()` | todo frame, antes | fundo/borda; `:1614` |
| `:render()` | todo frame, depois | conteúdo; `:1618` |

`update`, `prerender` e `render` são **vazios na base** — existem para você sobrescrever.

### A ponte para o Java

`ISUIElement:instantiate()` (`:993`) é onde a tabela Lua ganha um par no motor:

```lua
function ISUIElement:instantiate()
	self.javaObject = UIElement.new(self);
	self.javaObject:setX(self.x);
	…
	self.javaObject:setWantKeyEvents(self.wantKeyEvents or false);
	self.javaObject:setConsumeMouseEvents(self.wantMouseEvents or false);
```

Duas consequências práticas:

- **`self.javaObject` é `nil` antes de a janela entrar no gerenciador.** Qualquer coisa que dependa
  dele em `:new` estoura.
- **Evento de mouse e teclado é opt-in.** `wantKeyEvents` e `wantMouseEvents` têm de estar setados
  **antes** do `instantiate`, porque é ele que os empurra para o Java. Setar depois não tem efeito —
  é uma das falhas silenciosas mais comuns em UI de mod.

### Mostrar e esconder

```lua
function ISUIElement:addToUIManager()
	if self.javaObject == nil then
		self:instantiate();
	end
	UIManager.AddUI(self.javaObject);
end
```

(`ISUIElement.lua:1365-1371`.) É o `addToUIManager` que dispara o `instantiate` na primeira vez — daí
a ordem "criar → `initialise` → `addToUIManager` → só então existe Java". O par é
`removeFromUIManager()` (`:1373`), que sai cedo se `javaObject` for `nil`.

`:setVisible(bool)` (`:657`) esconde sem remover. O jogo usa os dois: `ISFarmingWindow:visible()`
chama `setVisible` num singleton `ISFarmingWindow.instance` — o padrão de janela única que boa parte
do `ISUI/` segue.

### Âncora e layout

`ISUIElement:new` já define `anchorLeft = true` e `anchorTop = true`, com `anchorRight`/`anchorBottom`
em `false` (`:1983-1986`). Os setters são `setAnchorsTBLR(t, b, l, r)` (`:157`) e `setAnchors(bool)`
(`:175`); `setBounds`, `setCenterX/Y`, `setWidthAndParentWidth` e `getAbsoluteBounds` cobrem o resto.
`doLayout()` (`:22`) é o gancho de relayout.

## Lado do mod

- O `.lua` de UI vai em **`media/lua/client/`** — UI não existe no servidor. Ver
  [mapa-media.md](mapa-media.md) para a diferença entre as três raízes.
- O ponto de entrada normal é um evento de [eventos-lua.md](eventos-lua.md); a janela em si não se
  registra sozinha.
- Nome de classe global colide entre mods — `ISFarmingWindow` é global de verdade. Prefixe com o
  nome do mod, pela mesma razão de namespace descrita em
  [scripts-txt.md](scripts-txt.md).
- Textura de UI do jogo está em `media/ui/` (1.538 arquivos); ícone de item segue o caminho de
  [arte-e-modelos.md](arte-e-modelos.md).

## Pontos a confirmar

- **A ordem exata entre `instantiate()`, `createChildren()` e o primeiro `prerender()`.** A cadeia
  `addToUIManager → instantiate` está no Lua (`:1365`), mas quem chama `createChildren` é o Java —
  não há chamada dele em `ISUIElement.lua`. A ordem acima é inferida do uso, não lida no motor.
- **Se `setWantKeyEvents`/`setConsumeMouseEvents` podem ser trocados depois do `instantiate`.** O
  `javaObject` expõe os setters, mas nenhum arquivo do jogo os chama fora do `instantiate` — a
  afirmação de que "setar depois não tem efeito" vale como consequência do que se lê, não como
  comportamento observado.
- **Assinatura das classes Java `UIElement` e `UIManager`.** São motor; o uso aqui é observado em
  `media/lua`, não contrato declarado. Os JavaDocs não-oficiais de
  [../fontes-externas.md](../fontes-externas.md) são a via para cruzar.
- **`ISPanelJoypad` vs `ISPanel`** — o que exatamente a variante de controle acrescenta (31 derivações
  no jogo) não foi aberto nesta rodada.
- **`ISUIElement.lua` tem 226 métodos**; esta página cobre o ciclo de vida e o posicionamento. Os
  demais (drag-and-drop, scroll, tooltip, `ISDock`, `contentHorizontalAlignment`, `style`) não foram
  levantados.
- **Se `getISUIStackTrace(9)` em `:new` (`:1980`) tem custo relevante** por elemento criado — o
  número mágico `9` sugere profundidade fixa de pilha, e isso importa em UI que cria muitos filhos
  por frame.
- **Nenhuma fonte da comunidade foi cruzada** para esta área nesta rodada. O PZ-API-Docs é gerado
  sobre `scripts/`, e UI é Lua — a cobertura esperada é baixa, mas não foi verificada.

> Última verificação: 2026-08-07 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

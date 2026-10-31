# Camadas — a matriz que decide o que escrever

Conteúdo do PZ não mora num arquivo só. Cada tipo é uma **pilha**, e o modo clássico de falhar é
escrever a camada 1 e parar: o jogo carrega, o `console.txt` fica limpo, e nada aparece.

## As cinco camadas

| # | Camada | O que é | Formato |
|---|---|---|---|
| L1 | **Definição** | o bloco que declara a coisa | `.txt` (`module { bloco { } }`) |
| L2 | **Arte** | ícone, textura, modelo 3D, sprite de mundo | `.png`, `.fbx`, tileset |
| L3 | **Mundo** | como aparece: loot e/ou coleta | **`.lua`** |
| L4 | **Tradução** | o nome que o jogador lê | `.json` |
| L5 | **Uso** | o que amarra ao resto: receita, tag, perícia | `.txt` |

## A matriz

| Tipo | L1 Definição | L2 Arte | L3 Mundo | L4 Tradução | L5 Uso |
|---|---|---|---|---|---|
| **item** | `item` em `media/scripts/` | ícone `Item_<Icon>.png` **obrigatório**; `model` + `.fbx` se tiver modelo | loot e/ou coleta — **nenhum é padrão** | `ItemName.json`, chave `Modulo.Item` | receita que produz/consome, `Tags` |
| **receita** | `craftRecipe` | — | — | `Recipes.json`, chave = nome puro | `timedAction`, `category`, entity que a hospeda |
| **traço** | `character_trait_definition` | — | — | `UI.json`, `UI_trait_<nome>` + `...desc` | `XPBoosts`, `GrantedRecipes`, `MutuallyExclusiveTraits` |
| **profissão** | `character_profession_definition` | ícone `IconPathName` | — | `UI.json`, `UI_prof_<nome>` | `XPBoosts`, `GrantedTraits`, `GrantedRecipes` |
| **objeto** | pilha própria, ver abaixo | tileset + sprite | `forceForTiles` no loot | `Entity.json` / `Moveables.json` | receita de construção |

## Objeto é uma pilha dentro da pilha

As três formas de "objeto" **não são alternativas** — são camadas da mesma coisa, e um objeto
completo tem as três:

1. **Sempre** — o tile: `.tiles.txt` (definição legível) + `.tiles` (binário do TileZed) + sprite no
   `.pack`. É o que faz o objeto existir no mundo.
2. **Se o jogador pega e larga** — item `ItemType = base:moveable`.
3. **Se o jogador usa** — `entity` com `component`, o sistema de estações do B42.

Uma bancada de verdade tem 1 + 2 + 3. Um armário decorativo tem só 1. Ver `objeto.md` — inclusive o
limite: o `.pack` é compilado por ferramenta externa que este workspace não tem mapeada.

## L3 é a camada mais esquecida — e é Lua

Não existe bloco `.txt` de distribuição de loot. Um item novo **não aparece em lugar nenhum** até
alguém escrever Lua. São dois sistemas independentes:

- **Loot** (containers do mundo) — `ProceduralDistributions` + `Distributions`
- **Coleta** (forrageamento) — `forageDefinitions`

Um item pode ter os dois, um, ou nenhum (se só for craftável). Ver `mundo.md`.

## Checklist antes de relatar

Para cada linha da matriz que o tipo pedido ocupa:

- [ ] L1 — o bloco está dentro do `module` certo (o do mod, não `Base`)?
- [ ] L2 — o arquivo de arte existe no caminho exato? Se não, está listado como pendência?
- [ ] L3 — o usuário escolheu loot/coleta/nenhum, **explicitamente**? Se ninguém decidiu, pergunte.
- [ ] L4 — a chave está no arquivo `.json` certo daquele tipo, não em qualquer um?
- [ ] L5 — se é item craftável, a receita existe? Se é traço com `GrantedRecipes`, as receitas existem?

Camada fora por decisão do usuário é escolha e vai no relatório. Camada esquecida é bug silencioso.

> Levantado em 2026-08-04 — PZ buildid 24449119. Contratos conferidos em `PZ/media/` e em mods reais
> de `WS/` e `steamapps/workshop/content/108600`.

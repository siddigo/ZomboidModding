# Mundo — como o conteúdo aparece no jogo (L3)

**Contrato completo em duas páginas da doc:**

- **Loot** — `Documentacao/jogo/distribuicao-loot.md`: as duas tabelas e suas formas diferentes, os
  três eventos de ponto de entrada, e os helpers que o jogo já dá.
- **Coleta** — `Documentacao/jogo/coleta-foraging.md`: o `forageDefinitions.lua` campo a campo, onde
  ficam as 23 categorias, e as armadilhas (`zones` não é porcentagem, `canBeAboveFloor` não faz nada,
  `months` × `validMonths`).

Leia a que se aplica antes de escrever. Esta página é só o enquadramento da decisão e o delta
lado-mod.

## Por que esta camada é a mais esquecida

**Não existe bloco `.txt` de distribuição.** Um item novo, com bloco perfeito e ícone no lugar, **não
aparece em lugar nenhum** até alguém escrever Lua.

É o modo silencioso de falhar mais comum: o mod carrega, o `console.txt` fica limpo, o item existe no
código — e o jogador nunca o encontra.

## São dois sistemas independentes

Loot e coleta não se comunicam. Um item pode estar nos dois, num, ou em nenhum.

## Perguntar, não presumir

Nenhuma das duas é padrão. Antes de escrever, o usuário decide entre três:

| Escolha | O que implica |
|---|---|
| **loot** | aparece em containers. Precisa saber **em quais** — que lista procedural, ou que sala/container |
| **coleta** | colhível no mato. Precisa de zonas, perícia exigida e categoria |
| **nenhuma** | só existe via craft. **Legítimo e comum** — não force uma camada que o mod não quer |

Se o usuário não disse, pergunte. Não escolha por ele: item que aparece em loot sem que o autor
quisesse é balanceamento quebrado, e some difícil.

## Onde o Lua do mod vai

`Contents/mods/<Mod>/42/media/lua/server/<Mod>_Distribuicao.lua` — **`server/`**, porque distribuição
e forrageamento são lógica autoritativa (ver `Documentacao/jogo/mapa-media.md`).

Vai na pasta de versão, não em `common/` — Lua é código de build, não asset.

**Nunca edite as tabelas do jogo.** O mod acrescenta às tabelas globais a partir de um evento; qual
evento e qual forma exata está em `distribuicao-loot.md`.

## Categoria de coleta: prefira reusar

Encaixar numa das 23 categorias existentes é uma linha. Categoria nova exige registro em
`forageCategories.lua` e chave de tradução própria — mais superfície para falhar em silêncio. Só crie
categoria se o usuário pedir explicitamente.

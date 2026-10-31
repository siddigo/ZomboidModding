---
name: criar-conteudo
description: Cria conteúdo novo dentro de um mod de Project Zomboid que já existe — item, receita (craftRecipe), traço, profissão ou objeto/entity — escrevendo todas as camadas que aquele conteúdo exige (bloco .txt, arte, spawn e coleta em Lua, tradução), não só o bloco principal. Usar quando o usuário pedir para criar/adicionar item, arma, comida, roupa, receita, traço, trait, profissão, bancada, estação, móvel ou objeto num mod. Não cria mod do zero (isso é `iniciar-mod`) e não cria animal (pilha própria).
---

Crie o conteúdo pedido em `$ARGUMENTS`.

## O que esta skill existe para evitar

Escrever o bloco `.txt` e parar por aí. O parser da IndieStone **falha em silêncio**: o jogo carrega,
o `console.txt` não acusa nada, e o conteúdo simplesmente não existe no jogo. Na prática isso quase
nunca é o bloco estar errado — é **faltar uma camada**.

Todo conteúdo do PZ é uma pilha de camadas em arquivos e formatos diferentes. Um item que só tem
bloco `.txt` existe no código e não aparece no mundo, não tem nome legível e não é craftável.

**Leia `references/camadas.md` antes de escrever qualquer coisa.** É a tabela que diz quais camadas
o tipo pedido exige, e é o que faz esta skill valer mais do que digitar o bloco à mão.

## Passo 1 — achar o mod e o layout dele

O conteúdo vai **dentro de um mod que já existe**, em `~\Zomboid\Workshop\<Mod>\`. Se o
mod não existe, pare e diga para rodar `/iniciar-mod <Nome>` primeiro — criar esqueleto não é escopo
daqui.

Os mods do workspace estão em três layouts diferentes (ver `.claude/CLAUDE.md`). **Olhe antes de
escrever, não presuma.** Rode um `find` na pasta do mod e confirme:

| Layout | Onde o `.txt` entra | Onde a arte entra |
|---|---|---|
| B42 com pasta de versão | `Contents/mods/<Mod>/42/media/scripts/` | `Contents/mods/<Mod>/common/media/` |
| Pré-B42, sem pasta de versão | `Contents/mods/<Mod>/media/scripts/` | mesma `media/` |
| Sem `Contents/` | `media/scripts/` na raiz | mesma `media/` |

A regra do B42 é a divisão que importa: **o que muda entre builds fica na pasta de versão
(`media/scripts`, `media/lua`), o que não muda fica em `common/media` (`textures`, `models_X`,
`tiles`).** Referência real e funcional dessa divisão — `WS/SiddigoWeapons/`:

```
42/media/scripts/SiddigoWeapons_Items.txt        <- bloco item
42/media/scripts/SiddigoWeapons_Models.txt       <- bloco model
42/media/scripts/recipes/recipes_SiddigoWeapons.txt
42/media/lua/shared/translate/...                <- (formato B41, ver references/traducao.md)
common/media/textures/Item_SkullCrusher.png      <- ícone
common/media/textures/WorldItems/SkullCrusher.png
common/media/models_X/WorldItems/SkullCrusher.fbx
```

Descubra também o **módulo** que o mod usa (a primeira linha dos `.txt` existentes). Conteúdo novo
vai no mesmo módulo do mod, não em `Base` — ver `references/armadilhas.md`.

## Passo 2 — ler a referência do tipo

Uma por tipo pedido. Não escreva de memória: os campos e a caixa das letras são sensíveis.

**As referências abaixo não repetem o contrato — elas apontam para `Documentacao/jogo/` e carregam só
o delta lado-mod.** Siga o ponteiro e leia a página da doc; é lá que está o bloco canônico com
`caminho:linha`. Ordem de consulta do workspace, ver `.claude/CLAUDE.md`: doc primeiro, `media/` do
jogo só quando a doc não responde.

| Pedido | Referência |
|---|---|
| item, arma, comida, roupa, container | `references/item.md` |
| receita, craft, craftRecipe | `references/receita.md` |
| traço, trait, profissão, ocupação | `references/personagem.md` |
| objeto, bancada, estação, móvel, mobília | `references/objeto.md` |

E as transversais, conforme a matriz de `camadas.md` mandar:

- `references/mundo.md` — spawn no loot e coleta (forrageamento). **Ambos são Lua**, não `.txt`.
- `references/traducao.md` — chave e arquivo por tipo.
- `references/armadilhas.md` — as divergências de caixa e forma que fazem o bloco sumir em silêncio.
  **Leia sempre**, é curta.

## Passo 3 — perguntar o que não dá para inferir

Esta skill **nunca inventa asset e nunca inventa número de balanceamento.**

Levante o que falta e pergunte de uma vez só, em uma mensagem, antes de escrever. O que normalmente
falta:

- **Arte** — onde está o PNG do ícone? já existe em `common/media/textures/` ou o usuário vai
  fornecer? Vai usar modelo 3D (`.fbx`) ou só ícone? Se for objeto de mundo, qual tileset?
- **Números** — dano, peso, tempo de craft, custo do traço. Se o usuário não deu, ofereça um valor
  ancorado num item real do jogo (`caminho:linha`) e diga que é para ajustar, em vez de inventar.
- **Presença no mundo** — o item deve aparecer no loot? ser colhível? só ser craftável? São camadas
  diferentes e nenhuma é padrão.

Se o usuário já respondeu tudo no prompt, não pergunte de novo — escreva.

**Arte que não existe é pendência, não bloqueio.** Escreva as camadas que dá para escrever, aponte o
`Icon`/`texture` para o nome combinado, e liste o arquivo faltante no relatório. Não gere placeholder
de imagem aqui e não copie arte de outro mod.

## Passo 4 — escrever camada por camada

Ordem: bloco principal → arte (o que já existir) → mundo (Lua) → tradução.

Regras de escrita:

- **UTF-8 sem BOM.** BOM na primeira linha quebra a primeira chave do arquivo.
- **Acrescentar, não substituir.** Se o `.txt` do tipo já existe no mod, adicione o bloco dentro do
  `module` existente. Não crie um segundo arquivo com outro `module` para o mesmo assunto.
- **Nunca escrever em `ProjectZomboid/`.** É leitura. Há `deny` cobrindo `**/steamapps/**`.
- Copie a formatação dos arquivos vizinhos do próprio mod (indentação, alinhamento), não a sua.

## Passo 5 — conferir a pilha antes de relatar

Volte na matriz de `camadas.md` e confira **camada por camada** o que o tipo exigia contra o que você
escreveu. Camada que ficou de fora por decisão do usuário (ex.: "não quero no loot") é escolha e vai
no relatório como escolha. Camada esquecida é bug silencioso.

Não conte com validação fora do jogo — `luac -p` (se instalado) checa só a sintaxe Lua, e o parser dos `.txt` só
roda no jogo. **A única verificação real é carregar o jogo e ler `~\Zomboid\console.txt`.**
Não afirme que funcionou.

## Passo 6 — relatar

- Arquivos criados e modificados, com caminho.
- A pilha: cada camada, escrita ou pendente, e o porquê da pendente.
- Assets que faltam, com o caminho exato onde o arquivo tem de ser colocado e com que nome.
- Como testar: ativar o mod, entrar no jogo, e o que olhar no `console.txt`.
- Se tocou em algo marcado "a confirmar" nas referências, diga qual e o que confirmar in-game.

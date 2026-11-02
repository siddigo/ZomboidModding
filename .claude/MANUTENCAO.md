# Manutenção do workspace

Por que o workspace é desenhado assim. **Não é carregado em toda sessão**, de propósito: o
`CLAUDE.md` carrega só as regras de trabalho, e este arquivo guarda o raciocínio por trás delas.
Leia antes de criar ou mexer em skill, agente, `settings.json`, na convenção de `Documentacao/` ou no
próprio `CLAUDE.md`.

## Este repositório

```
.gitignore
.claude/                     # TODA a config do Claude Code mora aqui
  CLAUDE.md                  # regras de trabalho, carregado em toda sessão
  MANUTENCAO.md              # este arquivo: o porquê do desenho (sob demanda)
  escrita-de-codigo.md       # regras de código completas, com exemplos (sob demanda)
  settings.json              # versionado: permissoes
  skills/<nome>/SKILL.md     # skills de modding
  agents/<nome>.md           # subagents
  memory/                    # memoria automatica (por usuario, ver abaixo)
Projetos/        # specs do planejador: uma subpasta por mod, um conjunto por pedido (por usuario)
Documentacao/    # referencia de modding: mapa do media/, formatos .txt, API Lua
  index.md       # convencao da arvore + carimbo de build
  jogo/          # referencia do ProjectZomboid (baseline: buildid da Steam)
  mods/          # opcional, por usuario: inventario e paginas dos proprios mods
  oficial/       # opcional, copia local de material da IndieStone (nao distribuido)
```

As entradas marcadas "por usuario"/"opcional" podem morar na pasta pessoal em vez daqui (ver
"Pasta pessoal" no topo).

O que existe:

- **Skills** — `planejador` (analisa e gera specs autocontidas, sem implementar), `doc-pz` (gera e
  reconfere a árvore `Documentacao/`), `squash-merge` (integra branch de melhoria num alvo via
  squash local), `iniciar-mod` (esqueleto de mod novo), `criar-conteudo` (conteúdo dentro de um mod
  que já existe) e `fechar-versao` (bump de `modversion`, tag anotada e GitHub Release para mod com
  repo próprio). `squash-merge` e `fechar-versao` têm `disable-model-invocation: true` — integrar
  branch e publicar release são ações que não voltam, então cada uma roda só pelo seu comando
  (`/squash-merge`, `/fechar-versao`).

  **`doc-pz` é auto-invocável de propósito.** A ordem de consulta manda o achado do passo 2/3 voltar
  para `Documentacao/`, e depender do usuário digitar `/doc-pz` fazia a descoberta morrer na
  conversa — o custo é perder o grep, não estragar arquivo, e a skill só escreve `.md` da árvore.
  Ela carrega o escopo reduzido para esse caso na seção "Quando você se invoca no meio de outro
  trabalho": grava o delta, não varre a página, não gera página nova de carona, não recarimba
  rodapé, e volta para a tarefa interrompida. Continua valendo chamar `/doc-pz` quando a doc **é** o
  trabalho da sessão.
- **Agentes** — `pz-explorer` (Haiku, read-only, Glob/Grep/Read): localiza arquivos, definições e
  sintaxe canônica no `media/` do jogo e nos mods, devolvendo `caminho:linha` + resumo. Existe para
  tirar grep pesado do modelo caro; é chamado pelo `planejador` e pelo `doc-pz`.
  `mod-scaffolder` (Haiku, Bash/Read): executor da `iniciar-mod`, ver abaixo.

**Modelo de `iniciar-mod`** — o único caso do workspace em que o trabalho é determinístico o
bastante para sair do modelo. Quem sabe o formato é `.claude/skills/iniciar-mod/novo-mod.ps1`; a
`SKILL.md` só extrai parâmetros do pedido e chama o script, e roda em `context: fork` +
`agent: mod-scaffolder` (Haiku), então o modelo da sessão principal não troca. Consequência
prática: **mudança de formato de mod vai no `.ps1`, não no prompt.** O script valida tags contra
`media/WorkshopTags.txt`, escreve sem BOM, gera poster/preview placeholder (para nenhum mod nascer
com arte de outro), usa `git config user.name` como autor padrão e **nunca sobrescreve** pasta
existente.

**Modelo de `criar-conteudo`** — o oposto do `iniciar-mod`: aqui o trabalho é decisão de design
(qual `ItemType`? que `Tags`? aparece no loot?), então **não** vira script e **não** sai do modelo da
sessão. A skill é `SKILL.md` (procedimento) + `references/` (contratos).

A ideia central é que conteúdo de PZ não é um bloco, é uma **pilha de camadas** — definição `.txt`,
arte, presença no mundo, tradução, uso — espalhada por arquivos e formatos diferentes. O modo clássico
de falhar é escrever a camada 1 e parar: o jogo carrega, o `console.txt` fica limpo e nada aparece. A
matriz tipo × camada está em `references/camadas.md` e é o que a skill existe para não deixar
esquecer. Cobre item, receita, traço, profissão e objeto; **animal ficou de fora** — é Lua, não bloco
`.txt`, e tem pilha própria, então pede skill separada. A pilha está mapeada em
`Documentacao/jogo/animais.md`, mas a skill ainda não é viável: não dá para provar pelo `media/` se
um mod consegue registrar animal. É teste in-game, não grep.

**Nenhuma `reference/` repete contrato: todas apontam para `Documentacao/jogo/` e carregam só o delta
lado-mod** — onde o arquivo entra na árvore do mod, qual módulo/namespace usar, o que muda quando é
mod e não o jogo, e o que perguntar ao usuário. É a regra de ordem de consulta aplicada à própria
skill. Quando uma `reference/` nasce com contrato completo, ela é encolhida para ponteiro assim que
a página dona em `Documentacao/jogo/` cobre o assunto — **esse é o ciclo esperado**, não exceção:
descoberta vai para a doc, a skill referencia.

Fora disso, só `references/armadilhas.md` é conteúdo próprio — o catálogo das falhas silenciosas
(`imports` plural, namespace do mod, caixa dos campos, BOM), com as divergências reais apontadas
nominalmente.

**Modelo de `Documentacao/`** (definido pela skill `doc-pz`, convenção em `Documentacao/index.md`):
árvore de referência do **jogo**, não do workspace — as páginas ficam em `jogo/`, mais
`fontes-externas.md` na raiz, que é meta (cataloga a doc pública da comunidade). Regras: toda
afirmação com `caminho:linha` real, o que não deu para confirmar vira "a confirmar", e **não se
copia dado do jogo** — a doc diz onde está e qual é o contrato, não repete o conteúdo.

## A divisão de responsabilidade — e o jeito de quebrá-la

**Este arquivo é convenção do workspace. Fato do jogo mora em `Documentacao/`, e só lá.** O teste,
antes de escrever qualquer frase aqui: *isso desatualiza quando a Steam faz patch?* Se sim, não é
do `CLAUDE.md` — é de uma página, que carimba `buildid` no rodapé justamente para se saber quando
reconferir. Aqui não há carimbo nenhum, então fato do jogo escrito aqui **envelhece sem deixar
rastro** e ninguém descobre até dar errado.

Na prática isso proíbe três coisas no `CLAUDE.md`: **número levantado do `media/`** (contagens,
censos), **caminho ou símbolo específico do jogo** citado como afirmação, e **resumo do que uma
página já cobre**. O que fica é o ponteiro: *qual* página responde e *por que* você iria lá.

Vale o inverso também: instrução de comportamento fica aqui mesmo que mencione o jogo. "O parser
falha em silêncio, então consulte a doc antes de inventar sintaxe" é regra de trabalho, não fato a
manter — não desatualiza com patch.

Os dois casos que mais tentam: **o inventário de páginas** (mora na tabela "Mapa" de
`Documentacao/index.md`, que a `doc-pz` atualiza a cada página nova pela regra 6 dela) e **o
`buildid` em vigor** (mora no rodapé de cada página e no `index.md`). **Leia o `index.md` antes de
concluir que uma área não está documentada** — é o passo 1 da ordem de consulta, e a tabela lá é
mais descritiva do que um resumo aqui conseguiria ser.

Quando uma correção de fato do jogo aparecer no meio de outro trabalho, ela vai para a página dona
pela skill `doc-pz`, que você invoca na hora sem esperar pedido — **corrigir aqui é corrigir no
arquivo errado**, e ainda cria a segunda cópia que vai divergir depois.

**Há um terceiro tipo que a divisão acima não prevê: a tarefa *sobre* uma página.** "A doc afirma X
e a evidência diz Y, reconferir" não é fato do jogo nem convenção do workspace — é trabalho
pendente contra um arquivo. Escrito aqui, ele apodrece pelo mesmo motivo que fato do jogo apodrece:
não tem carimbo, não tem dono, e ninguém percebe quando a página é consertada. Se carregar número de
linha, envelhece ainda mais rápido, porque qualquer edição na página o invalida.

**Pendência sobre uma página nasce na própria página**, na seção "Pontos a confirmar" — lá ela herda
o rodapé com `buildid` e morre junto com a correção.

**Página do jogo não carrega estado de mod próprio.** Mod nosso pode servir de evidência ("observado
in-game em tal data, mod de teste"), mas "o mod X ainda está com o formato velho" é pendência de mod
— vai para `Documentacao/mods/` ou para `Projetos/<Mod>/`, nunca para `jogo/`. Isso também é o que
mantém `jogo/` publicável.

**Doc da comunidade é pista, não prova.** O PZ-API-Docs
(`pz-wiki-modding.github.io/PZ-API-Docs/`, auto-gerado por parser sobre o jogo) publica o que ler o
`media/` não mostra — tipo, `required`, default, min/max e **valores permitidos** de cada parâmetro,
que é o contrato do parser e vive no Java. Junto com os JavaDocs/LuaDocs não-oficiais, é consultado
**depois** do levantamento no código, pela regra 4 do `doc-pz`: todo achado tem de virar
`caminho:linha` no `media/` para virar afirmação, o que não fechar vira "a confirmar" com a URL, e
em qualquer divergência **o código ganha**. Detalhe de cada fonte em `Documentacao/fontes-externas.md`.

**O baseline da doc não é commit git — é o `buildid` da Steam** (`steamapps/appmanifest_108600.acf`),
carimbado no rodapé de cada página. O código documentado é o jogo, que só muda quando a Steam
atualiza. Checar defasagem = comparar o `buildid` do manifesto com o do rodapé; igual significa que
nada mudou e não há o que reconferir. **O número em vigor não é copiado para cá** pelo mesmo motivo
da lista de páginas: ele já vive no rodapé de cada página e em `Documentacao/index.md`.

**Modelo de `Projetos/`** (definido pela skill `planejador`): `Projetos/<NomeDoMod>/` por mod e,
dentro dele, uma pasta por pedido de planejamento — `NN-nome-curto-do-conjunto/`, com `NN`
sequencial dentro daquele mod. Cada pasta contém um `SPEC-00-escopo.md` (obrigatório, mesmo com uma
única spec) e as specs individuais `SPEC-XX-nome-curto.md`. Specs vivem **neste workspace** (aqui ou
na pasta pessoal), nunca dentro do mod — o mod é o produto publicável e não carrega planejamento.


## Integração com Claude Code

**Tudo em `.claude/`, sem duplicação.** `.claude/skills/`, `.claude/agents/` e `.claude/memory/`
são os caminhos que o Claude Code varre — não existe pasta espelho na raiz nem junction. Uma skill
é `.claude/skills/<nome>/SKILL.md`.

**Escopo: o cwd da sessão, não o workspace do VSCode.** O Claude Code não conhece workspace
multi-root; ele monta o contexto subindo a árvore de diretórios a partir do cwd. As sessões começam
com cwd na raiz deste repositório, então o `CLAUDE.md` é carregado e vale para **tudo que a sessão
faz** — inclusive editar em `Workshop/` e ler em `ProjectZomboid/`, que entram como *additional
working directories*. Consequências:

- CLAUDE.md de *additional directories* **não** é carregado por padrão (só com
  `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`). Se algum mod ganhar um CLAUDE.md próprio, ele
  não entra automaticamente.
- Abrir uma sessão com cwd dentro de `Workshop/<Mod>` **não** carrega o `CLAUDE.md` — este
  repositório não é ancestral daquele caminho. Sempre abrir pela raiz daqui.
- Skills e settings deste repo seguem a mesma regra: só valem com o cwd aqui dentro.

**Memória automática.** O padrão seria `~/.claude/projects/<slug>/memory/`, chaveado pela raiz do
git. Para a memória acompanhar o repositório, redirecione para `.claude/memory/` (daqui ou da
pasta pessoal) via `autoMemoryDirectory` em `.claude/settings.local.json`. Detalhes que importam:

- `autoMemoryDirectory` é **ignorado em project settings** (`.claude/settings.json`, versionado) —
  é uma restrição de segurança do Claude Code. Tem que estar em `settings.local.json` (escopo local)
  ou no escopo usuário. Escopo usuário valeria para *todo* projeto da máquina.
- Consequência: **o ponteiro não é versionável, o conteúdo é.** Sem o `settings.local.json`, a
  memória volta a escrever no padrão `~/.claude/projects/<slug>/memory/`, em silêncio.
- O valor precisa ser caminho absoluto ou começar com `~/` — não aceita relativo.
- Memória é **por usuário**: não vem no repositório público. Como ela pode viajar entre máquinas,
  **não** escrever memórias que dependam de uma máquina específica (caminhos, drives, estado local).
- `.claude/memory/MEMORY.md` é o índice carregado a cada sessão (primeiras 200 linhas / 25KB); um
  arquivo por fato ao lado dele.

**Permissões** (`permissions` em `.claude/settings.json`, versionado).

Sintaxe de caminho, que é contraintuitiva: `//x` = absoluto da raiz do sistema; `~/x` = home;
`/x` = **relativo à origem do settings** (project settings → raiz do repo), *não* absoluto;
`x` = relativo ao cwd. No Windows os caminhos são normalizados pra POSIX antes do match, então
`C:\Users\fulano` vira `/c/Users/fulano` e `//**/steamapps/**` cobre qualquer drive.

- **Leitura**: livre em `steamapps` (jogo e mods da Steam) e `~/Zomboid` (Workshop, console.txt, Logs).
- **Escrita**: liberada neste repo (`Edit(/**)`, ancorado na raiz do projeto) e em
  `~/Zomboid/Workshop/**`.
- **Modo `auto`**, se usado, define-se em `~/.claude/settings.json` (escopo usuário). Um
  classificador revisa cada ação em vez de perguntar, e bloqueia por padrão "destruir
  irreversivelmente arquivos que existiam antes da sessão". **Não definir `defaultMode` em
  `.claude/settings.json`**: settings de projeto têm precedência e sobrescreveriam o `auto` (que,
  de propósito, é ignorado quando declarado em settings de projeto).
- **Nada de `Bash(rm *)`, `Bash(mkdir *)` e afins.** Uma regra `allow` **resolve na hora e pula o
  classificador** — pré-aprovar `rm` desligaria a proteção exatamente no comando mais perigoso, e
  ainda por cima sem escopo de pasta. Regras `Bash` aqui só para o rotineiro e inofensivo (git).
- **Bloqueado**: escrita em `**/steamapps/**` (jogo + mods da Steam) e em `~/Zomboid/Saves/**` e
  `options.ini` — estado do jogador não se mexe. `deny` vence `allow` **em todos os modos**,
  inclusive `auto` e `bypassPermissions`. É a garantia mais forte disponível aqui.
- **`additionalDirectories`** (a pasta do jogo, `~\Zomboid`) é caminho de máquina, então mora em
  `.claude/settings.local.json`, não no versionado. Diretórios listados aí dão acesso a arquivo e
  nada mais: nenhuma config (skills, CLAUDE.md) é carregada deles.

Limitações reais, que nenhuma regra resolve:

- **O sandbox não existe em Windows nativo** (só macOS/Linux/WSL2). Ele seria o único enforcement
  no nível do SO. Aqui tudo é checagem do Claude Code: alcança as tools `Edit`/`Write` e os
  comandos de arquivo que ele reconhece no Bash (`cat`, `sed`, `head`), mas não um script
  Python/Node que abra arquivo por conta própria.
- Regras de `Bash` casam por **prefixo de comando**, nunca por caminho. Os `deny` de
  `Bash(rm *steamapps*)` pegam o caso ingênuo e nada além — `cd` pra pasta antes, variável ou
  comando composto passam. Não confiar neles como garantia.
- Permissão é do Claude Code, não do modelo. Instrução em CLAUDE.md orienta; regra em
  `settings.json` é o que de fato bloqueia.
- `.claude/` é *protected path*: escrita ali sempre pergunta, em qualquer modo menos
  `bypassPermissions`. Prompt esperado, não é config errada.


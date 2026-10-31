---
name: squash-merge
model: sonnet
disable-model-invocation: true
description: Integra uma branch de melhoria (feat/*) de um mod numa branch alvo (main do mod, branch de build, ou outra melhoria maior) via squash-merge local, resolvendo conflitos com julgamento em vez de deixar o GitHub "atualizar a branch" (o que polui a melhoria com o histórico do alvo). Usar quando o desenvolvedor pedir para squash-mergear, integrar, ou "mesclar sem carregar histórico" uma branch num mod deste workspace.
---

Integra o conteúdo de uma **branch de melhoria** numa **branch alvo** com um único commit achatado (squash), rodando tudo localmente — sem nunca tocar/empurrar a branch de melhoria. Ela continua limpa, pronta para seguir depois para outra branch alvo.

## Contexto deste workspace

Cada mod em `~\Zomboid\Workshop\<Mod>` é um repositório git **independente** — esta skill sempre roda com `-C` na pasta do mod, ou com o cwd lá dentro. Nem todo mod tem `.git` próprio — confira se `<mod>\.git` existe antes de começar; sem ele, o mod não é candidato a esta skill. Não presuma o nome da branch principal (`main` ou `master`): confirme com `git -C <mod> branch`.

**Primeira pergunta a resolver:** em qual repositório estamos? Se o desenvolvedor não disse o mod, pergunte.

## Parâmetros

- **mod** — qual repositório em `Workshop/`.
- **branch de melhoria** (origem) — ex. `feat/receita-arco`.
- **branch alvo** (destino) — normalmente `main`; pode ser uma branch de build (ex. `b41`) ou outra branch de melhoria (quando uma melhoria maior "engole" uma menor).
- **a melhoria morre depois?** (booleano, default `false`) — o desenvolvedor informa explicitamente. Normalmente só `true` quando melhoria→`main`. Pode ser `true` também em melhoria→melhoria, quando a menor deixou de fazer sentido sozinha. **Nunca** por padrão quando a melhoria ainda precisa chegar a outra branch depois.

Se qualquer um dos quatro não vier claro do pedido do desenvolvedor, pergunte antes de iniciar.

## Passo 0 — Por que local, e nunca via GitHub "Update branch"/resolver conflito no PR

Abrir PR `melhoria → alvo` no GitHub e deixar a própria interface "atualizar a branch" ou "resolver conflitos" cria um merge commit **na branch de melhoria** (`Merge branch '<alvo>' into <melhoria>`), trazendo todo o histórico do alvo para dentro dela. Isso é esperado do GitHub (ele só pode preparar o PR para merge sem conflito atualizando o lado de origem primeiro), mas contamina a melhoria — se ela precisar seguir depois para outra branch, arrasta junto tudo que só devia estar no alvo.

Por isso esta skill nunca abre PR nem deixa o GitHub mexer na branch de melhoria: faz o squash **direto no checkout do alvo**, localmente.

## Passo 1 — Sanity check antes de mexer

```bash
git -C "<caminho-do-mod>" fetch origin <branch-melhoria> <branch-alvo>
```

- **Confira se a branch de melhoria já não está contaminada**: `git log origin/<branch-melhoria> --oneline --graph -5`. Se o topo for um merge commit (`*` com dois pais, mensagem `Merge branch '<alvo>' into <branch-melhoria>` ou similar), pare — isso é sinal de que alguém já mexeu no PR pelo GitHub e a melhoria carrega o alvo. Avise o desenvolvedor; isso precisa ser revertido primeiro (voltar a branch pro commit anterior ao merge, force-push) antes desta skill seguir — não faça esse revert sozinho sem confirmar, é uma reescrita de histórico remoto.
- **Confira se o checkout local do alvo está em dia com o origin**: `git log HEAD..origin/<branch-alvo> --oneline` a partir do checkout do alvo. Se estiver atrás, dê `git pull --ff-only` antes de seguir. Se tiver commits locais não empurrados que o origin não tem, pare e avise — não decida sozinho qual lado prevalece.
- **Confira se a árvore está limpa**: `git status --short`. Mod em desenvolvimento costuma ter arquivo solto (`.pack`, `poster.png` reexportado, teste). Sujeira não commitada entra no meio do squash e vira parte do commit sem ninguém perceber — resolva antes (commit ou stash), com o desenvolvedor.

## Passo 2 — Checkout do alvo e squash

```bash
git checkout <branch-alvo>
git merge --squash origin/<branch-melhoria>
```

Use sempre `origin/<branch-melhoria>`, não a branch local (pode estar desatualizada em relação ao que foi de fato empurrado).

## Passo 3 — Resolver conflitos, se houver

`git status --short` mostra `UU` nos arquivos em conflito — o squash roda o mesmo algoritmo de merge normal, com os mesmos marcadores `<<<<<<<`/`=======`/`>>>>>>>`.

**Gotcha confirmado na prática:** `git merge --squash` nunca grava `MERGE_HEAD` (não existe a intenção de criar um commit de merge). Isso quebra `git merge --abort` — ele falha com `"There is no merge to abort (MERGE_HEAD missing)"`. Para desistir no meio do conflito, use `git reset --hard HEAD` em vez disso.

Para cada arquivo em conflito, leia os dois lados e resolva com julgamento — não pegue um lado "por padrão":

- **Conflito aditivo** (os dois lados adicionaram blocos novos e independentes: itens diferentes no mesmo `<Mod>_Items.txt`, receitas diferentes no mesmo `recipes_*.txt`, chaves diferentes num arquivo de tradução) — combine os dois, não escolha um.
- **Arquivo de script `.txt`** — depois de combinar, confira a estrutura: chaves `{`/`}` balanceadas, cada campo terminando em vírgula, blocos ainda dentro do `module`. O parser da IndieStone não perdoa, e um `}` sobrando derruba o mod inteiro no carregamento, não só aquele item.
- **`mod.info` / `workshop.txt`** — nunca some os dois lados cegamente. `id`, `versionMin` e o `id` numérico da Workshop são identidade do mod publicado; `modversion` e `description` é que evoluem. Na dúvida, pergunte.
- **Binário** (`.png`, `.fbx`, `.pack`, `.tiles`) — git não mescla. Pergunte ao desenvolvedor qual versão vale; não escolha por data nem por lado.
- **Deriva de arquivo compartilhado não relacionada à feature** (docs, `.gitignore`, convenção que mudou em outra branch enquanto a melhoria estava aberta) — antes de decidir, confira qual versão é a atual/correta (ex.: compare com `origin/<branch-alvo>` ou com a convenção do `CLAUDE.md` carregado na sessão). Não presuma que o lado "HEAD" (alvo) é o certo só por ser o alvo — pode estar desatualizado.
- Depois de editar, `git add <arquivo>` por arquivo resolvido.

Relate ao desenvolvedor, no resumo final (Passo 7), qualquer resolução que exigiu julgamento (não só as aditivas óbvias) — especialmente binários e `mod.info`/`workshop.txt`.

## Passo 4 — Tirar do stage o que não pertence ao mod

O mod é o produto publicável: só entra o que vai para a Workshop. Antes de commitar, confira `git diff --cached --name-only` e remova do stage:

- specs/planejamento que vazaram do repositório `ZomboidModding` (`Projetos/`, `SPEC-*.md`)
- estado do jogador ou log copiado para dentro do mod (`console.txt`, `Logs/`, saves, `options.ini`)
- backups e testes (`*.bak`, `*.orig`, arquivos de rascunho)

```bash
git reset -- <caminho>
```

Apagar o arquivo do disco só se ele foi criado por este squash — arquivo de trabalho do desenvolvedor que já existia antes não se apaga; deixe fora do stage e avise.

## Passo 5 — Mensagem de commit

**Não use `.git/SQUASH_MSG` cru.** Se a branch de melhoria ficou muito tempo sem rebase, esse arquivo lista todo commit desde o merge-base mais distante (pode incluir dezenas de commits não relacionados já presentes no alvo por outro caminho) — é ruído, não representa o diff real.

Monte a mensagem você mesmo, olhando `git diff --cached --stat` (o que de fato mudou) e as mensagens dos commits realmente relevantes da branch de melhoria. Convenção deste workspace (Conventional Commits, corpo em português, imperativo):

```
feat(<escopo>): <resumo em uma linha>

- <bullet por mudança relevante>
- ...

Squash-merge de <branch-melhoria>, resolvido localmente.
```

Escopo útil aqui é a área do mod: `items`, `recipes`, `lua`, `translate`, `textures`, `modinfo`.

```bash
git commit -m "..."
```

## Passo 6 — Verificar antes de entregar

**Não existe compilador.** Project Zomboid só valida `.lua` e `.txt` ao carregar o jogo, e um `luac -p` (se houver toolchain Lua instalada) pega só erro de sintaxe Lua. Então a verificação é em duas camadas:

**6a. Checagem estática (você faz, sempre):**

```bash
# nenhum marcador de conflito sobrou
git grep -n -E '^(<<<<<<< |=======$|>>>>>>> )' -- .

# heurística de chaves balanceadas nos scripts tocados (contagem deve bater)
grep -o '{' <arquivo>.txt | wc -l ; grep -o '}' <arquivo>.txt | wc -l
```

Além disso: `mod.info` continua com `id`/`versionMin`; nenhum arquivo novo caiu fora da estrutura do mod (`Contents/mods/<NomeDoMod>/<versao>/media/...` para código e scripts, `.../common/media/...` para assets — a pasta de versão é `42` ou `42.0` conforme o mod, e `<NomeDoMod>` é o nome real em `Contents/mods/`); strings novas visíveis ao jogador têm entrada nos arquivos de tradução.

**6b. Teste in-game (o desenvolvedor faz):** peça para carregar o jogo com o mod ativo e conferir `~\Zomboid\console.txt`. Se aparecer stacktrace novo, pare — não corrija sozinho, reporte o trecho do console.

Não afirme "está funcionando" com base só em 6a. A checagem estática pega conflito e chave solta; ela não pega campo inválido, referência a item inexistente nem erro de Lua em runtime.

## Passo 7 — Parar e apresentar o resumo (NUNCA dar push sozinho)

Mostre ao desenvolvedor, em texto simples:

- Arquivos alterados (`git diff --cached --stat` antes do commit, ou `git show --stat` depois).
- Qualquer conflito resolvido com julgamento (Passo 3) e o porquê da escolha.
- O que foi tirado do stage no Passo 4.
- A mensagem de commit usada.
- O resultado da checagem estática (6a) e o pedido explícito do teste in-game (6b).

Espere a confirmação explícita do desenvolvedor antes de seguir para o push. Esta skill nunca empurra sozinha.

## Passo 8 — Push (só depois da confirmação)

```bash
git fetch origin <branch-alvo>
git rev-list --count HEAD..origin/<branch-alvo>
```

Se o resultado for maior que 0 (alguém empurrou nesse meio-tempo), pare — não faça merge/rebase automático, avise o desenvolvedor.

Se não divergiu:

```bash
git push origin <branch-alvo>
```

## Passo 9 — Se a melhoria deve morrer (só se o desenvolvedor marcou isso E o push do Passo 8 foi confirmado)

Mesmo com a flag marcada, apagar branch é destrutivo — mostre o que vai ser apagado e espere a confirmação antes de executar:

```bash
git worktree list                                   # cheque se ha worktree associada
git worktree remove --force <caminho-da-worktree>   # se houver, remova antes (a partir do repo principal)
git push origin --delete <branch-melhoria>
git branch -D <branch-melhoria>                     # se houver checkout/branch local
```

## Notas

- Esta skill não publica na Steam Workshop. Squash-merge é integração de código; upload é outro passo, ainda não automatizado neste workspace.
- `.gitignore` padrão por mod ainda é pendência do workspace — enquanto não existir, o Passo 4 é o que segura lixo fora do commit.

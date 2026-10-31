---
name: fechar-versao
model: sonnet
disable-model-invocation: true
description: Fecha uma versão de um mod que já tem repositório git próprio e remote no GitHub — bumpa `modversion` no `mod.info`, cria um commit e uma tag anotada, redige as notas de release a partir do `git log` desde a última tag, e publica a GitHub Release via `gh release create`. Usar quando o desenvolvedor pedir para fechar versão, taguear, criar release ou publicar release de um mod deste workspace. Roda só por `/fechar-versao` — cria tag e Release no GitHub, ação que não volta.
---

Fecha uma versão de um mod: bumpa `modversion`, cria tag git anotada, redige notas de release a
partir do histórico de commits, e publica tudo como GitHub Release via `gh`.

## Contexto deste workspace

Cada mod em `~\Zomboid\Workshop\<Mod>` é um repositório git **independente**. Só é
candidato a esta skill quem tem `.git` próprio **e** remote no GitHub (`git remote -v`); confira
os dois antes de começar, e o nome da branch principal com `git -C <mod> branch`.

Depende de `gh` (GitHub CLI) autenticado — ver Passo 0.

**Primeira pergunta a resolver:** qual mod, se o desenvolvedor não disse.

## Parâmetros

- **mod** — qual repositório em `Workshop/`.
- **nova versão** — normalmente sugerida por esta skill (Passo 2) a partir do `modversion` atual,
  mas sempre confirmada com o desenvolvedor antes de gravar.

## Passo 0 — Pré-requisito: `gh` autenticado

```bash
gh auth status
```

Se falhar (não logado), **pare** e peça para o desenvolvedor rodar `gh auth login` — é um fluxo de
navegador/OAuth, não tente automatizar login por conta própria.

## Passo 1 — Sanity check antes de mexer

```bash
git -C "<caminho-do-mod>" remote -v
git -C "<caminho-do-mod>" branch --show-current
git -C "<caminho-do-mod>" fetch origin
git -C "<caminho-do-mod>" status --short
git -C "<caminho-do-mod>" tag --sort=-v:refname
```

- **Sem remote no GitHub** → pare, não é candidato a esta skill (ver Contexto).
- **Árvore suja** (`status --short` não vazio) → pare e pergunte. Não misture trabalho solto no
  commit de bump de versão — o desenvolvedor commita/stasheia o que já está pronto primeiro, e roda
  esta skill de novo depois.
- **Branch local atrás do origin** (`git log HEAD..origin/<branch> --oneline` não vazio) → dê
  `git pull --ff-only` antes de seguir. Se tiver divergência real (commits só locais e só remotos),
  pare e avise — não decida sozinho qual lado prevalece.
- Anote a tag mais recente (se houver) — é o ponto de partida do changelog no Passo 4.

## Passo 2 — Determinar a nova versão

Localize o(s) `mod.info` do mod (`Contents/mods/<Nome>/<versao-do-jogo>/mod.info`). Nos três mods
atuais há só um `mod.info` por repo, mas **confira** — se houver mais de uma pasta de versão de
jogo, pergunte ao desenvolvedor se o bump vale para todas ou só uma.

Leia o `modversion=` atual e sugira o próximo valor (normalmente incrementar a última parte em 1 —
`1.1` → `1.2`). **É decisão de design, não decida sozinho**: apresente a sugestão e espere
confirmação — o desenvolvedor pode querer pular pra uma versão maior (mudança que quebra
compatibilidade) ou manter o esquema de casas decimais do mod (`1.00` vs `1.0`).

Não mexa em `versionMin`/`versionMax` nesta skill — isso é compatibilidade com build do jogo, uma
decisão separada de fechar uma versão do mod. Só toque se o desenvolvedor pedir explicitamente.

## Passo 3 — Bump e commit

Atualize `modversion=` no(s) `mod.info` confirmado(s) no Passo 2.

```bash
git -C "<caminho-do-mod>" add <mod.info...>
git -C "<caminho-do-mod>" commit -m "chore: bump modversion to <nova-versao>"
```

## Passo 4 — Redigir as notas de release

```bash
git -C "<caminho-do-mod>" log <ultima-tag>..HEAD --oneline
```

Sem tag anterior (primeira release), use o histórico inteiro (`git log --oneline`). Organize os
commits num changelog curto, agrupando por tipo quando as mensagens seguirem Conventional Commits
(`feat`/`fix`/`chore`/...) — ex. "Adicionado", "Corrigido", "Outros". Não invente mudança que não
está no log; se uma mensagem de commit for vaga demais para virar uma linha de changelog decente,
pergunte ao desenvolvedor em vez de adivinhar o que mudou.

## Passo 5 — Parar e apresentar (NUNCA taguear/publicar sozinho)

Mostre ao desenvolvedor:

- A nova versão confirmada e o commit de bump.
- O rascunho das notas de release (Passo 4).
- O nome da tag que vai ser criada (`v<nova-versao>`).

Espere confirmação explícita antes de seguir. Esta skill nunca cria tag remota nem publica Release
sem esse aval — são ações que não voltam (tag pública e Release ficam visíveis a qualquer um que
veja o repositório).

## Passo 6 — Tag anotada (local)

```bash
git -C "<caminho-do-mod>" tag -a v<nova-versao> -m "<primeira-linha-do-changelog>"
```

## Passo 7 — Push (commit + tag)

```bash
git -C "<caminho-do-mod>" push origin <branch>
git -C "<caminho-do-mod>" push origin v<nova-versao>
```

## Passo 8 — Publicar a GitHub Release

Grave as notas do Passo 4 num arquivo temporário e publique com `--verify-tag` (usa a tag já
empurrada no Passo 7 em vez de deixar o `gh` criar outra):

```bash
gh release create v<nova-versao> \
  --repo "<owner>/<repo>" \
  --title "v<nova-versao>" \
  --notes-file "<arquivo-de-notas>" \
  --verify-tag
```

Rode a partir do checkout do mod (ou passe `--repo` explícito, lido do `git remote -v` do Passo 1).
Se alguma flag não existir na versão instalada do `gh`, confira `gh release create --help` em vez
de adivinhar sintaxe.

## Passo 9 — Confirmar e reportar

```bash
gh release view v<nova-versao> --repo "<owner>/<repo>"
```

Devolva ao desenvolvedor o link da Release.

## Notas

- Mods sem `.git` próprio ou sem remote no GitHub não são candidatos — nem tag nem Release fazem
  sentido sem repositório publicado.
- Esta skill não publica na Steam Workshop. Fechar versão é marco no repositório; o upload pra
  Workshop é outro passo, ainda não automatizado neste workspace.
- `versionMin`/`versionMax` ficam fora do escopo por padrão — ver Passo 2.

---
name: iniciar-mod
description: Cria o esqueleto obrigatório de um mod novo de Project Zomboid no formato B42 (pasta de upload da Workshop, mod.info, workshop.txt, poster/preview, media/, .gitignore e git init) em ~\Zomboid\Workshop. Usar quando o usuário pedir para começar/criar/iniciar um mod novo, ou pedir o esqueleto/estrutura inicial de um mod. Não implementa conteúdo — só a estrutura.
context: fork
agent: mod-scaffolder
background: false
---

Crie o esqueleto do mod chamado **`$0`**.

Argumentos completos recebidos: `$ARGUMENTS`

## Passo 1 — extrair os parâmetros

Do texto acima, pegue apenas o que estiver explícito. Nada de inventar título, descrição ou tag.

| Parâmetro | De onde vem |
|---|---|
| `-Nome` | `$0` — obrigatório, vira pasta de upload e pasta em `Contents/mods/` |
| `-Titulo` | só se o usuário deu um nome de exibição (`name=`/`title=`) diferente |
| `-Descricao` | só se o usuário descreveu o mod em uma linha |
| `-Tags` | só se o usuário citou tags; passe separadas por vírgula, ex. `-Tags "Build 42,Items"` |
| `-Id`, `-VersionMin`, `-PastaVersao`, `-Autor`, `-SemGit` | só se o usuário pediu explicitamente |

**Se `$0` não veio** (chegou literalmente como cifrão-zero, ou está vazio): pare aqui e responda
pedindo o nome do mod. Não execute nada.

Nome válido é letra/número/`_`/`-`, começando por letra, sem espaço nem acento — é nome de pasta
lido pelo jogo. Se o que veio tiver espaço ou acento, **não corrija sozinho**: pare e pergunte.

## Passo 2 — rodar o script

Uma chamada só, via `Bash`:

```
powershell -NoProfile -ExecutionPolicy Bypass -File "${CLAUDE_SKILL_DIR}/novo-mod.ps1" -Nome <Nome> [demais parâmetros]
```

O script é a fonte da verdade do formato. Ele já resolve, sem sua ajuda:

- a árvore B42 completa (`workshop.txt`, `preview.png`, `Contents/mods/<Nome>/42/{mod.info,poster.png,media/...}`, `common/media/`);
- **validação das tags** contra as 31 de `media/WorkshopTags.txt` do jogo, corrigindo a grafia
  (`build 42` → `Build 42`) e abortando se a tag não existir;
- `poster.png` e `preview.png` 256x256 marcados como placeholder, para nenhum mod nascer com arte
  de outro;
- `.gitignore` + `git init` (sem commit);
- `mod.info` e `workshop.txt` em UTF-8 **sem BOM** — BOM quebraria a primeira chave.

Ele **nunca sobrescreve**: se a pasta já existe, aborta. Isso é o comportamento certo.

Em modo de permissão `auto` o classificador revisa a chamada; é um script que só cria arquivos
novos dentro da pasta do mod.

## Passo 3 — relatar

Repasse o que o script imprimiu: caminho, `id`, tags, estado do git, arquivos criados e as
pendências (arte, `description` em TODO, commit inicial). Se falhou, a mensagem de erro literal.

Feche lembrando que o esqueleto está vazio de propósito: conteúdo (item, receita, Lua, tradução)
não é escopo desta skill — para planejar o que vem depois, existe a skill `planejador`.

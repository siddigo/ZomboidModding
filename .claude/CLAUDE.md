# ZomboidModding — Workspace de Mods para Project Zomboid

Workspace de modding para Project Zomboid com Claude Code: config, skills, agentes e documentação de
referência do jogo. Os mods em si **não** ficam dentro deste repositório — moram na pasta `Workshop`
do jogo e são referenciados por caminho absoluto. Objetivo: desenvolver mods do zero até o formato
publicável na Steam Workshop, respeitando as convenções da IndieStone.

Este arquivo é carregado em **toda** chamada, então carrega só regra de trabalho. O porquê do desenho
(modelo de cada skill, divisão de responsabilidade completa, permissões, integração com o Claude
Code) está em `.claude/MANUTENCAO.md` — **leia antes de mexer em skill, agente, settings ou neste
arquivo.**

**Overlay local.** Este arquivo é a convenção compartilhada e é publicado: nada pessoal entra aqui.
O que é seu (caminhos da máquina, lista dos próprios mods, remotos, pendências) vai num `CLAUDE.md`
na raiz do repositório ou no `CLAUDE.local.md` (gitignorado).

**Pasta pessoal.** O que você gera (`Projetos/`, `Documentacao/mods/`, `Documentacao/oficial/`,
`.claude/memory/`) pode ficar na raiz daqui (o `.gitignore` já exclui) ou numa pasta pessoal fora
deste repositório, com git próprio e a mesma estrutura relativa. Nesse caso o `CLAUDE.local.md` daqui
importa o `CLAUDE.md` de lá e declara o caminho, e todo `Projetos/` ou `Documentacao/mods/` citado
aqui ou numa skill é relativo à pasta pessoal. A sessão continua abrindo **aqui** (skills e agentes
só carregam do cwd); a pasta pessoal entra em `additionalDirectories`.

## Locais do workspace

Caminhos padrão de uma instalação Steam no Windows — ajuste ao seu. `~` é `%USERPROFILE%`.

| Pasta | Caminho padrão | Papel |
|---|---|---|
| **ProjectZomboid** | `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid` | Instalação do jogo. **Somente leitura.** `media/` é a fonte de consulta; `mods/examplemod` é a estrutura mínima oficial. |
| **Workshop** | `~\Zomboid\Workshop` | Mods em desenvolvimento, um por pasta, independentes salvo `require=` no `mod.info`. |
| **Este repositório** | onde você clonou | Config do Claude Code, specs e doc. |
| **Zomboid (user data)** | `~\Zomboid` | Runtime: `console.txt` (**primeiro lugar a olhar** quando o mod não carrega), `Logs/`, `mods/`. `Saves/`, `Sandbox Presets/`, `options.ini` são estado do jogador — **nunca commitar.** |
| **Mods da Steam** | `C:\Program Files (x86)\Steam\steamapps\workshop\content\108600` | Mods da comunidade (a `STEAM/` da doc). Código de terceiros: nunca copiar sem checar licença/créditos. |

**`common\ProjectZomboid` e `workshop\content` são irmãs sob `steamapps\`.** Pode existir um resíduo
`common\ProjectZomboid\steamapps\workshop\content\108600\` com um punhado de itens: caminho relativo a
partir da pasta do jogo cai lá sem erro e devolve quase nada. **Sempre absoluto a partir de
`Steam\steamapps\`.**

### Formato de um mod (B42)

```
<PastaDoUpload>/
  workshop.txt          # metadados do upload (id numerico, title, description, tags, visibility)
  preview.png           # thumbnail da Workshop
  Contents/
    mods/
      <NomeDoMod>/      # nome do mod para o jogo; NAO precisa ser igual a pasta do upload
        42/             # pasta por versao do jogo — `42` ou `42.0`, conforme o mod
          mod.info      # id, name, description, poster, author, modversion, versionMin[, versionMax, require]
          poster.png
          media/{lua,scripts,...}
        common/
          media/{textures,models_X,scripts,...}
```

A pasta de versão carrega o específico do build (`mod.info`, `poster.png`, `media/lua`,
`media/scripts`); `common/` carrega o que não muda (texturas, `models_X`, tiles). Dois formatos
antigos ainda aparecem — pré-B42 sem pasta de versão, e fase inicial com só `mod.info` + `media/` na
raiz — então **olhe o layout do mod antes de mexer, não presuma.** Pasta em `Contents/mods/` com nome
de outro mod costuma ser resquício de template.

**Versionamento:** cada mod é seu próprio repo git, com o nome da pasta do upload. Confira se há
`.git` antes de presumir.

### Este repositório

`.claude/` (config: `CLAUDE.md`, `settings.json`, `skills/`, `agents/`, `memory/`), `Projetos/`
(specs, por usuário) e `Documentacao/` (referência do jogo: `index.md`, `jogo/`, `fontes-externas.md`,
e opcionais `mods/`, `oficial/`). Skills e agentes se descrevem sozinhos na listagem da sessão;
`squash-merge` e `fechar-versao` só rodam pelo comando, porque não voltam atrás.

- **`iniciar-mod`**: quem sabe o formato é `.claude/skills/iniciar-mod/novo-mod.ps1`. **Mudança de
  formato de mod vai no `.ps1`, não no prompt.**
- **`criar-conteudo`**: conteúdo de PZ é uma pilha de camadas (`.txt`, arte, presença no mundo,
  tradução, uso). Escrever só a camada 1 carrega limpo e nada aparece. Suas `references/` só carregam
  o delta lado-mod e apontam para `Documentacao/jogo/`.
- **`pz-explorer`** (Haiku): localiza no `media/` e devolve `caminho:linha`. **Subagente não dispara
  subagente** — só a sessão principal alcança o `pz-explorer`.
- **`Projetos/<NomeDoMod>/NN-nome-curto/`**: um conjunto por pedido, com `SPEC-00-escopo.md` +
  `SPEC-XX-*.md`. Spec vive no workspace, nunca dentro do mod.

## Onde cada coisa mora

**Este arquivo é convenção do workspace. Fato do jogo mora em `Documentacao/`, e só lá.** O teste:
*isso desatualiza quando a Steam faz patch?* Se sim, vai para uma página, que carimba o `buildid` no
rodapé. Aqui não entra número levantado do `media/`, caminho ou símbolo do jogo citado como
afirmação, nem resumo do que uma página cobre. O inventário de páginas está na tabela "Mapa" de
`Documentacao/index.md`: **leia-a antes de concluir que uma área não está documentada.**

- Correção de fato do jogo achada no meio de outro trabalho vai para a página dona pela `doc-pz`,
  invocada na hora, sem esperar pedido.
- Pendência sobre uma página nasce na própria página, em "Pontos a confirmar".
- Página de `jogo/` não carrega estado de mod próprio: isso vai para `Documentacao/mods/` ou
  `Projetos/<Mod>/`.
- O baseline da doc é o `buildid` da Steam (`steamapps/appmanifest_108600.acf`), não commit git.
  Igual ao do rodapé = nada a reconferir.
- Doc da comunidade (`Documentacao/fontes-externas.md`) é pista, não prova: todo achado vira
  `caminho:linha` no `media/` ou fica "a confirmar", e em divergência **o código ganha**.

## Formatos usados nos mods

- **`.lua`**: linguagem principal, scripts client/server/shared contra a API do motor (Java).
- **`.txt`**: itens, receitas, entidades, fixing, evolvedrecipes. Sintaxe própria da IndieStone
  (`module X { item Y { ... } }`), não é Lua nem JSON.
- **`.json`**: **traduções no B42** (`media/lua/shared/Translate/<IDIOMA>/*.json`). O `.txt` é B41.
- **`.xml`**: animações (AnimSets, animscript, animstates).

O parser da IndieStone é rígido e **falha em silêncio**: o bloco simplesmente não existe no jogo.

**Ordem de consulta — sempre nesta ordem, sem pular etapa:**

1. **`Documentacao/`**: `jogo/scripts-txt.md` traz o exemplo canônico com `caminho:linha`,
   `jogo/mapa-media.md` responde "onde fica o quê". Primeiro lugar em *qualquer* pergunta sobre o jogo.
2. **`ProjectZomboid/media`**: só quando a doc não responde, está "a confirmar" ou está defasada.
3. **Doc da comunidade**: pista, nunca prova.

**O que for descoberto no passo 2 ou 3 volta para `Documentacao/` pela skill `doc-pz`. Invoque-a
você mesmo ao terminar de levantar.** Lacuna na doc é achado a reportar, não detalhe a engolir.

**O B42 reestruturou `media/scripts` inteiro.** Quase todo tutorial da internet é B41. Não copie
sintaxe da web sem conferir ("O que mudou do B41 para o B42" em `Documentacao/jogo/scripts-txt.md`).

## Escrita de código

Vale para todo `.lua` de mod. Comentário é a saída de emergência para o que o código não alcança, não
o lugar onde se conta o que ele faz. **Versão completa, com exemplos: `.claude/escrita-de-codigo.md`**
— leia antes de escrever ou revisar `.lua` e passe o caminho a subagente que implementa.

1. **Nome antes de comentário.** Se foi preciso comentar *o que* faz, troque o nome. O teste é a
   chamada. Sem abreviação (`optionValue`, não `v`), sobretudo em parâmetro de loop/callback e em
   fórmula. Constante nomeada absorve o número mágico.
2. **O nome não pode mentir.** `list`, `map`, `count`, `is`/`has` só se for aquilo mesmo. Espelhar
   nome da API do jogo no wrapper é certo; inventar um `list` que não é array, não. Nome errado aqui
   dá silêncio, não erro (`l`/`1` num `fullType`).
3. **Distinção que não distingue é ruído.** Dois nomes, dois comportamentos. Nada de `Utils`,
   `Manager`, `Helper`, nem de `_Client`/`_Server` na tabela (a camada é da pasta), nem de cópia da
   mesma função em namespaces diferentes.
4. **Comentários que ficam** (lista fechada): contrato de uso que a assinatura não conta; origem de
   número mágico; o que quebraria se mexessem sem saber; ponteiro para `Documentacao/`.
5. **Os que não ficam:** abordagem descartada, medição, valor antigo, paráfrase da linha, código
   comentado, censo do jogo.
6. **Conteúdo novo é linha de dado, não bloco de código**: o que varia vira tabela declarativa, o que
   não varia vira uma função que a percorre.
7. **O escopo do arquivo termina numa chamada nomeada**, nunca em bloco solto.
8. **Falha silenciosa se conserta com `print("[Mod] …")`**, que cai no `console.txt`, não com
   comentário.
9. **Forma:** identificador e comentário em inglês; arquivo sem BOM; `.lua` com prefixo do mod no
   nome (`MeuMod_*.lua`), exceto `registries.lua`.

## Fluxo de trabalho

1. Ideia nasce em `Projetos/<NomeDoMod>/` pela skill `planejador`.
2. Desenvolvimento em `Workshop/<NomeDoMod>/`, consultando `ProjectZomboid/media`, nunca editando.
3. Testar in-game **sem copiar nada**: o jogo lê `Workshop/<Mod>/Contents/mods/<Mod>/` direto. Ler
   `~\Zomboid\console.txt` (sobrescrito a cada sessão; conferir a data) e
   `~/Zomboid/Logs/*_DebugLog.txt`. Ver `Documentacao/jogo/testar-e-debugar.md`.
4. Evoluir até o formato publicável e versionar cada mod no próprio repo.
5. Aprendizados voltam para `.claude/memory/` ou `Documentacao/`.

## Claude Code neste workspace

- **Sempre abrir a sessão pela raiz daqui.** O contexto sobe a árvore a partir do cwd: sessão aberta
  dentro de `Workshop/<Mod>` não carrega este arquivo, nem skills, nem settings. CLAUDE.md de
  *additional directories* não é carregado.
- **Memória:** `autoMemoryDirectory` só vale em `.claude/settings.local.json`; sem ele a memória volta
  em silêncio para `~/.claude/projects/`. Memória viaja entre máquinas: nada que dependa de caminho
  ou estado local.
- **Permissões** em `.claude/settings.json`: escrita liberada aqui e em `~/Zomboid/Workshop/**`;
  `deny` em `**/steamapps/**`, `~/Zomboid/Saves/**` e `options.ini`, que vence em qualquer modo. Não
  definir `defaultMode` no settings de projeto, nem `allow` para `rm`/`mkdir`. Escrita em `.claude/`
  sempre pergunta: é esperado. Sintaxe de caminho e limitações em `.claude/MANUTENCAO.md`.

## Regras gerais

- **Nunca editar nada dentro de `ProjectZomboid/`.**
- **Não pedir confirmação para gravar arquivo** nas pastas liberadas: o que protege é o `deny`, o
  modo `auto` e o git. Nenhuma skill reintroduz esse passo. Pergunte só o que a escrita não resolve:
  decisão de design que muda o resultado, pedido ambíguo demais para escopar, e ação que sai do disco
  ou não volta (`git commit`/`push`, apagar branch, publicar na Workshop).
- Não commitar saves, `options.ini`, logs (`hs_err_pid*.log`, `console.txt`) ou binários do jogo.
- Seguir a sintaxe e formatação observadas nos arquivos originais do jogo.
- **Checagem de sintaxe Lua: `luajit -b <arquivo.lua> <saida>`** em todo `.lua` tocado, antes de
  testar in-game. Nunca `luajit -e "loadfile(...)"`, que executa o arquivo. LuaJIT porque o Kahlua do
  PZ é Lua 5.1 (o 5.4 aceita `//`, `<const>` e bit a bit que o jogo recusa); o LuaJIT ainda aceita
  `goto`, que o Kahlua não tem. Só pega sintaxe: `nil` em runtime continua sendo `console.txt`.

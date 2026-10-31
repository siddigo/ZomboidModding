# ZomboidModding — Workspace de Mods para Project Zomboid

Workspace de modding para Project Zomboid com Claude Code: config, skills, agentes e documentação de
referência do jogo. Os mods em si **não** ficam dentro deste repositório — moram na pasta `Workshop`
do jogo e são referenciados por caminho absoluto.

Objetivo: desenvolver mods para o Project Zomboid, do zero até o formato publicável na Steam
Workshop, respeitando as convenções da IndieStone.

**Overlay local.** Este arquivo é a convenção compartilhada. Quem usa o workspace pode pôr um
`CLAUDE.md` na raiz do repositório (ou `CLAUDE.local.md`, gitignorado) com o que é seu: caminhos da
máquina, lista dos próprios mods, remotos, pendências. O Claude Code carrega os dois. Nada pessoal
entra aqui — este arquivo é publicado.

## Locais do workspace

Caminhos padrão de uma instalação Steam no Windows — ajuste ao seu.

| Pasta | Caminho padrão | Papel |
|---|---|---|
| **ProjectZomboid** | `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid` | Instalação do jogo. **Somente leitura, nunca editar.** |
| **Workshop** | `~\Zomboid\Workshop` | Mods em desenvolvimento. Cada pasta é um mod independente. |
| **Este repositório** | onde você clonou | Config do Claude Code, specs e doc. |
| **Zomboid (user data)** | `~\Zomboid` | Onde o jogo escreve em runtime. Ver abaixo. |
| **Mods da Steam** | `C:\Program Files (x86)\Steam\steamapps\workshop\content\108600` | Mods da comunidade baixados. Ver abaixo. |

`~` é a pasta do usuário (`%USERPROFILE%`).

### ProjectZomboid — referência (não alterar)

- `media/` — fonte principal de consulta: `lua/` (client/server/shared), `scripts/` (itens, traits,
  recipes em `.txt`), animações `.xml`, texturas, sons.
- `mods/examplemod` — mod de exemplo oficial da IndieStone. Superficial, mas mostra a estrutura
  mínima (`mod.info`, `media/lua`, `media/ui`, `poster.png`).

Leitura liberada, escrita bloqueada por `permissions.deny` em `.claude/settings.json` — ver
"Permissões" abaixo.

### Mods da Steam — referência de terceiros

`...\Steam\steamapps\workshop\content\108600` (108600 = App ID do PZ). É a `STEAM/` da
documentação — quantos itens há e o que eles provam mora em `Documentacao/`, não aqui.

**`common\ProjectZomboid` e `workshop\content` são pastas irmãs sob `steamapps\`**, então a pasta
não está dentro da instalação do jogo e `PZ/steamapps/...` é caminho inválido. A armadilha: um
`common\ProjectZomboid\steamapps\workshop\content\108600\` **pode existir**, resíduo antigo com um
punhado de itens. Caminho relativo a partir da pasta do jogo cai lá, não dá erro nenhum e devolve
quase nada — **sempre absoluto a partir de `Steam\steamapps\`.**

Quem libera a leitura é o `Read(//**/steamapps/**)` de `settings.json`, que vale para
`Read`/`Glob`/`Grep` em qualquer drive. Escrita bloqueada pelo mesmo `deny` do jogo. Código de
terceiros — nunca copiar sem checar licença/créditos.

### Zomboid (user data) — onde debugar

É onde o jogo grava tudo em runtime:

- `console.txt` — **primeiro lugar a olhar** quando um mod não carrega ou o Lua estoura. Contém o
  stacktrace de erro de Lua.
- `Logs/` — logs por sessão, histórico.
- `mods/` — mods instalados/ativos (diferente de `Workshop/`, que é o fonte em desenvolvimento).
- `Saves/`, `Sandbox Presets/`, `options.ini` — estado do jogador. **Nunca commitar.**

### Workshop — mods em desenvolvimento

Cada subpasta é um mod independente. Sem dependência entre eles, salvo declarada em
`mod.info` → `require=`.

Formato de destino ao publicar (B42):

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

A pasta de versão (`42`/`42.0`) carrega o que é específico daquele build — `mod.info`, `poster.png`,
`media/lua`, `media/scripts`. `common/` carrega o que não muda entre builds: texturas, modelos
(`models_X`), tiles, depthmaps. O jogo só carrega a pasta de versão correspondente ao build em uso.

Dois formatos mais antigos ainda aparecem — **olhe o layout do mod antes de mexer nele**, não
presuma:

- Pré-B42, sem pasta de versão: `Contents/mods/<Mod>/{mod.info, poster.png, media/}`.
- Fase inicial, sem `Contents/` nenhum: só `mod.info` + `media/` na raiz. Esperado, não é requisito
  para começar.

O nome da pasta em `Contents/mods/` é o nome do mod para o jogo e pode diferir legitimamente da
pasta do upload. Mas confira: pasta interna com nome de outro mod costuma ser resquício de cópia de
template, não convenção.

**Versionamento:** a meta é cada mod ser seu próprio repositório git, com o nome da pasta do upload
como nome do repositório — a pasta do upload manda, não o `id` do `mod.info` nem o título da
Workshop. Tratar cada pasta como projeto isolado no seu próprio estágio de maturidade: confira se
há `.git` antes de presumir.

### Este repositório

```
.gitignore
.claude/                     # TODA a config do Claude Code mora aqui
  CLAUDE.md                  # este arquivo
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

### A divisão de responsabilidade — e o jeito de quebrá-la

**Este arquivo é convenção do workspace. Fato do jogo mora em `Documentacao/`, e só lá.** O teste,
antes de escrever qualquer frase aqui: *isso desatualiza quando a Steam faz patch?* Se sim, não é
deste arquivo — é de uma página, que carimba `buildid` no rodapé justamente para se saber quando
reconferir. Aqui não há carimbo nenhum, então fato do jogo escrito aqui **envelhece sem deixar
rastro** e ninguém descobre até dar errado.

Na prática isso proíbe três coisas neste arquivo: **número levantado do `media/`** (contagens,
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
única spec) e as specs individuais `SPEC-XX-nome-curto.md`. Specs vivem **aqui**, nunca dentro do
mod — o mod é o produto publicável e não carrega planejamento.

## Formatos usados nos mods

- **`.lua`** — linguagem principal. Scripts client/server/shared contra a API do motor (Java).
- **`.txt`** — scripts "estilo banco de dados": itens, receitas, entidades, fixing, evolvedrecipes.
  Sintaxe própria da IndieStone (`module X { item Y { ... } }`) — não é Lua nem JSON.
- **`.json`** — **traduções, a partir do B42** (`media/lua/shared/Translate/<IDIOMA>/*.json`).
  **Escreva `.json`**; o `.txt` é B41. Ver `Documentacao/jogo/carregamento-de-mods.md`.
- **`.xml`** — animações (AnimSets, animscript, animstates).

O parser da IndieStone é rígido e **falha em silêncio** — o bloco simplesmente não existe no jogo.
Antes de inventar sintaxe, consultar a doc.

**Ordem de consulta — sempre nesta ordem, sem pular etapa:**

1. **`Documentacao/`** — nossa árvore. `jogo/scripts-txt.md` já traz o exemplo canônico com
   `caminho:linha`, `jogo/mapa-media.md` responde "onde fica o quê". É o primeiro lugar a olhar em
   *qualquer* pergunta sobre o jogo, inclusive antes de decidir que a resposta não está lá.
2. **`ProjectZomboid/media`** — só quando a doc não responde, está marcada "a confirmar", ou está
   defasada (comparar `buildid`, ver `Documentacao/index.md`).
3. **Doc da comunidade** (`Documentacao/fontes-externas.md`) — pista, nunca prova; o código ganha.

Ir direto ao `media/` refaz um levantamento já pago e não deixa rastro. **O que for descoberto no
passo 2 ou 3 volta para `Documentacao/` pela skill `doc-pz` — invoque-a você mesmo, ao terminar de
levantar, sem esperar o usuário pedir.** Se não voltar, a próxima sessão paga o mesmo grep de novo.
Lacuna encontrada na doc é achado a reportar, não detalhe a engolir.

**O B42 reestruturou `media/scripts` inteiro.** Quase todo tutorial de modding da internet é B41 e
está errado hoje — não copie sintaxe da web sem conferir. O que exatamente mudou está na seção
"O que mudou do B41 para o B42" de `Documentacao/jogo/scripts-txt.md`.

## Escrita de código

Vale para todo `.lua` de mod. A premissa: **código cheio de comentário não é código documentado — é
código que não conseguiu se explicar.** Comentário é a saída de emergência para o que o código não
alcança, não o lugar onde se conta o que ele faz.

**1. Nome antes de comentário.** Se foi preciso comentar *o que* uma função faz, o nome está errado:
troque o nome e apague o comentário. O teste é a **chamada**, não a definição — `spawns("SpawnSkullCrusher")`
não se lê, `isSpawnEnabled(loot.sandboxOption)` se lê. Vale igual para variável:
`for _, nome in ipairs(ALVOS)` não diz nada; `for _, listName in ipairs(SURVIVOR_BAG_LISTS)` diz tudo.
Constante nomeada absorve o comentário do número mágico: `IGNITE_CHANCE_ONE_IN = 4` dispensa a linha
que explicaria `CHANCE = 4`.

A abreviação falha sozinha, **sem comentário nenhum**. O parágrafo acima deriva o nome do comentário
que ele dispensa; mas `local v = vars[optionName]` e `local t = ProceduralDistributions.list[listName]`
não tentaram comentar nada — e ainda assim obrigam a subir a linha para saber o que carregam.
`optionValue` e `procList` custam dez teclas e devolvem a linha legível, porque **o nome se escreve
uma vez e se lê a cada leitura do arquivo.** Onde a tentação é maior: parâmetro de loop e de
callback, e variável de fórmula — se cada fator da conta é uma letra, a fórmula virou charada, e aí
nem constante nomeada salva.

**2. O nome não pode mentir.** Nome honesto não é a mesma coisa que nome longo: `accountList` num
map é tão ruim quanto `d`, e ainda passa por qualquer revisão porque *parece* descritivo. Palavra
que carrega tipo — `list`, `map`, `count`, prefixo `is`/`has` — só entra se for aquilo mesmo; se a
variável guarda `"pending"`, o nome é `status`, não `isComplete`. Vale para o par de nomes também:
dois identificadores que só divergem no meio de uma frase longa fazem o autocomplete escolher por
você.

Duas formas dessa mentira custam mais caro aqui do que na média:

- **A API do jogo já mente, e não dá para consertar.** `ProceduralDistributions.list` é chaveada por
  nome e não indexada, e as três tabelas de loot têm nomes parecidos com semântica de merge
  diferente (`Documentacao/jogo/distribuicao-loot.md`). Espelhar o nome do jogo no nosso wrapper
  está certo — é o que deixa rastrear a linha até o `media/`. **Inventar** um `list` nosso que não é
  array, não.
- **Nome errado aqui não dá erro, dá silêncio.** `l`/`1` e `O`/`0` dentro de um `fullType` ou de um
  nome de lista não são erro de sintaxe: são o `or {}` criando tabela órfã, loot que nunca aparece e
  `console.txt` limpo. É o caso mais caro da regra 8 — nome que só *parece* certo não tem quem o
  denuncie, então quem denuncia é o `print`.

**3. Distinção que não distingue é ruído.** As duas regras acima julgam um nome sozinho; esta julga
o **conjunto**. Se dois nomes diferem, o comportamento tem de diferir — senão quem for chamar para
na frente dos dois e vai ler a implementação para escolher. O caso típico: `Mod.getManufacturer`,
`Mod_Client.getManufacturer` e `Mod_Utils.getManufacturer` como **três cópias do mesmo corpo** em
três namespaces, cada uma redeclarando a mesma constante. Cada nome passa nas regras 1 e 2 — nenhum
abrevia, nenhum mente — e o conjunto ainda assim não diz qual chamar.

- **O sufixo genérico é o sintoma.** `Utils`, `Manager`, `Handler`, `Helper` não nomeiam papel
  nenhum; são o que se escreve quando o papel não foi decidido. `Mod_Utils` só significa "o resto".
- **A camada é da pasta, o nome é do papel.** `client/`, `server/` e `shared/` já separam a camada,
  e o jogo trata isso por diretório — repetir `_Client`/`_Server` na tabela é a distinção que
  parece existir e não existe, e é ela que autoriza a terceira cópia. O prefixo do mod no nome
  do **arquivo** continua valendo (regra 9): é contra colisão entre mods, não é sufixo de papel.
- **Aqui o preço não são os 5 minutos, é a divergência muda.** Três cópias da mesma constante:
  corrigir uma deixa as outras com o comportamento velho, sem erro e sem log.

**4. Os comentários que ficam** — a lista é fechada:

- **contrato de uso**, quando a assinatura não conta a história: Lua não tem tipo, então "recebe
  `InventoryItem`, devolve `true` quando a opção está ausente" só existe se estiver escrito;
- **número mágico**: de onde o valor saiu e como derivar o próximo (`0.001` porque é o peso de
  `PrimitiveToolMag1` *naquela* lista);
- **o que quebraria se mexessem sem saber**: "não mover para `shared/`, lá o `SandboxVars` ainda é o
  default"; "é tabela do jogo, inserir e nunca substituir";
- **ponteiro para `Documentacao/`**, que é onde o fato do jogo mora.

**5. Os que não ficam:** narrar a abordagem descartada, medição de teste, valor antigo, resumo do que
a linha abaixo já diz, código comentado "para descomentar depois" (isso é o git) e censo do jogo —
número levantado do `media/` vai para `Documentacao/` pela `doc-pz` e o comentário vira ponteiro.

**6. Acrescentar conteúdo é acrescentar uma linha de dado, nunca um bloco de código.** Se somar o
segundo item significa somar um `if` e um `for` iguais aos do primeiro, a estrutura está errada: o
que varia vira **tabela declarativa** no topo do arquivo, o que não varia vira **uma** função que
percorre essa tabela. O terceiro item não vai lembrar de repetir as quatro etapas do segundo.

**7. O escopo do arquivo termina numa chamada nomeada.** Bloco solto no corpo do arquivo
(`if spawns(...) then … end`) obriga a ler tudo para saber o que o arquivo faz;
`registerWeaponsOnSurvivorBack()` na última linha já disse.

**8. Falha silenciosa se conserta, não se comenta.** Quando o comentário existe para avisar de uma
armadilha do próprio código (`ProceduralDistributions.list[x] or {}` criando tabela órfã quando o
nome da lista está errado), o conserto é o código reclamar — um `print("[Mod] …")` cai no
`console.txt`, que é o único canal de diagnóstico que existe aqui. Comentário não impede ninguém de
cair na armadilha; log impede a próxima sessão de procurar no lugar errado.

**9. Convenções de forma.** Identificador em inglês (acompanha a API do jogo, que ocupa metade das
linhas), comentário em inglês também, arquivo sem BOM — misturar português no meio do inglês é o
que produz `ALVOS`/`nome` no meio de `addToBag`.
Arquivo `.lua` de mod carrega o prefixo do mod no nome (`MeuMod_*.lua`): todo mod despeja no
mesmo `media/lua/`, e nome genérico convida colisão. `registries.lua` é a exceção — o nome dele é
fixo.

## Fluxo de trabalho

1. Ideia nasce em `Projetos/<NomeDoMod>/` — a skill `planejador` grava ali o conjunto
   `NN-nome-curto/` com `SPEC-00-escopo.md` + as specs.
2. Desenvolvimento em `Workshop/<NomeDoMod>/`, consultando `ProjectZomboid/media` — nunca editando.
3. Testar in-game **sem copiar nada**: o jogo lê `Workshop/<Mod>/Contents/mods/<Mod>/` direto — basta
   ativar o mod na tela de seleção. Ler `~\Zomboid\console.txt` (sobrescrito a cada sessão; conferir
   a data) e, para stacktrace completo, `~/Zomboid/Logs/*_DebugLog.txt`. Modo debug = subir o jogo
   com `-debug` nas opções de inicialização da Steam. Ver `Documentacao/jogo/testar-e-debugar.md`.
4. Evoluir até o formato publicável (`Contents/mods/<NomeDoMod>/42/` + `common/` + `mod.info` +
   `workshop.txt` + `preview.png`).
5. Versionar cada mod no seu próprio repo git.
6. Aprendizados e convenções voltam para `.claude/memory/` ou `Documentacao/`.

## Integração com Claude Code

**Tudo em `.claude/`, sem duplicação.** `.claude/skills/`, `.claude/agents/` e `.claude/memory/`
são os caminhos que o Claude Code varre — não existe pasta espelho na raiz nem junction. Uma skill
é `.claude/skills/<nome>/SKILL.md`.

**Escopo: o cwd da sessão, não o workspace do VSCode.** O Claude Code não conhece workspace
multi-root; ele monta o contexto subindo a árvore de diretórios a partir do cwd. As sessões começam
com cwd na raiz deste repositório, então este arquivo é carregado e vale para **tudo que a sessão
faz** — inclusive editar em `Workshop/` e ler em `ProjectZomboid/`, que entram como *additional
working directories*. Consequências:

- CLAUDE.md de *additional directories* **não** é carregado por padrão (só com
  `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`). Se algum mod ganhar um CLAUDE.md próprio, ele
  não entra automaticamente.
- Abrir uma sessão com cwd dentro de `Workshop/<Mod>` **não** carrega este arquivo — este
  repositório não é ancestral daquele caminho. Sempre abrir pela raiz daqui.
- Skills e settings deste repo seguem a mesma regra: só valem com o cwd aqui dentro.

**Memória automática.** O padrão seria `~/.claude/projects/<slug>/memory/`, chaveado pela raiz do
git. Para a memória acompanhar o repositório, redirecione para `.claude/memory/` via
`autoMemoryDirectory` em `.claude/settings.local.json`. Detalhes que importam:

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

## Regras gerais

- **Nunca editar nada dentro de `ProjectZomboid/`.** Somente leitura.
- **Não pedir confirmação para gravar arquivo.** Escrever nas pastas liberadas (este repo e
  `Workshop/`) é o trabalho; apresentar rascunho e esperar "pode gravar" é ruído. O que protege
  aqui é o `deny` das permissões, o classificador do modo `auto` e o git — não um passo de
  aprovação no prompt. Nenhuma skill deve reintroduzir esse passo. Continua valendo perguntar o
  que a escrita **não** resolve: decisão de design que muda o resultado (qual `ItemType`? aparece
  no loot? que número de balanceamento?), pedido ambíguo demais para escopar, e ação que sai do
  disco ou não volta — `git commit`/`push`, apagar branch, publicar na Workshop.
- Mods em `Workshop/` são independentes, salvo dependência declarada no `mod.info`.
- Não commitar saves, `options.ini`, logs (`hs_err_pid*.log`, `console.txt`) ou binários do jogo.
- Seguir a sintaxe e formatação observadas nos arquivos originais do jogo — o parser é sensível.
- **Checagem de sintaxe Lua fora do jogo: `luajit -b <arquivo.lua> <saida>`** em todo `.lua`
  tocado, antes de mandar testar in-game (`winget install DEVCOM.LuaJIT`). O `-b` só compila; não
  use `luajit -e "loadfile(...)" arquivo`, que **executa** o arquivo e estoura no primeiro
  `require` do jogo. LuaJIT e não `luac` 5.4 porque o Kahlua do PZ é gramática 5.1 — o 5.4 aceita
  `//`, `<const>` e operador bit a bit que o jogo recusa. O LuaJIT ainda aceita `goto`, que o
  Kahlua não tem. Só pega sintaxe: `nil` em runtime e nome errado da API continuam sendo
  `console.txt`.

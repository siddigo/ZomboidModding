---
name: doc-pz
model: opus
description: Gera e reconfere a árvore de documentação de referência em Documentacao/ — sintaxe do jogo, mapa do media/, API Lua, formato de mod. Aterrada em path:linha e carimbada com o buildid da Steam. Usar quando o usuário pedir para documentar/levantar uma área do Project Zomboid ou reconferir a doc depois de um patch do jogo; e também por conta própria, sem pedido, quando no meio de outro trabalho você levantar no media/ (ou na doc da comunidade) um fato que a doc não cobre, ou descobrir que uma afirmação dela está errada — a descoberta volta para a página dona em vez de morrer na conversa. NÃO usar para apenas consultar a doc: ler Documentacao/ é Read, não esta skill.
---

Você mantém a árvore de referência de modding em `C:\Projetos\ZomboidModding\Documentacao\`. É a
única escrita permitida por esta skill — apenas os `.md` dali, incluindo o `index.md` de mapa.

**Não é sua função implementar ou editar mod.** Se o usuário pedir mudança em código de mod, pare e
diga que esta skill só documenta. Para planejar trabalho, existe a skill `planejador`.

**Nunca escreva em `ProjectZomboid/` nem em `steamapps/`** — leitura apenas, em qualquer
circunstância.

## Antes de qualquer coisa: leia a convenção

`Documentacao/index.md` é a fonte da convenção — "Regras da árvore", "Convenção de versão — o
carimbo de build" e a tabela de aliases de caminho. Releia antes de escrever. Se o que você for
fazer contraria o `index.md`, o `index.md` ganha (ou você propõe mudá-lo explicitamente).

## Regras obrigatórias

1. **Nunca invente.** Toda afirmação vem de `caminho:linha` levantado agora, no `media/` real. O
   parser da IndieStone falha em silêncio — sintaxe plausível é pior que ausência de doc. O que não
   der para confirmar vira **"a confirmar"** numa seção de pendências, não afirmação. Divergência
   entre levantamentos → registre como "a confirmar", não escolha um lado.
2. **Regra de ouro: documente o que custa um grep.** O código é legível; o caro é *achar*. Entram
   localização, exemplo canônico, contrato não-óbvio, o que mudou do B41 para o B42 e o que falha em
   silêncio. Não entra: reexplicar linha a linha, nem copiar dado do jogo (lista de itens, de sons,
   de veículos — isso é o `media/`, não a doc).
3. **Consulte o memory primeiro, depois delegue ao `pz-explorer`.** O índice `.claude/memory/MEMORY.md`
   já vem carregado; abra as memórias relevantes antes de grepar. Para o resto, dispare o subagente
   `pz-explorer` (Haiku, read-only) — ele devolve `caminho:linha` + resumo e mantém o grep pesado
   fora do modelo caro. Reserve `Read` inline para o trecho específico que você precisa ver para
   decidir. Numa varredura de `media/` isso é o que evita estourar contexto.
4. **Cruze com a doc da comunidade — depois do código, nunca no lugar dele.** As fontes públicas
   estão catalogadas em `Documentacao/fontes-externas.md` (o que cada uma cobre, padrão de URL,
   versão). A principal é o PZ-API-Docs, auto-gerado por parser sobre o jogo: publica por parâmetro
   o tipo, `required`, default, min/max e os **valores permitidos** — o contrato do parser, que mora
   no Java e não é legível no `media/`. É a classe de erro que falha em silêncio, então é onde a
   consulta rende. Regras de uso:
   - **Só depois de explorar o código.** A fonte serve para achar o que passou batido, não para
     poupar o levantamento.
   - **Confirme antes de afirmar.** Todo achado vira `caminho:linha` no `media/` ou não entra. Uma
     afirmação confirmada é citada pelo código, não pela URL — a fonte da verdade passou a ser ele.
   - **Não confirmou → "Pontos a confirmar", com a URL.** Nunca promova a afirmação em silêncio.
   - **Divergência: o código ganha.** Sem exceção, e sem escolher lado no meio-termo.
   - **Não copie prosa nem tabela de lá.** Vale o mesmo da regra 2: a página diz onde está e qual é
     o contrato.
   - As fontes carimbam versão semântica (42.20.0), que **não** mapeia no `buildid`. Podem estar à
     frente ou atrás do install; isso não muda a hierarquia.
   - **Este passo é seu, não do `pz-explorer`** — ele só tem `Glob`/`Grep`/`Read`, não acessa a web.
     Você busca com `WebFetch` e devolve ao `pz-explorer` só a lista de candidatos a confirmar.
5. **Carimbe o build no rodapé.** Leia o `buildid` de
   `C:\Program Files (x86)\Steam\steamapps\appmanifest_108600.acf` e feche cada página com:

   ```
   > Última verificação: <AAAA-MM-DD> — PZ buildid <id> (branch <BetaKey>, atualizado <data de LastUpdated>), media/.
   ```

   Use a data atual da sessão. Se a página documenta mod próprio (`Documentacao/mods/`), o baseline
   é outro: commit git do repo do mod (`git -C <pasta-do-mod> rev-parse --short HEAD`).
6. **Atualize o `index.md`.** Toda página nova entra na tabela "Mapa" de `Documentacao/index.md`.
   Essa tabela é o **único** inventário da árvore: `.claude/CLAUDE.md` não lista páginas de
   propósito e não deve ser tocado por esta skill — ele carrega o modelo, o `index.md` carrega o
   que existe. Se notar o CLAUDE.md descrevendo a árvore de um jeito que a contradiz, reporte ao
   usuário no fechamento; não edite.
7. **Não versiona.** `git add`/`commit` é decisão do usuário — ao final, liste o que mudou e avise
   que falta commitar.

## Quando você se invoca no meio de outro trabalho

O caso normal é o usuário chamar `/doc-pz` e a sessão inteira ser sobre a doc. Mas a regra da ordem
de consulta (`.claude/CLAUDE.md`) manda o achado do passo 2/3 voltar para `Documentacao/`, e é você
quem faz isso voltar — implementando um mod, planejando, respondendo pergunta. **Invoque-se ao
terminar de levantar algo que a doc não cobre ou cobre errado**, sem esperar pedido.

O que muda em relação a uma sessão dedicada é o **escopo** e o **retorno**:

1. **O delta é o escopo, não a área.** Você já pagou o grep de uma afirmação; grave essa. Não
   promova uma correção de uma linha em varredura da página inteira — isso sequestra a tarefa do
   usuário e é justamente o modo RECONFERIR, que é trabalho de sessão própria.
2. **Nenhuma regra relaxa por ser de passagem.** Sem `caminho:linha` levantado agora, não entra:
   vira "Pontos a confirmar". Pressa não autoriza afirmação plausível — o parser falha em silêncio,
   e doc errada é pior que lacuna.
3. **Não gere página nova de carona.** Se o achado não tem página dona, ele é do tamanho de uma
   sessão de modo GERAR. Reporte a lacuna e ofereça gerar depois — mesma regra do fim do modo
   RECONFERIR. Uma linha órfã num arquivo novo mal-escopado é pior que a lacuna anotada.
4. **Não recarimbe o rodapé.** O carimbo afirma que a **página** foi verificada contra aquele
   `buildid`; trocar o número depois de corrigir uma linha certifica o que você não conferiu. Deixe
   o rodapé como está. Se ele estiver atrás do `buildid` atual, diga isso no fechamento e sugira um
   RECONFERIR — não resolva sozinho.
5. **Volte para a tarefa interrompida.** Gravar não pede aprovação (regra do workspace), mas o
   usuário tem de saber que aconteceu: uma linha no fechamento dizendo qual página mudou e o que
   entrou, e siga o que ele pediu. A escrita na doc **soma** à tarefa, nunca a substitui, e nunca
   muda a decisão de código que estava em curso.

## Os dois modos

Decida qual pelo estado da árvore, não pergunte se der para inferir.

### Modo GERAR — a página não existe

1. **Classifique a área.** Referência do jogo → `Documentacao/jogo/<nome>.md`. Documentação de mod
   próprio → `Documentacao/mods/<NomeDoMod>.md` (crie a pasta e o `index.md` dela se for a primeira).
   Se a classificação estiver ambígua, pergunte antes de explorar.
2. **Explore via `pz-explorer`**: onde a área vive, qual é o arquivo canônico de cada construção,
   quais campos/eventos formam o contrato, o que é específico do B42. Peça sempre `caminho:linha`.
3. **Passe a doc da comunidade por cima do levantamento** (regra 4). Abra a página da área no
   PZ-API-Docs — `scripts/<nome-minúsculo>.html` para um bloco, senão `java.html`, `xml.html`,
   `mapping.html`, `translations.html`; `Documentacao/fontes-externas.md` tem o padrão de URL e as
   outras fontes. Procure só o que o código não entrega: valores permitidos, default, min/max,
   `required`, campo `deprecated`, hierarquia do bloco, campo que existe e você não viu usado. Cada
   candidato volta ao `pz-explorer` para virar `caminho:linha` — o que não fechar vai para "Pontos a
   confirmar" com a URL.
4. **Cruze com o B41 quando fizer diferença.** Boa parte do material público de modding é B41 e está
   errado hoje. Se a área mudou, a seção "O que mudou do B41 para o B42" é o conteúdo mais valioso
   da página. Fonte para isso: os mods de `STEAM/`
   (`C:\Program Files (x86)\Steam\steamapps\workshop\content\108600`, pasta **irmã** da do jogo) —
   dá para cruzar `mod.info → versionMin` com o que eles usam, e provar que uma forma é legada.
5. **Monte o `.md`**: título, escopo de uma linha, alias de caminho usado, corpo com cada afirmação
   citando `caminho:linha`, blocos de sintaxe **reais** copiados do jogo, seção final
   "Pontos a confirmar", rodapé com o carimbo.
6. **Grave** o `.md` e a entrada no `index.md`. Não apresente rascunho para aprovação — escrever é o
   trabalho da skill, e o resultado é revisável depois (git, e o próprio modo RECONFERIR).
7. **Feche** listando os arquivos criados e lembrando que falta commitar.

### Modo RECONFERIR — a página existe

O gatilho normal é patch da Steam. Comece pela checagem barata:

1. **Compare o `buildid`** do `appmanifest_108600.acf` com o do rodapé da página.
   - **Igual** → o jogo não mudou um byte desde a última verificação. Diga isso e pare. Não gaste
     token reconferindo. (Exceção: o usuário pedir reconferência completa explicitamente, ou a
     página ter pendências "a confirmar" que ele quer resolver agora.)
     `buildid` igual prova que **o jogo** não mudou — não que a página esteja completa. A doc da
     comunidade é republicada por conta própria, então é a única coisa que ainda pode render aqui:
     se houver "a confirmar" em aberto, ofereça resolver **essas** contra as fontes externas
     (passo 5) sem reconferir o resto.
   - **Diferente** → siga.
2. **Descubra o que o patch tocou, pelo `mtime`.** A Steam só reescreve arquivo que mudou, então o
   sistema de arquivos já dá o diff de graça — não varra a árvore antes disto:

   ```sh
   find media -type f -newermt "<data anterior ao patch>"
   ```

   Em 07/ago/2026 (`24449119` → `24574865`) isso deu 0 arquivos em `media/scripts`, 9 `.lua` e 350
   `.json` de `Translate/`: o patch era quase todo `projectzomboid.jar`. Cruze os arquivos tocados
   com as citações da doc (`grep -rl <basename> Documentacao/`) — **só o que aparece nos dois pode
   ter morrido.** Limite: `mtime` prova que a Steam não reescreveu o arquivo, não é comparação byte
   a byte; se o usuário pedir garantia dura, pule este passo.
3. **Extraia as afirmações da página** com seus `caminho:linha` e confira as das áreas atingidas.
   Para o volume todo, vale extrair as citações da árvore inteira e imprimir a linha atual de cada
   uma — ao parsear `grep -rn` no Windows, **divida os campos a partir do fim**: o caminho do doc
   contém `C:` e quebra qualquer split pelo primeiro `:`.
4. **Dispare o `pz-explorer`** para o que o passo 2 marcou como atingido — não para a página inteira.
   Passe as afirmações como baseline e peça o veredito:
   **IGUAL** (com a linha nova, se mudou de lugar), **MUDOU** (o quê + `caminho:linha`),
   **REMOVIDO** (afirmação órfã — o caminho ou o símbolo sumiu), **NOVO** (algo relevante da área
   que a página não cobre).
5. **Cruze a área com a doc da comunidade** (regra 4), mirando duas coisas: as pendências
   "a confirmar" da página e mais candidatos a **NOVO**. Cada candidato volta ao `pz-explorer` para
   virar `caminho:linha`; o que não fechar continua "a confirmar", agora com a URL.

   Notas de atualização da IndieStone entram aqui, com o mesmo peso das outras fontes: são pista.
   O que o patch mexeu no `media/` você prova pelo passo 2; o que ele mexeu no `.jar` **não é
   verificável aqui** e vai para "Pontos a confirmar" citando a versão do changelog.
6. **Consolide um relatório** por página: contagem de IGUAL/MUDOU/REMOVIDO/NOVO e os pontos a
   corrigir com `caminho:linha`.
7. **Aplique as correções** — sem passo de aprovação — e atualize o rodapé com o `buildid` novo.
   Quando uma mudança for de versão de jogo (não erro da doc), marque inline — `[novo 42.x]`,
   `[removido 42.x]`, `[mudou 42.x: o quê]` — para o leitor saber que a forma antiga existiu.
   Correção que dependa de decisão do usuário (a doc está certa e a **convenção** é que mudaria)
   não é correção: vai para o relatório como pergunta.
8. **Feche** com o relatório do passo 6, o que foi aplicado e o lembrete de commitar.

Se durante a reconferência aparecer área relevante ainda sem página, **reporte e sugira gerar** —
não gere de carona.

## Escopo — não estoure

`media/lua` tem 1.395 `.lua` e `media/scripts` 1.004 `.txt`. Documentar "o jogo" de uma vez não
existe. Se o usuário pedir sem delimitar área:

1. Liste as áreas candidatas e cruze com o que já existe em `Documentacao/`.
2. **Apresente a lista do que falta e confirme a prioridade** antes de gerar. Uma área por vez.

## Observações

- Não redocumente o que `.claude/CLAUDE.md` já cobre (locais do workspace, permissões, fluxo de
  trabalho, convenção de pastas). A árvore documenta o jogo, não o workspace.
- A API Java exposta ao Lua não tem assinatura **oficial** publicada e o `.jar` não é lido aqui.
  Ancore sempre numa chamada real encontrada em `media/lua`, com `caminho:linha`, e diga que é uso
  observado — não contrato declarado. Existem dois JavaDocs/LuaDocs não-oficiais de decompilação
  (`Documentacao/fontes-externas.md`) que ajudam a ler a assinatura; eles entram pela regra 4, como
  pista a confirmar, e não transformam uso observado em contrato.
- Se precisar saber o que o jogo fez em runtime, `~\Zomboid\console.txt` é sobrescrito
  a cada sessão; confira a data antes de tirar conclusão dele.

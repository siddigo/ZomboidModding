# Escrita de código — versão completa

O `CLAUDE.md` traz o resumo das nove regras, que vale em toda sessão. Aqui estão as mesmas regras com
os exemplos e o porquê. Leia antes de escrever ou revisar `.lua` de mod, e passe este caminho no
prompt de subagente que implementa.

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


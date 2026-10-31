# Tradução (L4)

**Contrato completo: `Documentacao/jogo/carregamento-de-mods.md`, seção de tradução.** Esta página é
a tabela de decisão rápida + as armadilhas.

Sem esta camada o jogador vê a chave crua na tela (`UI_trait_corajoso` em vez de "Corajoso"). Não
quebra nada, não gera erro — só fica feio e denuncia mod inacabado.

## Onde escrever

```
Contents/mods/<Mod>/42/media/lua/shared/Translate/<IDIOMA>/<Arquivo>.json
```

`Translate` com **T maiúsculo**, extensão **`.json`**.

**Não crie `language.json`.** [corrigido 2026-08-08] Uma versão anterior desta página mandava criar
um por pasta de idioma. Está errado: `language.json` é do **jogo**, para registrar o idioma no motor.
Censo sobre os 89 mods de `STEAM/` — **197 pastas de idioma de mod contendo `.json`, e zero com
`language.json`**. Só faria sentido para um mod que adicionasse idioma novo, caso que não aparece em
nenhum dos 89.

## Qual arquivo, qual chave

| Conteúdo | Arquivo | Chave | Confirmado em |
|---|---|---|---|
| item | `ItemName.json` | `Modulo.Item` — `"MeuMod.MinhaFaca"` | `PZ/.../EN/ItemName.json` |
| receita | `Recipes.json` | **nome puro**, sem prefixo — `"MakeMinhaFaca"` | `EN/Recipes.json:203` |
| categoria de craft | `IG_UI.json` | `IGUI_CraftingCategories_<category>` | `EN/IG_UI.json:6858` |
| traço | `UI.json` | `UI_trait_<nome>` e `UI_trait_<nome>Desc` | `EN/UI.json:836-837` |
| profissão | `UI.json` | `UI_prof_<nome>` | `EN/UI.json:899` |
| entity | `Entity.json` | — | |
| moveable | `Moveables.json` | — | |
| perícia | `IG_UI.json` | `IGUI_perks_<Nome>` | `EN/IG_UI.json:224` |
| evolvedrecipe | `EvolvedRecipeName.json` | — | |

**A chave é o valor literal do campo no `.txt`.** Em traço, `UIName = UI_trait_corajoso` significa
que a chave em `UI.json` é exatamente `UI_trait_corajoso`. Não há transformação implícita — o único
prefixo implícito do PZ é o `Item_` do ícone, e ele é de textura, não de tradução.

## Armadilhas

### `Recipe_` morreu no B42

`EN/Recipes.json` tem 1.909 chaves e **zero** começando com `Recipe_`. O prefixo é B41.

`PTBR/Recipes.json` é a exceção enganosa: 3.170 chaves, das quais 1.230 são `Recipe_*` legadas que
não existem mais em `EN`. **É resíduo, não convenção** — não copie de lá.

### O formato `.txt` é B41 e está morto

`translate/` minúsculo com `Recipes_EN.txt` é B41.

**[corrigido 2026-08-08]** Uma versão anterior desta página dizia que "nenhum" mod `.txt` declara
`versionMin=42`. Está errado — são **17 mods** de `STEAM/` com `versionMin=42.x` entregando tradução
só em `.txt`. O censo completo está em `Documentacao/jogo/carregamento-de-mods.md`, "Divergências
observadas".

**A evidência que vale não é o cruzamento com `versionMin`, é o teste in-game de 2026-08-07** (jogo
42.20.2): o B42 **não lê `.txt` e não avisa**. Com `WS/SiddigoWeapons` ativo e o cliente em PT-BR, o
item apareceu como "Skull Crusher" (o `DisplayName` do script), não como o "Racha Cuca" do
`ItemName_PTBR.txt` — e o `console.txt` da sessão inteira não tem uma linha sobre tradução além de
`Loading Translations`. Mod publicado usando `.txt` está inerte, não compatível.

**`WS/SiddigoWeapons/` usa o formato B41** (`42/media/lua/shared/translate/EN/Recipes_EN.txt`). É
pendência conhecida do workspace, não modelo. Ao criar tradução nova, use `Translate/` + `.json`
mesmo que o mod já tenha arquivos `.txt` — e avise no relatório que o mod ficou com os dois formatos.

### Idioma mínimo

`EN` sempre — é o fallback do jogo. `PTBR` se o mod é para o usuário. Não invente traduções para
idiomas que o usuário não pediu.

### JSON sem BOM

Mesma regra dos `.txt`. E JSON não aceita vírgula sobrando no último par.

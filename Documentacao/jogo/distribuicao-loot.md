# Distribuição de loot

Como o jogo decide o que aparece dentro de cada contêiner, e por onde um mod entra sem editar o
arquivo do jogo.

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\`.

## Onde fica — não é no `WorldGen/`

Tudo vive em **`PZ/media/lua/server/Items/`**, em **dez** arquivos. Três carregam a estrutura
principal:

| Arquivo | Linhas | Papel |
|---|---|---|
| `Distributions.lua` | 22.600 | **462 salas.** Sala → contêiner → que listas procedurais usar |
| `ProceduralDistributions.lua` | 53.418 | **1.352 listas**, todas de nome único. Lista → itens e pesos |
| `SuburbsDistributions.lua` | 210 | Só a cola: merge, aliases de sala e os helpers |

E **sete `Distribution_*.lua`**, 5.920 linhas somadas, que os outros dois referenciam por tabela
global e que é fácil não achar procurando só por "distributions":

| Arquivo | Linhas | Global | Papel |
|---|---|---|---|
| `Distribution_BagsAndContainers.lua` | 3.652 | `BagsAndContainers` | **o conteúdo de bolsa, mala, caixa e estojo** — 95 entradas, incluindo `SurvivorBag*` e `BanditBag*` |
| `Distribution_BinJunk.lua` | 1.171 | — | lixo de lixeira |
| `Distribution_ClosetJunk.lua` | 862 | — | lixo de armário |
| `Distribution_DeskJunk.lua` | 105 | — | lixo de escrivaninha |
| `Distribution_SideTableJunk.lua` | 49 | — | lixo de criado-mudo |
| `Distribution_CounterJunk.lua` | 45 | — | lixo de balcão |
| `Distribution_ShelfJunk.lua` | 36 | — | lixo de prateleira |

`BagsAndContainers` é o que importa para mod: é a tabela alcançada pelo campo `bags` de um contêiner,
e é onde mora o loot da mochila que um zumbi carrega. Ver "Loot de zumbi", adiante.

`PZ/media/lua/server/WorldGen/` (133 `.lua` recursivos) é **geração de terreno** — bioma, estrada,
veia de minério, prefab. Não tem loot.

## As duas tabelas têm formas diferentes

**`Distributions`** — sala, depois contêiner, depois quais listas procedurais valem ali.
`PZ/media/lua/server/Items/Distributions.lua:9`:

```lua
	aesthetic = {
		counter = {
			procedural = true,
			procList = {
				{name="StoreCounterCleaning", min=0, max=99, forceForTiles="location_shop_accessories_01_0;..."},
				{name="SalonShelfHaircare", min=0, max=99, weightChance=100},
			}
		},
```

`name` aponta para uma chave de `ProceduralDistributions.list`. `forceForTiles` amarra a lista a
sprites específicos (separados por `;`), o que permite dois balcões visualmente diferentes na mesma
sala terem loot diferente.

**`ProceduralDistributions.list`** — apesar do nome, **não é array: é tabela chaveada pelo nome da
lista** (`ProceduralDistributions.lua:3`, entrada em `:5`), então indexar por número não acha nada.
A **alternância plana de string e número** — item, peso, item, peso — é do `items` de cada entrada,
um nível abaixo (`:7`). `PZ/media/lua/server/Items/ProceduralDistributions.lua:5`:

```lua
	AmbulanceDriverOutfit = {
		rolls = 3,
		items = {
			"Jacket_NavyBlue", 10,
			"Shirt_FormalWhite", 6,
			"BookFirstAid5", 0.5,
		},
		junk = {
			rolls = 1,
```

O peso é float e aceita valor abaixo de 1 (`0.5`). `rolls` é quantas vezes a lista é sorteada.
`junk` é um sub-bloco com a mesma forma, para o lixo que acompanha.

**Não confunda com `Tags` de item.** Esta é a tabela de spawn no mundo; a amarração item↔receita é
outra coisa, em `scripts-txt.md`.

## O ponto de entrada de mod — três eventos, não um

Registrados juntos em `PZ/media/lua/server/Items/SuburbsDistributions.lua:208-210`:

```lua
Events.OnPreDistributionMerge.Add(preDistributionMerge)
Events.OnDistributionMerge.Add(mergeDistributions)
Events.OnPostDistributionMerge.Add(postDistributionMerge)
```

`preDistributionMerge` e `postDistributionMerge` são **corpos vazios no jogo** (`:132-133` e
`:194-195`) — existem só como gancho. Quem faz trabalho é o do meio (`:136-149`):

```lua
local function mergeDistributions()
	SuburbsDistributions = Distributions[1] -- the games distribition table should always be the first in table.

	-- if there are modded distribution tables merge them into the main suburbsdistributions
	if #Distributions>1 then
		for key,dist in pairs(Distributions) do
			if key > 1 then
				MergeDistributionRecursive(SuburbsDistributions, dist)
			end
		end
	end
```

*(O typo "distribition" é do código original.)*

**É esse o contrato para mod:** a tabela do jogo é sempre `Distributions[1]` — garantido pelo
`table.insert(Distributions, 1, distributionTable)` no fim de `Distributions.lua`. Um mod insere a
sua própria tabela no fim de `Distributions`, e `MergeDistributionRecursive`
(`SuburbsDistributions.lua:114`) funde tudo em cima da do jogo. Não é preciso editar arquivo do jogo
nem sobrescrever a tabela inteira.

`SuburbsDistributions` é **alias** da tabela do jogo, mantido explicitamente "for mod compat" no fim
de `Distributions.lua`. Código antigo que escreve em `SuburbsDistributions` direto ainda funciona,
mas passa por fora do merge — prefira `Distributions`.

## O merge só soma — e descarta escalar em silêncio

`MergeDistributionRecursive(_orig, _mod)` (`SuburbsDistributions.lua:114-130`) tem 16 linhas e três
casos. Vale ler inteiro antes de escrever mod de loot, porque **um deles não faz nada e não avisa**:

```lua
for k,v in pairs(_mod) do
	if _orig[k]~=nil then
		if type(_mod[k])=="table" then
			if type(k)=="string" and k=="items" then
				for _,v2 in ipairs(_mod[k]) do
					table.insert(_orig[k], v2)
				end
			else
				MergeDistributionRecursive(_orig[k], _mod[k])
			end
		end
	else --if original doesnt have the table the mod has, add it.
		_orig[k] = _mod[k]
	end
end
```

| Caso | O que acontece |
|---|---|
| Chave **não existe** no original | `_orig[k] = _mod[k]` — entra inteira, por referência |
| Chave existe, valor é tabela, chave é `"items"` | **concatena** com `table.insert` |
| Chave existe, valor é tabela, outra chave | recursa |
| Chave existe, valor é **escalar** | **nada** — a atribuição está só no `else` |

O último caso é a armadilha: `rolls`, `min`, `max`, `weightChance`, `procedural` são números e
booleanos, e **nenhum deles pode ser alterado por mod numa sala que o jogo já define**. O `if` de
tipo (`:117`) só deixa passar tabela, e o `else` que atribui (`:127`) só roda quando a chave é nova.
Escrever `rolls = 10` numa lista existente é aceito pelo Lua, sobrevive ao `pairs`, e é descartado —
sem log, sem erro. Para mudar peso de lista existente o caminho é outro: escrever direto em
`ProceduralDistributions.list` antes do merge, ou usar `RemoveItemFromDistribution` e reinserir.

Corolário para dois mods na mesma sala: **eles não colidem, acumulam.** Ambos concatenam em `items`,
e a lista final tem as duas contribuições. Não há "último vence" aqui.

Duas consequências menores do mesmo código: a chave nova entra **por referência** (`:127`), então
mutar a tabela do mod depois do merge muda a do jogo; e `items` é o único nome com tratamento
especial — um `junk` de mod numa sala existente recursa em vez de concatenar, porque `junk` é tabela
mas não se chama `items`. Como `junk` contém um `items` interno, o efeito acaba sendo o mesmo um
nível abaixo.

## A tabela procedural não tem merge — entra-se por escrita direta

O `MergeDistributionRecursive` só é chamado sobre `Distributions` (`:145`). Para
`ProceduralDistributions.list` **não existe função de merge em lugar nenhum do `media/lua`**: fora do
arquivo que a define, a tabela só é lida — duas vezes, num painel de debug de admin
(`client/ISUI/AdminPanel/LootZed/SpawnRateChecker.lua:112` e `:123`). Não há evento, não há helper.

O caminho que os mods usam é escrita direta, com o idioma `or {}` para não depender de a chave já
existir:

```lua
  ProceduralDistributions.list[x] = ProceduralDistributions.list[x] or {};
  ProceduralDistributions.list[x].items = ProceduralDistributions.list[x].items or {};
  table.insert(ProceduralDistributions.list[x].items,"AuthenticZBackpacks+.AuthenticCanteenCadetBlue");
  table.insert(ProceduralDistributions.list[x].items, count);
```

(`STEAM/2335368829/mods/Authentic Z - Backpacks+/42/media/lua/server/items/PZ_AZ2LootDistributions.lua:9-12`.)
São **114 arquivos de mod** em `STEAM/` referenciando a tabela — é a rota estabelecida, não um
contorno.

Note o par de `table.insert`: `items` é lista **plana e alternada** `nome, peso` (ver a seção das
duas formas acima), então cada item custa duas inserções. Inserir só o nome desalinha o resto da
lista, e o erro não aparece na carga.

**A diferença prática contra `Distributions`:** aqui não há merge, logo não há o descarte de escalar
descrito acima — mudar `rolls` de uma entrada procedural existente é atribuição Lua comum e
funciona. O preço é o oposto: nada protege contra dois mods escreverem a mesma chave, e o último a
carregar vence sem aviso.

## As propriedades, e quais tabela aceita quais

O PZ-API-Docs tem uma seção **mapping** que lista as propriedades de distribuição procedural
(`pz-wiki-modding.github.io/PZ-API-Docs/mapping/procedural_distributions_properties.html`). Cruzando
essa lista com o censo dos três arquivos de loot, o resultado separa as duas tabelas de forma nítida:

| Propriedade | `Distributions.lua` | `ProceduralDistributions.lua` |
|---|---|---|
| `rolls` | 829 | 2.784 |
| `junk` | — | 1.420 |
| `isShop` | — | 502 |
| `ignoreZombieDensity` | — | 354 |
| `cookFood` | — | 49 |
| `bags` | — | 25 |
| `isTrash` / `isWorn` / `canBurn` | — | 18 cada |
| `gunStorage` | — | 17 |
| `dontSpawnAmmo` | — | 14 |
| `maxMap` | — | 3 |
| `onlyOne` / `isRotten` | — | 2 cada |
| **`weightChance`** | **3.061** | **0** |
| **`procedural`** | **1.328** | **0** |
| `fillRand` | 4 | 0 |

Duas leituras que valem mais que os números:

- **`weightChance` e `procedural` são exclusivos de `Distributions`**, com zero ocorrências do outro
  lado. É a confirmação, por censo, da separação de papéis descrita no topo desta página: a tabela de
  sala escolhe *qual* lista procedural usar e com que peso; a lista procedural diz *o que* sai. Pôr
  `weightChance` numa entrada procedural é escrever no bloco errado — e, sendo tabela Lua, não há
  erro.
- **`rolls` é o único nome nas duas**, com significados de nível diferente. É o campo mais fácil de
  copiar de um exemplo para o lugar errado.

**Correção (2026-08-10): `stashChance` é usado, ao contrário do que esta página afirmava.** São **8
ocorrências** — 5 em `Distribution_BagsAndContainers.lua` (nas três `SurvivorBag*` e nas `BanditBag*`)
e 3 em `ProceduralDistributions.lua`. O censo anterior varria só os três arquivos principais e não
enxergava os sete `Distribution_*.lua` (ver "Onde fica", no topo). A grafia é **`stashChance`**,
camelCase — a fonte externa escreve `stashchance`, e é provavelmente essa diferença que passou. O
comentário do próprio jogo descreve o campo como a chance de a bolsa trazer um mapa anotado
(`Distribution_BagsAndContainers.lua`, no bloco `SurvivorBag`).

Segue com zero uso confirmado: **`noAutoAge`**. Existe no parser Java segundo a fonte e não há
exemplo no `media/` — é a mesma situação de `text` em [sandbox-options.md](sandbox-options.md): o
censo mede o que foi escrito, a fonte mede o que é aceito. Use com a ressalva de que nada aqui
confirma.

**A lição do erro vale mais que a correção:** um censo só é tão bom quanto o conjunto de arquivos que
ele varre. Antes de afirmar "zero ocorrências", confira que a varredura cobre a pasta inteira, não os
arquivos que você já conhecia.

A fonte também marca **`onlyOne` como deprecated no código Java**. O `media/` é consistente com isso
— duas ocorrências em toda a tabela procedural —, mas "pouco usado" não prova "deprecado"; a
afirmação é da fonte, não do código.

## Loot de zumbi — duas rotas, e nenhuma se parece com sala

Zumbi não é contêiner, mas o que ele carrega sai das **mesmas duas tabelas**. São duas rotas
independentes:

### 1. A sala `all` — vale para todo zumbi do mapa

`Distributions.lua` tem uma sala chamada `all` com duas chaves que não existem em nenhuma outra:
**`inventorymale`** (`PZ/media/lua/server/Items/Distributions.lua:551`) e **`inventoryfemale`**
(`:488`). São listas planas `item, peso` no mesmo formato de `ProceduralDistributions`, com os
itemzinhos de bolso — `"BluePen", 1`, `"Camera", 0.03`, os mapas de cidade a `0.01` cada.

Para um mod isso é a rota **mais fácil e a mais grosseira**: entra pelo merge normal de
`Distributions`, e como a chave se chama `items`, o merge **concatena** (ver a tabela dos três casos,
acima) em vez de descartar. O preço é que não há filtro — o item passa a poder sair no bolso de
**qualquer** zumbi.

### 2. `Outfit_<Traje>` — o loot por traje, e a mochila é sub-bloco

Ainda dentro da sala `all`, mas em contêineres próprios: **`Outfit_<NomeDoTraje>`**. O traje
survivalista ocupa **15 deles**, que são 5 variantes × 3 eras
(`PZ/media/lua/server/Items/Distributions.lua:2840` em diante):

```
Outfit_Survivalist        Outfit_Survivalist02        … Outfit_Survivalist05          → bags = SurvivorBag
Outfit_Survivalist_Mid    Outfit_Survivalist02_Mid    … Outfit_Survivalist05_Mid      → bags = SurvivorBag_Mid
Outfit_Survivalist_Late   Outfit_Survivalist02_Late   … Outfit_Survivalist05_Late     → bags = SurvivorBag_Late
```

Cada um tem **duas** cargas independentes:

- **`items`** — o que está no corpo/bolso do zumbi, lista plana `nome, peso` como sempre;
- **`bags = BagsAndContainers.<X>`** — o que vem **dentro da mochila** que ele carrega
  (`Distributions.lua:2861`).

O sufixo `_Mid`/`_Late` é a progressão temporal do apocalipse: quanto mais tarde, mais coisa
fabricada. É o gancho natural de **era** para arma de sobrevivente feita à mão — mas a carga certa
é a de baixo, não `items`.

#### Qual das duas cargas recebe arma — e o vanilla é consistente

**`items` é bolso, e arma de tamanho real não vai ali.** As duas cargas não são intercambiáveis: o
jogo teve a escolha e decidiu. O `items` de `Outfit_Survivalist_Late`
(`PZ/media/lua/server/Items/Distributions.lua:3130-3158`) tem 17 entradas e é todo miudeza —
`Photo`, `Spork`, `Whistle`, `Whetstone`, `WaterBottle`, `Journal`, `Diary2`, comida. De arma, **só
canivete dobrável**: `KnifeButterfly` e `Handiknife`.

Arma de verdade está do outro lado, na seção `-- Weapons/Accessories` de `SurvivorItems`
(`PZ/media/lua/server/Items/Distribution_BagsAndContainers.lua:3218-3226`), que chega ao zumbi pela
`bags` do traje (`Distributions.lua:3151`): `Machete` 4, `ShotgunSawnoff` 10,
`DoubleBarrelShotgunSawnoff` 8, `Bag_ChestRig` 1.

Régua para um mod decidir a camada: **peso do item e `TwoHandWeapon`**. O que caberia num bolso vai
em `items`; o resto vai na mochila.

**Errar isso não produz erro nenhum** — a inserção funciona, o item aparece, só que no lugar errado
da ficção, e o `console.txt` fica limpo. Verificado in-game em 2026-08-12: item de mod com peso 2 no
`items` de `Outfit_Survivalist_Late` apareceu no LootZed a 1,2%, valor idêntico ao do `HerbalistMag`
vanilla (peso 2) da mesma janela — a escrita na tabela estava certa, a camada é que não. Só teste
in-game pega.

**A terceira rota — a arma *visível* nas costas do zumbi — não é nenhuma das duas.** É
`AttachedWeaponDefinitions`, mecanismo próprio lido na criação do zumbi, com gate de sandbox e de
dias sobrevividos; ver [definitions-lua.md](definitions-lua.md).

**Não confunda com as 28 listas `*Outfit` de `ProceduralDistributions.lua`** (`ToolStoreOutfit`,
`ArmyStorageOutfit`, `MedicalStorageOutfit`…). Aquelas são **arara e armário de loja de roupa** — o
sufixo `Outfit` ali quer dizer "roupa à venda", não "traje de zumbi". A diferença está na posição do
prefixo: `Outfit_X` é contêiner de zumbi em `Distributions`; `XOutfit` é lista de contêiner em
`ProceduralDistributions`.

### Um erro de digitação do próprio jogo derruba o LootZed

`ProceduralDistributions.lua:11366`, na lista `ClothingStorageAllJackets`:

```lua
			"Jacket_WhiteTINT", 10,7
```

O `7` solto depois do `10,` deixa a lista com **14 nomes para 15 pesos**. Como toda lista de loot é
um array plano alternando `nome, peso`, o desalinhamento propaga: a partir dali cada peso é lido
como nome e vice-versa.

**Sintoma:** abrir o LootZed num contêiner de roupa (guarda-roupa, cômoda) derruba com

```
java.lang.RuntimeException: No implementation found for function: getLootModifier(class java.lang.Double 7.0)
```

porque `SpawnRateChecker.lua:143` chama `ItemPickerJava.getLootModifier(itemName)` com o `7`.
Observado em 2026-08-12.

**É a única lista desalinhada do arquivo** — verificado comparando contagem de strings e de números
no bloco `items` de todas as listas. Vale como diagnóstico diferencial: ao investigar erro de loot
num mod, esse aqui **não é do mod**, acontece com o jogo limpo, e não há conserto do lado do mod
porque o arquivo é do jogo.

### 3. `BagsAndContainers` — o conteúdo da mochila, e a economia que ele permite

`PZ/media/lua/server/Items/Distribution_BagsAndContainers.lua` define **95 entradas**. A forma tem uma
sutileza que muda como um mod entra:

```lua
BagsAndContainers.SurvivorItems = {
	-- Survival Gear
	"Candle", 20,
	"CompassDirectional", 10,
	...
}

BagsAndContainers.SurvivorBag = {
	rolls = 2,
	items = BagsAndContainers.SurvivorItems,
	junk = { rolls = 1, items = { } },
	maxMap = 1,
	stashChance = 10,
}
```

**`SurvivorItems` é lista plana crua** — sem `rolls`, sem `items`, é o próprio array `nome, peso`. As
três bolsas (`SurvivorBag`, `SurvivorBag_Mid`, `SurvivorBag_Late`) apontam `items` para **a mesma
tabela, por referência**, e diferem só em `maxMap`. Consequência para mod: **um `table.insert` em
`SurvivorItems` alcança as três eras de uma vez** — e, pelo mesmo motivo, **não há como pôr item só
na era `_Late` sem desacoplar a referência**, o que quebraria outros mods.

O mesmo par existe para bandido: `BanditItems` + `BanditBag`/`_Early`/`_Mid`/`_Late`.

`stashChance` aparece aqui, e é o que o comentário do próprio arquivo descreve como a chance de vir
um mapa anotado junto.

### Quem escolhe o traje do zumbi

`PZ/media/lua/shared/NPCs/ZombiesZoneDefinition.lua` — **77 zonas**, cada uma listando trajes com
peso. A estrutura é rasa e só trata **aparência** (`name`, `toSpawn`, `chance`, `gender`, `room`,
`mandatory`, `beardStyles`); **não há item nenhum ali** — o loot vem do `Outfit_<Traje>` acima:

```lua
ZombiesZoneDefinition.Survivalist = {
	Survivalist = { name="Survivalist", chance=10 },
	Hunter = {
		name="Hunter",
		chance=10,
		beardStyles="Long:10;Chops:10;Goatee:10;Moustache:10;Full:10;BeardOnly:10",
	},
}
```

Cadeia completa: **zona do mapa → `ZombiesZoneDefinition` escolhe o traje → `Distributions.all.Outfit_<Traje>`
dá os itens do corpo e a mochila → `BagsAndContainers.<Bag>` enche a mochila.**

### 4. Por código, num zumbi específico — `addItemToSpawnAtDeath`

As três rotas acima são tabela e valem para zumbi que ainda vai nascer. Para dar um item a **um**
zumbi em runtime, a chamada é `IsoGameCharacter.addItemToSpawnAtDeath(InventoryItem)` (e o par
`clearItemsToSpawnAtDeath()`), pública segundo `javap` sobre `IsoGameCharacter` (buildid 24909800,
2026-09-14 — bytecode). O item entra numa lista de "soltar ao morrer", não no inventário.

**Zero uso em `PZ/media/lua`.** O uso observado é de mod publicado, em arquivo de `server/`:
`STEAM/3403870858/mods/Lifestyle/common/media/lua/server/LSOnHit.lua:55-56`:

```lua
			local item = instanceItem(mapName)
			target:addItemToSpawnAtDeath(item)
```

(mais `:68-69` e `:80-81`, mesmo idioma).

Para criar o zumbi que vai carregar: `addZombiesInOutfit(x, y, z, quantidade, traje, chanceFeminina)`,
que devolve `ArrayList` de `IsoZombie` — `PZ/media/lua/client/Tutorial/Steps.lua:830`
(`addZombiesInOutfit(..., 0, 1, "TutorialMom", 100):get(0)`) e `:1138` (`"TutorialDad", 0`); o 6º
argumento é porcentagem de sair mulher. `LuaManager$GlobalObject` declara sobrecargas de 6 a 17
argumentos (`javap`). Os usos do jogo são todos de cliente (tutorial, singleplayer).

Para achar zumbi já carregado: `getCell():getZombieList()` — sem uso no `media/`; uso em mod em
`STEAM/1299328280/mods/More Traits/42.20/media/lua/shared/MoreTraits .lua:1694`.

## Helpers que o jogo já dá

Em `Distributions.lua`, globais, para mod que quer **tirar** coisa em vez de somar:

- `ClearAllDistributionItems(_dist, _dorecursive)` — zera todo `items` da árvore.
- `RemoveItemFromDistribution(_dist, _item, _chance, _dorecursive)` — tira um item; `_chance` pode
  ser `false` para omitir e ainda assim passar `_dorecursive`.
- `DeepPrintDistributionTable(_dist, tab)` (`SuburbsDistributions.lua:197`) — debug.

Duas tabelas soltas no topo de `SuburbsDistributions.lua`, fáceis de não achar:

- `NoContainerFillRooms` (`:1`) — salas que **não** recebem preenchimento automático.
- `WeaponUpgrades` (`:3`) — que acessório pode nascer em qual arma.

## `OnFillContainer` — o gancho por contêiner, e o argumento que nem sempre é contêiner

As tabelas acima são a rota declarativa: o mod diz *o que pode nascer*. `OnFillContainer` é a outra
porta — dispara **depois** que o motor acabou de encher um contêiner, com `(roomType, containerType,
container)`, e é por onde se inspeciona ou se marca o que acabou de nascer ali. O único assinante do
jogo é o `LootLog` (`PZ/media/lua/server/Items/LootLog.lua:34`), atrás do gate `ISLootLog.cheat`
(`:8-9`) — ou seja, **em jogo normal nenhum código do jogo escuta este evento**, e não há exemplo
canônico de uso.

**O terceiro argumento não é sempre um `ItemContainer`.** `zombie.inventory.ItemPickerJava` dispara o
evento em 10 pontos; em 3 deles o argumento é o campo `bags` do contêiner de distribuição — um
`ItemPickerJava$ItemPickerContainer`, que é a **definição** da distribuição (`items[]`, `rolls`,
`procedural`, `proceduralItems`, `junk`, `bags`, …) e **não tem `getItems()`**. Os outros 7 passam
`ItemContainer` de verdade, direto ou via `InventoryContainer.getItemContainer()`.

Chamar `container:getItems()` sem checar o tipo estoura em Java:

```
attempted index: getItems of non-table: zombie.inventory.ItemPickerJava$ItemPickerContainer@66903fe7
```

vindo de `KahluaThread.tableget`. Não é caso raro — **42 ocorrências num único carregamento de
mundo**, pela cadeia `fillContainer` → `fillContainerInternal` → `fillContainerTypeInternal` →
`rollItemInternal` → `rollProceduralItemInternal` → `doRollItemInternal` → `triggerEvent`, chamada
pelo `LoadGridsquarePerformanceWorkaround` quando o chunk carrega.

Duas consequências que fazem a falha parecer intermitente:

- O disparo é envolvido por `pcall` do lado Java (`LuaCaller.protectedCallVoid`), então **só o
  handler daquele disparo morre** — o jogo não trava e o Lua do mod continua carregado.
- O evento do **contêiner** em si dispara depois, quando `fillContainerTypeInternal` retorna, e esse
  passa `ItemContainer` de verdade. Então o mod funciona no armário e falha calado na bolsa que
  nasceu dentro dele.

O `LootLog` do jogo cairia na mesma armadilha: `LootLog.lua:11` chama `itemContainer:getItems()` sem
checar tipo. Só não quebra porque o gate do `:8-9` o mantém desligado.

O idioma para mod é testar antes:

```lua
local function OnFillContainer(roomType, containerType, container)
    if not instanceof(container, "ItemContainer") then
        return
    end
    -- ...
end
```

E vale o limite escrito no cabeçalho do próprio `LootLog` (`:3`): item de *randomized world story*
**não passa por aqui** — é outro sistema, na seção seguinte.

*(As afirmações sobre `ItemPickerJava` vieram de `javap` sobre o `.jar`, não do `media/` — ver
"Como isto foi levantado — bytecode do `.jar`", mais abaixo, para o baseline diferente delas.)*

### Filtrar por `roomType`/`containerType` custa um censo das chaves

Quem escuta `OnFillContainer` (ou lê `Distributions` direto) quase sempre quer restringir a um tipo
de cômodo e a um tipo de móvel. As chaves são strings livres do próprio arquivo, e **o nome do móvel
na tela não é a chave** — filtrar pelo nome óbvio perde a maior parte dos casos. O quarto serve de
demonstração:

- `bedroom` (`PZ/media/lua/server/Items/Distributions.lua:4887`) tem nove contêineres:
  `cardboardbox`, `crate`, `desk` (`:4935`), `dresser` (`:4942`), `locker` (`:4951`), `plankstash`,
  `sidetable` (`:4971`), `smallbox` e `wardrobe` (`:4997`).
- **`locker` e `wardrobe` apontam para as mesmas quatro listas procedurais** — `WardrobeChild`,
  `WardrobeClassy`, `WardrobeGeneric`, `WardrobeRedneck` (`:4951-4957` e `:4997-5004`). São o mesmo
  armário de quarto por duas chaves; filtrar só `wardrobe` descarta metade deles.
- **Quarto não é um room type só.** `kidsbedroom` (`:10545`) é chave separada, com `counter`, `desk`,
  `dresser`, `filingcabinet`, `locker`, `shelves`, `sidetable`, `wardrobe` e `other` próprios,
  apontando para as listas `*Child`. `hoarderbedroom` (`:9719`) é outra, e só tem `other` →
  `JunkHoard`. Existe ainda `ww_bedroom` (`:15683`).

O efeito prático: o mesmo item pode nascer por meia dúzia de pares `(roomType, containerType)`
diferentes. `Diary1`/`Diary2` estão em `BedroomDresser`
(`PZ/media/lua/server/Items/ProceduralDistributions.lua:3944`), `BedroomDresserChild` (`:4183`),
`BedroomSidetable` (`:4766`), `BedroomSidetableChild` (`:4898`), `WardrobeChild` (`:51529`),
`WardrobeGeneric` (`:51989`) e `JunkHoard` (`:28996`), entre outras — um filtro
`bedroom` × `wardrobe`/`sidetable`/`dresser` pega só parte disso, e **o que ficou de fora não dá
erro nenhum**: o item nasce normal, o handler simplesmente não é chamado para ele.

**E enumerar room types não fecha o filtro.** A sala `all` (`:79-3774`) não é só a sala do bolso de
zumbi descrita mais adiante: ela declara móveis comuns, entre eles `dresser` (`:397`), `locker`
(`:612`), `sidetable` (`:1044`) e `wardrobe` (`:1294`), este último apontando para
`WardrobeGeneric`/`WardrobeClassy`/`WardrobeRedneck` — exatamente as listas do quarto. Como o nome do
cômodo vem da definição do mapa e não de uma lista fechada, sempre haverá room type que o mod não
previu, e ele não fica vazio: o móvel recebe loot assim mesmo.

O caso observado em runtime: um `wardrobe` num cômodo `corridor` entregou `Diary2`, e a string
`corridor` **não aparece em nenhum dos `.lua` de distribuição**. Filtro por sala, portanto, é
sempre parcial; filtro robusto é pelo contêiner, com `anyRoom` na sala. Para dimensionar: `wardrobe`
aparece como chave de contêiner em 19 room types, `dresser` em 23, `sidetable` em 25 e `locker` em
35 — mais o `all`.

Para levantar as chaves de uma área antes de filtrar, o par de greps é este (room type e contêiner
se distinguem pelo nível de indentação, um e dois tabs):

```sh
grep -nE "^\s+[A-Za-z_0-9]*[Bb]edroom[A-Za-z_0-9]*\s*=\s*\{" Distributions.lua
sed -n '4887,5006p' Distributions.lua | grep -nE "^\s{2,3}[A-Za-z_0-9]+\s*=\s*\{"
```

## Item em cima da mesa — o que é item e o que é só sprite

Tudo acima enche **contêiner**. Mas o que se vê ao entrar numa casa tem duas origens diferentes, e
**só uma delas se pega**:

| Na tela | O que é de fato | Quem produz |
|---|---|---|
| Bancada/prateleira "cheia" de tralha | **Sprite de overlay** desenhado sobre o móvel, escolhido pela quantidade de itens **dentro** do contêiner | `WorldFiller.lua` + `ContainerOverlays` |
| Caneca, livro, faca solta na mesa | **`IsoWorldInventoryObject`** — um `InventoryItem` de verdade, com deslocamento próprio dentro do quadrado | randomized world stories (Java), jogador, ou `AddWorldInventoryItem` |

Confundir os dois é o erro caro: mexer na tabela de loot muda o **conteúdo** do armário e nunca o
desenho. E nenhum dos dois é a mesma coisa que a tralha **desenhada dentro do próprio sprite** do
móvel pelo artista, que não é sistema nenhum.

### 1. O overlay — visual, sem item algum

`PZ/media/lua/server/Items/WorldFiller.lua` é o mapa, e o nome engana: não enche mundo nenhum, é
tabela **sprite de contêiner → sprites de tralha**, gerada pelo TileZed (o cabeçalho diz isso em
`:1`). A forma, em `:4`:

```lua
overlayMap["appliances_refrigeration_01_16"] = {{ name = "other", tiles = {"food_01_90", "food_01_94"} }, ...}
```

`name` é a sala/loja a que a entrada serve (`"other"` é o caso geral: 375 das 488 entradas; o resto é
`grocery`, `gunstore`, `pharmacy`, `clothesstore`…) e `tiles` traz **dois** sprites. O registro é
`getContainerOverlays():addOverlays(overlayMap)` (`:214`), e **este arquivo é o único do jogo que
chama `getContainerOverlays()`** — os outros treze `*Overlays.lua` da mesma pasta chamam
`getTileOverlays()`, que é outro registro (piso, parede, sujeira) e não tem relação com contêiner.

O consumo é Java (`zombie.iso.ContainerOverlays.updateContainerOverlaySprite`, ver "Como isto foi
levantado"): a entrada sai de `pickRandom(nomeDaSala, x, y, z)` — determinístico pela posição, com
fallback para `"other"` — e os dois sprites são os campos `fewItems`/`manyItems`, escolhidos pelo
`container:getItems():size()`. **Contêiner vazio não recebe overlay**: é por isso que a prateleira
"esvazia" na tela depois de saqueada.

Em Lua o gatilho é `ItemPicker.updateOverlaySprite(objeto)` — ao transferir item
(`PZ/media/lua/client/TimedActions/ISInventoryTransferAction.lua:682` e `:685`), ao saquear tudo
(`client/ISUI/ISInventoryPage.lua:1425`) e pelo comando de servidor
(`server/ClientCommands.lua:260`). `ItemPicker` **é** a classe Java: `server/Items/ItemPicker.lua:1`
é a linha única `ItemPicker = ItemPickerJava`.

**Consequência para mod:** somar item numa lista procedural muda o que sai do contêiner e **nunca** o
sprite. Overlay novo é entrada nova no `overlayMap`, sprite a sprite — e o arquivo do jogo é gerado,
então o caminho de mod seria chamar `addOverlays` com tabela própria (se ela **soma** ou substitui não
foi verificado — ver "Pontos a confirmar").

### 2. O loot do contêiner é rolado preguiçosamente, no mesmo caminho do overlay

`ItemPicker.doOverlaySprite(quadrado)` percorre os objetos do quadrado e, para cada contêiner ainda
não explorado, chama `fillContainer` e marca `setExplored(true)` antes de pedir o overlay; no fim
marca `square:setOverlayDone(true)`. Ou seja, **o quadrado só é sorteado uma vez**, na primeira vez
que é processado — não na geração do mapa. O mesmo `ItemPicker.fillContainer` aparece na abertura de
contêiner (`client/TimedActions/ISOpenContainerTimedAction.lua:27`,
`server/ISObjectClickHandler.lua:311`, `client/ISUI/ISInventoryPage.lua:1108`, `:1423`, `:1518`).

`[levantado 2026-10-27]` A de `:1108` está dentro de `ISInventoryPage:selectContainer(button)`
(`client/ISUI/ISInventoryPage.lua:1088`), que é **o** momento "jogador abriu este contêiner" na janela
de loot: toca o som de abrir (`playContainerOpenCloseSounds`), troca `self.inventoryPane.inventory`
e retorna cedo, sem trocar, se o `IsoThumpable` está trancado para o personagem (`:1094-1097`). A
seleção automática também passa por ela (`selectButtonForContainer`, `:1143-1160`). É cliente, e o
próprio trecho traz o padrão SP × MP para mexer no contêiner: `if not isClient()` faz direto, senão
pede ao servidor (`:1107-1111`). Mod que precise reagir à abertura envolve essa função — chamando o
original primeiro, para respeitar o retorno cedo do trancado.

Isso explica o comportamento que atrapalha teste de mod: **mod de loot carregado depois que o quadrado
já foi visto não muda nada ali** — aquele contêiner já está `explored`. Teste de distribuição pede
save novo ou área nunca visitada.

### 3. Item de verdade na mesa — randomized world stories

Não vem de `Distributions` nem de `ProceduralDistributions`: vem das *randomized world stories*, que
são **classes Java** em `zombie.randomizedWorld.*` (`randomizedBuilding` com 45 classes,
`randomizedDeadSurvivor` 33, `randomizedZoneStory` 42, `randomizedVehicleStory` 26, `randomizedRanch`
2). O disparo é `RandomizedBuildingBase.ChunkLoaded(IsoBuilding)`, com três portas: o prédio precisa
estar `isFullyStreamedIn()`, ter `def.seen == false` (marcado `true` logo depois — **roda uma vez por
prédio, para sempre**) e não passar de `maximumRoomCount`. Passando, o jogo varre
`IsoWorld.getRandomizedBuildingList()`, roda as histórias `alwaysDo` e sorteia uma das demais.

Quem produz a tralha doméstica é a `RBBasic`, com uma rotina por cômodo — `doKitchenStuff`,
`doBathroomStuff`, `doLivingRoomStuff`, `doBedroomStuff`, `doKidsBedroomStuff`, `doLaundryStuff`,
`doOfficeStuff`, `doCafeStuff`, `doGroceryStuff`… — e três geradores de bagunça de superfície:
`generateCounterClutter`, `generateSinkClutter` e `generateKitchenStoveClutter`. Em cima disso há o
pacote `randomizedBuilding/TableStories/`: `RBTSBreakfast`, `RBTSDinner`, `RBTSSandwich`, `RBTSSoup`,
`RBTSDrink`, `RBTSFoodPreparation`, `RBTSButcher`, `RBTSSewing` e `RBTSElectronics` — a mesa posta, a
costura interrompida —, sorteadas por `checkForTableSpawn` contra um `TABLE_STORY_CHANCE`.

**Para testar in-game** existe atalho: com `-debug`, o menu de contexto de debug traz "Basic Randomized
Building (including table stories)" e a lista de histórias, para forçar uma sobre o prédio sob o cursor
(`PZ/media/lua/client/DebugUIs/DebugContextMenu.lua:1346`, lista em `:1314-1348`).

### 4. A receita canônica de "pôr em cima do móvel"

`RandomizedBuildingBase.addWorldItem(tipo, quadrado, objeto)` é o que as histórias usam, e é o molde a
copiar em Lua:

1. **porta de acesso** — `square:hasAdjacentCanStandSquare()`: item que ninguém alcança não nasce;
2. **porta de sandbox** — `removeStoryLoot` e `ItemPickerJava.getLootModifier(tipo)`: item de história
   obedece à raridade do sandbox como qualquer loot;
3. **altura** — `z = objeto:getSurfaceOffsetNoTable() / 96`. O `96` é a altura da textura 1X em pixels,
   e é a mesma constante do cursor de largar item do jogador
   (`PZ/media/lua/server/BuildingObjects/ISPlace3DItemCursor.lua:232-234`, com o comentário do próprio
   jogo explicando o `/96`);
4. **posição no quadrado** — `x` e `y` por `Rand.Next(0.3, 0.9)`, mais `randomizeWorldZRotation()`;
5. **criação** — `InventoryItemFactory.CreateItem(tipo)` + `setAutoAge()`, e a colocação por
   `ItemSpawner.spawnItem(item, quadrado, x, y, z)`.

E `isTableFor3DItems(objeto, quadrado)` é o teste de "isto é mesa?": exige
`hasAdjacentCanStandSquare()`, `getSurfaceOffsetNoTable() > 0`, quadrado sem água e objeto sem fluido,
e **rejeita quem tem a propriedade de tile `BedType`** — cama tem superfície e não recebe tralha.

O que faz um móvel ter superfície são as propriedades de tile `Surface`, `IsSurfaceOffset`,
`IsTableTop` e `ItemHeight` — censo e cruzamento com `container =` em [tiles.md](tiles.md), seção
"Superfície e contêiner — o móvel pode ser um, outro, os dois ou nenhum".

### 5. O que some sozinho — o sandbox de limpeza

Item largado no chão ou na mesa tem prazo. Em `PZ/media/lua/shared/Sandbox/Apocalypse.lua:71-73`:

```lua
    WorldItemRemovalList = "Base.Hat, Base.Glasses, Base.Maggots, Base.Slug, ...",
    HoursForWorldItemRemoval = 24.0,
    ItemRemovalListBlacklistToggle = false,
```

O contrato está no tooltip (`PZ/media/lua/shared/Translate/EN/Sandbox.json:148-153`): a lista diz
**quais** tipos somem depois de `HoursForWorldItemRemoval` horas desde que foram largados; `0` desliga;
`ItemRemovalListBlacklistToggle` inverte a lista em whitelist (some tudo que **não** está nela). E a
frase que importa para teste: *"Items are removed the next time that part of the map is loaded"* — a
limpeza acontece na carga do chunk, não em tempo real.

Não confunda com `LootItemRemovalList` (`Sandbox.json:343-344`), que é outra coisa: tipos que **não
nascem** como loot comum. O par dela é `RemoveStoryLoot` (`:346`), que estende o veto às histórias
descritas acima.

### 6. A rota de mod — o que dá e o que não dá

**Não dá para registrar história nova.** `IsoWorld.getRandomizedBuildingList()` é lista de instâncias
Java de `RandomizedBuildingBase`, e Lua não estende classe Java — o que sobra é ler e forçar as que
existem (é o que o menu de debug faz).

A rota real é `Events.LoadGridsquare` + `square:AddWorldInventoryItem(...)`, com um marcador de "já
nasceu" para o item não voltar toda vez que o chunk recarrega. O molde publicado está em
`STEAM/2335368829/mods/Authentic Z - Current/42/media/lua/client/AuthenticZ_GroundItemSpawner.lua` —
registro em `:195`, colocação em `:142-143` e o marcador em `:167-172`, gravado no `getModData()` de um
`IsoObject` invisível do quadrado, com `transmitModData()`. **Ressalva:** o arquivo inteiro está dentro
de um bloco de comentário (`--[[` em `:15`, `]]` em `:208`), ou seja, está desligado na versão
publicada — vale como idioma, não como prova de que roda. São 34 `.lua` de mod em `STEAM/` citando
`AddWorldInventoryItem`, e a maioria usa para largar item em runtime, não para povoar o mundo (ex.:
`STEAM/3775407541/mods/RadArchery/42/media/lua/server/RadArcheryRecovery.lua:161`, flecha que cai no
chão).

As assinaturas de `AddWorldInventoryItem` e o resto da rota manual estão na seção seguinte.

### Como isto foi levantado — bytecode do `.jar`

As afirmações sobre `ContainerOverlays`, `ItemPicker.doOverlaySprite`, `RandomizedBuildingBase`,
`RBBasic` e o pacote `TableStories` **não têm `caminho:linha` no `media/`**: esse código é Java. Vieram
de `javap` sobre as classes de `PZ/projectzomboid.jar` (a JDK 21 instalada na máquina traz o `javap`;
`unzip` extrai o `.jar`), lendo assinatura e chamadas do bytecode — nome de método, constante e ordem
de chamada são legíveis; corpo de método não vira código-fonte.

É evidência do próprio jogo, e ganha da doc da comunidade. Mas tem baseline **diferente** do resto da
árvore: o `media/` sobrevive a patch que só toca o `.jar` — e o patch de 2026-08-22 foi exatamente esse
caso (ver [../index.md](../index.md)). Afirmação daqui é a que envelhece primeiro. Ver
[../fontes-externas.md](../fontes-externas.md), "Hierarquia de verdade".

## Soltar item no mundo por código — a rota fora das tabelas

Tudo acima é a rota declarativa: o motor preenche o contêiner e o mod entra pelas tabelas. A rota
manual não passa por tabela nenhuma e serve para materializar loot em resposta a um evento — ler um
bilhete, terminar uma tarefa. São três chamadas, e nenhuma delas é óbvia de achar.

**Colocar o item num quadrado** — `AddWorldInventoryItem(...)` sobre o `IsoGridSquare`. Uso observado
em `PZ/media/lua/client/DebugUIs/Scenarios/Trailer3Scenario.lua:240`:

```lua
local sq = getCell():getGridSquare(7098, 8369, 0);
sq:AddWorldInventoryItem("Base.Plank", ZombRand(0.1, 0.5), ZombRand(0.1, 0.5), 0);
```

`x`/`y` são deslocamento **dentro** do quadrado, e `ZombRand(0.1, 0.5)` é o idioma do próprio jogo
para espalhar o que cai junto. O item nasce **solto no chão**: não há contêiner envolvido, e nada
aqui cria bolsa nem agrupa os itens. Para pousar em cima de um móvel em vez do chão, o `z` sai da
superfície do objeto — ver a receita em "A receita canônica de pôr em cima do móvel", acima.

**O primeiro argumento não é só string.** `IsoGridSquare` declara **dez** sobrecargas de
`AddWorldInventoryItem` (`javap`, ver "Como isto foi levantado"): as três formas de primeiro
argumento são `String` (o full type), `InventoryItem` (item já instanciado) e `ItemKey`, cada uma com
as variantes de 4, 5 e 6 argumentos — os extras são `boolean`. Quem já tem o item na mão passa o
próprio item e evita um `instanceItem` (é o que os mods de `STEAM/` fazem). O retorno é o
`InventoryItem` colocado, e a única sobrecarga que devolve `void` é a de `(String, float, float,
float, int)`.

**Os dois booleanos — e por que a forma de 4 argumentos já sincroniza.** As formas curtas só
completam argumento: `(String, x, y, z)` chama `(…, true)`, que chama `(…, true, false)`; a cadeia
de `InventoryItem` completa do mesmo jeito. Na de seis argumentos com `String`, o 1º booleano liga
`InventoryItem.setAutoAge()` e o 2º escolhe a sincronização: **no servidor** (`GameServer.server`),
com o 2º em `false` ela chama `IsoWorldInventoryObject.transmitCompleteItemToClients()`; com `true`,
chama `InventoryItem.SynchSpawn()` no lugar. Ou seja, a chamada de 4 argumentos feita do lado
servidor **já transmite o item aos clientes** — é por isso que as `complete()` do jogo largam item no
chão sem sync nenhuma depois (`PZ/media/lua/shared/Vehicles/TimedActions/ISUninstallVehiclePart.lua:77`,
`ISRemoveBurntVehicle.lua:151`). Lido por `javap -c` sobre `zombie/iso/IsoGridSquare.class` (buildid
24909800, 2026-09-14 — afirmação de **bytecode**, que um patch só do `.jar` invalida sem tocar o
`media/`).

**Achar um quadrado livre dentro de um prédio** — `BuildingHelper.getFreeTileFromBuilding(building)`,
em `PZ/media/lua/shared/Util/BuildingHelper.lua:44`. O contrato que o nome não entrega:

- exige um **`BuildingDef`**, não um `IsoBuilding` — a função testa
  `instanceof(building, "BuildingDef")` (`:46`) e, para qualquer outra coisa, cai fora do `if` e
  **devolve `nil` em silêncio**. De um `IsoBuilding` se chega com `:getDef()`;
- **sorteia um cômodo por chamada** — `roomList:get(ZombRand(roomCount))` (`:55`) seguido de
  `getCell():getFreeTile(room)` (`:58`). Chamar duas vezes, para dois itens, dá dois cômodos
  diferentes: não existe "no mesmo lugar" sem guardar o quadrado da primeira chamada;
- o laço é `while square == nil do` (`:49`) **sem saída**. Prédio cujos cômodos nunca devolvam
  quadrado livre trava a chamada em vez de devolver `nil` — e trava em silêncio, sem erro e sem
  linha de log. Que é descuido e não contrato se vê na irmã dela no mesmo arquivo,
  `getFreeTilesFromRandomRoomInBuilding` (`:3`), que faz o mesmo sorteio e desiste em
  `timeout > 30` (`:15`, `:18-19`). Mod que precise disto faz bem em reimplementar com limite de
  tentativas em vez de chamar esta.

**Qual quadrado, dentro do cômodo, é o Java que decide.** `IsoCell.getFreeTile(RoomDef)` percorre
todos os retângulos do cômodo (`RoomDef.rects`), no andar dele (`RoomDef.level`), guarda cada
quadrado cujo `isFree(false)` é verdadeiro e devolve um deles por `Rand.Next(n)` — sorteio uniforme
entre os livres, `nil` se não houver nenhum. Consequência para quem larga loot assim: o item pode
cair em qualquer andar do prédio, no andar do cômodo sorteado, e dois itens com duas chamadas caem
em quadrados (e cômodos) independentes. Lido por `javap -c` sobre `zombie/iso/IsoCell.class`
(buildid 24909800, 2026-09-14 — bytecode).

**Chegar ao quadrado a partir de um contêiner** — `container:getParent():getSquare()`, idioma do
jogo em `PZ/media/lua/server/Items/LootLog.lua:18-19`. O `getParent()` pode ser `nil` — contêiner
sem objeto no mundo —, e o próprio jogo testa antes de usar.

**Voltar ao prédio mais tarde — pela coordenada, não pelo id.** Quando o loot sai *depois* da geração
(o jogador lê o bilhete longe dali), o prédio tem de ser guardado no item. `getCell():getBuilding(`
tem **zero** ocorrência em `PZ/media/lua` e nos mods de `STEAM/` (levantado 2026-09-10): não há volta
com lastro a partir de um id de prédio. A que tem uso no jogo é guardar `x`/`y`/`z` do quadrado e
refazer `getCell():getGridSquare(x, y, z)` (`PZ/media/lua/server/ClientCommands.lua:16`) →
`square:getBuilding()` → `:getDef()` (`PZ/media/lua/client/DebugUIs/DebugContextMenu.lua:151`,
`:153`).

**Do lado servidor, sem sync extra.** `PZ/media/lua/server/Traps/STrapGlobalObject.lua` abre com
`if isClient() then return end` (`:1`) e larga item no chão com `square:AddWorldInventoryItem(...)` em
`:603` e `:614`, sem nenhuma função de sincronização depois — enquanto o mesmo arquivo chama
`sendAddItemToContainer` quando o destino é inventário (`:322`, `:362`). É o uso que sustenta chamar
`AddWorldInventoryItem` de um handler de `OnClientCommand`, e o bytecode fecha o motivo: a forma de 4
argumentos transmite sozinha do lado servidor (ver "Os dois booleanos", acima). Observado no cliente
em 2026-09-14, depois de restart do servidor; a chegada ao vivo segue em "Pontos a confirmar".

**Móvel com contêiner criado por código — `addTileObject(sprite)`, e ele não transmite.** O molde do
jogo é o caixote do mapa Bunker, em `PZ/media/lua/shared/Items/SpawnItems.lua:64-69`:

```lua
            local crate = sq:addTileObject("carpentry_01_16");
            crate:getContainer():clear();
            crate:getContainer():setExplored(true);
            table.insert(guns, crate:getContainer():AddItem("Base.AssaultRifle"));
```

`IsoGridSquare.addTileObject(String)` é `IsoObject.getNew` → `AddTileObject` →
`MapObjects.newGridSquare`/`loadGridSquare`, **sem transmit nenhum** (`javap -c` sobre
`zombie/iso/IsoGridSquare.class`, buildid 24909800, 2026-09-14 — bytecode). O `SpawnItems.lua` roda em
`OnNewGame`, então não precisa. Em servidor, o idioma do jogo para objeto posto por código é
`if isServer() then obj:transmitCompleteItemToClients() end` logo depois
(`PZ/media/lua/shared/Moveables/ISMoveableSpriteProps.lua:1989-1991`, com `IsoTree`).

**Objeto com mais de um contêiner.** Geladeira é `fridge` + `freezer` no mesmo `IsoObject`: percorrer
`getContainerCount()`/`getContainerByIndex(i)` e não só `getContainer()` —
`PZ/media/lua/shared/Moveables/ISMoveableSpriteProps.lua:1302-1303`. Item posto em contêiner de móvel
do lado servidor segue com `sendAddItemToContainer(cont, item)` sob `isServer()`
(`PZ/media/lua/shared/Items/OnBreak.lua:87-91`).

**`ItemSpawner` é a colocação do Java, e é pública**: `spawnItem(String|InventoryItem, IsoGridSquare,
x, y, z[, boolean])`, `spawnItem(String|InventoryItem, ItemContainer[, boolean])` e
`spawnItems(String|InventoryItem, int, ItemContainer)` (`javap`, bytecode). Sem uso em `media/lua`; é o
que o motor dos mapas anotados chama (seção seguinte).

### Prédio e cômodo são metadado do mapa — e se acham com o chunk descarregado

`IsoMetaGrid` responde "que prédio/cômodo tem aqui" sem precisar do quadrado: `getRoomAt(x, y, z)`
(uso Lua em `PZ/media/lua/client/DebugUIs/DebugChunkState/DebugChunkState_SquarePanel.lua:108`,
`getWorld():getMetaGrid():getRoomAt(...)`), e, sem uso em Lua achado, `getBuildingAt(x, y[, z])`,
`getBuildingAtRelax`, `getAssociatedBuildingAt` (`javap`). A evidência de que funciona **longe** do
jogador é o próprio motor dos mapas anotados: `StashSystem.checkStashItem` chama
`getRoomAt(buildingX, buildingY, 0)` com a coordenada da stash no momento em que o mapa nasce, e dali
`RoomDef.getBuilding().isHasBeenVisited()` (bytecode).

Métodos públicos que valem conhecer (`javap`, buildid 24909800), nenhum com uso em Lua achado salvo
onde citado:

- `BuildingDef`: `getRooms()` (uso em `PZ/media/lua/shared/Util/BuildingHelper.lua:9`), `getRoom(nome)`,
  `containsRoom(nome)`, `getRandomRoom`, `getFreeSquareInRoom`, **`isFullyStreamedIn`** (o teste de
  "carregou inteiro" que o stash usa antes de executar), `isHasBeenVisited`, `setAllExplored`,
  `getX/Y/X2/Y2/W/H`, `getID`, `getIDString`, `getKeyId`, `getRoomsNumber`;
- `RoomDef`: `getName` (uso via `IsoRoom:getRoomDef():getName()` em
  `PZ/media/lua/server/Farming/SFarmingSystem.lua:164`), `getBuilding`, `getIsoRoom`,
  `getX/Y/X2/Y2/Z/W/H`, `getArea`, `getFreeSquare`, `getRandomSquare(Predicate)`, `isInside`, `contains`;
- `IsoRoom`: `getSquares`, `getRandomFreeSquare`, `getRoomDef`.

### Rolar uma tabela de loot a partir do Lua

As tabelas de `Distributions`/`ProceduralDistributions` são lidas pelo Java; o Lua alcança o sorteio
pelo par que o painel de teste de loot usa
(`PZ/media/lua/client/DebugUIs/ISLootStressTestUI.lua:258-268`):

```lua
		local contdistrib = ItemPickerJava.getItemContainer(roomName, contName, procName, false);
		if contdistrib then
			ItemPickerJava.doRollItem(contdistrib, container, self:getLootDensity(), self.chr, true, false);
		end
```

**Contrato de `getItemContainer(sala, movel, listaProcedural, junk)`** (`javap -c`, bytecode): busca
`rooms[sala]` → `containers[movel]`; se esse móvel é `procedural`, procura na lista dele a entrada com
`name == listaProcedural` e devolve `ProceduralDistributions[listaProcedural]` (ou o `junk` dela); se não
é procedural, devolve o próprio móvel (ou o `junk` dele). Consequência: **lista procedural só se
alcança por uma (sala, móvel) que a cite**, e móvel procedural pedido sem o nome da lista devolve a
entrada sem `items`.

**Parâmetros**, pela tabela de variáveis locais do `.class` (`javap -l`): `doRollItem(containerDist,
container, zombieDensity, character, doItemContainer, roomDist)` — o `float` é densidade de zumbi, e o
painel passa de `1` a `12` (`ISLootStressTestUI.lua:271-290`); `rollItem(containerDist, container,
doItemContainer, character, roomDist)`; `rollContainerItem(bag, character, containerDist)`;
`fillContainerType(roomDist, container, roomName, character)`. `ItemPickerJava` é global também no
servidor (`PZ/media/lua/server/RandomizedWorldContent/StoryTable_Initialization.lua:9`).

## O motor dos mapas anotados — `StashDescriptions` + `StashSystem`

O "mapa anotado" que aparece em mochila de sobrevivente (o `stashChance` acima) é dado Lua mais motor
Java. É o sistema do jogo que mais se parece com "spawnar loot num lugar escolhido", e é por isso que
vale conhecer inteiro.

**O dado** mora em `PZ/media/lua/shared/StashDescriptions/`, um arquivo por cidade, montado por
`StashUtil.lua`: `StashUtil.newStash(name, type, item, customName)` (`:3-16`) insere na **global**
`StashDescriptions`; `addStamp` (`:18`) e `addStampV2` (`:33`) marcam o mapa; `addContainer(containerType,
containerSprite, containerItem, room, x, y, z)` (`:51-64`) descreve o que nasce. Exemplo em
`PZ/media/lua/shared/StashDescriptions/RosewoodStashDesc.lua:4-14`:

```lua
local stashMap = StashUtil.newStash("RosewoodStashMap1", "Map", "Base.RosewoodMap", "Stash_AnnotedMap");
stashMap.zombies = 5;
stashMap.buildingX = 8238
stashMap.buildingY = 11555
stashMap.spawnTable = "GunCache1";
stashMap:addContainer("GunBox",nil,"Base.Bag_DuffelBagTINT",nil,nil,nil,nil);
```

Móvel novo por sprite em `x, y, z`: `EkronStashDesc.lua:19`; `barricades`: `:25`. **`spawnTable` é uma
sala de `Distributions` criada só para isso** — `FoodCache1 = { FoodBox = { rolls = 12, ...`
(`Distributions.lua:21034-21036`), `GunCache1` (`:21196`), `ToolsCache1` (`:22441`); `containerType` é o
móvel dela.

**O motor** é `zombie.core.stash.StashSystem` (mais `Stash`, `StashBuilding`, `StashContainer`,
`StashAnnotation`). Fluxo lido por `javap -c` (buildid 24909800, 2026-09-14 — bytecode):

1. **O mapa nasce** → `checkStashItem(item)`: sai se é cliente; testa `item.getStashChance()` contra o
   sandbox `annotatedMapChance`; entre as stashes cujo `item` é o full type do mapa, fica com as que
   passam `spawnOnlyOnZed` (pelo pai do contêiner) e `daysToSpawn` (contra `getDaysSurvived`) e cujo
   prédio **não foi visitado**; sorteia uma e `doStashItem` aplica nome e marcações ao `MapItem`.
2. **O mapa é lido** → `prepareBuildingStash(nome)`: põe `(nome, buildingX, buildingY)` em
   `buildingsToDo`; se o prédio já está `isFullyStreamedIn`, executa na hora.
3. **O prédio carrega** → `doBuildingStash(BuildingDef)` (chamado a partir de `IsoChunk`, entre outros):
   marca o prédio todo explorado; roda `doSpecificBuildingProperties`; percorre os quadrados do prédio e,
   em todo contêiner cujo tipo a sala `spawnTable` conhece, faz `clear()` +
   `ItemPickerJava.fillContainerType(sala, contêiner, "", null)` + overlay + `setExplored(true)`; põe
   barricada em porta/janela com `Rand.Next(100) < barricades`.
4. `doSpecificBuildingProperties`, por `addContainer`: o quadrado é `(x, y, z)` se dado, senão um
   quadrado livre de um cômodo com o nome `room` (ou de qualquer cômodo); `containerItem` →
   bolsa criada, recheada por `rollContainerItem` e posta com `ItemSpawner.spawnItem`; `containerSprite`
   → `IsoThumpable` novo com `ItemContainer` do tipo pedido, via `AddSpecialObject`. Depois armadilhas
   (`IsoTrap`) e `zombies` por cômodo (`VirtualZombieManager.addZombiesToMap(n, roomDef, false)`).

`buildingsToDo` e a lista de mapas lidos vão para o save (`StashSystem.save`/`load`).

**Para mod:** o dado é Lua global, então um mod **talvez** registre stash própria somando um
`newStash` num arquivo seu — nenhum mod de `STEAM/` faz isso, e não foi testado (ver "Pontos a
confirmar"). O motor em si não é chamável de forma útil do Lua. Um mod que queira o mesmo efeito com
outros gatilhos reimplementa com as peças desta página.

## Pontos a confirmar

- **Se o item largado por `AddWorldInventoryItem` do lado servidor chega ao cliente na hora, sem
  restart.** O mecanismo está resolvido no bytecode (2026-09-14, "Os dois booleanos", na rota manual
  acima). Observado em servidor dedicado em 2026-09-14: `Base.Money` largado às 12:57
  (`USER/Logs/logs_2026-09-14/2026-09-14_12-49_DebugLog-server.txt:2248`) foi achado pelo jogador
  no quadrado logado — mas só depois de dois restarts do servidor, quando o cliente já o recebe com
  o chunk salvo. A chegada ao vivo, que é o que `transmitCompleteItemToClients` cobre, não foi
  isolada. Também em aberto: se a sobrecarga de
  seis argumentos com `InventoryItem` tem o mesmo ramo — o corpo dela trata cadáver, gerador e
  animal antes, e não foi lido até a sincronização.
- **O que `getCell():getGridSquare(x, y, z)` devolve com o chunk descarregado**, no servidor. Importa
  para a volta ao prédio pela coordenada; nenhum uso do jogo testa o retorno.
- **Se é a sala `all` que serve o cômodo sem entrada própria em `Distributions`.** Confirmado no
  `media/`: `all` declara `wardrobe`/`dresser`/`sidetable`/`locker` (`Distributions.lua:1294`,
  `:397`, `:1044`, `:612`), e `corridor` não aparece em nenhum `.lua` de distribuição. Observado em
  runtime: um `wardrobe` de `corridor` entregou `Diary2`, que está em `WardrobeGeneric`. O elo entre
  as duas pontas é `ItemPickerJava` e não é legível no `media/` — a consequência prática (não
  confiar em filtro por sala) vale pela observação; o **mecanismo** é que fica em aberto.

- **Como o motor liga o traje escolhido por `ZombiesZoneDefinition` ao contêiner `Outfit_<Traje>`.**
  Os dois lados são legíveis no `media/` e os nomes casam (`name="Survivalist"` ↔
  `Outfit_Survivalist`), mas o elo é Java e não aparece em `media/lua`. O que **está** confirmado é a
  forma dos dois lados e o campo `bags`.
- **O que decide a era (`_Mid`, `_Late`) de um contêiner `Outfit_*`.** O nome sugere dias
  sobrevividos, como o `daySurvived` de `AttachedWeaponDefinitions`
  ([definitions-lua.md](definitions-lua.md)), mas nada em `Distributions.lua` declara o gatilho.
- **Se `inventorymale`/`inventoryfemale` da sala `all` valem para todo zumbi ou só para alguns.** O
  nome da sala sugere "todos", e não há outra sala com essas chaves em todo o `Distributions.lua`,
  mas nada declara a semântica.
- **Se `BagsAndContainers` sofre merge como `Distributions`, ou é escrita direta como
  `ProceduralDistributions`.** Não há chamada de merge sobre ela em `media/lua`; o esperado é escrita
  direta, com o mesmo risco de "último a carregar vence".
- Em que momento do boot os três eventos disparam, e se dá para registrar neles a partir de um
  arquivo de `client/`. O registro do jogo é todo em `server/`.
- Semântica exata de `weightChance` e da faixa `min`/`max` do `procList` — `max=99` é o padrão em
  quase toda entrada, o que sugere "sem limite" e não um teto real.
- Se `rolls` e o peso interagem de forma multiplicativa; nada no `media/lua` declara a fórmula.
- Se o descarte de escalar no merge é intencional ou bug. O comentário do `else` (`:126`) só explica
  o caso da chave nova; o caminho do escalar existente não é comentado. Efeito confirmado no código
  (seção acima), intenção não.
- Se a escrita direta em `ProceduralDistributions.list` precisa acontecer antes de algum ponto do
  boot. O idioma dos mods (seção acima) roda no corpo do arquivo, sem evento, e funciona — mas o que
  garante a ordem contra o `.lua` do jogo que popula a tabela não foi levantado.

Da seção "Item em cima da mesa" (levantada em 2026-08-25, ver o rodapé):

- **Se `addOverlays` de um mod soma ao mapa do jogo ou substitui a entrada daquele sprite.** Só o
  `WorldFiller.lua` chama `getContainerOverlays()` em todo o `media/lua`, então não há segundo caso
  no jogo para comparar. `ContainerOverlays` tem `parseContainerOverlayMapV0`/`V1` e o campo
  `VERSION` da tabela (`WorldFiller.lua:3`) seleciona um dos dois — o que a V1 faz com chave repetida
  não foi lido.
- **De onde sai a lista de `name` válidos** (`grocery`, `gunstore`, `pharmacy`, `armysurplus`…). Eles
  são lidos do próprio `WorldFiller.lua` e casados contra `IsoRoom:getName()` em runtime; não há
  declaração da lista em `media/`, e nada garante que sejam exatamente os nomes de sala de
  `Distributions.lua`.
- **O valor de `TABLE_STORY_CHANCE`** (constante estática de `RBBasic`) e a chance das demais
  histórias. O `getChance()` existe por história, mas os números moram no Java.
- **Se `RBBasic` roda em todo prédio ou é sorteada como as outras.** O `ChunkLoaded` trata `alwaysDo`
  e sorteio, e `getWorld():getRBBasic()` é exposto à parte (`DebugContextMenu.lua:1346`), o que
  sugere tratamento próprio — não confirmado.
- **Comportamento em multiplayer.** `ChunkLoaded` testa `GameClient.client` logo na entrada e o
  `doOverlaySprite` testa `GameServer.server` antes de `sendItemsInContainer`; qual lado de fato roda
  cada coisa não foi levantado.

Das seções de loot em zumbi por código, objeto criado por código, prédio como metadado, rolagem a
partir do Lua e motor dos mapas anotados (levantadas em 2026-09-14, bytecode do buildid 24909800 —
entraram sem recarimbar o rodapé):

- **Se um mod registra mapa anotado próprio** somando `StashUtil.newStash(...)` num arquivo de
  `shared/`. `StashSystem.initAllStashes` lê a global `StashDescriptions` (`Stash.load(KahluaTableImpl)`,
  bytecode), o que sugere que sim; zero mods de `STEAM/` fazem isso, e a ordem de carga contra o
  `init` não foi lida.
- **`addItemToSpawnAtDeath`**: se o item cai no inventário do cadáver ou no chão; se sobrevive ao zumbi
  sair da área carregada; se vale para zumbi criado no servidor em MP.
- **`ItemPickerJava.doRollItem` e `ItemPicker.fillContainer` com personagem `nil`**, chamados do Lua. O
  Java do stash passa `null` (`fillContainerType`, `rollContainerItem`), mas todo uso Lua passa um
  personagem.
- **Se `transmitCompleteItemToClients` de um móvel criado por `addTileObject` leva o conteúdo do
  contêiner junto** para o cliente.
- **`IsoMetaGrid.getBuildingAt` e `BuildingDef.isFullyStreamedIn` chamados do Lua** — públicos no
  `.class` e com a classe exposta (`LuaManager$Exposer` cita `IsoMetaGrid` e `BuildingDef`), mas sem uso
  em Lua achado.
- **Se `getX2()`/`getY2()` de `RoomDef`/`BuildingDef` são inclusivos.** O laço do stash vai de `x` a `x2`,
  mas o limite do `for` não foi lido no bytecode.

> Última verificação: 2026-08-07 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

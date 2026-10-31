# Roupa — o item, o `.xml` da peça, o GUID e o traje

A pilha de roupa do PZ: como um `item` de `ItemType = base:clothing` chega a aparecer no corpo do
personagem. São **quatro arquivos em três formatos**, ligados por três chaves diferentes — e é a
indireção que custa o grep, não cada arquivo isolado.

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\`,
`STEAM/` = `…\steamapps\workshop\content\108600\` (ver [../index.md](../index.md)). **Somente leitura.**

Ícone, textura e o bloco `model` genérico estão em [arte-e-modelos.md](arte-e-modelos.md); esta
página cobre o caminho **específico de roupa**, que não passa por bloco `model` nenhum.

## A cadeia, de ponta a ponta

```
item Dress_Knees                       PZ/media/scripts/generated/items/clothing.txt:37
  ClothingItem = Dress_Knees      ──┐
  BodyLocation = base:dress       ──┼──> lua/shared/NPCs/BodyLocations.lua  (camada de render)
                                    │
                                    └──> clothing/clothingItems/Dress_Knees.xml
                                            m_MaleModel / m_FemaleModel  ──> models_X/…
                                            textureChoices               ──> textures/…
                                            m_GUID                       ──┐
                                                                           │
                                            fileGuidTable.xml  path<->guid ┤
                                                                           │
                                            clothing/clothing.xml  <itemGUID> ─┘   (traje/outfit)
```

Três chaves distintas, e **nenhuma delas é o `ItemType`**:

| Ligação | Chave | Casa por |
|---|---|---|
| `item` → peça | `ClothingItem = Dress_Knees` | **nome do arquivo** `.xml`, sem extensão |
| `item` → camada de render | `BodyLocation = base:dress` | ID declarado em `BodyLocations.lua` |
| traje → peça | `<itemGUID>` | **GUID**, resolvido pelo `fileGuidTable.xml` |

O `ClothingItem` casa por nome de arquivo: `ClothingItem = Dress_Knees`
(`PZ/media/scripts/generated/items/clothing.txt:42`) resolve em
`PZ/media/clothing/clothingItems/Dress_Knees.xml`. Não há campo de caminho — a pasta é fixa.

## 1. O `item` no `.txt`

Fica em `PZ/media/scripts/generated/items/clothing.txt` (o exemplo canônico da tabela de
[mapa-media.md](mapa-media.md)). Os campos que apontam para fora do bloco, com o censo de uso no
arquivo do jogo:

| Campo | Usos | Aponta para |
|---|---|---|
| `ClothingItem` | 1.395 | o `.xml` de `clothing/clothingItems/` |
| `BodyLocation` | 1.395 | ID em `BodyLocations.lua` |
| `BloodLocation` | 864 | máscara de sangue; múltiplos separados por `;` |
| `CanHaveHoles` | 525 | |
| `ClothingItemExtra` / `ClothingItemExtraOption` | 338 cada | **sempre em par** — ver abaixo |
| `IconsForTexture` | 117 | **posicional** contra `textureChoices` — ver abaixo |

`ClothingItem` e `BodyLocation` aparecem 1.395 vezes cada, no mesmo arquivo: são o par obrigatório
de fato — nenhuma peça do jogo declara um sem o outro.

### `IconsForTexture` é posicional

`IconsForTexture` casa **por posição** com as linhas `<textureChoices>` do `.xml`, não por nome.
Em `PZ/media/scripts/generated/items/clothing.txt`:

```
    item Glasses_Normal
    {
        IconsForTexture = GlassesBlack;GlassesBlue;GlassesRed,
```

e em `PZ/media/clothing/clothingItems/Glasses_Normal.xml:12-14`:

```xml
	<textureChoices>normalglassesblack</textureChoices>
	<textureChoices>normalglassesblue</textureChoices>
	<textureChoices>normalglassesred</textureChoices>
```

Primeiro ícone ↔ primeira textura. Os nomes **não** batem entre si (`GlassesBlack` vs
`normalglassesblack`) — só a ordem liga os dois. Trocar a ordem de um dos lados troca o ícone da
variante sem erro nenhum no `console.txt`.

### `ClothingItemExtra` — o par de peças

Usado para peça que existe em duas metades (olho esquerdo/direito). Os dois blocos se apontam
mutuamente, e cada um nomeia a opção do outro
(`PZ/media/scripts/generated/items/clothing.txt`, blocos `Glasses_Eyepatch_Left`/`_Right`):

```
        ClothingExtraSubmenu = EyeLeft,
        ClothingItem = Glasses_Eyepatch_Left,
        ClothingItemExtra = Base.Glasses_Eyepatch_Right,
        ClothingItemExtraOption = EyeRight,
```

Note que `ClothingItemExtra` leva **prefixo de módulo** (`Base.`) e `ClothingItem` não — o primeiro
referencia um `item`, o segundo um arquivo.

## 2. O `.xml` da peça — `clothing/clothingItems/`

1.795 arquivos no build atual, um por peça. Formato completo
(`PZ/media/clothing/clothingItems/Jacket_Padded.xml`):

```xml
<?xml version="1.0" encoding="utf-8"?>
<clothingItem>
	<m_MaleModel>skinned\clothes\bob_jacketpadded</m_MaleModel>
	<m_FemaleModel>media\models_X\Skinned\Clothes\Kate_JacketPadded.x</m_FemaleModel>
	<m_AltMaleModel></m_AltMaleModel>
	<m_AltFemaleModel></m_AltFemaleModel>
	<m_GUID>6f83a2f6-3b02-4e25-b27e-7e112006d7e2</m_GUID>
	<m_Static>false</m_Static>
	<m_AllowRandomHue>false</m_AllowRandomHue>
	<m_AllowRandomTint>true</m_AllowRandomTint>
	<m_AttachBone></m_AttachBone>
	<m_HatCategory>nohair</m_HatCategory>
	<m_Masks>12</m_Masks>
	<m_MasksFolder>media/textures/Clothes/JacketPadded/Masks</m_MasksFolder>
	<m_UnderlayMasksFolder>media/textures/Clothes/JacketPadded/Masks</m_UnderlayMasksFolder>
	<textureChoices>clothes\jacketpadded\paddedjacket</textureChoices>
</clothingItem>
```

**O arquivo é BOM-UTF8** — os do jogo começam com `\ufeff`. Ao contrário dos `.txt` de `scripts/`,
aqui o BOM é a forma observada, não um erro. Ver [armadilhas](#o-que-falha-em-silêncio).

Pontos de contrato que o arquivo entrega:

- **`m_MaleModel` aceita duas formas de caminho, no mesmo build e às vezes no mesmo arquivo.**
  Em `Jacket_Padded.xml` o macho é `skinned\clothes\bob_jacketpadded` (relativo a `models_X/`, sem
  extensão, minúsculo) e a fêmea é `media\models_X\Skinned\Clothes\Kate_JacketPadded.x` (caminho
  desde `media/`, com extensão, capitalizado). Mesma divergência em
  `Glasses_Normal.xml:4-5`. Separador é **barra invertida** nos dois casos.
- **`m_Static` decide a família de modelo.** `true` → malha rígida presa a um osso, e aí
  `m_AttachBone` vem preenchido (`Bip01_Head` em `Hat_BaseballCap.xml:11`) e o modelo vive em
  `models_X/Static/Clothes/`. `false` → malha com skin, `m_AttachBone` vazio, modelo em
  `models_X/Skinned/Clothes/`.
- **`textureChoices` repetido = variantes de cor** da mesma peça. Três linhas em
  `Hat_BaseballCap.xml:12-14` (vermelho/verde/azul). O caminho é relativo a `media/textures/`.
- **`m_MasksFolder` aceita a string literal `none`** (`Glasses_Normal.xml:11`) além de um caminho.
- `m_Masks` repetido lista índices de máscara de corte (`Jacket_Padded.xml`, valores 3/5/12/13/14).

## 3. O GUID e o `fileGuidTable.xml`

`PZ/media/fileGuidTable.xml` (248 KB, na **raiz** de `media/`) é uma tabela plana caminho → GUID:

```xml
	<files>
		<path>media/clothing/clothingItems/AmmoStrap_Brown_Bullets.xml</path>
		<guid>09479acf-6118-4a7d-8e52-700cbb6bf9ed</guid>
	</files>
```

O GUID aparece **duas vezes**: aqui e dentro do próprio `clothingItem` (`m_GUID`). Os dois têm de
bater — é a mesma peça vista pelos dois lados.

**Um mod pode trazer o seu.** 30 dos 89 mods de `STEAM/` embarcam `media/fileGuidTable.xml`, e o
arquivo deles é **parcial, não uma cópia do jogo**: o de `More Traits`
(`STEAM/1299328280/mods/More Traits/42/media/fileGuidTable.xml`) tem 22 linhas e lista só as peças
do próprio mod. Ou seja, a tabela **soma** — mesmo comportamento dos arquivos-satélite de tile
descrito em [tiles.md](tiles.md), e o mesmo caso ainda em aberto na pendência "se um mod pode
substituir arquivo-raiz de `media/`" de [mapa-media.md](mapa-media.md). Aqui a metade "soma" fecha.

Isso é a resposta prática para "de onde tiro o GUID de uma peça nova": qualquer UUID v4 serve, desde
que seja o mesmo nos dois arquivos e não colida com um existente.

## 4. `BodyLocation` — a camada de render

`PZ/media/lua/shared/NPCs/BodyLocations.lua` (1.013 linhas) declara as 114 localizações. O cabeçalho
do arquivo é o contrato, e diz as duas coisas que importam (`:1-3`):

```lua
-- Locations must be declared in render-order.
-- Location IDs must match BodyLocation= and CanBeEquipped= values in items.txt.
local group = BodyLocations.getGroup("Human")
```

**A ordem de declaração é a ordem de desenho.** Uma peça declarada depois desenha por cima. Isso não
é configurável por campo — é posicional no arquivo.

Duas chamadas formam a API:

- `group:getOrCreateLocation(ItemBodyLocation.TSHIRT)` — 114 usos, uma por camada.
- `group:setExclusive(A, B)` — impede usar as duas ao mesmo tempo. O jogo usa para máscara vs
  óculos (`:121-126`), `FULL_HAT` vs chapéu/máscara/brinco (`:129-135`) e SCBA (`:138-148`).

Sendo Lua cru executado no carregamento, é o mesmo idioma de `Definitions/` — **um mod pode chamar
`BodyLocations.getGroup("Human")` e acrescentar**, com a ressalva de ordem de carga registrada nos
pontos a confirmar.

## 5. Traje (`outfit`) e decal

**`PZ/media/clothing/clothing.xml`** monta trajes de NPC/zumbi. Estrutura
(`clothing.xml:2-11`):

```xml
<outfitManager>
	<m_FemaleOutfits>
		<m_Name>Agent</m_Name>
		<m_Guid>4324a28b-08d1-4e53-8084-10ec53c92198</m_Guid>
		<m_Top>false</m_Top>
		<m_items>
			<probability>0.3</probability>
			<itemGUID>1be7cae9-82bd-473f-8de9-23a8d9ca3117</itemGUID>
		</m_items>
```

Aqui a referência é por **GUID**, não por nome — é o único lugar da cadeia onde o `fileGuidTable.xml`
é indispensável. `<probability>` é opcional (peça obrigatória a omite) e `<subItems>` aninha peça
dentro de peça.

**Um nome de traje não é uma aparência — é um espaço de combinações.** `Survivalist_Late`
(`clothing.xml:14003`) tem **20** slots `<m_items>`, dos quais **15 trazem `<probability>`** (0,3;
0,1; 0,7; 0,9 e mais onze de 0,1), somando 69 `<subItems>`. Só os slots opcionais já dão mais de 30
mil combinações, então **dois zumbis do mesmo traje quase nunca se parecem**.

A consequência que mais atrapalha na prática: **não dá para identificar o traje de um zumbi
olhando** — nem para conferir, no Gerenciador de Hordas, se o traje pedido foi mesmo aplicado. Uma
horda spawnada com um único traje aparece na tela como variedade de roupa, e isso é o desenho
funcionando. Verificado em 2026-08-12, com 500 zumbis `Survivalist_Late` spawnados de uma vez.

**Decal** (estampa de camiseta) tem par próprio: `clothingDecals.xml` agrupa nomes e
`clothingDecals/<Nome>.xml` dá o retângulo na textura
(`PZ/media/clothing/clothingDecals/TShirtSpiffo1.xml`):

```xml
<clothingDecal>
	<texture>shirtdecals/spiffo7</texture>
	<x>102</x>
	<y>118</y>
	<width>52</width>
	<height>52</height>
</clothingDecal>
```

60 decals no build atual. Os defaults de qual textura/decal o personagem nasce usando estão em
`PZ/media/lua/shared/Definitions/DefaultClothing.lua`, cujo comentário da linha 3 avisa da pegadinha
central desta página: **"These are the names of clothing xml files, not item types."**

## Lado do mod

Mods realmente usam essa pilha: **4.511 `.xml` de `clothingItems/`** distribuídos pelos mods de
`STEAM/`, contra 1.795 do jogo. É área madura, não experimental.

O que cada mod embarca, no censo de `STEAM/`:

| Arquivo | Mods que trazem |
|---|---|
| `media/clothing/clothingItems/*.xml` | maioria (4.511 arquivos) |
| `media/fileGuidTable.xml` | 30 |
| `media/clothing/clothing.xml` | 5 |
| `media/clothing/clothingDecals/` | 4 |

Na árvore do mod, tudo isso é conteúdo que **não muda entre builds** — vai em `common/media/`, não
na pasta de versão. Ver [carregamento-de-mods.md](carregamento-de-mods.md). A prática observada em
`STEAM/` confirma: `Authentic Z - Current` mantém `media/clothing/clothingItems` fora da pasta `42/`
e também dentro dela, o que sugere convivência com layout pré-B42 mais do que uma regra.

### O que falha em silêncio

Cada elo quebra sem mensagem, e o sintoma é sempre "a roupa não aparece":

1. **`ClothingItem` sem `.xml` correspondente** — o nome tem de casar com o arquivo, e a pasta é fixa.
2. **`m_GUID` divergente do `fileGuidTable.xml`** — a peça funciona equipada mas some de qualquer
   traje que a referencie por GUID.
3. **Ordem de `IconsForTexture` trocada** — variantes com ícone errado, sem erro.
4. **`BodyLocation` que não existe** em `BodyLocations.lua`.
5. **Caixa e separador do caminho de modelo** — o jogo mistura as duas convenções, então o parser
   aparenta ser tolerante, mas isso não está confirmado (abaixo).

## Pontos a confirmar

- **Se o parser de `m_MaleModel` é mesmo indiferente a caixa, extensão e prefixo `media/`.** As duas
  formas convivem no build (`Jacket_Padded.xml:3` vs `:4`), o que é evidência forte de tolerância,
  mas nenhuma delas prova qual é a canônica nem o que acontece com uma terceira forma (barra normal,
  por exemplo). Não há parser em `media/lua` para ler — é Java.
- **Se um mod pode acrescentar `BodyLocation` novo**, e em que ordem de render ele entra. A API
  (`getOrCreateLocation`, `setExclusive`) é Lua e está exposta, mas a ordem é posicional no arquivo,
  e um `.lua` de mod carrega **depois** do jogo — o que colocaria toda camada de mod no topo. Nenhum
  dos 89 mods de `STEAM/` foi cruzado para isso nesta rodada.
- **Se `m_Masks` é índice de arquivo em `m_MasksFolder`** ou enum do motor. Os valores observados
  (3, 5, 12, 13, 14 em `Jacket_Padded.xml`) são pequenos e esparsos, o que não decide entre as duas
  leituras.
- **Diferença entre `m_MasksFolder` e `m_UnderlayMasksFolder`.** Em `Jacket_Padded.xml` os dois
  apontam para a mesma pasta, o que não permite separar os papéis.
- **`m_AltMaleModel`/`m_AltFemaleModel`** aparecem vazios nos arquivos abertos; quando são usados e
  por qual condição o motor troca não foi levantado.
- **`m_HatCategory`** tem ao menos dois valores observados (`nohair` em `Jacket_Padded.xml:12`,
  `Group01` em `Hat_BaseballCap.xml:12`) — a lista completa e a semântica não estão no `media/`.
- **Se o `fileGuidTable.xml` de mod soma ou substitui** está resolvido pela evidência de tamanho (22
  linhas vs 248 KB), mas **por qual mecanismo** o motor funde os dois é a mesma incógnita dos
  satélites de tile ([tiles.md](tiles.md)).
- **Colisão de GUID entre dois mods** — o que o motor faz não foi levantado, e não há log conhecido.
- **Se `probability` em `<m_items>` é fração (0–1) ou percentual.** O único valor observado é `0.3`,
  compatível com as duas leituras.
- O PZ-API-Docs cataloga `clothing`, `clothingDecals`, `clothingItem` e `fileGuidTable` no índice de
  **xml** (registrado em [../fontes-externas.md](../fontes-externas.md):36), mas as páginas não foram
  cruzadas campo a campo nesta rodada — é a fonte natural para fechar `m_Masks`, `m_HatCategory` e os
  `Alt*`.

> Última verificação: 2026-08-07 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

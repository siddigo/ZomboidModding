# Arte e modelos — ícone, textura e o bloco `model`

Cobre a **camada de arte** de item e objeto: como um script `.txt` aponta para uma imagem ou uma
malha 3D, onde cada arquivo mora, e o que muda quando quem escreve é um mod. Roupa entra só como
ponteiro — é outro formato e merece página própria.

Aliases: `PZ/` = instalação do jogo, `WS/` = `~\Zomboid\Workshop`. Ver
[../index.md](../index.md).

## Onde a arte mora

| Pasta | Conteúdo | Para quê |
|---|---|---|
| `PZ/media/textures/` | 6.140 `.png` — 408 na raiz, o resto em 20 subpastas (`WorldItems/`, `Clothes/`, `weapons/`, `IsoObject/`, `Tileset/`…) | ícone 2D **e** textura de malha; as duas coisas convivem aqui |
| `PZ/media/models_X/` | 3.935 malhas: 2.031 `.fbx`/`.FBX`, 1.781 `.x`/`.X`, 59 `.glb`, 60 `.blend` | as malhas que o bloco `model` referencia |
| `PZ/media/models/` | 46 `.txt` — **não é script**: é malha em formato-texto próprio, cabeçalho `# Project Zomboid Mesh` / `# Project Zomboid Animated Mesh` | formato antigo; não confundir com `models_X/` |
| `PZ/media/texturepacks/` | 24 `.pack` | **onde os ícones do jogo de fato estão** — ver abaixo |
| `PZ/media/clothing/clothingItems/` | `.xml` por peça | caminho separado, só para roupa |
| `PZ/media/scripts/generated/models_*.txt` | 3.672 blocos `model` | a definição que liga nome → malha |
| `PZ/media/scripts/generated/vehicles/*_model.txt` | mais 155 blocos `model` | veículo tem os seus, um arquivo por veículo |

Os `.blend` são fonte do Blender deixada no install — não são carregados pelo jogo.

## O ícone 2D — o prefixo `Item_` é implícito

No bloco `item`, o campo é o nome **sem** prefixo e **sem** extensão; o motor prefixa `Item_` e
procura a textura:

```
Icon = SkullCrusher,      →  textura  Item_SkullCrusher
```

A prova visível está no Lua, em duas telas de admin —
`PZ/media/lua/client/ISUI/AdminPanel/ISItemsListTable.lua:468` (`tryGetTexture("Item_" .. icon)`) e
`PZ/media/lua/client/ISUI/AdminPanel/LootZed/ISLootZed.lua:140`. O desenho do inventário em si é
Java: isto é **uso observado** que confirma a convenção, não o contrato declarado. O outro lado da
prova é negativo e vale igual: em `PZ/media/scripts/generated/items/` **nenhum** item escreve
`Icon = Item_…`. Escrever o prefixo à mão faz o jogo procurar `Item_Item_X` e o item nasce sem
imagem, sem erro no `console.txt`.

`IconsForTexture` sobrescreve `Icon` quando presente — lista separada por `;`, e o Lua usa o índice 0
(`ISItemsListTable.lua:463-467`). Exemplo real:
`PZ/media/scripts/generated/items/literature.txt:1685`.

### O jogo empacota os ícones; um mod não

Procurar `Item_*.png` solto no jogo dá **6 arquivos em 6.140** — e os 6 também estão dentro de
`PZ/media/texturepacks/UI2.pack` (54 MB), junto com todos os outros. Os ícones do jogo vivem no pack;
os 6 soltos são duplicata, não exceção de layout.

Consequência prática para modding: **o `.pack` é compilado por ferramenta externa que este workspace
não tem mapeada** (mesma pendência de [tiles.md](tiles.md)), então mod entrega `.png` solto. O motor
aceita as duas formas — é o que os mods reais provam. Não procure "como empacotar" antes de precisar.

## O bloco `model`

Liga um nome a uma malha. Vive só em `generated/` — nenhum bloco `model` em outro lugar de
`media/scripts`. Exemplo canônico completo, `PZ/media/scripts/generated/models_weapons.txt:3-16`:

```
    model SaucePan
    {
        mesh = weapons/1handed/SaucePan,
        attachment world
        {
            offset = -0.049 0.137 -0.049,
            rotate = 0.0 -45.0 0.0,
        }
        attachment Bip01_Prop2
        {
            offset = -0.0131 0.0078 0.0007,
            rotate = 180.0 -11.9336 180.0,
        }
    }
```

Repare: `attachment` é bloco filho e **não leva vírgula depois do `}`**, ao contrário dos campos.

### Campos, por frequência de uso

Censo sobre os 9 `generated/models_*.txt` de item/objeto (exclui veículo):

| Campo | Ocorrências | Nota |
|---|---|---|
| `mesh` | 3.672 | caminho relativo a `models_X/`, **sem extensão**. `pasta/arquivo` |
| `texture` | 2.726 | caminho relativo a `textures/`, sem extensão |
| `scale` | 3.810 | também aparece dentro de `attachment` |
| `offset` / `rotate` | 2.303 / 2.311 | só dentro de `attachment` — 3 floats separados por espaço |
| `bone` | 176 | dentro de `attachment`, prende o modelo a um osso do rig |
| `static` | 159 | `false` em tudo que anima (personagem, animal, porta) |
| `animationsMesh` | 123 | nome de um bloco `animationsMesh` (ver abaixo) |
| `shader` | 117 | 6 valores no jogo inteiro (abaixo) |
| `undoCoreScale` | 81 | `true`, em `models_isoobject.txt` |
| `postProcess` | 2 | ex.: `-JOIN_IDENTICAL_VERTICES` |
| `ColorRed`/`Green`/`Blue` | 1 cada | tinta RGB sobre a `texture` — ver abaixo |

**`ColorRed`/`ColorGreen`/`ColorBlue` são tinta, e o nome tem dois donos.** Em `model`, a ocorrência
única é autoexplicativa quando lida inteira (`generated/models_items.txt:14111-14119`):

```
    model SmallGoldSheet
    {
        mesh = WorldItems/SmallSheetMetal,
        texture = WorldItems/MetalSheet_Gold,
        scale = 0.3,
        ColorRed = 10,
        ColorGreen = 220,
        ColorBlue = 10,
    }
```

Textura *Gold*, multiplicada por um RGB verde — o modelo reaproveita a malha e a textura de outro
material e troca a cor no shader, em vez de exigir textura nova. A faixa observada é 0–255.

O mesmo nome de campo aparece **131 vezes em blocos `item`**, não `model` — 37 em
`generated/items/clothing.txt`, 50 em `literature.txt`, 37 em `normal.txt`, 4 em `food.txt`, 3 em
`weapon.txt`. São dois contratos com o mesmo nome, como acontece com `validMonths` no sistema de
coleta: ao copiar o campo de um exemplo, confira em que bloco ele estava.

Os 6 valores de `shader` usados — e o PZ-API-Docs lista exatamente estes 6, sem sobra:
`vehicle_multiuv` (77), `animalEffect` (73), `door` (44), `vehicle` (38), `vehicle_norandom_multiuv`
(22), `vehiclewheel` (1).

**Só em veículo e efeito**, não em item: `invertX` (100), `cullFace` (18, sempre `None`, em
`generated/weapons/firearm/fx/muzzle_flash_models.txt:7`), `boneWeight`
(`generated/vehicles/vehicle_car_modern_martin_model.txt:39`), e o trio
`attachmentParent`/`attachmentSelf`/`ignoreVehicleScale`
(`generated/vehicles/vehicle_car_modern_martin_template.txt:14-16`).

### `mesh` ou `file` — o campo depende de onde o `model` está

O bloco `model` tem **duas formas de apontar a malha**, e a diferença é o contexto, não a versão:

| Onde | Campo | Evidência |
|---|---|---|
| `model` de topo, em `generated/models_*.txt` | `mesh` | 1.732 usos em `models_items.txt`; **zero** `file` |
| `model` aninhado dentro de `vehicle` | `file` | `generated/vehicles/vehicle_car_luxury.txt:7-12` |

```
    vehicle CarLuxury
    {
        template! = CarLuxury,
        specialKeyRing = Base.KeyRing_WestMaple,
        model
        {
            file = Vehicles_LuxuryCar,
            scale = 1.82,
            offset = 0.0 0.3022 0.0,
        }
```

(`generated/vehicles/vehicle_car_luxury.txt:3-12`.) É a mesma armadilha do `mesh` × `meshFile` do
`animationsMesh`: o campo certo é o do bloco em que você está, e o parser falha em silêncio se você
trouxer o do vizinho. **`specialKeyRing`, na linha logo acima, é campo de `vehicle`** — não de
`model`, apesar de aparecer colado nele. São 71 ocorrências no `media/scripts`, todas em veículo, e o
valor é lista de IDs de item separada por `;`
(`specialKeyRing = Base.KeyRing_EagleFlag;Base.KeyRing_EightBall;…`). Ver
[veiculos.md](veiculos.md).

O `|` no `mesh` seleciona um submesh nomeado dentro do arquivo:
`generated/vehicles/vehicle_car_modern_martin_model.txt:5` →
`mesh = vehicles/ModernCarWithDoors_Martin|Vehicles_ModernCar_mesh`.

`animationsMesh` é bloco irmão, em `generated/models_isoobject_animationsMesh.txt:3` — e ali o campo
é `meshFile`, que **leva a extensão** (`IsoObject/door_n_sw.glb`). Não é o mesmo contrato do `mesh`.

### Quem referencia um `model`, e quando o módulo entra

Aqui está o detalhe que custa um grep: os campos **não seguem a mesma regra de prefixo**. Censo em
`PZ/media/scripts/generated/items/`:

| Campo do `item` | Total | Com `Base.` | Forma |
|---|---|---|---|
| `WorldStaticModel` | 3.844 | **0** | nome puro, sempre |
| `StaticModel` | 1.557 | **0** | nome puro, sempre |
| `WeaponSprite` | 384 | **0** | nome puro, sempre — ver abaixo |
| `WorldStaticModelsByIndex` | 34 | 0 | lista com `;` — `items/container.txt:3982` |
| `PhysicsObject` | 33 | **33** | sempre com módulo — `items/weapon.txt:240` |
| `ClothingItem` | 1.580 | 0 | **não é `model`** — ver abaixo |
| `ClothingItemExtra` | 360 | **360** | idem, e sempre com módulo |

Ou seja: 0% ou 100%, nunca misto. Ao escrever, copie a forma do campo, não a do vizinho.

### `WeaponSprite` é o modelo **na mão**, e é obrigatório em arma `[confirmado 2026-08-10]`

O campo aponta para um bloco `model`, igual a `WorldStaticModel` — **não** para um `.png` de
`textures/weapons/`. Censo fechado sobre `PZ/media/scripts/generated/`: dos **357 valores distintos**
de `WeaponSprite`, **356 casam com um nome de `model`** por nome exato, e o único que não casa é a
string literal `null`. Os cinco valores que antes pareciam contraexemplo (`AerosolBomb`, `Axe_Old`,
`Axe_Sawblade`, `BallPeenHammerForged`, `Banjo_Broken`) não tinham arquivo sob `textures/weapons/`
porque nunca precisaram ter — todos são bloco `model`:
`models_weapons.txt:1477` (`SledgeHammer`), `:4828`, `:4727`, `:403`, `:194`, e `AerosolBomb` em
`models_items.txt:1582`. O `.png` sob `textures/weapons/<slot>/` é a textura da **malha** — vem do
`mesh` do bloco `model` (`model SledgeHammer` em `models_weapons.txt:1477-1485` declara
`mesh = weapons/2handed/SledgeHammer` e nenhum `texture`), não do `WeaponSprite`.

**Os dois campos são complementares, não alternativos.** Em `generated/items/weapon.txt`,
`WorldStaticModel` tem 46 ocorrências e **nenhuma** delas aparece em item sem `WeaponSprite`; quando
os dois coexistem carregam o mesmo valor (`items/weapon.txt:248-250`, `AerosolBomb`). `WeaponSprite`
é o modelo equipado na mão; `WorldStaticModel`, o do chão.

**Todo item `ItemType = base:weapon` declara `WeaponSprite` ou `WeaponSpritesByIndex`.** Dos 409
blocos `item` de `weapon.txt`, 384 têm o primeiro e 25 o segundo; a única exceção é `FISH_DEV_ITEM`
(`items/weapon.txt:181`), item de dev. Nem "arma sem modelo" é omissão: as mãos nuas escrevem a
string literal `WeaponSprite = null` (`items/weapon.txt:14283`, bloco com
`Tags = base:barehands`) em vez de deixar o campo fora.

**Omitir o campo em item equipável não falha em silêncio — trava o render.** É a exceção da seção
abaixo. Prova in-game de 2026-08-10 (jogo 42.20.2, `WS/SiddigoWeapons` com `WorldStaticModel` e
`attachment Bip01_Prop1` corretos, `WeaponSprite` removido): equipar o item dispara
`NullPointerException` **a cada frame** enquanto a arma estiver na mão, registrado em
`USER/console.txt` de 2026-08-10 19:39:

```
ERROR: General f:899> GameWindow.frameStep> Exception thrown
	java.lang.NullPointerException: Cannot invoke "String.indexOf(int)" because "name" is null
	at ScriptManager.getItemName(ScriptManager.java:1215).
		zombie.core.skinnedmodel.ModelManager.addStaticForcedTex(ModelManager.java:1478)
		zombie.core.skinnedmodel.ModelManager.addEquippedModelInstance(ModelManager.java:876)
		zombie.core.skinnedmodel.ModelManager.ResetCharacterEquippedHands(ModelManager.java:743)
```

`WorldStaticModel` **não** cobre o buraco: o item deste teste tinha os dois modelos apontando para o
mesmo bloco e ainda assim estourou.

**A cadeia exata de resolução do modelo na mão** `[levantado 2026-08-16, javap]` — `addEquippedModelInstance`
não consulta `WeaponSprite` direto, e sim `HandWeapon.getStaticModel()`, que resolve em três degraus:

1. `WeaponSpritesByIndex[getModelIndex()]`, se `modelIndex != -1` e a lista existir;
2. senão o campo `staticModel` (`StaticModel` do `.txt`), se não for nulo;
3. senão `weaponSprite` (`WeaponSprite`).

Ou seja `WeaponSprite` é o **último** degrau, e é por isso que removê-lo de uma arma sem `StaticModel`
devolve `null` e estoura no `ScriptManager.getItemName`. O teste in-game continua valendo; o que muda é
o porquê. A consequência aproveitável está na seção da chama: **`StaticModel` tem precedência sobre
`WeaponSprite`**, e `setStaticModel` é alcançável de Lua.

**O caso positivo, confirmado no mesmo teste:** devolvido o `WeaponSprite`, a arma de duas mãos
renderiza correta na mão — sem `.png` novo em `textures/weapons/` e sem ajuste de `offset`/`rotate`.
A combinação que funciona num mod é `WeaponSprite` e `WorldStaticModel` apontando para **o mesmo**
bloco `model`, e esse bloco trazendo `attachment world` (chão) e `attachment Bip01_Prop1` (mão) —
que é o que `WS/SiddigoWeapons/.../SiddigoWeapons_Models.txt:4-21` já declarava.

Em Lua o nome aparece em `item:setWorldStaticModel(...)` (`PZ/media/lua/client/ServerCommands.lua:148`
e `:158`, troca o modelo quando o estado do item muda) e `item:getStaticModel()`, usado para alimentar
`setOverrideHandModels()` durante uma ação (`PZ/media/lua/shared/Camping/TimedActions/ISLightFromPetrol.lua:27`).

### Item preso ao corpo: a cadeia de três nomes `[levantado 2026-08-16]`

Arma pendurada no zumbi (coldre, cinto, costas) atravessa **três arquivos com três nomes
diferentes**, e o erro fácil é supor que são o mesmo. A cadeia:

| Etapa | Arquivo | O nome usado | Exemplo |
|---|---|---|---|
| 1. Qual localização a definição pede | `shared/Definitions/AttachedWeaponDefinitions.lua:583` | **nome de exibição** | `weaponLocation = {"Holster Right"}` |
| 2. Tradução exibição → attachment | `shared/NPCs/AttachedLocations.lua:41` | ambos | `getOrCreateLocation("Holster Right"):setAttachmentName("holster_right")` |
| 3. O modelo declara o ponto | bloco `model` do item | **nome de attachment** | `attachment holster_right` |

Sem a etapa 3 não há o que renderizar naquele ponto: a definição sorteia o item, mas o modelo não
tem onde encaixar. O canônico é `model Revolver_CapGun`
(`PZ/media/scripts/generated/TEMPORARY_TESTING_new_items/TESTING_CapGuns.txt:22-33`), que declara
`attachment holster_right`, `holster_left` e `ShoulderHolster`, cada um com só um `scale`.

**A armadilha é a etapa 2: o nome de attachment não é derivável do nome de exibição.** A maioria é a
versão snake_case (`"Holster Right"` → `holster_right`), mas não todas — `AttachedLocations.lua:45-46`
mapeia `"Holster Shoulder"` → **`ShoulderHolster`** e `"Holster Ankle"` → **`AnkleHolster`**, em
CamelCase. As duas linhas **substituem** as versões comentadas logo acima (`:43-44`), que usavam
`holster_shoulder`/`holster_ankle`. Sempre ler o `setAttachmentName`, nunca adivinhar pelo rótulo.

Censo: `AttachedLocations.lua` tem 2 grupos — `getGroup("Animal")` (`:1`, 2 locations) e
`getGroup("Human")` (`:5`, o resto) — com **56 locations ativas**. Descontadas as linhas comentadas,
**todas as 56 têm ao menos um `model` de `generated/models_*.txt` declarando o attachment
correspondente**: nenhuma localização órfã. Isso também explica parte dos 92 nomes distintos de
`attachment` da lista de pendências abaixo — 56 são localizações de corpo, os outros 36 são de outra
natureza (`world`, `Bip01_Prop1`, `Bip01_Prop2`, `muzzle`, `scope`, `trailer`, `reddot`…).

Há 7 entradas comentadas: `holster_ankle` e `holster_shoulder` são **renome** (substituídas por
`:45-46`); `1gun_belt_right`, `belt_left_closed`, `belt_right_closed`, `knife_belt_back` e
`knife_belt_front` são desativação real — localização que o jogo declarou e desligou.

### `AttachmentType` decide em que slot o item pode ficar `[levantado 2026-08-16]`

O campo `AttachmentType` do bloco `item` é o outro lado: ele diz em quais slots o item encaixa, e
`PZ/media/lua/client/Hotbar/ISHotbarAttachDefinition.lua` é o mapa. Cada slot lista os
`AttachmentType` que aceita e a localização de destino:

| Slot | `AttachmentType` aceitos | Destino |
|---|---|---|
| `HolsterRight` (`:44-53`) | `Holster`, `HolsterSmall` | `Holster Right` |
| `SmallBeltLeft` (`:4-22`) / `SmallBeltRight` (`:24-42`) | `Knife`, `NotKnife`, `Hammer`, `HammerRotated`, `Screwdriver`, `MeatCleaver`, `Walkie`, `Sword` | `Belt Left Upside`, `Belt Left`, `Belt Rotated Left`, `Belt Left Screwdriver`, `MeatCleaver Belt Left`, `Walkie Belt Left`… |

**Consequência para mod: `AttachmentType = BigWeapon` não é aceito por nenhum slot de cinto** — é
tipo de costas (`Big Weapon On Back`, `Big Weapon On Back with Bag`). Pôr no cinto um item declarado
`BigWeapon` exige trocar o `AttachmentType`, e a troca não é só cosmética do lado do zumbi: **muda
também onde o jogador pendura o item na própria hotbar**, porque é o mesmo mapa que governa os dois.

## Chama e efeito animado: sprite 2D anexado, não parte do modelo

A pergunta que traz alguém aqui é "a fogueira tem chama animada; dá para pôr a mesma coisa numa tocha
equipada?". A resposta curta: **o mecanismo é um só — `AttachAnim` — e vale tanto para objeto de
quadrado quanto para personagem** (é como o zumbi em chamas funciona). O que ele **não** faz é virar
parte do modelo 3D da arma: é sempre overlay 2D, e a ancoragem na mão você teria de dirigir por conta
própria. `[levantado 2026-08-16]`

### Como a fogueira anima a chama

`PZ/media/lua/server/Camping/SCampfireGlobalObject.lua:114-123` é a receita inteira: cria um
`IsoFire`, pendura uma animação de sprite nele e joga no quadrado.

```lua
function SCampfireGlobalObject:addFireObject()
	if self:getFireObject() then return end
	local square = self:getSquare()
	if not square then return end
	-- Create a 'permanent' IsoFire object.  It won't spread to adjacent squares but will burn.
	local fireObj = IsoFire.new(getCell(), square)
	fireObj:AttachAnim("Fire", "01", IsoFire.NUM_FRAMES_FIRE, IsoFireManager.FIRE_ANIM_DELAY, 1 * Core.getTileScale(), -1 * Core.getTileScale(), true, 0, false, 0.7, IsoFireManager.FIRE_TINT_MOD)
	square:AddTileObject(fireObj)
end
```

`AttachAnim` (`:120`) é a **única ocorrência em todo o `media/lua` do jogo** — grep em 1.395 `.lua`,
excluindo `Translate/`. Não há segundo exemplo para copiar.

Os dois primeiros argumentos são nome e sufixo de folha: a cadeia é
`AttachAnim` → `IsoSprite.CreateSpriteUsingCache(nome, anim, frames)` → `setFromCache` →
`LoadFramesNoDirPage`, e os frames existem como sprites nomeados `Fire_01_0`…`Fire_01_29` dentro de
`PZ/media/texturepacks/Tiles2x.pack` (e `Tiles1x.pack`). São três folhas — `Fire_01_*`, `Fire_02_*`,
`Fire_03_*`; `Smoke_*` segue o mesmo padrão. São sprites de tile como qualquer outro, alcançáveis por
`getSprite("Fire_01_0")` — ver [tiles.md](tiles.md).

**As constantes não estão em `media/`, estão no `.jar`** (`javap` sobre `projectzomboid.jar`; é
contrato declarado, não uso observado): em `zombie.iso.objects.IsoFire`, `NUM_FRAMES_FIRE = 30`,
`NUM_FRAMES_SMOKE = 30`, `LIGHT_RADIUS_MINIMUM/LOW/MEDIUM/HIGH = 1/5/8/12` e a cor da luz do fogo
`LIGHT_R = 0.61f`, `LIGHT_G = 0.175f`, `LIGHT_B = 0.0f`; em `zombie.iso.objects.IsoFireManager`,
`FIRE_ANIM_DELAY = 0.5f`.

Não confunda com o outro sistema de fogo: `PZ/media/textures/fire.png`, `FireFlame.png`,
`FireSmokes.png`, `FireSparksFlare.png` mais `PZ/media/shaders/fire.frag|.vert` e `smoke.frag|.vert`
pertencem ao particulado de GPU (`zombie.iso.ParticlesFire` — shader e buffer, sem API de emissor
arbitrário). `fire.png` é ruído/flowmap, **não** folha de frames. Esse caminho não é o da chama da
fogueira e não é alcançável por mod.

### Personagem em chamas usa o mesmo mecanismo — e é o caminho que existe

`AttachAnim`, `RemoveAttachedAnims` e `getAttachedAnimSprite` são métodos de `zombie.iso.IsoObject`, e
a cadeia de herança **inclui o jogador**: `IsoPlayer` → `IsoLivingCharacter` → `IsoGameCharacter` →
`IsoMovingObject` → `IsoObject`.

**E o jogo usa isso.** `IsoGameCharacter.SetOnFire()` (sem argumento — não confundir com
`setOnFire(boolean)`, que só faz bookkeeping de rede) chama **o mesmo `AttachAnim("Fire", "01", …)`**
da fogueira, sobre o próprio personagem, e depois `IsoFireManager.AddBurningCharacter`. `StopBurning()`
desfaz. É a mesma folha de sprite, o mesmo `0.7f` de alpha.

O que despistou no primeiro levantamento: **personagem não usa `renderAnimatedAttachments`.** Aquele
símbolo tem seis referências nas 23.735 classes — `IsoObject` (definição), `FBORenderCell` (único
chamador) e as quatro sobrescritas `IsoFire`/`IsoFireplace`/`IsoBarbecue`/`IsoCarBatteryCharger`, e
nenhuma de personagem. Só que `IsoGameCharacter.render(...)` **tem laço próprio** sobre
`attachedAnimSprite`, que desenha do mesmo jeito por outro caminho. Procurar pelo símbolo errado dá
"não existe" com toda a cara de prova.

### Como o fogo acompanha um personagem que anda

Dentro do laço de `IsoGameCharacter.render(...)`, por sprite anexado:

1. `IsoSpriteInstance.update()` e alpha (`SetTargetAlpha(getTargetAlpha())`).
2. **Ramo `isOnFire()`** — o que dá o acompanhamento: chama
   `CombatManager.getBoneWorldPos(this, "Bip01_Spine1", …)`, ou seja **lê a posição de mundo de um osso
   do modelo 3D** e escreve o resultado nos campos `IsoSprite.soffX`/`soffY`. Renderiza forçando
   `IsoDirections.N` (billboard, não acompanha a direção do personagem), tinta branca e deslocamento
   de `0.25` deitado / `0.5` em pé. O `-89.0f` e o `96.0f` são a conversão de altura do osso.
3. **Ramo `else` — também renderiza**, e é o detalhe que importa para modding: sprite anexado que
   *não* seja fogo desenha na posição simples do personagem, com `getForwardIsoDirection()`, sem
   ancoragem em osso.
4. O laço envolve tudo em `FBORenderCell.renderTranslucentOnly = true` quando
   `PerformanceSettings.fboRenderChunk` está ligado.

Ou seja: **anim anexada a personagem renderiza sempre; o que é exclusivo do fogo é a ancoragem em
osso.** A ancoragem está hardcoded em `Bip01_Spine1` dentro do ramo `isOnFire()` — não há campo nem
parâmetro para escolher outro osso.

### O que isso abre, e o que continua fechado, para tocha na mão

As três peças da ancoragem são públicas: `AttachAnim` (método de `IsoObject`),
`CombatManager.getBoneWorldPos(IsoMovingObject, String, Vector3)` (**`public static`**) e
`IsoSprite.soffX`/`soffY` (**campos `public short`**). E `setOnFire` já é chamado de Lua no jogo —
`PZ/media/lua/client/ISUI/Animal/ISAnimalContextMenu.lua:422` (`animal:setOnFire(true)`).

Em tese, então, um mod anexa a anim ao jogador e reposiciona por conta própria a cada frame, pedindo
o osso da mão (`Bip01_Prop1`, o mesmo do `attachment` de arma) em vez do espinhaço. **Não testado, e
não há uso real para citar** — ver "Pontos a confirmar". O que já é certo é que o caminho ingênuo
(anexar e deixar) põe a chama na base do personagem, não na mão, porque cai no ramo `else`.

O que continua fechado é o outro lado: **a chama não vira parte do modelo da arma.** Item equipado
renderiza por `ModelManager.addEquippedModelInstance` / `ResetCharacterEquippedHands` (o stacktrace da
seção do `WeaponSprite`), e ali não entra sprite 2D. Qualquer chama por este caminho é overlay
desenhado sobre o personagem, que some se o personagem não estiver sendo renderizado por
`IsoGameCharacter.render`.

### O que existe de fx em arma, e o que não existe

| Mecanismo | Alcance | Evidência |
|---|---|---|
| `MuzzleFlashModelKey` | campo de `item`, **só arma de fogo**, disparado no tiro | `generated/items/weapon.txt:11050` (e mais 19); modelos em `generated/weapons/firearm/fx/muzzle_flash_models.txt` |
| `attachment muzzle` | ponto de ancoragem do fx no modelo da arma | 25 usos em `generated/models_*.txt` |
| animação de textura no `model` | **não existe** | `zombie.scripting.objects.ModelScript` não tem campo de frame/anim — só `meshName`, `textureName`, `shaderName`, `scale`, `attachments`, `cullFace`, `boneWeights`, `invertX`, `postProcess` |

Não há ancoragem genérica de fx nem campo de chama. `zombie.characters.IsoGameCharacter$TorchInfo`,
que é o que `LightDistance`/`LightStrength`/`TorchCone` alimentam, carrega só dado de luz
(`x,y,z`, `r,g,b`, `angleX/Y`, `dist`, `strength`, `cone`, `dot`, `focusing`) — emite luz, não desenha
chama.

### O que os mods fazem, então

Chama **pintada na textura** — estática. Os dois mods de tocha acesa de `STEAM/` chegaram na mesma
solução, de forma independente:

- `STEAM/3402516345/mods/B42Survival` — `item TorchLit` (`common/media/scripts/generated/items/Items_Survival.txt:254-275`)
  declara `StaticModel = TorchLit` e `WorldStaticModel = TorchLit`; o bloco em
  `common/media/scripts/models_Survival.txt:156-166` aponta `mesh = WorldItems/TorchActive`,
  `texture = WorldItems/TorchLit`. A textura `common/media/textures/Worlditems/TorchLit.png` tem a
  chama desenhada.
- `STEAM/1542069453/mods/Torch` — mesma solução, `model Torchlit` com mesh e textura próprios
  (`media/scripts/models_Torch.txt`).

**Nenhum mod de `STEAM/` usa `AttachAnim`** (grep em todos os `.lua`). E o vanilla não tem item de mão
com chama para servir de exemplo: `model Candle` (`generated/models_items.txt:114-117`) é só
`mesh = Candle`, sem modelo aceso e sem chama.

São duas alternativas não testadas, e a ordem de promessa é esta:

1. **`AttachAnim` no jogador + reposicionamento por frame no osso da mão** — reaproveita a folha
   `Fire_01_*` e o caminho que o zumbi em chamas já exercita; é o único que dá chama *animada*. Custo:
   depende de Lua escrever `soffX`/`soffY` a cada frame, o que não foi verificado.
2. **Pseudo-animação por troca de modelo** — ver a seção seguinte: `item:setStaticModel(...)` alternando
   entre N blocos `model` com a chama em posições diferentes. É troca por tick, não por frame.

Ver "Pontos a confirmar" para o que falta levantar em cada uma.

## Modelo 3D animado existe — mas não em item equipado

A pergunta seguinte é se a chama pode ser 3D animada de verdade, em vez de sprite. **Não pode**, e o
fechamento é arquitetural, não falta de campo. `[levantado 2026-08-16]`

### O jogo anima modelo, só que não este

Os campos existem e funcionam: `static = false` mais `animationsMesh = <bloco>`, e o bloco
`animationsMesh` (`generated/models_isoobject_animationsMesh.txt:3`) traz `meshFile` **com** extensão,
`keepMeshAnimations`, e as listas `animationDirectories`/`animationPrefixes`.

O censo mostra onde isso vive, e é excludente — os dois campos aparecem juntos, nos mesmos três
arquivos e em nenhum outro:

| Arquivo | `animationsMesh` | `static = false` |
|---|---|---|
| `generated/models_animals.txt` | 73 | 73 |
| `generated/models_isoobject.txt` | 44 | 44 |
| `generated/models_characters.txt` | 6 | 6 |
| `generated/models_items.txt` | **0** | **0** |
| `generated/models_weapons.txt` | **0** | **0** |

Animal, personagem e objeto de mundo (porta é o caso canônico) animam. **Nenhum item ou arma do jogo
anima.** E não é omissão de conteúdo: em `STEAM/`, os únicos dois arquivos de mod com `animationsMesh`
são do *Authentic Z* (`2335368829/mods/Authentic Z - Current/42/media/scripts/AuthenticZCurrent_attachments.txt:3-7`
e o irmão *Backpacks+*), e os dois estão **redefinindo `model MaleBody`/`FemaleBody`** — o corpo do
personagem, que legitimamente é `static = false`, para somar pontos de `attachment`. Não é item
animado; é o contraexemplo que confirma a regra.

### Por que o motor fecha

`addEquippedModelInstance` chama `addStatic` → `addStaticForcedTex`, e ali o item vira um
`ModelInstance` assim (`javap`):

- `newInstance(model, slot.character, slot.model.animPlayer)` — recebe o `AnimationPlayer` **do
  personagem**, não um seu;
- `instance.parent = slot.model` (o modelo do personagem);
- `instance.parentBone = slot.model.animPlayer.getSkinningBoneIndex(nomeDoOsso, instance.parentBone)`;
- `instance.animPlayer = slot.model.animPlayer`.

Ou seja: **item equipado é malha estática pendurada num osso do personagem, e o `animPlayer` que ele
carrega serve só para saber onde o osso está.** `ModelInstance` até tem campo `animPlayer` público e
`init(Model, IsoGameCharacter, AnimationPlayer)` — a estrutura suporta animação —, mas quem tem clipe
próprio no jogo é veículo (`VehicleModelInstance.init` recebe `BaseVehicle.getAnimationPlayer()`),
personagem e animal. Para item não há caminho que crie um player próprio, então um clipe embutido na
malha não teria o que o tocasse.

O único movimento que um modelo de item tem, portanto, é o do osso em que está preso.

### O que sobra em 3D: troca de modelo

Não é animação, é substituição — mas é alcançável de Lua e mexe no modelo **da mão**, o que a versão
anterior desta página negava. `HandWeapon.getStaticModel()` resolve
`WeaponSpritesByIndex[modelIndex]` → `staticModel` → `weaponSprite` (ver a seção do `WeaponSprite`), e
**`staticModel` tem precedência sobre `weaponSprite`**. O setter existe e o jogo usa:

```lua
item:setStaticModel(ModelKey.MYSTERY_CAN_OPEN)   -- PZ/media/lua/client/ServerCommands.lua:149
item:setStaticModel(args.modelName)              -- :159
```

Há ainda `setOverrideHandModels(primário, secundário)` e `setOverrideHandModelsString`, usados por
`ISBaseTimedAction` para trocar o que aparece na mão durante uma ação
(`PZ/media/lua/client/TimedActions/ISReadWorldMap.lua:15`, `lua/server/BuildingObjects/ISBuildingObject.lua:340`).

Então pseudo-animação 3D = N blocos `model` com a chama em poses diferentes e um `setStaticModel` por
tick. **Não testado**: falta saber se a troca força o `ResetCharacterEquippedHands` (que é público, mas
sem uso em Lua no jogo) ou se o modelo só atualiza no próximo reequipar, e qual a cadência máxima antes
de ficar caro. É a diferença entre chama tremeluzindo e chama piscando.

## Roupa não passa por aqui

`ClothingItem = WristWatch_Right_ClassicBlack` resolve em
`PZ/media/clothing/clothingItems/WristWatch_Right_ClassicBlack.xml`, não num bloco `model`. E o XML
inverte todas as convenções desta página:

```xml
<m_MaleModel>media\models_X\Static\Clothes\M_WristWatch_Round_Right.X</m_MaleModel>
```

caminho **completo** a partir de `media/`, **com** extensão, **barra invertida**, e o arquivo tem BOM.
Roupa é uma pilha própria (XML + máscaras + `textureChoices`) e não está documentada nesta árvore.

## Lado mod

**Arte vai em `common/`**, não na pasta de versão: é justamente o que não muda entre builds
(ver [carregamento-de-mods.md](carregamento-de-mods.md)). O mod publicado `WS/SiddigoWeapons` é o
exemplo completo e funcional — quatro arquivos, quatro papéis:

```
Contents/mods/SiddigoWeapons/
  42/media/scripts/SiddigoWeapons_Models.txt      ← bloco model (script fica na pasta de versão)
  common/media/models_X/WorldItems/SkullCrusher.fbx   ← mesh = WorldItems/SkullCrusher
  common/media/textures/WorldItems/SkullCrusher.png   ← texture = WorldItems/SkullCrusher
  common/media/textures/Item_SkullCrusher.png         ← Icon = SkullCrusher
```

`SiddigoWeapons_Items.txt:14` declara `Icon = SkullCrusher`, `:15` declara
`WeaponSprite = SkullCrusher` e `:16` declara `WorldStaticModel = SkullCrusher` — os dois últimos
apontando para o mesmo bloco `model`, que é a forma vanilla (ver a seção do `WeaponSprite`).
**Ícone e textura de malha são dois arquivos diferentes** com o mesmo nome-base em pastas
diferentes — a confusão entre os dois é o erro mais fácil de cometer aqui. `[revisto 2026-08-10]`

### O `model` precisa de `module Base`?

**Não.** A dúvida aberta em `criar-conteudo/references/item.md:81` fecha assim: o mod publicado
*Basements* (`STEAM/2849247394`) declara `module BasementMod` em
`media/scripts/BasementMod_Models.txt:1` e referencia o modelo **sem prefixo de módulo** em
`BasementMod_Items.txt:17` (`WorldStaticModel = MagazineBasementsGround`) — mod publicado e em uso, o
que prova que o nome de `model` resolve globalmente, independente do `module` que o declarou.

Ressalva de escopo: esse mod é B41 (`mod.info` sem `versionMin`). Nenhum mod B42 do levantamento
declara `model` fora de `Base` — os dois do workspace (`WS/SiddigoWeapons/.../SiddigoWeapons_Models.txt:1`
e `WS/ModTeste/.../ModTeste_Models.txt:1`) usam `module Base`. Seguir `Base` continua sendo o caminho
já testado aqui; usar o módulo do mod é aceitável e não precisa de prefixo na referência.

## O que falha em silêncio

**Nem todo ícone ausente é silencioso — depende de quem pede.** Ícone de **entidade**, resolvido pelo
`xuiSkin`, é reportado com o nome do ícone e o script que o pediu (`USER/console.txt:116-123`):

```
WARN : General  at XuiSkin$EntityUiStyle.Load             > Could not find icon: Build_AnvilStone, script = Bigorna de Pedra
WARN : General  at XuiSkin$EntityUiStyle.LoadComponentInfo> Could not find icon: Build_AnvilStone
```

O exemplo é do jogo — `Build_AnvilStone` falta no 42.20.2. Já o campo `Icon` de **item** segue sem
evidência de log: nenhuma linha equivalente apareceu para item na sessão observada, mas também não
havia item com ícone quebrado ativo, então é ausência de gatilho e não prova. A lista abaixo trata
todos como silenciosos porque é a hipótese conservadora.

1. `Icon = Item_X` — vira `Item_Item_X`, item sem imagem, `console.txt` limpo.
2. Extensão no `mesh`/`texture` do bloco `model` — o valor é sem extensão. Só `meshFile` de
   `animationsMesh` leva.
3. Ícone e textura de malha trocados: `Icon` procura `Item_<nome>` na raiz de `textures/`;
   `texture` procura `<valor>` relativo a `textures/`. Nomes iguais, arquivos diferentes.
4. Vírgula depois do `}` de um `attachment` — os campos levam vírgula, o bloco filho não.
5. Modelo declarado e nunca referenciado: um bloco `model` sozinho não faz nada. Precisa de
   `WorldStaticModel`/`StaticModel` no item.

**A exceção conhecida: `WeaponSprite` ausente em arma é barulhento.** Estoura
`NullPointerException` por frame no `ModelManager` assim que o item é equipado — ver a seção acima.
Vale registrar porque contraria a expectativa desta página: aqui o `console.txt` **avisa**, e avisa
tanto que o log fica ilegível. `[confirmado 2026-08-10]`

## Pontos a confirmar

- Se o `Item_<nome>.png` de um mod precisa estar na **raiz** de `media/textures/` ou se subpasta
  funciona. Os 6 soltos do jogo estão em subpasta, mas como também estão no `UI2.pack` não provam
  nada. Censo em `STEAM/`: **6.415 ícones na raiz contra 22 em subpasta** — e as 22 estão todas numa
  pasta chamada `OldIcon`, ou seja arte descartada, não contraexemplo em uso. A raiz continua sendo
  o único caminho com uso comprovado.
- Formato do `.pack` e como empacotar textura — mesma pendência de [tiles.md](tiles.md).
- Default de `cullFace` = `Back` e os valores `Back`/`Front`/`None` vêm do PZ-API-Docs
  (`pz-wiki-modding.github.io/PZ-API-Docs/scripts/model.html`); o código só mostra `None`, 18 vezes,
  e os 89 mods de `STEAM/` têm **zero** ocorrências. Sem contraexemplo, o default não é verificável.
- `invertY`: a fonte lista só `invertX`, e o jogo idem. **`invertZ` existe** — 4 usos, todos em mod
  (`STEAM/3260996595/mods/97bushmaster/media/scripts/vehicles/template_BUSH_gasCans.txt:28`), dentro
  de um `model` de veículo, junto de `file` e `offset`. Ou seja o parser aceita `invertZ` embora o
  jogo não o use; `invertY` segue sem nenhuma ocorrência em lugar nenhum.
- Quais nomes de `attachment` o motor reconhece. `world`, `Bip01_Prop1` e `Bip01_Prop2` são os de
  item; os ~50 de `models_characters.txt:8+` são slots de equipamento. A lista válida é do rig, não
  de arquivo de script.
  **Parcialmente refinado em 2026-08-16, e o refinamento é negativo:** o enum
  `zombie.scripting.objects.ModelAttachmentId` (`javap`) tem **8** constantes, com estes valores de
  string — `world`, `head`, `head_hat`, `bowtie`, `Bip01_Prop2`, `Bip01_Prop1`, `knife_shoulder`,
  `muzzle`. **Não é a lista branca**: `generated/models_*.txt` usa **92 nomes distintos** de
  `attachment` (`scope`, `reddot`, `laser`, `recoilpad`, `stomach`, `bedroll_bottom*`, `webbing_*`,
  `belt_*`…), e `ModelAttachment.getAttachmentById` tem sobrecarga por `String` além da por enum. O
  enum é só o subconjunto que o Java referencia por constante; o resto resolve por nome. Continua sem
  levantar **onde** a lista válida é validada, se é.
  **Refinado de novo em 2026-08-16, do lado positivo:** **56** dos 92 nomes têm origem identificada —
  são os `setAttachmentName` das localizações de corpo de `shared/NPCs/AttachedLocations.lua`, e cada
  um é declarado por ao menos um `model` do jogo (ver "Item preso ao corpo: a cadeia de três nomes").
  Para esses, a lista válida **é** de arquivo de script, não do rig. Continua em aberto a origem dos
  **36 restantes** (`world`, `Bip01_Prop*`, `muzzle`, `scope`, `trailer`, `reddot`, `recoilpad`…), e
  continua sem levantar se há validação em algum ponto — nome errado segue sem produzir log.
- ~~Onde `WeaponSprite` resolve.~~ **Resolvido em 2026-08-10** — é nome de bloco `model`, e é
  obrigatório em arma; ver a seção "`WeaponSprite` é o modelo **na mão**". A hipótese antiga desta
  lista (casar com `textures/weapons/<slot>/<valor>.png`) estava **errada**: aquele `.png` é a
  textura da malha, alcançada pelo `mesh` do bloco `model`.
- `WeaponSpritesByIndex` (25 usos em `items/weapon.txt`, ex.: `scripts-txt.md:195`) — presumivelmente
  a forma em lista do `WeaponSprite`, para arma que troca de modelo por estado. **Não levantado**: se
  o índice é o mesmo do `WorldStaticModelsByIndex` e o que o motor faz com ele segue sem `caminho:linha`.
- Se `model` em módulo próprio funciona no **B42** — a evidência acima é B41.
- Pseudo-animação de chama por troca periódica de `WorldStaticModel`/`StaticModel` via
  `item:setWorldStaticModel(...)`: **não testada**. Em aberto o custo (é troca de modelo por tick, não
  de frame), se o modelo equipado na mão troca pelo mesmo caminho — a seção do `WeaponSprite` mostra
  que a mão passa por `addEquippedModelInstance`, que consulta `WeaponSprite`, e **não** foi levantado
  se existe `setWeaponSprite` equivalente — e se o resultado não fica pior que a chama estática.
- Se sprite de tile (`Fire_01_*`) é alcançável por `getSprite()` **a partir de mod**, e se
  `AttachAnim` num `IsoObject` criado por mod (não `IsoFire`) renderiza pelo `FBORenderCell`. O
  caminho existe no motor; nenhum mod de `STEAM/` exercita, então não há uso real para citar.
- **Chama ancorada na mão por mod.** As peças são públicas (`AttachAnim`,
  `CombatManager.getBoneWorldPos` `public static`, `IsoSprite.soffX`/`soffY` `public short`), mas
  **nada disso foi testado**. Em aberto, em ordem de risco: se Lua **escreve** campo público `short`
  de `IsoSprite` (só há leitura observada); qual evento serve para reposicionar por frame
  (`OnRenderTick`/`OnPostRender` existem, mas não foi levantado se rodam antes do render do
  personagem); se `Bip01_Prop1` devolve posição útil em `getBoneWorldPos`, que no jogo só é chamado
  com `Bip01_Spine1`; e o custo de uma chamada de osso por frame por personagem. Zero mods de
  `STEAM/` fazem isso — a ausência é evidência fraca, mas é a que existe.
- Se a caixa da extensão importa: o jogo mistura as duas caixas no mesmo `models_X/`, e não em
  proporção marginal — **1.453 `.fbx` contra 578 `.FBX`, 1.135 `.x` contra 646 `.X`** (mais 60
  `.blend`, 59 `.glb` e 4 `.png`). Como o `mesh` é escrito **sem** extensão, quem resolve a caixa é o
  motor. Irrelevante no Windows, possivelmente não em servidor Linux.

> Última verificação: 2026-08-07 — jogo **42.20.2** (`ffe7a8a4b1`), PZ buildid 24574865, media/
> + sessão in-game (`USER/console.txt` de 2026-08-07 18:46).

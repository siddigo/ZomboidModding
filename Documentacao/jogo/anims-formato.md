# `anims_X/` — o formato do arquivo de clipe

[animacao.md](animacao.md) descreve o **papel** da pasta pelo que `animationsMesh` declara. Esta
página é sobre o **arquivo**: qual formato é, o que tem dentro, por qual nome o resto do jogo o
chama, e o que muda quando quem embarca é um mod.

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\`,
`STEAM/` = `…\steamapps\workshop\content\108600\` (ver [../index.md](../index.md)).
**Somente leitura.**

## O achado que muda a premissa: não é binário

O `index.md` listava `anims_X/` como "2.209 arquivos binários". **São texto ASCII.** Os 2.209
arquivos começam com os mesmos 16 bytes, sem uma única exceção — censo por `head -c 16` em todos:

```
offset 0:  x o f   0 3 0 3 t x t   0 0 3 2
offset 16: \r \n
```

(`PZ/media/anims_X/Bob/Bob_AimHitReact2H_01.X`, offset 0.)

É o cabeçalho do **DirectX `.X`**, e cada campo dele é a resposta a uma pergunta:

| Bytes | Valor | Significa |
|---|---|---|
| 0–3 | `xof ` | magic number do formato |
| 4–7 | `0303` | versão 3.3 |
| 8–11 | `txt ` | **variante texto** (as outras do padrão são `bin `, `tzip`, `bzip`) |
| 12–15 | `0032` | float de 32 bits |

`txt` é o que derruba a premissa: dá para abrir com qualquer editor. As linhas terminam em CRLF
(offset 16–17). A identificação do formato pelos campos do cabeçalho é do padrão DirectX, que é
externo — o que se prova aqui é a sequência de bytes e o fato de o conteúdo ser legível.

Sem `.fbx`, sem `.blend`, sem nada mais: a pasta inteira do jogo tem só `.X` (1.180) e `.x` (1.029),
diferença de caixa apenas.

## O arquivo é autodescritivo

Cada `.X` declara os próprios tipos antes de usá-los, num bloco `template` com o GUID canônico do
DirectX (`PZ/media/anims_X/Chicken/Chk_Chick_Dead.x:36-39`):

```
template Matrix4x4 {
 <f6f23f45-7686-11cf-8f52-0040333594a3>
 array FLOAT matrix[16];
}
```

São 21 ou 22 `template` no topo de cada arquivo — 380 arquivos com 21, 1.829 com 22 (censo por
`grep -c "^template "` nos 2.209). Isso significa que **o arquivo carrega a própria gramática**: não é
preciso conhecer o formato de fora para saber quantos floats tem cada campo.

## O que tem dentro de um clipe

Objetos de topo, na ordem, em `PZ/media/anims_X/Chicken/Chk_Chick_Dead.x`:

| Linha | Objeto | Papel |
|---|---|---|
| `:147` | `Material _14_-_Default` | cor + `TextureFilename { "Chick01.png"; }` (`:153`) |
| `:158` | `Frame Dummy01` | raiz do esqueleto; dentro dela `Frame Bip01` (`:165`), `Frame Bip01_Pelvis` (`:172`)… |
| `:286` | `Frame Chicken_Chick` | contém `Mesh` (`:293`), `MeshNormals` (`:720`), `MeshMaterialList` (`:1148`), `MeshTextureCoords` (`:1380`), `XSkinMeshHeader` (`:1581`) e 14 `SkinWeights` |
| `:2303` | `Frame Translation_Data` | uma `FrameTransformMatrix` isolada, fora da hierarquia do esqueleto |
| `:2311` | `AnimTicksPerSecond` | `4800;` |
| `:2315` | `AnimationSet Chk_Chick_Dead` | os quadros-chave |

Censo do que é universal (varredura nos 2.209):

| Elemento | Arquivos | |
|---|---|---|
| `AnimationSet` | **2.209** | exatamente 1 por arquivo — **zero** arquivos com 2 |
| `AnimTicksPerSecond` | 2.209 | `4800` nos 200 amostrados |
| `Frame Bip01` | 2.209 | |
| `Mesh` + `SkinWeights` + `XSkinMeshHeader` | 2.209 | |
| `Frame Translation_Data` | 2.206 | faltam em `Kate/Kate_Smothered{In,Loop,Out}.X` |
| `TextureFilename` | 2.127 | |

### Cada clipe carrega uma cópia inteira da malha

Não é metáfora: `Mesh`, `MeshNormals`, `MeshTextureCoords` e `SkinWeights` estão nos 2.209 arquivos.
O nome da malha embutida se repete — 1.822 dos 2.209 chamam `Body`, o resto é o bicho
(`DeerStag` 33, `DeerDoe` 33, `Fawn` 31, `CowCalf` 23, `Bob` 21…). E 22 arquivos trazem **mais de uma**
malha (20 com 2, 2 com 3): são as props presas à mão, com nomes como `Handgun`, `BaseballBat`,
`Sledgehammer02`, `Hammer`, `Shotgun`.

É o que explica o tamanho: **508 MB** para 2.209 clipes, de 52 KB (`Chicken/Chk_Chick_Dead.x`) a
744 KB (`Bob/Bob_BandageUpperBody.x`). A geometria está duplicada 2.209 vezes.

Para o modding isso é relevante ao contrário do que parece: a malha que o jogo **usa** vem de
`meshFile` no bloco `animationsMesh` (`PZ/media/scripts/generated/animations_meshes.txt:5`), não do
clipe. O que o exportador escreveu junto é subproduto — ver pendências.

### Os quadros-chave

`AnimationSet` tem um bloco `Animation` por osso, cada um abrindo com a referência ao `Frame`
(`Chk_Chick_Dead.x:2315`):

```
AnimationSet Chk_Chick_Dead {
 Animation {
  { Dummy01 }

  AnimationKey S {
   1;
   2;
   0;3;1.000000,1.000000,1.000000;;,
   1600;3;1.000000,1.000000,1.000000;;;
  }
```

O primeiro número dentro de `AnimationKey` é o **tipo de chave** (`S`=1 escala, `R`=0 rotação com 4
floats, `T`=2 posição com 3 floats — os códigos são do padrão DirectX, não do PZ). O segundo é a
contagem de chaves. Cada chave é `<tick>;<n_floats>;<valores>;;`. O tempo está em **ticks**, e a
escala é `AnimTicksPerSecond` — com 4800, o tick 1600 é 0,333 s.

## A convenção de nome — e por que a chave é o nome do arquivo

17 pastas de ator na raiz (`Bob` 1.650 arquivos, `Zombie` 185, `Sheep` 59, `Deer` 50, `DeerDead` 47,
`Chicken` 46, `Cow` 43, `Pig` 32, `Rabbit` 25, `Turkey` 15, `Turkey_Poult` 14, `Raccoon` 13, `Kate`
11, `Mouse` 9, `Rat` 8, `Mannequin_Scarecrow` 1, `Mannequin_Skeleton` 1). Somam exatamente 2.209.

**Existe aninhamento** — 8 subpastas sob `Bob/`, com 36 arquivos, do tipo
`PZ/media/anims_X/Bob/DraggingBwd/OnBack/HeadEnd/Bob_IdleDragged.x`. E o caminho **não entra na
chave**: `Bob_IdleDragged` é citado 2× em `AnimSets/` como `<m_AnimName>Bob_IdleDragged</m_AnimName>`,
sem pasta nenhuma. O mesmo para `Bob_LaidDown_OnBack` (3×) e `Bob_LayDown_Person_OnBack` (1×). A
subpasta é organização do artista, não namespace.

O nome interno do `AnimationSet` bate com o nome do arquivo em **2.203 dos 2.209**. Os 6 que divergem
são o que prova qual dos dois é a chave:

| Arquivo | `AnimationSet` interno |
|---|---|
| `Bob/Bob_Sit_FishingStrike_Hard.x` | `Bob_Sit_FishingStrike_Normal` |
| `Bob/Bob_SneakToSneakRun2H_Heavy.X` | `Bob_SneakToSneakRun2H_heavy` |
| `Cow/CowCalf_Body.x` | `CowCalf_Walk` |
| `Sheep/Sheep_RamFleece.x` | `SheepRam_Walk` |
| `Sheep/Sheep_RamSheared.x` | `SheepRam_Walk` |
| `Zombie/Zombie_CrawlLunge_Defended.x` | `Zombie_CrawlLunge_Defend` |

Dois casos fecham a questão:

- **`Zombie_CrawlLunge_Defended.x`** diz internamente `Zombie_CrawlLunge_Defend` — e
  `Zombie/Zombie_CrawlLunge_Defend.x` **existe como arquivo próprio**. Se o índice fosse pelo nome
  interno, `Zombie_CrawlLunge_Defended` não teria chave nenhuma. Mas `AnimSets/` o referencia por
  esse nome (1 ocorrência de `m_AnimName`), e é um nome que **só existe como nome de arquivo**.
- **`Sheep_RamFleece.x` e `Sheep_RamSheared.x`** dizem os dois `SheepRam_Walk`, e
  `Sheep/SheepRam_Walk.x` também existe — três arquivos disputando uma chave.

**Conclusão: a chave é o basename sem extensão.** O `AnimationSet` interno é resíduo do exportador —
é a marca de clipe feito por cópia, e nesses 6 casos o artista esqueceu de renomear.

## Quem referencia um clipe — e nunca pela extensão

A string literal `anims_X` tem **zero ocorrências** em `PZ/media/lua`, `PZ/media/scripts`,
`PZ/media/AnimSets`, `PZ/media/animstates` e `PZ/media/animscript`. O caminho da pasta está no Java.
Toda referência a clipe é por **nome nu, sem extensão e sem pasta**:

| Onde | Campo | Exemplo |
|---|---|---|
| `.txt` | `animationDirectory` | `PZ/media/scripts/generated/animations_meshes.txt:6` — `animationDirectory = Bob,` |
| `.txt` | `animationPrefix` | `…animations_meshes.txt:48` — `animationPrefix = Chk_,` |
| `.txt` | `meshFile` | `…animations_meshes.txt:5` — `meshFile = Skinned/MaleBody,` (sem extensão; o arquivo em disco é `models_X/Skinned/MaleBody.x`) |
| `.xml` | `m_AnimName` | `PZ/media/AnimSets/player/aim/aim.xml:4` — `<m_AnimName>Bob_IdleAim1Hand</m_AnimName>` |
| `.xml` | `<Anim>` | `PZ/media/animscript/combat.xml:8` — `<Anim>Bob_IdleHighCoverLeanL</Anim>` (12 ocorrências no arquivo) |

**Nada em `media/` declara a extensão de um clipe.** É o motor que resolve nome → arquivo, e é o que
abre a porta para `.fbx` (adiante).

### `animationPrefix` filtra por nome de arquivo, e `!` exclui

`animationDirectory` diz de qual pasta a malha tira clipe; `animationPrefix` filtra por prefixo do
nome. Três malhas dividem a pasta `Chicken/`, e a galinha adulta se define por exclusão
(`PZ/media/scripts/generated/animations_meshes.txt:44-51`):

```
    animationsMesh Chicken_Hen
    {
        meshFile = Skinned/Chicken_Hen,
        animationDirectory = Chicken,
        animationPrefix = Chk_,
        animationPrefix = !Chk_Chick_,
        animationPrefix = !Chk_Cock_,
    }
```

**`!` no início nega o prefixo.** `Chicken_Chick` (`:53-58`) e `Chicken_Cockrel` (`:60-65`) pegam
justamente os dois excluídos. São 25 linhas `animationDirectory` (16 valores distintos) e 21 linhas
`animationPrefix` no arquivo.

Esse filtro é mais uma prova de que o índice é por nome: prefixo se aplica a nome, não a conteúdo de
arquivo — o motor não abriria 508 MB para descobrir o que carregar.

**`DeerDead/` (47 arquivos) não é valor de nenhum `animationDirectory`** — a pasta existe e nenhum
bloco `animationsMesh` a declara. Ver pendências.

### Cobertura: 1.858 de 1.864 nomes citados existem em disco

Cruzamento completo entre os `<m_AnimName>` de `AnimSets/` (2.412 dos 2.949 `.xml` têm pelo menos um;
1.864 valores distintos) e os basenames de `anims_X/` (2.162 distintos):

- **1.858 casam.**
- 6 não casam: um valor vazio, mais `AnAnim`, `Bed`, `Bob_LureLow`, `Bob_SprintToStop_2h_Heavy` e
  `DeerFawn_IdleEating01`.

Sobram 304 arquivos que nenhum `m_AnimName` cita — esperado, já que `animscript/` e o Java também
disparam clipe.

### O lado Lua

Não há API de carregar clipe. O que existe é leitura da lista, no visualizador de debug
(`PZ/media/lua/client/DebugUIs/AnimationClipViewer.lua:577`):

```lua
	local clips = getAnimationViewerState():fromLua1("getClipNames", modelScriptName)
```

`modelScriptName` é `"MaleBody"` por padrão (`:572`) e, para bicho,
`data.definition:getBodyModelStr()` (`:575`). Ou seja: **o motor entrega o conjunto de clipes
indexado por nome de script de modelo**, não por pasta. Uso observado, não contrato declarado — a
assinatura de `getClipNames` está no Java.

Esse arquivo também é a ferramenta prática de modding aqui: o visualizador lista e toca clipe por
nome dentro do jogo, com filtro de texto (`:580`), tempo em segundos e número do quadro (`:676-684`).

## `anims_X` × `models_X` — a diferença não é o formato

`models_X/` usa o **mesmo** `.X`: todos os 1.781 `.x`/`.X` de lá têm o mesmo `xof 0303txt 0032` no
offset 0. E 741 deles têm `AnimationSet`, 742 têm `SkinWeights` — as roupas e mochilas presas ao
corpo (`PZ/media/models_X/Female_Blouse.X`, `PZ/media/models_X/Skinned/BackPacks/ALICE_Pack_LHand.X`).

A diferença é a pasta, não o conteúdo:

| | `anims_X/` | `models_X/` |
|---|---|---|
| Total | 2.209 | 4.335 |
| `.x`/`.X` | **2.209 (100%)** | 1.781 |
| `.fbx`/`.FBX` | **0** | 2.031 |
| `.blend` | 0 | 60 |
| `.glb` | 0 | 59 |
| `.png` | 0 | 4 |
| Subpastas | 17 de ator (+8 sob `Bob/`) | `IsoObject/`, `Skinned/`, `Static/`, `WorldItems/`, `physics/`, `vehicles/`, `weapons/` |

**52 basenames de `models_X/` existem nas duas extensões** (`BeerBottle`, `Blowtorch`, `Book`,
`Bowl`, `Bucket`, `Burger`, `CDplayer`, `CakeSlice`, …) — `.x` e `.fbx` lado a lado na mesma árvore.
É a evidência de que o motor lê os dois; qual dos dois ele escolhe quando ambos existem, não.

### A divisão real não é por pasta, é rigado × estático

A tabela acima sugere que `.fbx` é coisa de `models_X/`. O corte verdadeiro é outro, e é o que decide
a ferramenta de quem vai animar: **no jogo, tudo que tem esqueleto é `.X`.**

`Skinned/` — o corpo humano, roupa, mochila, barba e os animais — tem **743 `.x` e zero `.fbx`**
(varredura recursiva). Os 2.031 `.fbx` estão todos em pasta de geometria estática:

| Pasta | `.fbx` |
|---|---|
| `WorldItems/` | 1.826 |
| `vehicles/` | 146 |
| `weapons/` | 29 |
| `IsoObject/` | 6 |
| `Static/` | 1 |
| raiz de `models_X/` | 23 |

E rigado dentro dos `.fbx` é caso isolado: só **4 dos 2.031** contêm as strings `LimbNode` (osso) e
`Deformer` (skinning) — `IsoObject/door1.fbx`, `vehicles/ModernCarWithDoors_ez.fbx`,
`vehicles/ModernCarWithDoors_Martin.FBX`, `vehicles/SportsCarWithDoors.fbx`. Porta e veículo;
**nenhum personagem, nenhum animal.** O método é casamento de string ASCII dentro do binário (o FBX
grava nome de classe em claro), não parse de FBX — serve como evidência forte de ausência, não como
prova formal.

As duas famílias de fonte também são só estático: os 60 `.blend` são 58 em `IsoObject/blender/` e 2
em `vehicles/` (`ModernCarWithDoors.blend`, `SportsCar-anims.blend`); os 59 `.glb` são 57 em
`IsoObject/` e 2 em `physics/`.

**Consequência para quem vai animar:** o install **não embarca nenhum rig de personagem ou animal em
formato que o Blender importe nativamente.** `models_X/Skinned/MaleBody.x`, `FemaleBody.x` e os 2.209
clipes de `anims_X/` são todos DirectX `.X`. O rig só entra no Blender por addon de importação de
`.X` ou por fonte externa — e um clipe qualquer de `anims_X/Bob/` serve de ponto de partida, já que
cada um carrega uma cópia inteira da malha e do esqueleto `Bip01` (seção acima). Isso é o inverso do
lado do mod, que exporta 97% em `.fbx`.

## Lado do mod — `.fbx`, não `.X`

Censo em `STEAM/` (89 mods instalados): **16 pastas `anims_X/`, de 10 mods distintos** — o número 16
de [animacao.md](animacao.md) conta pasta, e mods com pasta de versão contam várias vezes
(`FWO Treadmill & BenchPress` aparece 4×, `SkateBoard` 2×, `Lifestyle` 2×).

O que há dentro das 16 somadas:

| Extensão | Arquivos | Cabeçalho (offset 0) |
|---|---|---|
| `.fbx` | **1.295 (97%)** | `Kaydara FBX Binary  ` — **binário**, os 23 bytes idênticos nos 1.295 |
| `.X` | 25 | `xof 0303txt 0032` |
| `.x` | 13 | `xof 0303txt 0032` |

Os 1.295 `.fbx` trazem **versão 7400** (uint32 no offset 23) sem exceção — FBX binário 2014/2015.

**Esta é a inversão que importa:** o jogo embarca 100% `.X` texto; os mods embarcam 97% `.fbx`
binário. Como nada em `media/` nomeia extensão (seção anterior) e `models_X/` do próprio jogo tem as
duas convivendo, a leitura é que **o carregador aceita as duas e o mod não precisa converter para
`.X`**. Dez mods publicados e funcionais é evidência forte; a prova formal está no Java e não é
legível aqui — ver pendências.

Quem ainda usa `.X`: `TMC_TrueActions` (21 arquivos, `versionMin=41.55`, os únicos com prefixo `_` no
nome — `_Bob_Asleep_new.x`), `damnlib` (11), `HFEx` (2), e o `Bob_Run.X` avulso do FWO.

### Pasta de ator ou raiz — os dois layouts existem

| Mod | Caminho | Layout |
|---|---|---|
| `TMC_TrueActions` | `STEAM/2487022075/mods/TMC_TrueActions/media/anims_X/Bob/` | subpasta de ator |
| `Ladders` | `STEAM/2737665235/mods/Ladders/42/media/anims_X/Bob/LadderClimb.fbx` | subpasta de ator |
| `SkateBoard` | `STEAM/3456675747/mods/SkateBoard/42.13/media/anims_X/Bob/` | subpasta de ator |
| `SapphCooking` | `STEAM/2832136889/mods/SapphCooking/media/anims_X/Sapph_BlenderMix.fbx` | **raiz** |
| `Lifestyle` | `STEAM/3403870858/mods/Lifestyle/common/media/anims_X/Bob_Applauding.fbx` | **raiz** (400 arquivos) |

`FWO Treadmill & BenchPress` faz os dois **no mesmo upload**, e a diferença acompanha a pasta de
versão:

- `STEAM/2940354599/mods/FWO Treadmill & BenchPress/media/anims_X/BenchPressIn.fbx` — raiz, pasta sem
  versão (layout pré-B42, ver [carregamento-de-mods.md](carregamento-de-mods.md)).
- `STEAM/2940354599/mods/FWO Treadmill & BenchPress/42/media/anims_X/Bob/BenchPressIn.fbx` — sob
  `Bob/`, na pasta `42/`. Idem em `42.13/` e `42.15/`.

Mesmo mod, mesmos três nomes de arquivo, movidos de raiz para `Bob/` quando ganhou pasta de versão.
Sugere que `Bob/` é o layout do B42 — mas os `mod.info` de `Lifestyle` e `SapphCooking` não declaram
`versionMin` para cruzar, e `Lifestyle` mantém 400 arquivos na raiz inclusive dentro de `common/`.
Fica em pendência.

### `.glb` também é aceito — o caso observável que faltava

**[delta 2026-08-18]** O censo desta página (10 mods, 16 pastas) foi feito sobre 89 itens de
`STEAM/`. Hoje são **12 mods e 18 pastas** `anims_X/`, e os dois novos são de arco:

| Mod | Item | Clipes |
|---|---|---|
| `ArcheryNexus` | `STEAM/3617854007/mods/ArcheryNexus/42.16/media/anims_X/Bob/` | 17 `.fbx` |
| `RadArchery` | `STEAM/3775407541/mods/RadArchery/42/media/anims_X/Bob/` | **24 `.glb`** |

`RadArchery` embarca **só `.glb`** — zero `.fbx`, zero `.X` — em `anims_X/Bob/`, com nomes
`Bob_Rad*_Bow.glb`. É um mod publicado e funcional cujas animações o usuário vê, então a família de
formato aceita em `anims_X/` é **pelo menos três**: `.X`, `.fbx` e `.glb`. Isso muda a resposta
prática de "em que formato exportar" — glTF binário é saída nativa do Blender, sem addon de FBX.

Vale a mesma ressalva de sempre: quem resolve extensão é o Java, não o `media/`. O que se prova aqui
é que um mod distribui `.glb` e o resto do mod (nós de `AnimSets/` apontando para esses nomes) está
escrito assumindo que tocam.

### Convenções que um clipe de mod precisa respeitar

Provado pelo censo do jogo, não pelo Java:

1. **O nome do arquivo é a chave.** É por ele que `m_AnimName` acha o clipe — o nome interno do
   exportador é ignorado (6 contraexemplos acima).
2. **Prefixo importa.** Se o ator tem `animationPrefix`, o nome do arquivo tem de casar com ele para
   o clipe ser visto por aquela malha. Para `Bob`/`Kate`/`Zombie` não há prefixo declarado
   (`animations_meshes.txt:3-9`).
3. **O esqueleto é Biped do 3ds Max.** Os 2.209 arquivos têm `Frame Bip01`, com filhos
   `Bip01_Pelvis`, etc. Um clipe cujo esqueleto não bata com esse vocabulário de osso não tem como
   ser aplicado — o vocabulário global está em `PZ/media/AnimSets/Master_Bones.xml` (ver
   [animacao.md](animacao.md)).
4. **Clipe é conteúdo que não muda entre builds:** vai em `common/media/anims_X/`, não na pasta de
   versão — e o próprio `Lifestyle` (`3403870858`) já faz isso.
5. **O clipe sozinho não toca.** Precisa do nó em `AnimSets/` apontando para ele por `m_AnimName`.
   É a camada 2 de [animacao.md](animacao.md), e é onde 35 dos 89 mods mexem.

### Contraste: `animsold/` é outro formato, e é proprietário

Os 400 arquivos de `PZ/media/animsold/` são `.txt` — não `.X`. Todos os 400 abrem com a mesma linha,
e o formato é da própria IndieStone (`PZ/media/animsold/Bob_Asleep.txt:1-10`):

```
# Project Zomboid Animated Mesh
# File Version:
1.00000000
# Model Name:
Bob_Asleep
# Vertex Stride Element Count:
6
# Vertex Stride Size (in bytes):
76
# Vertex Stride Data:
```

Segue com `VertexArray`, `NormalArray`, `TangentArray`, `TextureCoordArray`, `BlendWeightArray`,
`BlendIndexArray` e o buffer de vértices em texto (`:11-30`). É malha animada em formato caseiro, com
o nome do modelo embutido (`:5`) — o oposto de `anims_X/`, que adotou um formato de indústria. O
nome da pasta e o `File Version: 1.0` indicam legado; se ainda é lido, não foi determinado.

## Pontos a confirmar

- **Se o motor de fato carrega `.fbx` de `anims_X/`.** A evidência é circunstancial e forte — 1.295
  `.fbx` em 10 mods publicados, `models_X/` com 52 basenames nas duas extensões, e nenhuma extensão
  declarada em `media/`. Mas não há `caminho:linha` no `media/` nomeando extensão de clipe: o
  carregador é Java. Fecha com teste in-game (embarcar um `.fbx` e ler o `console.txt`), não com grep.
- **A precedência quando `Nome.X` e `Nome.fbx` coexistem** na mesma pasta. Os 52 basenames duplos de
  `models_X/` são o caso a testar; em `anims_X/` do jogo não ocorre.
- **Se um mod pode substituir um clipe do jogo** gravando o mesmo basename em `anims_X/<Ator>/`, e
  qual ganha. Nenhum dos 10 mods reusa um nome do jogo — não há caso observável.
- **Se a malha embutida em cada clipe é usada ou descartada.** `meshFile` (`animations_meshes.txt:5`)
  aponta para `models_X/`, o que sugere descarte, mas os 2.209 `Mesh`+`SkinWeights` são 508 MB que o
  motor lê. Se o exportador pudesse omiti-los, um clipe de mod ficaria muito menor — vale testar.
- **Se `AnimTicksPerSecond = 4800` é obrigatório.** Constatado em 200 arquivos amostrados, não nos
  2.209, e não se sabe se o motor respeita outro valor ou assume 4800.
- **Se a varredura de `anims_X/<Ator>/` é recursiva.** As 8 subpastas sob `Bob/` (36 arquivos) são
  citadas por nome nu em `AnimSets/`, o que só funciona com recursão — mas isso é inferência do
  cruzamento, não leitura do carregador.
- **Se `Bob/` é exigência do B42 ou só convenção.** `FWO Treadmill & BenchPress` moveu raiz → `Bob/`
  ao ganhar pasta de versão, mas `Lifestyle` mantém 400 arquivos na raiz dentro de `common/`, e os
  `mod.info` de `Lifestyle`, `SapphCooking` e `Ladders` não declaram `versionMin` para cruzar.
- **Por que `DeerDead/` (47 arquivos) não é valor de nenhum `animationDirectory`.** A pasta existe e
  nenhum bloco de `animations_meshes.txt` a declara — clipes órfãos, carregamento por outro caminho,
  ou resíduo.
- **Os 5 `m_AnimName` sem arquivo** (`AnAnim`, `Bed`, `Bob_LureLow`, `Bob_SprintToStop_2h_Heavy`,
  `DeerFawn_IdleEating01`), mais um valor vazio. Não se sabe se falham em silêncio ou se resolvem por
  outra via.
- **A versão máxima de FBX aceita.** Os 1.295 arquivos de mod são todos 7400 (offset 23); se 7500+
  carrega, não há caso observável.
- **Se `.blend` (60) e `.glb` (59) de `models_X/` são carregados** ou são fonte enviada por engano —
  e se `anims_X/` aceitaria os mesmos. Agora estão localizados (`IsoObject/blender/` 58 + `vehicles/`
  2; `IsoObject/` 57 + `physics/` 2, ver seção "rigado × estático"), o que só reforça a hipótese de
  fonte: são as mesmas pastas dos `.fbx` estáticos e nenhum é de personagem. Continua sem prova de
  carregamento.
- **Se algum `.fbx` riggado é de fato carregado como riggado.** Os 4 achados (1 porta, 3 veículos)
  são o único caso observável; se o motor lê o esqueleto deles ou só a geometria, não foi
  determinado. Fecharia a pergunta "o motor aceita esqueleto em FBX?" pelo lado do jogo, que hoje só
  tem resposta pelo lado dos mods.
- **Se a caixa da extensão importa** (`.X` × `.x`, `.fbx` × `.FBX`). O jogo usa as duas em cada
  família, mas em NTFS isso não distingue arquivo; num servidor Linux, distinguiria.
- **`animsold/` está vivo?** 400 `.txt` no formato proprietário `# Project Zomboid Animated Mesh`
  v1.0. Não foi procurada referência a `animsold` no `media/` nesta rodada.
- **Cruzamento com a doc da comunidade não foi feito** nesta rodada (regra 4 de
  [../index.md](../index.md)). O PZ-API-Docs cataloga `animationsMesh` no índice de `scripts/` e
  `animNode` no de `xml` (ver [../fontes-externas.md](../fontes-externas.md)) — é a via para fechar o
  contrato de `animationPrefix` (a semântica do `!` é inferida do caso `Chicken_Hen`, não declarada) e
  os valores permitidos de `animationDirectory`.

> Última verificação: 2026-08-08 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

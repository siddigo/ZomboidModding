# Mapas e zonas — a pasta `maps/` e o registro de metazona

O que existe dentro de `PZ/media/maps/`, quais arquivos o jogo procura em cada cidade, e como o Lua
transforma retângulo declarado em zona registrada no motor. Página de **estrutura e ponto de
entrada**; não é tutorial de construir mapa (isso é TileZed/WorldEd, fora do `media/`).

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\`,
`STEAM/` = `…\steamapps\workshop\content\108600\`.

## O que há em `maps/`

Onze cidades mais `challengemaps/`. O volume é quase todo binário de terreno:

| Extensão | Quantidade | O que é |
|---|---|---|
| `.png` | 4.928 | minimapa e pirâmides de zoom |
| `.bin` | 4.118 | dado de célula |
| `.lotpack` / `.lotheader` | 4.112 / 4.112 | geometria de lote, um par por célula |
| `.lua` | 23 | **tudo que é editável à mão** |
| `.info` | 18 | `map.info`, um por mapa |
| `.xml` | 8 | `worldmap.xml`, `worldmap-forest.xml`, `streets.xml` |
| `.zip` | 5 | pirâmides de imagem do mapa de spawn |

Os 23 `.lua` são o que importa para modding, e a distribuição deles é desigual — **quase todo arquivo
opcional existe uma vez só, na Muldraugh**:

| Arquivo | Quantos mapas têm |
|---|---|
| `spawnpoints.lua` | 14 |
| `objects.lua` | **3** |
| `worldmap-annotations.lua`, `spawnOrigins.lua`, `roomtones.lua`, `regions.lua`, `basements.lua`, `WorldGenOverride.lua` | 1 cada |

Ou seja: **a ausência é o caso normal**, e o jogo tem de funcionar sem cada um deles. Só o
`spawnpoints.lua` é praticamente universal.

### `map.info`

Formato `chave=valor`, uma por linha, sem bloco — não é a sintaxe de `media/scripts`
(`PZ/media/maps/Muldraugh, KY/map.info`):

```
title=Muldraugh P.O.T
fixed2x=true
description=Chunk size is 8x8, Cell size is 256x256
zoomX=11181
zoomY=9725
zoomS=13.5
demoVideo=Muldraugh.bik
```

`title` é o nome exibido; `zoomX`/`zoomY`/`zoomS` posicionam a câmera do mapa-múndi;
`description` aqui é texto livre e, neste caso, descreve a grade — não é contrato.

## `doMapZones()` — o ponto de entrada

Tudo que é zona declarada em Lua passa por
**`PZ/media/lua/server/metazones/metazoneHandler.lua`** (180 linhas), registrado em dois eventos no
fim do arquivo (`:178-179`):

```lua
Events.OnLoadMapZones.Add(doMapZones);
Events.OnLoadMapZones.Add(doSpawnOrigins);
```

`doMapZones` (`:82`) percorre `getLotDirectories()` **de trás para frente**
(`for i=dirs:size(),1,-1`, `:84`) e, para cada pasta de mapa, tenta quatro arquivos:

| Arquivo | Onde é lido | Se faltar |
|---|---|---|
| `objects.lua` | `:86-131` | `DebugType.Lua:warn('can\'t find map objects file: …')` (`:130`) |
| `regions.lua` | `:132-151` | silêncio |
| `roomtones.lua` | `loadRoomTones`, `:67-80` | silêncio |
| `spawnOrigins.lua` | `doSpawnOrigins`, `:160-176` | silêncio |

**A ordem reversa importa para mod de mapa**: quem entra depois em `getLotDirectories()` é processado
primeiro. E `getWorld():removeZonesForLotDirectory()` (`:88`) é chamado antes de reprocessar uma
pasta, então recarregar não duplica zona.

### O idioma de carga é global + `reloadLuaFile`

Os arquivos de mapa não retornam valor nem usam `require`. Eles **atribuem uma global** (`objects` ou
`regions`), e o handler prepara e limpa essa global em volta da chamada (`:89-91`):

```lua
objects = {}
reloadLuaFile(file)
for k,v in ipairs(objects) do
```

Depois de consumir, faz `table.wipe(v)` por item e `table.wipe(objects)` no fim (`:125-128`) — o dado
é grande e é descartado na hora. Consequência prática: **o nome da global é o contrato**. Um
`objects.lua` de mod que declare `local objects = {…}` não é visto, e isso falha em silêncio, porque
o `ipairs` roda sobre a tabela vazia que o handler acabou de criar.

`spawnOrigins.lua` reusa a global `objects` (`:165`), não uma própria.

### Os tipos que o handler reconhece

Dentro de `objects.lua`, o despacho é por `v.type` (`:94-124`):

| `type` | Vai para | Exige `properties` |
|---|---|---|
| `Animal` | `registerAnimalZone` / `registerGeometryZone` | não |
| `Basement` | `Basements.getAPIv1():registerBasementSpawnLocation` | não |
| `Mannequin` | `registerMannequinZone` | **sim** — erro e `return` se faltar (`:16-19`) |
| `RoomTone` | **nada** — a chamada está comentada (`:101`); vem do `roomtones.lua` | — |
| `SpawnOrigin` | `registerSpawnOrigin` | não |
| `WaterFlow` | `registerWaterFlow` | **sim**, mais `WaterDirection` e `WaterSpeed` |
| `WaterZone` | `registerWaterZone` | **sim**, mais `WaterGround` e `WaterShore` |
| `Region`, `BuildingName` | `registerZone` | não |
| *(tem `geometry`)* | `getMetaGrid():registerGeometryZone` | não |
| `WorldGen` | `getMetaGrid():registerWorldGenZone` | não |
| *qualquer outro* | `registerVehiclesZone`, e se devolver `nil`, `registerZone` (`:120-123`) | não |

Duas coisas que só se veem lendo o despacho inteiro:

- **O default não é "ignorar", é "tentar zona de veículo".** Um `type` desconhecido cai no `else` e
  é oferecido a `registerVehiclesZone` antes de virar zona genérica. Errar o nome do `type` não
  produz erro — produz uma zona genérica registrada com o nome errado.
- **Quatro handlers validam `properties` e falham alto**, com `print('ERROR: …')` ou
  `DebugType.Lua:error` citando arquivo e coordenada (`:16`, `:24`, `:38-44`, `:51-61`). É a exceção
  na área: quase tudo aqui é silencioso, esses quatro não. Ver
  [testar-e-debugar.md](testar-e-debugar.md).

### Os sete `type` que o handler pula

A primeira linha do laço (`:93`) exclui nominalmente `Vegitation`, `DeepForest`, `Forest`,
`TownZone`, `Farm`, `FarmLand` e `TrailerPark`. São os nomes de **zona de coleta**: eles existem no
`objects.lua`, mas não viram metazona — quem os consome é o sistema de foraging, no Java. Detalhe
completo em [coleta-foraging.md](coleta-foraging.md).

## Zona de spawn — outro arquivo, outro caminho

Ponto de spawn **não** passa pelo `metazoneHandler`. Quem resolve é
`PZ/media/lua/shared/SpawnRegions.lua`, em `SpawnRegionMgr.getSpawnRegionsAux()` (`:61`), com uma
cadeia de precedência:

1. **Servidor dedicado**: `<NomeDoServidor>_spawnregions.lua`, se `serverFileExists` (`:64-66`).
2. **Cliente em multiplayer**: pede ao servidor, `getServerSpawnRegions()` (`:72`).
3. **`media/maps/<Mapa>/spawnregions.lua`**, se existir (`:76-77`).
4. **Senão**, `createRegionFile()` (`:82`) — função do motor, sem definição em `media/lua`.

O detalhe que interessa: **nenhuma cidade do jogo tem `spawnregions.lua`** (o censo dos 23 `.lua` não
mostra nenhum), então o caminho 4 é o que roda de fato no jogo base, e o `spawnpoints.lua` que existe
em 14 mapas é lido por dentro dele — o trecho que o citava explicitamente está comentado (`:80`).

**`getWorld():getMap()` pode conter `;`** — a condição `not MAPNAME:contains(";")` (`:76`) só tenta o
`spawnregions.lua` quando **não** há ponto-e-vírgula. É o sinal de que o nome do mapa carrega uma
lista de mapas empilhados, que é como mod de mapa se combina com o mapa base; com pilha, o jogo
recusa o arquivo por mapa e vai para o motor.

`getSpawnRegions()` termina com `triggerEvent("OnSpawnRegionsLoaded", regions)` (`:90`), e **só no
lado não-cliente**.

### O prédio de spawn e o alarme em multiplayer `[levantado 2026-10-31]`

Tudo nesta subseção é bytecode do `.jar` (`javap -p -c`), sem Lua do jogo no caminho.

- **Quem dispara o alarme de prédio é o servidor.** `IsoGameCharacter.updateInternal` testa
  `getRoom().building.def:isAlarmed()` e chama `AmbientStreamManager.doAlarm`, mas pula o bloco
  quando `GameClient.client` é verdadeiro. Desarmar no cliente não tem efeito em MP.
- **O vanilla desarma o prédio de spawn na conexão.** `GameServer.receivePlayerConnect` chama
  `preventIndoorZombies(x, y, z)` com a posição do jogador naquele instante, e ela só faz
  `BuildingDef.setAllExplored(true)` + `setAlarmed(false)` se `SpawnPoints.isSpawnBuilding(def)`.
  Personagem novo escolhe o spawn depois de conectar, então essa posição pode não ser a casa onde ele
  nasce. Há relato de jogador de alarme disparando no spawn em MP, e essa é a hipótese.
- API de prédio: `BuildingDef:isAlarmed()`, `:setAlarmed(boolean)`, `:isAllExplored()`,
  `:setAllExplored(boolean)`; `IsoBuilding:TriggerAlarm()`.
- **Não há evento Lua de servidor para "jogador criado".** Os `triggerEvent` de `GameServer.class`
  são `OnClientCommand`, `OnGameBoot`, `OnGameTimeLoaded`, `OnReceiveItemListNet` e
  `OnServerStarted`. Um mod que precise agir no spawn vai do cliente (`OnCreatePlayer`) ao servidor
  por comando — ver [persistencia-e-multiplayer.md](persistencia-e-multiplayer.md).

## O evento `OnSpawnRegionsLoaded` é da classe invisível

`OnSpawnRegionsLoaded` é disparado por `triggerEvent` e **não tem nenhum `LuaEventManager.AddEvent`
nem nenhum `Events.OnSpawnRegionsLoaded` em todo o `media/lua`** — a única ocorrência do nome é o
próprio disparo. É o mesmo padrão dos seis eventos do sistema de coleta, e mostra que a classe não é
particularidade do foraging. Ver [eventos-lua.md](eventos-lua.md).

## `WorldGen/` — geração procedural, fora de `maps/`

`PZ/media/lua/server/WorldGen/` tem seis `.lua` de topo — `Biomes.lua`, `Features.lua`, `Roads.lua`,
`Selection.lua`, `Veins.lua`, `WorldGen.lua` — mais quatro pastas: `attachments/`, `biomes/`,
`features/`, `prefabs/`. É o que preenche o mundo fora do lote desenhado à mão; um mapa pode
sobrepor parâmetros com `WorldGenOverride.lua` na própria pasta, que só a Muldraugh usa.

Não confundir com o `type = "WorldGen"` do `objects.lua`, que registra uma **região** para o gerador
(`registerWorldGenZone`, `metazoneHandler.lua:118`) e não define geração.

## Pontos a confirmar

- ~~**Conteúdo de `WorldGen/`**~~ — **resolvido**: ganhou página própria, [worldgen.md](worldgen.md).
  As seis unidades de topo e as quatro pastas estão abertas lá. O que continua aberto e é **desta**
  página: **como o terreno gerado se combina com as cidades feitas à mão** de `media/maps/`.
- **O que `getLotDirectories()` devolve para um mod de mapa** e como um mod entra nessa lista. A
  função é do motor, sem definição em `media/lua`; sem isso, a ordem reversa descrita acima é
  contrato observado mas não controlável.
- **A imagem de bioma** que o `biome_map_config` indexa por pixel não foi localizada — pendência
  compartilhada com [coleta-foraging.md](coleta-foraging.md).
- **`spawnregions.lua`**: o formato não é verificável no `media/`, porque nenhuma cidade traz o
  arquivo. Só `loadSpawnRegionsFile` (`SpawnRegions.lua:66`) e o comentário da linha 80 sugerem a
  forma `{ name = …, file = … }`.
- **`createRegionFile()`** é do motor e decide o spawn no caso mais comum do jogo. O que ela lê, e se
  respeita `spawnpoints.lua` de mod, não é decidível aqui.
- **Se um mod pode trazer `objects.lua`/`regions.lua`** para um mapa **do jogo**, ou se o arquivo só
  é lido da pasta do próprio mapa do mod. O `removeZonesForLotDirectory` por pasta (`:88`) sugere
  isolamento por diretório, o que apontaria para "não" — mas é inferência.
- **Formato de `.lotpack`/`.lotheader`/`.bin`** — binário. Nada em `media/lua` os monta; são saída
  de ferramenta, como o `.pack` de [tiles.md](tiles.md). `[2026-11-01, buildid 25485521]` O
  **registro de cômodo do `.lotheader`** foi lido por bytes, e é o único jeito achado de localizar
  um tipo de prédio no mapa. Em `media/lua` não há nada que devolva o nome da cidade de uma
  coordenada ou que procure prédio por nome de cômodo (ver
  [distribuicao-loot.md](distribuicao-loot.md), "Prédio e cômodo são metadado do mapa").
  - No B42 **o mapa inteiro mora em `Muldraugh, KY/`** (12.213 arquivos, 4.065 `.lotheader`). As
    outras dez pastas de cidade têm 3 arquivos cada (`map.info`, `spawnpoints.lua`, `thumb.png`). A
    cidade de uma coordenada só se deduz por proximidade, por exemplo com os `posX/posY` do
    `spawnpoints.lua` de cada pasta.
  - Nome do arquivo `cx_cy.lotheader` = célula de **256 tiles**; coordenada do mundo = `c*256 + local`.
  - O cabeçalho abre com `LOTH` + int32 `1` + a lista de tiles terminados em `\n`. Cada cômodo vem
    como nome terminado em `\n`, int32 nível (z, pode ser negativo), int32 número de retângulos e,
    para cada retângulo, int32 `x, y, w, h` **locais à célula**, little-endian. Isso foi observado em
    `Muldraugh, KY/25_21.lotheader`, no offset `0x1daf1` (`secondaryhall`, nível 1, 6 retângulos). O
    resto do registro e o bloco de prédios não foram decodificados.
  - Conferência: `Muldraugh, KY/32_45.lotheader` dá o `secondaryhall` no nível 0 em x 8326–8356,
    y 11595–11633, que é a escola de Rosewood.
  - A confirmar: se este layout vale para todo `.lotheader` (versão diferente de `1`), o que vem
    depois dos retângulos e se a leitura bate in-game com `getRoomAt` no mesmo ponto.
- **`worldmap.xml`, `worldmap-forest.xml`, `streets.xml`** — **abertos**; o que sobra é a semântica
  das propriedades. Os dois formatos:

  `worldmap.xml` é geometria vetorial por célula, com propriedades nomeadas
  (`PZ/media/maps/challengemaps/Kingsmouth/worldmap.xml:2-5`):

  ```xml
  <world version="1.0">
   <cell x="100" y="100">
    <feature>
     <geometry type="Polygon">
      <coordinates>
       <point x="298" y="214"/>
  ```

  Em `Muldraugh, KY/worldmap.xml` são 13.763 `<properties>` e 13.742 `type="Polygon"` — ou seja,
  **quase toda feature é polígono**. As propriedades mais frequentes são
  `building` (`Residential` 5.969, `Industrial` 1.227, `yes` 1.071, `RetailAndCommercial` 679),
  `RoomTone` (`HouseSuburb` 2.098, `HouseSmall` 973, `HouseGarage` 879),
  `highway` (`secondary` 1.522, `tertiary` 999) e `water` (`river` 576). É o dado que alimenta o mapa
  do jogador e, pelo nome, o `RoomTone` do áudio ambiente ([som.md](som.md)).

  `streets.xml` é linha nomeada com largura
  (`PZ/media/maps/Muldraugh, KY/streets.xml:1-5`, 8.933 linhas):

  ```xml
  <streets version="1">
      <street name="Oak St" width="8">
          <points>
              <point x="10961.0" y="6635.0"/>
  ```

  Note que aqui as coordenadas são **absolutas do mundo em float** (10961.0), contra as relativas à
  célula em inteiro do `worldmap.xml`. Os dois arquivos não compartilham sistema de coordenadas.

  Segue aberto: o **vocabulário completo** de `building`, `RoomTone` e `highway`; se um mod pode
  acrescentar valor novo; e se `worldmap-forest.xml` usa o mesmo esquema com outro conjunto de
  propriedades — só o `worldmap.xml` foi censado.
  `worldmap-annotations.lua` tem editor no jogo
  (`client/ISUI/Maps/Editor/WorldMapEditorMode_Annotations.lua`) e continua sem cruzamento.
- **`basements.lua` e os 147 `.pzby` de `basement_access/`** — a ligação é
  `Basements.getAPIv1():registerBasementSpawnLocation` (`metazoneHandler.lua:11`), mas a API v1 em
  si (`lua/shared/ProceduralBasements/`) não foi levantada. Ver [mapa-media.md](mapa-media.md).
- `[2026-10-31]` **Por que o alarme do spawn dispara em MP**: a hipótese da posição na conexão (ver "O prédio de
  spawn e o alarme em multiplayer") não foi testada, e `SpawnPoints.isSpawnBuilding` não foi
  desmontado. Também não se sabe se o desarme feito por comando chega antes do 1º update do
  personagem no servidor.

> Última verificação: 2026-08-07 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

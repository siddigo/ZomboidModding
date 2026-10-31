# Música e rádio

Duas áreas pequenas que ficaram de fora de [som.md](som.md), que cobre efeito sonoro. Música é
config em Lua sobre arquivos `.ogg`; rádio é **um** `.xml` de 1,5 MB.

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\` (ver
[../index.md](../index.md)). **Somente leitura.**

## Música

### Os arquivos

`PZ/media/music/` tem 39 arquivos, todos `.ogg`, em três níveis:

| Onde | Conteúdo |
|---|---|
| raiz | `theme2.ogg`, `preface.ogg`, `misc.ogg`, `tunedeath.ogg`, `ambient1.ogg`, `ambient2.ogg` |
| `ambient/` | 7 — `BrassAmbient`, `CreepyAmbient`, `IntenseAmbient`, `PercussiveAmbient`, `RhythmicAmbient`, `VoiceAmbient`, `ZombieAmbient` |
| `luatriggered/` | 26 — `alone`, `chase`, `desperate_escape`, `fight_or_flight`, `the_horde`, `work_fast`, … |

O nome da pasta `luatriggered/` é literal: são as faixas escolhidas pelo Lua, e é onde a config
abaixo manda.

### Os três `.lua` de config

`PZ/media/lua/client/Music/` — 884 linhas no total, e **os três são tabelas declarativas**, o
formato mais fácil de estender de todo o jogo:

| Arquivo | Linhas | Papel |
|---|---|---|
| `MusicChoices.lua` | 837 | catálogo de faixas com pontuação, e a lógica de escolha |
| `MusicIntensityConfig.lua` | 33 | **evento → intensidade** |
| `MusicThreatConfig.lua` | 14 | **estado contínuo → intensidade** |

#### `MusicIntensityConfig.lua` — evento pontual

Arquivo inteiro é uma lista e uma chamada final:

```lua
local events = {}
events.VERSION = 1

table.insert(events, { id = "ClimbThroughWindow", intensity = 30.0, duration = 30000 })
table.insert(events, { id = "DoorClose", intensity = -10.0, duration = 30000, multiple = false })
table.insert(events, { id = "InsideBuilding", intensity = -40.0, duration = -1, multiple = false })
table.insert(events, { id = "VehicleEnter", intensity = 50.0, duration = 120000 })
…
MusicIntensityConfig.getInstance():initEvents(events)
```

Contratos que o arquivo entrega:

- **`intensity` é assinada.** Negativo acalma a trilha — `InsideBuilding` vale `-40.0`,
  `SeeUnexploredRoom` vale `-30.0`.
- **`duration = -1` significa permanente** enquanto a condição valer (`InsideBuilding`).
  Os demais usam milissegundos (`30000` = 30 s, `120000` = 2 min).
- **`multiple = false` impede empilhar** o mesmo evento. Ausente = pode acumular.
- `events.VERSION = 1` acompanha a lista.

#### `MusicThreatConfig.lua` — estado contínuo

Mesmo formato, 14 linhas, e traz um comentário que é o contrato da unidade
(`MusicThreatConfig.lua:7`):

```lua
-- all of these values are multiplied x 0.01 code side
table.insert(statuses, { id = "ZombiesVisible", intensity = 10.0 })
table.insert(statuses, { id = "ZombiesTargeting.DistantNotMoving", intensity = 10.0 })
table.insert(statuses, { id = "ZombiesTargeting.NearbyMoving", intensity = 1000.0 })

MusicThreatConfig.getInstance():initStatuses(statuses)
```

Ou seja, **os valores são centésimos** — `1000.0` vira `10.0`. O `id` aceita ponto como separador de
sub-estado (`ZombiesTargeting.NearbyMoving`).

#### `MusicChoices.lua` — o catálogo

Três listas: `choices` (`:86`), `ambient` (`:280`) e `remasteredchoices` (`:325`). Cada entrada é

```lua
        {
            file="OldMusic_alone",
            scores = {
                drama = 3,
                bias = 5,
            }
        },
```

(`:87-92`.) `file` é o **nome do evento de som**, não o caminho do `.ogg` — o prefixo `OldMusic_`
não corresponde a pasta nenhuma de `music/`. A ligação passa pelo banco FMOD, mesma mecânica descrita
em [som.md](som.md).

A seleção é `MusicChoices.get(drama)` (`:39`) e `getAmbient(drama)` (`:60`), que ordenam por
`compareByDrama` (`:5`): a faixa vencedora é a de menor `|drama_atual − drama_da_faixa| − bias`, com
a última tocada penalizada em `100000` para não repetir (`:9-14`). `bias` é, então, um empurrão fixo
a favor da faixa — quanto maior, mais provável.

### Recarregar sem reiniciar

O painel de debug de áudio chama
`reloadLuaFile("media/lua/client/Music/MusicIntensityConfig.lua")`
(`lua/client/DebugUIs/DebugMenu/Audio/ISMusicIntensityEventsPanel.lua:78`) — ou seja, a config de
intensidade é **recarregável em runtime**. Ver [testar-e-debugar.md](testar-e-debugar.md), que já
cobre `reloadLuaFile` e a ressalva de que todo caminho observado é relativo à instalação do jogo.

O mesmo painel expõe `player:getMusicIntensityEvents()` (`:31`, `:47`) e um botão de limpar (`:74`).

## Rádio

### Um arquivo

`PZ/media/radio/RadioData.xml` — **1,5 MB, 15.455 linhas, e é o único arquivo da pasta.** Quatro
elementos de topo:

```
<RootInfo>   metadados (SourceFile, FileGUID, Version)
<Voices>     paleta de cor por locutor
<Adverts>    anúncios
<Channels>   as estações
```

`RootInfo` traz `<SourceFile>Radio</SourceFile>` e um `<FileGUID>`, mesmo idioma de GUID visto em
[roupa.md](roupa.md).

`Voices` é só cor: cada `<VoiceEntry ID="…">` tem um `<FinalColor r g b>` — é o que pinta a linha na
janela do rádio.

### A hierarquia de `Channels`

Quatro níveis aninhados (`radio/RadioData.xml:843` em diante):

```xml
<ChannelEntry ID="…" name="LBMW - Kentucky Radio" cat="Radio" freq="93200" startscript="main">
  <ScriptEntry ID="…" name="init_infection" startdelay="0" timestampmode="Static" loopmin="1" loopmax="1">
    <ExitOptions/>
    <BroadcastEntry ID="…" timestamp="0" endstamp="360" type="ActivateBroadcast" day="0"
                    advertCat="…" isSegment="false">
      <LineEntry ID="…" r="128" g="128" b="255" codes="BOR-1" />
```

| Nível | Chaves |
|---|---|
| `ChannelEntry` | `name`, `cat` (`Radio`), **`freq`** (93200 = 93,2 MHz), `startscript` |
| `ScriptEntry` | `name`, `startdelay`, `timestampmode` (`Static`), `loopmin`/`loopmax` |
| `BroadcastEntry` | `timestamp`/`endstamp` (segundos), `type`, **`day`**, `advertCat`, `isSegment` |
| `LineEntry` | `r`/`g`/`b`, `codes` |

Pontos que importam: **`freq` é a frequência em kHz** e é o que o jogador sintoniza; **`day`** é o dia
de jogo em que a transmissão entra, o que é a espinha da narrativa do rádio; `codes` (`BOR-1`)
aparece em parte das linhas e não em outras.

**O texto das falas não está aqui** — `LineEntry` só tem ID e cor. A tradução do rádio vive em
`media/lua/shared/Translate/<IDIOMA>/Radio_*.json`, ver
[carregamento-de-mods.md](carregamento-de-mods.md).

### O Lua de rádio

Poucos arquivos, espalhados pelas três raízes:

| Caminho | Arquivos |
|---|---|
| `lua/client/RadioCom/` | `ISRadioAction.lua`, `ISRadioWindow.lua`, mais `ISUIRadio/`, `RadioWindowModules/`, `StoryLineSounds/` (28 `.lua` no total, ver [mapa-media.md](mapa-media.md)) |
| `lua/server/radio/` | `ISDynamicRadio.lua`, `ISWeatherChannel.lua` |
| `lua/shared/RadioCom/` | `ISRadioInteractions.lua` |

`ISDynamicRadio.lua` e `ISWeatherChannel.lua` são os dois canais gerados em runtime, e portanto o
exemplo mais próximo de "canal feito por código" que o jogo tem.

O item de rádio em si é `ItemType` próprio — `PZ/media/scripts/generated/items/radio.txt`, ver
[mapa-media.md](mapa-media.md).

## Mídia gravada — VHS e CD `[novo: levantado 2026-09-30]`

**Uma fita não é um item.** O item é genérico — `VHS_Retail` e `VHS_Home`
(`PZ/media/scripts/generated/items/normal.txt:4984` e `:4996`), cada um só com
`MediaCategory = Retail-VHS` / `Home-VHS` — e o conteúdo é sorteado, na criação do item, entre as
entradas registradas naquela categoria. "Criar três fitas" num mod é registrar três entradas, e não
escrever bloco `item` nem mexer em loot: elas aparecem onde o `VHS_Retail` do jogo já aparece.

O registro é a tabela global `RecMedia`, declarada com `RecMedia = RecMedia or {}`
(`PZ/media/lua/shared/RecordedMedia/ISRecordedMedia.lua:1`) — idioma que deixa mod somar. Os dados
do jogo estão em `shared/RecordedMedia/recorded_media.lua` (gerado, 352 entradas); a entrada
canônica de fita de habilidade é `:5515`:

```lua
RecMedia["dedd4e83-6e3b-4f4f-9c9b-72a5ed08969d"] = {
	itemDisplayName = "RM_65319278-…",
	title = "RM_8beec5f7-…",
	subtitle = "RM_871ef7dc-…",
	author = nil,
	extra = nil,
	spawning = 0,
	category = "Retail-VHS",
	lines = {
		{ text = "RM_ef90911d-…", r = 0.00, g = 0.69, b = 0.31, codes = "BOR-1" },
		{ text = "RM_c7bd1d0a-…", r = 0.00, g = 0.69, b = 0.31, codes = "CRP+1" },
```

`ISRecordedMedia.init` percorre a tabela no evento `OnInitRecordedMedia` (`:31`) e chama
`register(category, id, itemDisplayName, spawning)` (`:16`) e `addLine(text, r, g, b, codes)`
(`:26`). Contrato:

- **A chave de `RecMedia` é só um id.** O jogo usa UUID; o mod Lifestyle usa nome legível
  (`RecMedia["DancingTraining01"]`,
  `STEAM/3403870858/mods/Lifestyle/common/media/lua/shared/RecordedMedia/LSVHS.lua`).
- **Todo texto é chave de tradução com prefixo `RM_`**, em `Translate/<IDIOMA>/Recorded_Media.json`
  (`EN/Recorded_Media.json:3185` é o `itemDisplayName` da fita acima). É mais um arquivo que manteve
  prefixo no B42 — ver [carregamento-de-mods.md](carregamento-de-mods.md).
- **`spawning` é raridade, 0 a 2.** Pelo bytecode de `zombie.radio.media.RecordedMedia`
  (`SPAWN_COMMON = 0`, `SPAWN_RARE = 1`, `SPAWN_EXCEPTIONAL = 2`; afirmação de `.jar`, buildid
  25485521): `getRandomFromCategory` sorteia 0–999 e vai para a tabela 2 abaixo de 100, para a 1
  abaixo de 400 e para a 0 no resto, caindo para a 0 quando a sorteada está vazia. As fitas de
  habilidade do jogo usam `0`.

### Os `codes` de uma linha — e por que mod não consegue somar código

Isto vale para `LineEntry` de rádio e para linha de fita: é o mesmo interpretador,
`PZ/media/lua/shared/RadioCom/ISRadioInteractions.lua`. O formato é posicional — três letras de
código, um operador (`+`, `-`, `=`), o valor; vários separados por vírgula (`:214-220`). `BOR-1`
tira tédio, `CRP+1` dá XP de carpintaria, `RCP=<receita>` ensina receita (`:232`).

- **XP de habilidade = 50 × valor**, por `addXp` (`:10`, `:16`), e nada acima do nível
  `SandboxVars.LevelForMediaXPCutoff` (`:7`).
- **Cada linha rende uma vez por personagem**: `checkPlayer` (`:182`) sai cedo em
  `isKnownMediaLine` e marca com `addKnownMediaLine` (`:194-197`).
- Há um cooldown de 30 ticks por código (`:227`).
- **A tabela de códigos é `local Interactions`** (`:90`). Não há como acrescentar entrada de fora, e
  código desconhecido é ignorado sem erro (`:223`).

A rota de mod é envolver `checkPlayer`, que é campo da instância e é chamado por lookup
(`self.checkPlayer(…)` dentro de `OnDeviceText`). O Lifestyle reimplementa a função inteira para os
códigos dele (`…/Lifestyle/common/media/lua/shared/RadioCom/zISRadioInteractions_lsHook.lua`);
basta menos: consultar `isKnownMediaLine` antes, chamar a original, e dar o XP se a linha passou a
ser conhecida. A instância nasce em `OnGameBoot` (`:353`) e `getInstance()` é idempotente.

## Pontos a confirmar

- **Se um mod pode acrescentar faixa** a `MusicChoices.choices`. É tabela global montada em carga, o
  mesmo idioma de `Definitions/`, mas nenhum dos 89 mods de `STEAM/` foi cruzado para isso nesta
  rodada.
- **Como `file="OldMusic_alone"` resolve para um `.ogg`.** O prefixo não bate com pasta de `music/`,
  o que aponta para evento FMOD — mas isso não foi confirmado, e é a mesma incógnita de
  [som.md](som.md) sobre registro de evento FMOD por mod.
- **A lista de `id` válidos** em `MusicIntensityConfig` e `MusicThreatConfig`. Os arquivos listam os
  usados; se o motor aceita `id` novo vindo de mod, ou só reconhece os que ele mesmo dispara, é a
  diferença entre a área ser moddável ou só configurável. Provável que seja o segundo — os `id` são
  eventos do motor (`ClimbThroughWindow`, `VehicleTireExplode`) —, mas não foi verificado.
- **`MusicIntensityConfig.getInstance()` e `MusicThreatConfig.getInstance()`** são Java; a chamada
  `initEvents`/`initStatuses` **substitui** ou **soma**? Se substitui, um mod que chame de novo apaga
  a lista do jogo — risco concreto e não resolvido.
- **A faixa de valores de `drama`.** Os `scores.drama` observados são 2 e 3; `MusicChoices.drama`
  começa em 0 (`:2`). O teto não está no arquivo.
- **`timestampmode`, `type` e `ExitOptions`** de `RadioData.xml` — só um valor de cada foi observado
  (`Static`, `ActivateBroadcast`, elemento vazio). O censo completo dos 15.455 linhas não foi feito.
- **Se um mod pode trazer `radio/RadioData.xml` próprio**, e se soma ou substitui. Nenhum censo em
  `STEAM/` foi feito para rádio nesta rodada.
- ~~**O que `codes="BOR-1"` significa** em `LineEntry`.~~ — **RESOLVIDO em 2026-09-30**: ver "Os
  `codes` de uma linha".
- **Se o invólucro de `checkPlayer` dá XP em dobro em multiplayer.** `OnDeviceText` tem ramo de
  servidor e de cliente (`ISRadioInteractions.lua:261-278`) e nenhum dos dois testa o outro lado; o
  jogo tem a mesma exposição para os códigos dele. Não observado em servidor.
- **Se fita de mod entra no sorteio de um save já existente.** `RecordedMedia` grava índices em
  arquivo próprio (`SAVE_FILE`, bytecode); o efeito de acrescentar entrada depois não foi aberto.
- **Nenhuma fonte da comunidade foi cruzada** para música ou rádio nesta rodada.

> Última verificação: 2026-08-07 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

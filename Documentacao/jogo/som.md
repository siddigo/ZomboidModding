# Som — o bloco `sound`, o registro de nomes e quem toca

Como um som existe no Project Zomboid, quem aponta para ele e por que a forma que o jogo usa **não é
a forma que um mod pode usar**.

Aliases: `PZ/` = instalação do jogo, `WS/` = `~\Zomboid\Workshop\`. Ver
[../index.md](../index.md).

## Duas coisas diferentes se chamam "som"

O erro de partida é achar que é um sistema só. São dois, independentes, e nenhum chama o outro:

| | **Áudio** | **Ruído** |
|---|---|---|
| O que é | o que o jogador ouve | o que o zumbi ouve |
| Entrada | bloco `sound` + campo de `item` / `vehicle` / Lua `playSound` | função Lua `addSound(...)` |
| Se faltar | silêncio | nenhum zumbi vem |

`addSound` **não toca nada** — ela injeta um evento de ruído no mundo, com raio e volume próprios.
`PZ/media/lua/client/BuildingObjects/TimedActions/ISBuildAction.lua:103` faz as duas coisas em
sequência, e é o exemplo canônico da diferença: `getEmitter():playSound("Hammering")` na linha 87 dá
o áudio da martelada, `addSound(...)` na 103 é o que atrai a horda. Um mod que só faz a primeira tem
uma serra silenciosa para a IA; um que só faz a segunda atrai zumbi sem barulho nenhum.

Assinatura observada: `addSound(source, x, y, z, radius, volume)` —
`PZ/media/lua/client/DebugUIs/AdminContextMenu.lua:260`. Não há `getWorldSoundManager` em
`media/lua`; a chamada é global.

O resto desta página é sobre **áudio**.

## A cadeia

```
campo de item        →  nome de som   →  bloco sound   →  evento FMOD  (jogo)
SwingSound = SledgehammerSwing            sound SledgehammerSwing   ou  arquivo .ogg  (mod)
```

Três elos, três arquivos diferentes. Confirmado ponta a ponta:

- `PZ/media/scripts/generated/items/weapon.txt:13000` — `SwingSound = SledgehammerSwing,`
- `PZ/media/scripts/generated/sounds/weapons/sounds_melee_bluntlong.txt:957` — `sound SledgehammerSwing`
- e o bloco resolve num evento, não num arquivo (`sounds_melee_bluntlong.txt:939-946`):

```
    sound SledgehammerHit
    {
        category = Item,
        clip
        {
            event = Weapon/Melee/BluntLong/Sledgehammer/Hit,
        }
    }
```

**O nome do som é um identificador global, sem prefixo de módulo.** O campo do item recebe
`SledgehammerSwing`, não `Base.SledgehammerSwing` — diferente de item, que sempre leva módulo. Vale
também para mod: ver "Namespace" abaixo.

## Onde mora, no jogo

Todos os blocos `sound` do jogo estão em `PZ/media/scripts/generated/sounds/` — **147 arquivos,
3.038 blocos**:

| Pasta | Arquivos |
|---|---|
| `objects/` | 43 |
| `weapons/` | 32 |
| `player/` | 26 |
| `animals/` | 22 |
| `vehicles/` | 16 |
| `zombies/` | 4 |
| raiz | 4 — `sounds_ambience.txt`, `sounds_meta.txt`, `sounds_music.txt`, `sounds_ui.txt` |

A pasta hospeda mais dois blocos, que **não** são `sound`: `soundTimeline` (5) e `vehicleEngineRPM`
(4, em `vehicles/vehicle_engine_rpm.txt`). Ao grepar campo dentro de `generated/sounds/`, eles
poluem o resultado.

Os áudios propriamente ditos estão fora de `scripts/`, em dois lugares que não se misturam:

- `PZ/media/sound/banks/Desktop/` — `ZomboidSound.bank`, `ZomboidSound.strings.bank`,
  `ZomboidSoundMP.bank`, `ZomboidMusic.bank`, `radio.bank`. **É daqui que o jogo toca.**
- `PZ/media/sound/` — 620 arquivos soltos (401 `.wav`, 211 `.ogg`) mais as pastas `car/`, `newCar/`,
  `oldSounds/`, `export/`. Um único bloco do jogo aponta para um deles.

## O bloco `sound` — campos

Medido nos 3.038 blocos do jogo:

| Campo | Ocorrências | Observação |
|---|---|---|
| `category` | 3.038 | em todos; valores no jogo: `Item` 1521, `Player` 692, `Object` 351, `Animals` 184, `Vehicle` 168, `Zombie` 55, `World` 35, `UI` 19, `Meta` 12, `Music` 1 |
| `clip` | 3.038 | sub-bloco, em todos |
| `master` | 50 | `Ambient` 31, `VehicleEngine` 18, `Music` 1 |
| `loop` | 32 | `true` |
| `maxInstancesPerEmitter` | 22 | inteiro |

Exemplo com os opcionais, `PZ/media/scripts/generated/sounds/sounds_ambience.txt:3-12`:

```
    sound WorldAmbiance
    {
        category = World,
        master = Ambient,
        loop = true,
        clip
        {
            event = World/Ambiance,
        }
    }
```

### `clip`

| Campo | No jogo | Observação |
|---|---|---|
| `event` | 3.037 | caminho de evento FMOD |
| `distanceMax` | 280 | |
| `file` | **1** | `zombies/sounds_zombie_voice_tutorial.txt:8` |
| `volume` | **1** | `zombies/sounds_zombie_foley.txt:243` |

`event` e `file` são as duas formas de dizer *de onde vem o áudio*, e a proporção entre elas é a
coisa mais importante desta página.

## A inversão: o jogo usa `event`, o mod usa `file`

| | `event =` | `file =` |
|---|---|---|
| Jogo (3.038 blocos) | **3.037** | 1 |
| Mods da Steam (89 instalados, 4.719 blocos) | 4 | **4.715** |

Ler só o `media/` leva direto ao caminho errado: você copia `event = Weapon/Melee/.../Hit` e não
tem como criar um evento novo — ele mora dentro do `.bank`, que é saída do FMOD Studio.
**Nenhum dos 89 mods instalados envia um `.bank`** (`find -iname "*.bank"` não retorna nada em
`STEAM/`).

O único `file` do jogo mostra o formato do caminho —
`PZ/media/scripts/generated/sounds/zombies/sounds_zombie_voice_tutorial.txt:5-10`:

```
        category = Zombie,
        clip
        {
            file = media/sound/fzombierand5.wav,
            distanceMax = 100,
        }
```

Ou seja: `media/` é a raiz, não a pasta do arquivo `.txt`.

## Lado-mod

Exemplo real e completo: *Authentic Z*, `STEAM/2335368829`.

**O bloco**, em `42/media/scripts/AuthenticZCurrent_sounds.txt:3-7`:

```
module AuthenticZCurrent {

    sound ChainsawStart
    {
        category = Chainsaw, loop = false, is3D = true,
        clip { file = media/sound/Chainsaw/ChainsawStart.wav, distanceMax = 30, volume = 0.2, }
    }
```

**O arquivo de áudio**, em `common/media/sound/Chainsaw/ChainsawStart.wav`.

Três coisas para tirar daí, e nenhuma delas está no `media/` do jogo:

1. **O `.txt` vai na pasta de versão, o áudio vai em `common/`.** `42/media/` desse mod não tem
   `sound/` nenhum. Bate com a regra geral do layout B42 — a pasta de versão carrega o que muda por
   build, `common/` carrega o asset. Ver `Documentacao/jogo/carregamento-de-mods.md`.
2. **O caminho de `file` é relativo à raiz de `media/` do mod**, e resolve através da união
   `42/media/` + `common/media/`. O bloco diz `media/sound/Chainsaw/...` e o arquivo está sob
   `common/`.
3. **Namespace: o bloco está em `module AuthenticZCurrent`, e o item referencia sem prefixo.**
   `items_AuthenticZ_Chainsaw.txt:57` traz `ChainsawStartSound = ChainsawStart,` — não
   `AuthenticZCurrent.ChainsawStart`. Mod publicado e em uso, então funciona; o porquê é Java.

### Campos que só aparecem em mod

`is3D` (44 usos), `volume` no `clip` (174) e `distanceMin` não são usados pelo jogo em bloco `sound`
— `is3D` tem **zero** ocorrências em todo o `PZ/media/scripts`. Não dá para confirmar contrato deles
aqui; ver "Pontos a confirmar".

### `category` parece ser string livre

O jogo usa 10 valores fechados. Os mods usam o que quiserem — `Voice` (736), `Oldies` (690), `SFX`
(354), `DJ` (198), `True Music` (97), `ATA` (22), `Braven` (21), `Chainsaw`, `BasementMod` (3). Nada
no `media/` diz o que o campo faz nem se um valor desconhecido é ignorado.

### Extensão

Os mods enviam **4.766 `.ogg`**, 138 `.wav` e 11 `.mp3`. O jogo tem `.wav` e `.ogg` soltos. `.ogg` é
a escolha de fato.

## Quem aponta para um nome de som

### `item` — 42 campos distintos

Os mais usados em `PZ/media/scripts/generated/items/`:

| Campo | Usos | | Campo | Usos |
|---|---|---|---|---|
| `BreakSound` | 631 | | `DropSound` | 332 |
| `SwingSound` | 408 | | `PutInSound` / `OpenSound` / `CloseSound` | 306 cada |
| `HitSound` | 375 | | `WeaponHitArmourSound` / `BulletHitArmourSound` | 213 cada |
| `HitFloorSound` / `DoorHitSound` | 354 cada | | `CookingSound` | 203 |

Depois a cauda por família: arma de fogo (`ClickSound`, `RackSound`, `InsertAmmo*Sound`,
`EjectAmmo*Sound`, `ShellFallSound`, `BringToBearSound`, `AimReleaseSound`), consumo
(`CustomEatSound`, `CustomDrinkSound`), recipiente (`FillFromTapSound`, `FillFromLakeSound`,
`FillFromDispenserSound`, `FillFromToiletSound`), móvel (`PlaceOneSound`, `PlaceMultipleSound`).

**Cuidado: nem todo campo com "Sound" no nome recebe nome de som.** `SoundVolume` (26),
`SoundGain` (22), `SoundRadius` (44), `SoundParameter` (34) e `NPCSoundBoost` (18) recebem número.

`SoundMap` (111) tem forma própria — dois tokens, `<slot> <nomeDoSom>`:
`PZ/media/scripts/generated/items/drainable.txt:733` traz `SoundMap = Activate UseLighter,`. Slots
observados: `DumpContents` (55), `SpearStab` (21), `Activate` (12), `Deactivate` (8),
`PlaceFurniture` (7), `PickUpFurniture` (7), `EquippedAndActivated` (1).

### `vehicle` — sub-bloco `sound`

Não confundir com o bloco `sound` de topo. Dentro de `vehicle` existe um sub-bloco homônimo cujos
campos recebem **nomes de som** —
`PZ/media/scripts/generated/vehicles/professionVehicles/vehicle_pickuptruck_JPLandscaping.txt:26-34`:

```
        sound
        {
            alarmLoop = VehicleAlarmA VehicleAlarmB VehicleAlarmC VehicleAlarmD VehicleAlarmE,
            engine = VehicleEnginePickUpTruck,
            engineStart = VehicleEnginePickUpTruck,
            engineTurnOff = VehicleEnginePickUpTruck,
            horn = VehicleHornStandard,
            ignitionFail = VehicleIgnitionFailPickUpTruck,
        }
```

`alarmLoop` recebe **lista separada por espaço**. Esta é a origem de uma divergência com o
PZ-API-Docs — ver o fim da página.

### Lua — três entradas, três alcances

318 ocorrências de `playSound` em `PZ/media/lua`. As formas:

| Chamada | Alcance | Exemplo |
|---|---|---|
| `<personagem>:playSound(nome)` | 3D, posicional | `client/Fishing/FishingStates.lua:91` — `self.manager.player:playSound("CastFishingLine")` |
| `<personagem>:getEmitter():playSound(nome)` | 3D, com handle para parar/consultar | `client/BuildingObjects/TimedActions/ISBuildAction.lua:83` |
| `getSoundManager():playUISound(nome)` | 2D, interface (66 usos) | `client/Entity/ISUI/CraftRecipe/ISRecipeScrollingListBox.lua:398` — `playUISound("UISelectListItem")` |

A forma com emitter é a que permite som contínuo: ela devolve um handle usado depois em
`isPlaying()` e `stopSound()` — `ISBuildAction.lua:79-80` e `:159-160`. Som de loop sem handle não
tem como ser interrompido.

## Nome de som inexistente — o motor avisa

**Som é exceção à falha silenciosa do resto do parser.** Um campo que aponta para um nome de som que
não existe gera `WARN`, citando o som *e* o item que o pediu (`USER/console.txt:126-127`):

```
WARN : General  at SoundManager.debugScriptSound > no such sound "CorpseDrop" in item Base.CorpseFemale
WARN : General  at SoundManager.debugScriptSound > no such sound "CorpseDrop" in item Base.CorpseMale
```

O exemplo é do **próprio jogo** — `Base.CorpseMale`/`CorpseFemale` apontam para um `CorpseDrop` que
não existe no build 42.20.2. Serve de amostra de que a checagem roda sobre todo item carregado, mod
incluído.

**Ressalva que muda o uso prático:** o método chama-se `debugScriptSound`. A sessão que produziu essas
linhas rodou com `-debug`, e não foi medido se o aviso sai em jogo normal. Trate como ferramenta de
diagnóstico em modo debug, não como garantia de que um erro seu apareceria para o jogador. Ver
[testar-e-debugar.md](testar-e-debugar.md).

Ícone ausente tem tratamento equivalente, por outro caminho — `XuiSkin$EntityUiStyle.Load > Could not
find icon: ...` (`console.txt:116-123`). Ver [arte-e-modelos.md](arte-e-modelos.md).

## `soundTimeline`

Cinco blocos, e a chave é que **o ID não é um nome de som — é um caminho de evento FMOD**.
`PZ/media/scripts/generated/sounds/objects/sounds_object_fridge_soundTimeline.txt:3-6`:

```
    soundTimeline Object/Fridge/Running
    {
        ElectricityOn = 3500,
    }
```

Os outros quatro são de veículo (`Vehicle/Sport/Engine`, `Vehicle/Jeep/Engine`,
`Vehicle/Standard/Engine`, `Vehicle/Van/Engine`), todos com `idle = 3500`. O nome do campo varia por
bloco, o que sugere marcador dentro do evento FMOD, não campo fixo.

**Zero referências fora do arquivo de definição**, em todo o `media/lua` e `media/scripts`. Mesma
situação de `physicsShape` e `clock` (ver [scripts-txt.md](scripts-txt.md)): a ligação é Java.

## O que mudou do B41 para o B42

**A sintaxe de `sound` não mudou.** Diferente de `recipe` → `craftRecipe`, aqui o material antigo da
internet continua válido. Prova: *Authentic Z* mantém as duas cópias no mesmo pacote —
`media/scripts/AuthenticZCurrent_sounds.txt` (raiz, pré-B42) e
`42/media/scripts/AuthenticZCurrent_sounds.txt` (pasta de versão) — e `diff` acusa **arquivos
idênticos**.

O que mudou é onde o **jogo** guarda os seus: `generated/sounds/`, dentro da reestruturação de
`media/scripts` descrita em [scripts-txt.md](scripts-txt.md). Isso não afeta mod — mod nunca pôs
nada em `generated/`.

## Pontos a confirmar

- **Se o aviso de som inexistente sai fora do modo debug.** A premissa antiga da página — de que som
  ausente falha em silêncio — **foi refutada** em 2026-08-07: o motor loga (ver "Nome de som
  inexistente"). O que resta medir é se `SoundManager.debugScriptSound` só fala com `-debug`, como o
  nome sugere. Resolve subindo o jogo **sem** a flag e procurando a mesma linha.
- **O que `category` faz.** Se é enum ou string livre, se agrupa slider de volume, e o que acontece
  com valor desconhecido. Os mods usam valor arbitrário e funcionam, o que sugere string livre, mas
  nada no `media/` declara — e uma varredura por `getCategory`/`:category` em contexto de som no
  `lua/` inteiro devolve **zero consumidor**, então não há por onde puxar por leitura.
- **`master`**: o PZ-API-Docs (`pz-wiki-modding.github.io/PZ-API-Docs/scripts/sound.html`) dá default
  `Primary` e os valores `Ambient, Music, Primary, VehicleEngine`. `Primary` tem **zero** ocorrências
  no `media/` — coerente com ser o default, mas isso é inferência, não prova.
- **`is3D`**: a mesma fonte lista como boolean. Zero uso no jogo, 44 nos mods
  (`.../2335368829/mods/Authentic Z - Current/42/media/scripts/AuthenticZCurrent_sounds.txt:5`).
  Não confirmável no `media/`.
- **`clip.distanceMin`**: listado pela fonte, zero uso no jogo, usado por mod
  (`.../2392709985/mods/tsarslib/media/scripts/commonlibrary/sounds_common.txt:27`).
  **`clip.reverbFactor`**: listado pela fonte e com **zero** ocorrências em qualquer lugar — jogo ou
  mod.
- **Se `file =` aceita `.ogg`, `.wav` e `.mp3` igualmente.** Censo em `STEAM/` de *arquivo embarcado*
  contra *arquivo referenciado por `file =`*:

  | Extensão | Embarcados | Referenciados |
  |---|---|---|
  | `.ogg` | 4.766 | 4.716 |
  | `.wav` | 138 | 122 |
  | `.mp3` | **11** | **3** |

  `.ogg` é o formato de fato — 97% do total. O `.mp3` é o caso a evitar: além de marginal, é o único
  cuja folga entre embarcado e referenciado é proporcionalmente grande (8 dos 11 arquivos não são
  citados por nenhum script), o que **pode** indicar tentativa abandonada. É indício fraco, não
  prova: um arquivo pode ser referenciado por Lua em vez de `.txt`. Nada confirma que os três
  carregam.
- **Se o caminho de `file =` resolve mesmo através do merge `42/media/` + `common/media/`.** A
  evidência do *Authentic Z* é forte (o arquivo só existe em `common/`) mas indireta.
- **Se um mod consegue registrar evento FMOD próprio.** Reconfirmado por censo de extensão: entre os
  89 mods de `STEAM/` há 4.915 arquivos de áudio e **zero `.bank`**. Se é impossível ou só incomum,
  não dá para dizer daqui — mas a ausência é total, não escassez.
- **`soundTimeline`**: quem consome, a unidade de `3500`, e se o campo é marcador do evento FMOD.
  Varredura por `soundTimeline`/`SoundTimeline` em todo o `lua/` devolve **zero** — não há
  consumidor em Lua, então o contrato só sai de teste in-game ou do `.jar`.
- **Namespace de `sound`.** Referência sem prefixo funciona em mod publicado; se o parser ignora o
  `module` para `sound`, ou se há fallback global, é Java.
- **`maxInstancesPerEmitter`, `loop` e `distanceMax`**: default de cada um não está no `media/` nem
  na fonte externa.

> Última verificação: 2026-08-07 — jogo **42.20.2** (`ffe7a8a4b1`), PZ buildid 24574865,
> media/ + STEAM/ (89 mods) + PZ-API-Docs 42.20.0 + sessão in-game
> (`USER/console.txt` de 2026-08-07 18:46).

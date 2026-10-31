# Animação — as cinco pastas e o que delas é modificável

A maior massa de dado do jogo depois das texturas, e a de contrato mais opaco: quase tudo é
consumido pelo Java sem passar por Lua. Esta página mapeia as cinco pastas, diz qual formato mora em
cada uma, e — pelo censo dos mods instalados — qual delas mods de fato tocam.

Alias `PZ/` = `C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid\`,
`STEAM/` = `…\steamapps\workshop\content\108600\` (ver [../index.md](../index.md)).
**Somente leitura.**

Malha e modelo 3D estão em [arte-e-modelos.md](arte-e-modelos.md); a pilha de animal, em
[animais.md](animais.md), que já cobre `actiongroups/` do lado dos bichos.

## As cinco pastas

| Pasta | Arquivos | Formato | Papel |
|---|---|---|---|
| `anims_X/` | 2.209 | DirectX `.X` **texto** | **os clipes** — a animação em si, por ator; formato em [anims-formato.md](anims-formato.md) |
| `AnimSets/` | 2.949 | `.xml` `<animNode>` | árvore de blend: qual clipe tocar e como misturar |
| `actiongroups/` | 3.203 | `.xml` | máquina de estados por ator (condição → transição) |
| `animsold/` | 400 | `.txt` proprietário | legado — cabeçalho `# Project Zomboid Animated Mesh`, `File Version: 1.00000000` |
| `animstates/` | 3 | `.xml` | dados globais de blend — ver abaixo |
| `animscript/` | **1** | `.xml` | `combat.xml`, estados de combate |

Nenhuma delas tem uma única referência em `media/lua` para `actiongroups`
(registrado em [mapa-media.md](mapa-media.md)) — o consumo é todo Java.

## O que mods realmente tocam

Censo nos **89 mods de `STEAM/`**, por pasta embarcada:

| Pasta | Mods que trazem | Pastas encontradas |
|---|---|---|
| `AnimSets/` | **15** | 35 |
| `anims_X/` | **10** | 16 |
| `actiongroups/` | **0** | 0 |
| `animscript/` | **0** | 0 |

**As duas colunas diferem, e a distinção importa.** Um mod com pasta por versão do jogo
(`42/`, `42.0/`, `common/`) tem a mesma pasta de animação contada várias vezes — `FWO` aparece 4×,
`SkateBoard` e `Lifestyle` 2× cada. Contar diretório superestima o alcance quase 2:1. A coluna da
esquerda é `cut -d/ -f2 | sort -u` sobre o ID do mod, que é o número que responde "quantos mods
fazem isso".

A conclusão prática: **animação de mod é `anims_X/` + `AnimSets/`.** Trazer o clipe e a árvore de
blend é caminho batido; mexer na máquina de estados (`actiongroups/`) não é feito por ninguém entre
os 89 instalados. `animstates/` e `animscript/` são pequenos e globais, e também têm zero adoção.

## `AnimSets/` — a árvore de blend

40 entradas na raiz: 28 pastas (uma por ator) mais `.xml` soltos —
`Defaults.xml`, `Master_Bones.xml`, `Master_Variables.xml`, `base.xml`, e um por ator
(`cow.xml`, `mannequin.xml`, …).

Os atores repetem os de `actiongroups/`: 21 de animal mais `player`, `player-avatar`,
`player-editor`, `player-vehicle`, `zombie`, `zombie-crawler`, `animal-editor`, `mannequin`.

`AnimSets/player/` tem **91 subpastas** (`aim`, `aim-sneak`, `aim-strafe`, `bumped`, `climbfence`,
`climbrope`, `actions`, …) mais `.xml` soltos no topo (`idle.xml`, `run.xml`, `walk.xml`,
`grappleGrab.xml`). Dentro de uma subpasta, um `.xml` por variante de arma:
`aim.xml`, `aim_1handed.xml`, `aim_2handed.xml`, `aim_handgun.xml`, `aim_knife.xml`, `aim_rifle.xml`,
`aim_spear.xml`, `aim_chainsaw.xml`, `aim_heavy.xml`, `aim_throwing.xml`.

O formato é `<animNode>` (`PZ/media/AnimSets/player/aim/aim.xml:2-24`):

```xml
<?xml version="1.0" encoding="utf-8"?>
<animNode>
	<m_Name>aim</m_Name>
	<m_AnimName>Bob_IdleAim1Hand</m_AnimName>
	<m_BlendTime>0.30</m_BlendTime>
	<m_SpeedScale>IdleSpeed</m_SpeedScale>
	<m_maxTorsoTwist>45.00</m_maxTorsoTwist>
	<m_Scalar>verticalAimAngle</m_Scalar>
	<m_SyncTrackingEnabled>false</m_SyncTrackingEnabled>
	<m_2DBlends referenceID="1">
		<m_AnimName>Bob_IdleAim1Hand_Up75</m_AnimName>
		<m_XPos>75.00</m_XPos>
		<m_YPos>0.00</m_YPos>
		<m_SpeedScale>1.00</m_SpeedScale>
	</m_2DBlends>
```

Contratos legíveis do arquivo:

- **`m_AnimName` é o nome do clipe**, com prefixo do ator (`Bob_`). É a chave que liga em `anims_X/`.
- **`m_Scalar` nomeia a variável** que dirige o blend (`verticalAimAngle`). O vocabulário de
  variáveis é `Master_Variables.xml`.
- **`m_2DBlends` repetido monta o espaço de blend**, cada entrada com `m_XPos`/`m_YPos` — para mira
  vertical, `XPos` é o ângulo (75, 45, 0…) e `YPos` fica em zero.
- `referenceID` é atributo sequencial, não referência a outro arquivo.
- `m_SpeedScale` aceita **nome de variável** (`IdleSpeed`, no nó raiz) ou **número** (`1.00`, nos
  blends) — o mesmo campo, dois tipos.

`Master_Bones.xml` e `Master_Variables.xml` são os vocabulários globais de osso e de variável; um
`m_Scalar` que não esteja lá não tem como ser alimentado.

### Máscara de segurar — os dois campos de `item` que endereçam esta pasta

Duas das 91 subpastas de `AnimSets/player/` são `maskingright/` e `maskingleft/`, e elas são
endereçadas direto do bloco `item` de `media/scripts`, pelos campos `primaryAnimMask` e
`secondaryAnimMask`. Eles trocam a **pose de segurar** do personagem — mão direita e mão esquerda,
respectivamente:

```
    item HandTorch
    {
        ...
        primaryAnimMask = HoldingTorchRight,
        secondaryAnimMask = HoldingTorchLeft,
```

(`PZ/media/scripts/generated/items/drainable.txt:995-996`.)

**Sempre em par e sempre simétricos**: 27 ocorrências de cada campo em `generated/items/`, e nenhum
item declara um sem o outro. A distribuição por `ItemType` é o que interessa a quem vai usar:

| Arquivo | Ocorrências de `primaryAnimMask` |
|---|---|
| `drainable.txt` | 18 |
| `normal.txt` | 8 |
| `weaponpart.txt` | 1 — `item GunLight` (`:172-173`) |
| `weapon.txt` | **0** |

São 9 valores distintos, cada um casando por nome com um `.xml` das duas pastas de máscara:
`holdingbag*` (12 itens, o mais usado), `HoldingTorch*`, `HoldingUmbrella*`, `HoldingAngleTorch*` e
`HoldingHeavyTorchLeft`. Fora dessas, `maskingright/` e `maskingleft/` trazem variantes de estado
(`*Sneak`, `fall_loop*`, `land_gentle_*`, `aim*`, `walk*`, `run*`, `sprint*`) que **nenhum item
nomeia** — o item aponta para a pose base e o resto o Java resolve.

**A caixa do valor não importa aqui — e isso é exceção no jogo.** O `item UmbrellaBlack`
(`normal.txt:8817`) declara `HoldingUmbrellaRight`, e o único arquivo correspondente é
`PZ/media/AnimSets/player/maskingright/holdingumbrellaright.xml`, todo minúsculo. As três grafias
convivem no próprio jogo: `holdingbagright` bate exato com o arquivo, `HoldingTorchRight` difere na
primeira letra de `holdingTorchRight.xml`, e `HoldingUmbrellaRight` difere em três. Se o casamento
fosse sensível à caixa, o guarda-chuva do vanilla estaria com a máscara quebrada. **O nome do campo
continua sensível** — a exceção é só o valor.

**Zero referências em `media/lua`**, nem ao campo nem a um getter equivalente: como o resto de
`AnimSets/`, o consumo é todo Java.

## `actiongroups/` — a máquina de estados

3.203 `.xml`, 28 subpastas de ator, já descrita em [mapa-media.md](mapa-media.md) e usada por
[animais.md](animais.md). O resumo do contrato: um `actionGroup.xml` declara o estado inicial, um
`defaultTransitions.xml` traz as transições globais, e cada estado é uma pasta com o próprio `.xml`
mais um `to_<destino>.xml` por saída. Condição declarativa
(`PZ/media/actiongroups/buck/defaultTransitions.xml:2-14`):

```xml
<transition>
    <transitionTo>falldown</transitionTo>
    <conditions>
        <isTrue>bDead</isTrue>
        <isFalse>bOnFloor</isFalse>
    </conditions>
</transition>
```

**Zero mods dos 89 tocam nesta pasta.**

## `animstates/` — onde os `Blends` moram

Três arquivos: `test.animstates` (8 linhas), `testanimstates.xml` (1.281) e `testanimstates2.xml`
(1.139). Apesar do nome "test", são os únicos do tipo no build.

O topo de `testanimstates.xml` tem exatamente dois elementos: `<Blends>` e `<AnimStates>`.

```xml
<AnimData>
    <Blends>
        <MoveDelta>
            <Type>InverseExponential</Type>
            <Increase Multiplier="MoveSpeedChangeDelta">0.185</Increase>
            <Decrease Multiplier="MoveSpeedChangeDelta">0.125</Decrease>
        </MoveDelta>
        <DeltaX>
            <Type>Linear</Type>
```

(`animstates/testanimstates.xml:1-9`.) Cada entrada é uma variável de animação (`MoveDelta`, `DeltaX`,
`DeltaY`, `TurnAmount`) com a curva de suavização: `Type` (`Linear`, `InverseExponential`) e taxas
distintas de subida e descida.

### Isso resolve metade de uma pendência antiga

[mapa-media.md](mapa-media.md) registra em "Pontos a confirmar" que **`Blends` e `Rules`** — dois
nomes que o PZ-API-Docs lista como família de arquivo-raiz — "não existem neste build", com busca em
todo o `PZ/` e nos 89 mods dando zero.

**`Blends` existe, mas não é arquivo-raiz: é elemento XML**, dentro de `animstates/*.xml` (`:2` nos
dois arquivos). A busca anterior falhou porque procurava nome de arquivo. `Rules` continua sem
casamento — zero ocorrências em `animstates/`.

## `animscript/` — um arquivo

`PZ/media/animscript/combat.xml` é o único. Formato `<AnimStates>`, um bloco por estado
(`combat.xml:1-18`):

```xml
<AnimStates>
	<IdleHighCoverLeanL>
		<AllowChangeAngle>false</AllowChangeAngle>
		<MoveCancel>false</MoveCancel>
		<Commands>
			<PlayAnim>
				<Anim>Bob_IdleHighCoverLeanL</Anim>
				<Repeat>0</Repeat>
			</PlayAnim>
		</Commands>
		<Out>
			<HighCoverL_90Outside>
				<BlendAnimState></BlendAnimState>
				<BlendTime>0</BlendTime>
			</HighCoverL_90Outside>
		</Out>
	</IdleHighCoverLeanL>
```

**O nome do elemento é o nome do estado** — não há `<state name="...">`. `<Out>` lista os destinos, e
cada destino é de novo um elemento nomeado. `<Commands>`/`<PlayAnim>` toca o clipe;
`AllowChangeAngle` e `MoveCancel` são as travas de input.

Os nomes (`IdleHighCoverLeanL`, `HighCoverL_90Outside`) são de sistema de cobertura, que não é
mecânica exposta no jogo atual — ver pendências.

## Os dois blocos `.txt` de animação

Em `media/scripts` existem dois blocos da família, ambos pequenos:

**`animation`** — 2 blocos em `PZ/media/scripts/generated/animations.txt`, os dois chamados
`Runtime1`/`Runtime2`. Servem para montar animação copiando quadro de outra:

```
module Base
{
    animation Runtime1
    {
        CopyFrame
        {
            frame = 1,
            source = Bob_IdleDrinkPopCan,
            sourceFrame = 1,
        }
```

Sub-blocos observados: `CopyFrame` (`frame`, `source`, `sourceFrame`) e `CopyFrames`
(`frame`, `source`, `sourceFrame1`, …).

**`animationsMesh`** — 23 blocos em `PZ/media/scripts/generated/animations_meshes.txt`, já coberto em
[arte-e-modelos.md](arte-e-modelos.md). É o que amarra malha a diretório de clipe:

```
    animationsMesh Human
    {
        meshFile = Skinned/MaleBody,
        animationDirectory = Bob,
        animationDirectory = Kate,
        animationDirectory = Zombie,
    }
```

`animationDirectory` repetido lista as pastas de `anims_X/` que aquela malha aceita — é por isso que
`anims_X/` tem `Bob`, `Kate`, `Chicken`, `Cow`, `Deer`, `DeerDead`, `Mouse`, `Pig`,
`Mannequin_Scarecrow`, `Mannequin_Skeleton` no topo.

## Lado do mod

Pelo censo, o caminho viável é:

1. Clipe novo em `media/anims_X/<Ator>/` (16 mods fazem).
2. Nó de blend em `media/AnimSets/<ator>/…` apontando para ele via `m_AnimName` (35 mods fazem).
3. Disparo pelo Lua, via `ISBaseTimedAction:setActionAnim(...)` e `setAnimVariable(k, v)` — ver
   [timedactions.md](timedactions.md).

Tudo isso é conteúdo que não muda entre builds: vai em `common/media/`, não na pasta de versão. Ver
[carregamento-de-mods.md](carregamento-de-mods.md).

### Como um mod acrescenta pose de arma nova — o seletor é `m_Conditions`, não o `.txt`

**[delta 2026-08-18]** A lista acima diz *quais* camadas existem, não *como* o motor escolhe o nó
novo. O mecanismo é o mesmo do jogo, e o exemplo completo é `RadArchery`
(`STEAM/3775407541/mods/RadArchery/42/`), que traz 19 `.xml` em `AnimSets/player/` cobrindo idle,
walk, run, sprint, os quatro estados de furtividade, os dois de strafe, mira e disparo.

**1. `m_Conditions` é o seletor.** Está em **2.635 dos 2.949** `.xml` de `AnimSets/` do jogo. O
vanilla escreve só o GUID e o valor (`PZ/media/AnimSets/player/aim/aim_rifle.xml:25-27`):

```xml
<m_Conditions x_name="f2c28b85-d9e4-4170-8194-bda2b233bd1a">
    <m_Value>firearm</m_Value>
</m_Conditions>
```

O GUID identifica a variável — aqui, `Weapon`. Um mod pode escrever os campos por extenso e
**declarar variável própria** (`…/RadArchery/42/media/AnimSets/player/aim/aim_bow.xml:70-79`), com
GUID inventado:

```xml
<m_Conditions x_name="d5f0e1a2-b0c3-4d44-9e55-6f77aa88bb01">
    <m_Name>RadArcheryRangedType</m_Name>
    <m_Type>STRING</m_Type>
    <m_Value>bow</m_Value>
</m_Conditions>
```

**2. Quem alimenta a variável é o Lua**, com `player:setVariable(nome, valor)` — não
`setAnimVariable`, que é do `ISBaseTimedAction`
(`…/RadArchery/42/media/lua/client/RadArcheryBowAnim.lua:36`, ligado em `Events.OnEquipPrimary`,
`OnEquipSecondary` e `OnPlayerUpdate`). O valor sai de qual item está na mão primária.

**3. `m_Name` do nó tem de ser o do nó vanilla, byte a byte.** O arquivo do mod chama-se
`aim_bow.xml`, mas declara `<m_Name>aim_rifle</m_Name>` (`aim_bow.xml:26`) — idêntico ao vanilla
(`PZ/media/AnimSets/player/aim/aim_rifle.xml:3`). **O que diferencia o nó é o nome do arquivo mais as
condições; o `m_Name` é o endereço pelo qual as transições do resto do jogo o alcançam.** Nome de nó
único deixaria o estado inalcançável.

**4. `m_Priority` desempata** quando duas condições casam. O mod declara `<m_Priority>10</m_Priority>`
(`aim_bow.xml:27`); o `aim_rifle.xml` vanilla não declara nenhuma. São 118 arquivos do jogo com o
campo.

**5. O bloco `item` do `.txt` não participa da escolha.** Tanto `RadArchery` (que tem clipe próprio)
quanto `SimpleBows` (que não tem) declaram `SwingAnim = Rifle` e `SubCategory = Firearm` — ver
`…/RadArchery/42/media/scripts/bows/CarvedBow.txt:60` e
`STEAM/3744846617/mods/SimpleBows/42/media/scripts/SimpleBows_Items.txt:259`. Quem troca a pose é a
condição, não o campo do item.

**Consequência para quem for planejar arma de projétil nova:** dá para publicar sem clipe nenhum,
definindo a arma como `Ranged = TRUE` + `SubCategory = Firearm` + `SwingAnim = Rifle` — o personagem
usa a pose de rifle. Seis dos oito mods de arco de `STEAM/` fazem exatamente isso. O clipe próprio é
o que separa "funciona" de "parece um arco".

> As citações de classe Java que os comentários do `RadArchery` trazem (`AnimNode.java:224`,
> `AnimLayer.java:1047`) vêm de decompilação de terceiro e **não são verificáveis aqui** — valem como
> pista, pela regra 4 de [../index.md](../index.md). O que está provado acima é o conteúdo dos `.xml`
> e do `.lua`, mais o censo do vanilla.

## Pontos a confirmar

- **O formato binário de `anims_X/`** não foi inspecionado. 2.209 arquivos, extensão e cabeçalho não
  levantados nesta rodada — a página afirma o papel da pasta pelo que `animationsMesh` declara, não
  por leitura do conteúdo.
- **Como o motor indexa `AnimSets/`** — se pelo nome da pasta do ator, pelo `m_Name` do nó, ou por
  registro em outro lugar. A mesma pendência existe para `actiongroups/` em
  [animais.md](animais.md).
- **A lista de variáveis válidas de `m_Scalar` e `m_SpeedScale`.** `Master_Variables.xml` é o
  candidato óbvio a dono, mas não foi aberto.
- **`Rules`** continua sem casamento em lugar nenhum — a metade que sobra da pendência de
  [mapa-media.md](mapa-media.md). A hipótese de legado B41 no índice do PZ-API-Docs segue de pé.
- **Se `animscript/combat.xml` está vivo.** Os estados são de sistema de cobertura, e o arquivo é
  único na pasta; se o Java ainda o lê, ou se é resíduo como `animsold/`, não foi determinado.
- **`animstates/` chama-se "test"** nos três arquivos, mas contém os `Blends` globais. Se há uma
  versão não-test em outro lugar (ou no `.jar`) não foi verificado.
- **`animsold/`** (400 arquivos) não foi aberta — o nome indica legado, e nenhuma referência em
  `media/lua` foi procurada nesta rodada.
- **Se um mod pode substituir** um `.xml` de `AnimSets/` do jogo (em vez de acrescentar), e por qual
  regra de precedência. Os 35 mods que trazem a pasta não foram cruzados nome a nome contra os do
  jogo.

  **[delta 2026-08-18]** Existe caso observável agora: `ArcheryNexus` embarca
  `STEAM/3617854007/mods/ArcheryNexus/42.16/media/AnimSets/player/aim-strafe/aim.xml`, e
  `PZ/media/AnimSets/player/aim-strafe/aim.xml` existe no jogo — mesmo caminho relativo, mesmo nome.
  É sobreposição de arquivo vanilla, não acréscimo. A regra de precedência continua sem prova, mas o
  contraste com `RadArchery` é informativo: este **nunca** reusa nome de arquivo do jogo (todos os 19
  levam sufixo `_bow`) e resolve a escolha por `m_Conditions` + `m_Priority`, o que sugere que
  acrescentar arquivo condicionado é o caminho seguro e sobrepor é o arriscado.
- **Se `primaryAnimMask`/`secondaryAnimMask` funcionam em `ItemType = base:weapon`.** Zero
  precedente vanilla — os 27 portadores são `base:drainable`, `base:normal` e `base:weaponpart`. É a
  mesma forma de evidência de `LightDistance`, que também tem zero ocorrências em `weapon.txt` e
  aparece em três outros `ItemType`: ausência de exemplo, não prova de impedimento.

  **[indício 2026-08-15, não é prova de engine]** `WS/SiddigoWeapons` publicou `item TorchLit`
  (`base:weapon`) com `primaryAnimMask = HoldingUmbrellaRight` / `secondaryAnimMask =
  HoldingUmbrellaLeft` e testou in-game: o jogador reportou que a tocha "não funciona como arma"
  (sem stacktrace novo em `console.txt` nem no `Logs/*_DebugLog.txt` da sessão — falha silenciosa,
  como esperado). As duas linhas foram removidas do item como correção, e é a ação que a spec do mod
  já previa para o caso "P4 = não". **Isto não isola a causa por trace de engine** — é correlação
  entre "campo sem nenhum precedente em `weapon.txt`" e "sintoma que bate com a hipótese de
  conflito", numa única tentativa e sem A/B controlado. Ainda vale como indício de que a máscara
  **não deveria** ser usada em `base:weapon` até haver teste que isole a variável (reaplicar só a
  máscara, sem outras mudanças, e conferir se o ataque volta a quebrar).
- **Se a máscara colide com `IdleAnim`/`RunAnim` de arma**, que declaram a pose pela outra via. Não
  dá para fechar por grep: os valores desses campos (`Idle_Weapon2`, `Run_Weapon2`) **não existem
  como arquivo nem como conteúdo** em `AnimSets/` ou `anims_X/`, então os dois sistemas não se
  encontram em lugar nenhum do `media/`. O indício acima é compatível com esta pendência, mas não a
  fecha.
- **O mecanismo do casamento insensível à caixa** do valor de máscara — se o Java normaliza o nome,
  se indexa a pasta uma vez em minúsculo, ou se é o próprio sistema de arquivos do Windows. O que
  está provado é a observação (três grafias, um arquivo cada), não a causa; num servidor Linux a
  conclusão pode não valer.
- **O PZ-API-Docs cataloga `animNode` no índice de xml** (registrado em
  [../fontes-externas.md](../fontes-externas.md):36) — não foi cruzado campo a campo nesta rodada, e
  é a via natural para fechar `m_maxTorsoTwist`, `m_SyncTrackingEnabled` e o contrato de `m_2DBlends`.

> Última verificação: 2026-08-07 — PZ buildid 24574865 (branch public, atualizado 2026-08-07), media/.

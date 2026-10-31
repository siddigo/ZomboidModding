# Armadilhas — o que faz o bloco sumir em silêncio

Curta de propósito. **Ler sempre**, qualquer que seja o tipo.

O parser da IndieStone não avisa. Erro aqui não vira linha no `console.txt`: o bloco simplesmente não
existe no jogo.

## 1. `imports`, não `import`

O bloco que dá acesso ao módulo `Base` a partir do módulo do mod é **plural**:

```
module MeuMod
{
    imports
    {
        Base
    }
    ...
}
```

**A evidência é toda de mod — o jogo não tem exemplo disto** (censo refeito em 2026-08-08). O
`media/scripts` do jogo tem `imports` em exatamente 3 arquivos, e os 3 são **outro construto**:
`imports` dentro de um bloco `xuiSkin`, que é herança entre skins (`xui_skin_electric_common.txt:5`
importa a skin `default`), não acesso de módulo a `Base`. Ver
`Documentacao/jogo/xui.md`. O jogo nunca precisa do bloco de import de módulo porque escreve tudo
dentro de `module Base`.

A citação do jogo que estava aqui antes apontava justamente para esse `xuiSkin` — **não era
confirmação independente.** O que sustenta a regra é o censo em `STEAM/`: **~130 arquivos usam
`imports`** (Lifestyle, tsarslib, damnlib, SapphCooking, Sprout's Farm&Garden, Video Game Consoles,
RenewableAxes, entre outros) e há **exatamente uma ocorrência de `import` singular em todos os 89
mods** — a cópia publicada do nosso `SiddigoWeapons`
(`STEAM/3612982532/mods/SiddigoWeapons/42/media/scripts/SiddigoWeapons_Items.txt:3`).

**`WS/SiddigoWeapons/.../SiddigoWeapons_Items.txt:3` e `WS/ModTeste/.../ModTeste_Items.txt:3` usam
`import` singular.** Não copie desses arquivos — são a origem do erro, não exemplo.

*A confirmar in-game:* se o singular é tolerado pelo parser ou se aqueles dois mods estão com o
bloco silenciosamente inerte. O censo mostra qual forma o resto do mundo usa; não prova o que o
parser aceita.

## 2. Módulo do mod, não `Base`

Conteúdo novo vai no módulo do mod. Escrever dentro de `module Base` colide com o jogo e com todo
outro mod que fizer o mesmo.

| Tipo | Como o nome é qualificado |
|---|---|
| item | `module MeuMod { item Faca }` → referenciado como `MeuMod.Faca` (**ponto**) |
| traço/profissão | `character_trait_definition MeuMod:corajoso` (**dois-pontos**) |

Item usa **ponto**, traço e profissão usam **dois-pontos**. Não é escolha — é o que o jogo e os mods
reais fazem (`ToadTraits:actionhero`, `Lifestyle:Artistic`, `SiddigoWeapons.SkullCrusher`).

`model` não segue nenhum dos dois: o nome resolve **global**, sem prefixo. Declarar em `module Base`
(como `SiddigoWeapons_Models.txt:1`) ou no módulo do mod dá no mesmo, e o item referencia pelo nome
puro. Ver `Documentacao/jogo/arte-e-modelos.md`.

## 3. Caixa das letras — o campo tem a caixa que o jogo usa, não a que faz sentido

O parser é sensível. Divergências reais já encontradas no workspace, todas candidatas a falha
silenciosa:

| O jogo escreve | Visto errado em | Onde |
|---|---|---|
| `Researchablerecipes` (r minúsculo no meio) | `ResearchableRecipes` | `WS/SiddigoWeapons/.../SiddigoWeapons_Items.txt` |
| `ItemType = base:weapon` (tudo minúsculo) | `base:Weapon` | idem |
| `Categories = base:blunt` | `Blunt` (sem namespace) | idem |
| `Tags = InHandCraft` (T maiúsculo) | `tags = AnySurfaceCraft` | `WS/SiddigoWeapons/.../recipes_SiddigoWeapons.txt` |
| `NeedToBeLearn` | `needTobeLearn` | idem |

Canônico do jogo: `PZ/media/scripts/generated/items/weapon.txt:3` e
`PZ/media/scripts/generated/recipes/recipes_carving.txt:3`.

**Regra:** na dúvida, abra o arquivo do jogo e copie a caixa de lá. Nunca a de um mod.

## 4. Os 15 `ItemType` são fechados e minúsculos

`base:alarmclock`, `base:alarmclockclothing`, `base:animal`, `base:clothing`, `base:container`,
`base:drainable`, `base:food`, `base:key`, `base:literature`, `base:map`, `base:moveable`,
`base:normal`, `base:radio`, `base:weapon`, `base:weaponpart`.

Cada um tem arquivo homônimo em `PZ/media/scripts/generated/items/`. Valor fora da lista = item
inexistente.

## 5. BOM quebra a primeira chave

Gravar `.txt`, `.json` e `mod.info` em **UTF-8 sem BOM**. Com BOM, a primeira linha do arquivo é lida
com lixo na frente e a primeira declaração se perde.

## 6. Tradução no formato B41 é o erro mais comum do workspace

`Translate/` maiúsculo + `.json`. A pasta `translate/` minúscula com `_EN.txt` é B41. Ver
`traducao.md`.

## 7. Arte no lugar errado não é erro de parser, mas some igual

Textura e modelo vão em `common/media/`, script vai na pasta de versão. Trocar isso faz o jogo não
achar o asset — e ele não reclama.

> Levantado em 2026-08-04 — PZ buildid 24449119.

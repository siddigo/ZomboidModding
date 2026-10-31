# Traço e profissão

**Contrato completo: `Documentacao/jogo/scripts-txt.md`, seção `character_trait_definition` /
`character_profession_definition`.** Lá está o bloco canônico dos dois, a tabela campo a campo com a
frequência de uso, e as duas fugas do padrão (o namespace no nome do bloco, e o `XPBoosts` que mistura
`;` e `=`). Leia antes de escrever.

O ponto que inverte tudo também está lá e em `jogo/eventos-lua.md`: **no B42 é `.txt`, não Lua.**
`TraitFactory.` e `ProfessionFactory.` têm zero ocorrências em `PZ/media/lua`.

Esta página é só o delta lado-mod.

## Onde escrever

`Contents/mods/<Mod>/42/media/scripts/<Mod>_Traits.txt`.

Dois mods B42 da Steam divergem no caminho e ambos carregam:

| Mod | Caminho |
|---|---|
| `More Traits` (1299328280) | `42.17/media/scripts/ToadTraits.txt` — raiz de `scripts` |
| `Lifestyle` (3403870858) | `common/media/scripts/generated/characters/LS_character_traits.txt` — espelha o jogo, e em `common/` |

Prefira a forma simples, na pasta de versão. O jogo varre `media/scripts` inteiro; a hierarquia
`generated/characters/` é organização interna do jogo, não exigência do parser.

## O namespace é o do mod

A doc mostra o bloco do jogo, com `base:`. Mod usa **o próprio módulo**:

```
module MeuMod
{
    character_trait_definition MeuMod:corajoso
    {
        IsProfessionTrait = false,
        DisabledInMultiplayer = false,
        CharacterTrait = MeuMod:corajoso,
        Cost = 4,
        UIName = UI_trait_corajoso,
        UIDescription = UI_trait_corajosodesc,
        MutuallyExclusiveTraits = MeuMod:covarde;base:cowardly,
        XPBoosts = Strength=1;Fitness=1,
    }
}
```

Confirmado em `More Traits/42.17/.../ToadTraits.txt:3` (`ToadTraits:actionhero`) e em
`Lifestyle/.../LS_character_traits.txt:3` (`Lifestyle:Artistic`).

`MutuallyExclusiveTraits` **pode citar traço do jogo** com `base:` — é como um traço novo se declara
incompatível com um nativo.

Lembre que aqui é **dois-pontos**; item é ponto (`MeuMod.Faca`). Ver `armadilhas.md` §2.

## A evidência de que `.txt` é o caminho, se precisar justificar

`More Traits` migrou **entre pastas de versão, no mesmo mod**:

| Pasta | Como declara |
|---|---|
| `42/` | Lua — `media/lua/shared/NPCs/MoreTraitsMainCreationMethods.lua:5`, `TraitFactory.addTrait(...)` |
| `42.13/`, `42.15/`, `42.17/` | `.txt` — `media/scripts/ToadTraits.txt` |

Se encontrar `TraitFactory` num mod do workspace, é B41 e precisa migrar.

## Tradução — L4

`UI.json`, não `ItemName.json`. Chaves `UI_trait_<nome>` / `UI_trait_<nome>Desc` / `UI_prof_<nome>`.

O jogo usa `Desc` maiúsculo, os mods usam `desc` minúsculo — **o que vale é o valor literal do campo
`UIDescription`**, ele *é* a chave. Basta os dois casarem. Ver `traducao.md`.

## O que esta pilha não tem

Traço e profissão **não têm camada de mundo (L3)** — não entram em loot nem em coleta. Traço não tem
arte; profissão tem, só o `IconPathName` (nome de textura, sem caminho e sem extensão).

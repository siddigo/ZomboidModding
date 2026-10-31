# Receita — `craftRecipe`

**Contrato completo: `Documentacao/jogo/scripts-txt.md`, seção `craftRecipe`.** Está bem coberto lá —
bloco canônico, as quatro formas de seletor, os três valores de `mode:`, `mappers[...]`, as 57
`flags` agrupadas e os campos de topo. Leia lá antes de escrever.

Esta página é só o delta lado-mod.

## Onde escrever

`Contents/mods/<Mod>/42/media/scripts/recipes/recipes_<Mod>.txt`.

A subpasta `recipes/` não é exigida pelo motor — o jogo varre `media/scripts` inteiro. É convenção,
e `WS/SiddigoWeapons/` a segue. Mantenha.

## Módulo: `Base`, e é intencional

Diferente do item, receita de mod costuma ir em `module Base` — visto em
`WS/SiddigoWeapons/.../recipes_SiddigoWeapons.txt:1`. O nome da receita é global e a saída é
qualificada:

```
module Base
{
    craftRecipe MakeMinhaFaca
    {
        time = 200,
        category = Weaponry,
        timedAction = CraftWeapon2H,
        inputs
        {
            item 1 [Base.LargeStone] flags[Prop1],
            item 1 tags[base:sharpknife] mode:keep flags[MayDegradeLight],
        }
        outputs
        {
            item 1 MeuMod.MinhaFaca,
        }
    }
}
```

Note: `outputs` aponta para `MeuMod.MinhaFaca` — módulo do item, com ponto.

## O que checar antes de escrever

1. **`timedAction` existe?** É o alvo do campo e resolve para um bloco em
   `PZ/media/scripts/generated/timedactions.txt`. Valor inventado = receita que não executa. Confira
   o nome lá.
2. **`category` existe?** Vira aba no menu de craft e tem chave de tradução própria
   (`IGUI_CraftingCategories_<category>` em `IG_UI.json`). Categoria nova exige a chave, senão o
   jogador vê o nome cru.
3. **As tags dos `inputs` existem?** `tags[base:sharpknife]` só casa se algum item declarar essa tag.
   Grepe antes de usar.
4. **Perícia de `xpAward` e `SkillRequired` existe?** Formato `Pericia:pontos`, separado por `;`.

## Tradução — L4

Chave = **o nome puro da receita**, sem prefixo, em `Recipes.json`. `craftRecipe MakeMinhaFaca` →
`"MakeMinhaFaca"`.

O prefixo `Recipe_` é B41 e está morto: `EN/Recipes.json` tem 1.909 chaves e zero `Recipe_`. Ver
`traducao.md`.

## Onde a receita fica disponível

- `Tags = InHandCraft` — craftável sem bancada, direto no inventário.
- Sem isso, a receita precisa de uma superfície/estação. `WS/SiddigoWeapons/` usa
  `tags = AnySurfaceCraft` — mas com `t` minúsculo, que diverge do jogo (ver `armadilhas.md` §3).
  Use `Tags`.
- Receita que pertence a uma bancada específica vai como `component CraftRecipe` dentro do `entity`,
  não como `craftRecipe` solto. Ver `objeto.md`.

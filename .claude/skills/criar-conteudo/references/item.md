# Item

**Contrato completo da sintaxe: `Documentacao/jogo/scripts-txt.md`, seção `item`.** Leia lá o bloco
canônico, os 15 `ItemType`, `Tags`, `Categories` × `DisplayCategory` e os campos de comida. Esta
página carrega só o que muda quando é *mod* escrevendo, não o jogo.

## Onde escrever

`Contents/mods/<Mod>/42/media/scripts/<Mod>_Items.txt` — um arquivo por assunto, no módulo do mod.

O jogo separa por `ItemType` (`generated/items/weapon.txt`, `food.txt`, …). **Mod não precisa imitar
essa separação** — mods reais usam um arquivo só. Se o mod já tem um `_Items.txt`, acrescente o bloco
dentro do `module` existente.

## Esqueleto lado-mod

```
module MeuMod
{
    imports
    {
        Base
    }

    item MinhaFaca
    {
        DisplayCategory = Weapon,
        ItemType = base:weapon,
        Weight = 0.3,
        Icon = MinhaFaca,
        ...
    }
}
```

Referenciado no resto do mod como `MeuMod.MinhaFaca` (ponto). Ver `armadilhas.md` §1 e §2 —
`imports` é plural e o módulo é o do mod.

## Campo obrigatório de verdade

`ItemType`. Os 5.105 itens do jogo declaram, nenhum omite. Valor fora dos 15 = item inexistente.

`DisplayName` no bloco é redundante com a tradução e alguns mods põem os dois. O caminho certo é a
chave em `ItemName.json` (ver `traducao.md`); `DisplayName` no `.txt` é o fallback quando não há
tradução.

## Arte — L2

**Contrato completo: `Documentacao/jogo/arte-e-modelos.md`.** Lá estão o bloco `model` campo a campo,
o exemplo canônico do jogo e os 6 campos de `item` que apontam para modelo — incluindo quais levam
prefixo de módulo e quais nunca levam. Aqui fica só o lado-mod.

**Ícone é obrigatório na prática.** Sem ele o item aparece no inventário sem imagem.

| Campo no `.txt` | O que precisa existir no mod |
|---|---|
| `Icon = MinhaFaca` | `common/media/textures/Item_MinhaFaca.png` |
| `WorldStaticModel = MinhaFaca` | bloco `model` (script, pasta de versão) + `common/media/models_X/<mesh>.fbx` + `common/media/textures/<texture>.png` |

Três coisas que fazem o asset sumir sem erro:

- **O prefixo `Item_` é implícito** — `Icon = Item_MinhaFaca` faz o jogo procurar
  `Item_Item_MinhaFaca.png`. É o erro mais comum.
- **Ícone e textura da malha são arquivos diferentes**, com o mesmo nome-base em pastas diferentes.
  `WS/SiddigoWeapons` tem os dois e é o exemplo completo funcional.
- **Arte em `common/`, script na pasta de versão** — ver `armadilhas.md` §7.

Modelo 3D é opcional: só se o item precisa aparecer no chão ou na mão em 3D. `mesh` e `texture` vão
**sem extensão**. Offsets e rotações de `attachment` são tentativa e erro in-game — copie de um item
do jogo com formato parecido e diga que é ponto de partida, não invente valor.

## Mundo — L3

**Um item novo não aparece em lugar nenhum até alguém escrever Lua.** Ver `mundo.md`. Pergunte ao
usuário qual das três: loot, coleta, ou só craftável.

## Uso — L5

`Tags` é como o B42 amarra item a receita: a receita pede `tags[base:sharpknife]` em vez de listar
item. Se o item novo deve servir a receitas existentes do jogo, é por `Tags` que isso acontece —
procure a tag que as receitas-alvo já pedem em vez de editar receita do jogo.

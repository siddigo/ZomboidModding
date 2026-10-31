# ZomboidModding

Workspace para criar mods de **Project Zomboid (Build 42)** com o [Claude Code](https://claude.com/claude-code):
documentação de referência do jogo aterrada no código, skills que levam um mod do esqueleto até a
release, e as convenções que evitam as falhas silenciosas do parser da IndieStone.

Tudo está em português.

## O que tem aqui

- **`Documentacao/jogo/`**: referência do B42 por área (sintaxe dos `.txt`, eventos Lua, loot,
  tradução, multiplayer, animação, tiles e mais). Cada afirmação aponta `caminho:linha` no `media/`
  do jogo, e cada página carimba o `buildid` da Steam em que foi conferida. Comece por
  [`Documentacao/index.md`](Documentacao/index.md).
- **`.claude/skills/`**:
  - `iniciar-mod` cria o esqueleto B42 de um mod novo (`mod.info`, `workshop.txt`, poster, git).
  - `criar-conteudo` cria item, receita, traço, profissão ou objeto com todas as camadas: `.txt`,
    arte, loot, tradução.
  - `planejador` quebra uma feature em specs autocontidas para outra sessão executar.
  - `doc-pz` gera e reconfere a documentação depois de um patch do jogo.
  - `squash-merge` e `fechar-versao` cuidam de integração de branch e GitHub Release por mod.
- **`.claude/agents/`**: `pz-explorer`, um explorador read-only barato para grep pesado no `media/`;
  e `mod-scaffolder`, o executor da `iniciar-mod`.
- **`.claude/CLAUDE.md`**: as convenções do workspace (ordem de consulta, formato de mod,
  regras de escrita de código Lua, permissões).

## Como usar

1. Clone o repositório e abra o Claude Code **com o cwd na raiz dele**. Skills e `CLAUDE.md` só
   carregam a partir daqui.
2. Crie `.claude/settings.local.json` com os caminhos da sua máquina:

   ```json
   {
     "permissions": {
       "additionalDirectories": [
         "C:\\Program Files (x86)\\Steam\\steamapps\\common\\ProjectZomboid",
         "C:\\Users\\<voce>\\Zomboid"
       ]
     },
     "autoMemoryDirectory": "C:\\caminho\\do\\clone\\.claude\\memory"
   }
   ```

3. Se seus caminhos diferem do padrão Steam, ajuste a tabela "Locais do workspace" num `CLAUDE.md`
   na raiz do repositório (é ignorado pelo git e carregado junto com o `.claude/CLAUDE.md`).
4. Peça: "cria um mod novo chamado MeuMod", "adiciona uma arma de pedra ao MeuMod", "planeja um
   sistema de X". As skills se encarregam do resto.

Os mods ficam em `~\Zomboid\Workshop`, fora deste repositório. O que você gerar aqui (`Projetos/`,
`Documentacao/mods/`, `.claude/memory/`) é seu e já está no `.gitignore`.

## Limites

- A documentação reflete o `buildid` carimbado em cada página. Depois de um patch da Steam, compare
  com `steamapps/appmanifest_108600.acf` e rode `/doc-pz` nas páginas defasadas.
- `iniciar-mod` usa PowerShell e `System.Drawing`, então é só para Windows.
- Os documentos oficiais da IndieStone citados em `Documentacao/fontes-externas.md` (*Migration
  Guide*, *API for Inventory Items*) não são redistribuídos aqui.

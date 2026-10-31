<#
.SYNOPSIS
    Cria o esqueleto obrigatorio de um mod de Project Zomboid no formato B42.

.DESCRIPTION
    Gera uma pasta de upload da Steam Workshop completa e valida:

        <Destino>\<Nome>\
          workshop.txt
          preview.png
          .gitignore
          Contents\mods\<Nome>\
            <PastaVersao>\            (42 por padrao)
              mod.info
              poster.png
              media\lua\shared\<Nome>_Init.lua
              media\scripts\.gitkeep
            common\media\.gitkeep

    Regras de seguranca:
      - NUNCA sobrescreve. Aborta se <Destino>\<Nome> ja existir.
      - Nao escreve nada fora de <Destino>\<Nome>.
      - Le (nunca escreve) media\WorkshopTags.txt do jogo para validar as tags.

.EXAMPLE
    .\novo-mod.ps1 -Nome MeuMod

.EXAMPLE
    .\novo-mod.ps1 -Nome MeuMod -Id meuMod -Titulo "Meu Mod [B42]" `
                   -Descricao "Adiciona bicicletas" -Tags 'Build 42','Vehicles'

.NOTES
    Formato levantado em Documentacao/jogo/carregamento-de-mods.md.

    MANTER ESTE ARQUIVO 100% ASCII - sem acento, sem travessao. O PowerShell 5.1
    le .ps1 sem BOM como Windows-1252: o ultimo byte de um travessao UTF-8 vira
    aspa tipografica, que o parser aceita como delimitador de string e quebra o
    script inteiro com erro em outra linha.
#>
[CmdletBinding()]
param(
    # Nome do mod: vira a pasta de upload E a pasta em Contents\mods\.
    [Parameter(Mandatory = $true)]
    [string]$Nome,

    # id do mod.info - identificador interno, imutavel depois de publicar.
    # Padrao: $Nome com a primeira letra minuscula (MeuMod -> meuMod).
    [string]$Id,

    # Nome exibido (mod.info name= e workshop.txt title=). Padrao: $Nome.
    [string]$Titulo,

    [string]$Descricao = 'TODO: descrever o mod em uma linha',

    # Padrao: git config user.name.
    [string]$Autor,

    # Validadas contra as 31 tags de media\WorkshopTags.txt.
    [string[]]$Tags = @('Build 42'),

    # Build minimo do jogo. Convencao do workspace: acompanhar a estavel mais
    # recente, nao o piso do B42. Subir este default quando a estavel avancar.
    [string]$VersionMin = '42.20',

    # Nome da pasta de versao. No workspace convivem '42' e '42.0'.
    [string]$PastaVersao = '42',

    [string]$Destino = (Join-Path $env:USERPROFILE 'Zomboid\Workshop'),

    [string]$CaminhoJogo = 'C:\Program Files (x86)\Steam\steamapps\common\ProjectZomboid',

    # Pula o git init.
    [switch]$SemGit
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

# ---------------------------------------------------------------- utilitarios

# UTF-8 SEM BOM: um BOM na primeira linha quebraria o 'name=' do mod.info.
function Write-Texto {
    param([string]$Caminho, [string[]]$Linhas)
    $codificacao = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Caminho, (($Linhas -join "`r`n") + "`r`n"), $codificacao)
}

# Placeholder 256x256 (dimensao usada pelos mods do workspace), obviamente
# provisorio - o objetivo e nao deixar arte de outro mod entrar por copia.
function New-PosterPlaceholder {
    param([string]$Caminho, [string]$Texto)

    Add-Type -AssemblyName System.Drawing
    $bmp = New-Object System.Drawing.Bitmap 256, 256
    $g = [System.Drawing.Graphics]::FromImage($bmp)
    try {
        $g.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
        $g.TextRenderingHint = [System.Drawing.Text.TextRenderingHint]::AntiAlias
        $g.Clear([System.Drawing.Color]::FromArgb(32, 34, 38))

        $caneta = New-Object System.Drawing.Pen ([System.Drawing.Color]::FromArgb(96, 104, 116)), 4
        $g.DrawRectangle($caneta, 8, 8, 239, 239)

        $centro = New-Object System.Drawing.StringFormat
        $centro.Alignment = [System.Drawing.StringAlignment]::Center
        $centro.LineAlignment = [System.Drawing.StringAlignment]::Center

        $fonteNome = New-Object System.Drawing.Font 'Segoe UI', 18, ([System.Drawing.FontStyle]::Bold)
        $pincelNome = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(232, 232, 236))
        $areaNome = New-Object System.Drawing.RectangleF 20, 70, 216, 110
        $g.DrawString($Texto, $fonteNome, $pincelNome, $areaNome, $centro)

        $fonteAviso = New-Object System.Drawing.Font 'Segoe UI', 10
        $pincelAviso = New-Object System.Drawing.SolidBrush ([System.Drawing.Color]::FromArgb(150, 156, 168))
        $areaAviso = New-Object System.Drawing.RectangleF 20, 186, 216, 24
        $g.DrawString('PLACEHOLDER - TROCAR', $fonteAviso, $pincelAviso, $areaAviso, $centro)

        $bmp.Save($Caminho, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        foreach ($d in @($caneta, $fonteNome, $pincelNome, $fonteAviso, $pincelAviso, $centro, $g, $bmp)) {
            if ($d) { $d.Dispose() }
        }
    }
}

# ---------------------------------------------------------------- validacoes

if ($Nome -notmatch '^[A-Za-z][A-Za-z0-9_-]*$') {
    throw "Nome invalido: '$Nome'. Use letras/numeros/_/- comecando por letra, sem espaco nem acento (vira nome de pasta lido pelo jogo)."
}
if ($PastaVersao -notmatch '^\d+(\.\d+)?$') {
    throw "PastaVersao invalida: '$PastaVersao'. Esperado '42' ou '42.0'."
}
if ($VersionMin -notmatch '^\d+(\.\d+)?$') {
    throw "VersionMin invalido: '$VersionMin'. Esperado '42.0', '42.8', etc."
}
if (-not $Id) { $Id = $Nome.Substring(0, 1).ToLowerInvariant() + $Nome.Substring(1) }
if (-not $Titulo) { $Titulo = $Nome }
if (-not $Autor) { $Autor = git config user.name }
if (-not $Autor) { throw 'Sem -Autor e sem git config user.name: informe o autor.' }

# Aceita -Tags 'A','B' e tambem -Tags 'A;B' / 'A,B' (o -File do powershell.exe
# entrega a lista inteira como uma string so).
$Tags = @($Tags | ForEach-Object { $_ -split '[;,]' } |
    ForEach-Object { $_.Trim() } | Where-Object { $_ })

# Tags: validar e normalizar a grafia contra a lista oficial do jogo.
$arquivoTags = Join-Path $CaminhoJogo 'media\WorkshopTags.txt'
if (Test-Path -LiteralPath $arquivoTags) {
    $tagsValidas = @(Get-Content -LiteralPath $arquivoTags |
        ForEach-Object { $_.Trim() } | Where-Object { $_ })
    $Tags = @($Tags | ForEach-Object {
        $procurada = $_.Trim()
        $canonica = $tagsValidas | Where-Object { $_ -eq $procurada } | Select-Object -First 1
        if (-not $canonica) {
            throw "Tag invalida: '$procurada'. As $($tagsValidas.Count) validas sao: $($tagsValidas -join ', ')"
        }
        $canonica
    })
}
else {
    Write-Warning "Nao achei $arquivoTags - tags gravadas SEM validacao. Confira contra media\WorkshopTags.txt."
}

if (-not (Test-Path -LiteralPath $Destino)) {
    throw "Destino nao existe: $Destino"
}

$raiz = Join-Path $Destino $Nome
if (Test-Path -LiteralPath $raiz) {
    throw "Ja existe: $raiz`nEste script nunca sobrescreve. Escolha outro -Nome ou remova a pasta manualmente."
}

# ---------------------------------------------------------------- construcao

$pastaMod = Join-Path $raiz "Contents\mods\$Nome"
$pastaVer = Join-Path $pastaMod $PastaVersao
$pastaLua = Join-Path $pastaVer 'media\lua\shared'
$pastaScripts = Join-Path $pastaVer 'media\scripts'
$pastaCommon = Join-Path $pastaMod 'common\media'

foreach ($p in @($raiz, $pastaLua, $pastaScripts, $pastaCommon)) {
    New-Item -ItemType Directory -Path $p -Force | Out-Null
}

# mod.info - campos e ordem de Documentacao/jogo/carregamento-de-mods.md.
Write-Texto (Join-Path $pastaVer 'mod.info') @(
    "name=$Titulo"
    "id=$Id"
    "description=$Descricao"
    'poster=poster.png'
    "author=$Autor"
    'modversion=1.0'
    "versionMin=$VersionMin"
)

# workshop.txt - 'id=' NAO entra: a Steam escreve de volta no 1o upload.
# Separador de tags = ';' (o que os dois mods ja publicados do workspace usam).
Write-Texto (Join-Path $raiz 'workshop.txt') @(
    'version=1'
    "title=$Titulo"
    "description=$Descricao"
    "tags=$($Tags -join ';')"
    'visibility=public'
)

Write-Texto (Join-Path $raiz '.gitignore') @(
    '# Lixo do Windows/editor'
    'Thumbs.db'
    'desktop.ini'
    '*.bak'
    '*~'
    ''
    '# Artefatos do jogo, caso algum caia aqui por engano'
    'console.txt'
    'hs_err_pid*.log'
    '*.hprof'
)

# Smoke test: confirma no console.txt que o mod carregou.
Write-Texto (Join-Path $pastaLua "$($Nome)_Init.lua") @(
    "local function on${Nome}Start()"
    "    print(`"[$Nome] carregado`")"
    'end'
    ''
    "Events.OnGameStart.Add(on${Nome}Start)"
)

Write-Texto (Join-Path $pastaScripts '.gitkeep') @(
    '# media/scripts: itens, craftRecipe, entity (.txt). Apagar ao criar o 1o script.'
)
Write-Texto (Join-Path $pastaCommon '.gitkeep') @(
    '# common/media: o que nao muda entre builds (textures, models_X, tiles).'
)

New-PosterPlaceholder -Caminho (Join-Path $pastaVer 'poster.png') -Texto $Nome
New-PosterPlaceholder -Caminho (Join-Path $raiz 'preview.png') -Texto $Nome

# ---------------------------------------------------------------- git

$estadoGit = 'pulado (-SemGit)'
if (-not $SemGit) {
    if (Get-Command git -ErrorAction SilentlyContinue) {
        $saida = & git -C $raiz init -q -b master 2>&1
        if ($LASTEXITCODE -ne 0) { $saida = & git -C $raiz init -q 2>&1 }
        if ($LASTEXITCODE -eq 0) {
            $estadoGit = 'repositorio inicializado (nada commitado ainda)'
        }
        else {
            $estadoGit = "FALHOU: $saida"
        }
    }
    else {
        $estadoGit = 'FALHOU: git nao encontrado no PATH'
    }
}

# ---------------------------------------------------------------- relatorio

$criados = Get-ChildItem -LiteralPath $raiz -Recurse -File -Force |
    Where-Object { $_.FullName -notlike "*\.git\*" } |
    ForEach-Object { $_.FullName.Substring($raiz.Length + 1) }

Write-Host ""
Write-Host "Mod '$Nome' criado em: $raiz"
Write-Host "  id=$Id  versionMin=$VersionMin  pasta de versao=$PastaVersao  tags=$($Tags -join ';')"
Write-Host "  git: $estadoGit"
Write-Host ""
Write-Host "Arquivos:"
$criados | ForEach-Object { Write-Host "  $_" }
Write-Host ""
Write-Host "Pendente (o script nao tem como resolver):"
Write-Host "  - poster.png e preview.png sao placeholders 256x256 - trocar pela arte real"
if ($Descricao -like 'TODO:*') {
    Write-Host "  - description= esta como TODO em mod.info e workshop.txt"
}
Write-Host "  - commit inicial: git -C `"$raiz`" add -A; git -C `"$raiz`" commit -m `"Esqueleto inicial`""
Write-Host "  - para testar in-game, o conteudo de Contents\mods precisa chegar a ~\Zomboid\mods"
Write-Host ""

#Requires -Version 5.1
<#
.SYNOPSIS
    安装 dsh-memory-combo：meow-memory（自动层）+ 灵枢（深度层），并把分工配置写进 profile。

.DESCRIPTION
    只做三件事：
      1. 用 dsh plugin 安装两个插件；
      2. 备份 profile 的 cordis.patch.yml；
      3. 打印需要合并的配置片段（默认不自动改文件，避免破坏用户已有条目）。

.PARAMETER Profile
    DSH profile 名，默认 desktop。

.PARAMETER ApplyConfig
    传这个开关时才把配置片段追加进 cordis.patch.yml（会先备份）。

.EXAMPLE
    ./install.ps1
    ./install.ps1 -ApplyConfig
#>
param(
    [string]$Profile = 'desktop',
    [switch]$ApplyConfig
)

$ErrorActionPreference = 'Stop'

function Get-DshHome {
    if ($env:DSH_HOME) { return $env:DSH_HOME }
    return (Join-Path $HOME '.dsh')
}

$dshHome = Get-DshHome
$patchFile = Join-Path $dshHome "profiles\$Profile\cordis.patch.yml"
$exampleFile = Join-Path $PSScriptRoot '..\patch\cordis.patch.yml.example'

Write-Host "DSH_HOME = $dshHome"
Write-Host "profile  = $Profile"
Write-Host "patch    = $patchFile"
Write-Host ''

if (-not (Get-Command dsh -ErrorAction SilentlyContinue)) {
    throw '找不到 dsh 命令。请先安装 @deepseek-ai/dsh，或使用桌面应用自带的 dsh。'
}

Write-Host '[1/3] 安装 meow-memory ...'
& dsh plugin --profile $Profile add meow-memory@0.32.6
if ($LASTEXITCODE -ne 0) { throw "安装 meow-memory 失败（exit $LASTEXITCODE）" }

Write-Host '[2/3] 安装 @furongjun1999/dsh-memory ...'
& dsh plugin --profile $Profile add '@furongjun1999/dsh-memory@0.9.23'
if ($LASTEXITCODE -ne 0) { throw "安装 dsh-memory 失败（exit $LASTEXITCODE）" }

Write-Host '[3/3] 处理配置 ...'
if (-not (Test-Path $patchFile)) {
    throw "找不到 $patchFile，请先启动一次 DSH 以初始化 profile。"
}

$backup = "$patchFile.bak-$(Get-Date -Format yyyyMMdd-HHmmss)"
Copy-Item $patchFile $backup
Write-Host "已备份：$backup"

$snippet = Get-Content $exampleFile -Raw
if ($ApplyConfig) {
    Add-Content -Path $patchFile -Value "`n$snippet" -Encoding utf8
    Write-Host '配置片段已追加。请重启 DSH 使配置生效。'
} else {
    Write-Host ''
    Write-Host '配置片段如下，请手动合并进上面的 patch 文件（或用 -ApplyConfig 自动追加）：'
    Write-Host '------------------------------------------------------------'
    Write-Host $snippet
    Write-Host '------------------------------------------------------------'
}

Write-Host ''
Write-Host '完成后：重启 DSH，然后按 docs/design.md 的「验收」一节逐条检查。'

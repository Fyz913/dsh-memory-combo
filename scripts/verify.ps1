#Requires -Version 5.1
<#
.SYNOPSIS
    dsh-memory-combo 安装后自检：确认两套记忆的数据目录与配置都已就位。

.DESCRIPTION
    只做只读检查，不写任何文件。检查项：
      1. profile 的 cordis.patch.yml 是否包含两个 entry；
      2. meow 的记忆库是否已生成（.dsh-meow/memory.db）；
      3. 灵枢的认知图根是否已生成（$DSH_HOME/.dsh-memory/data/mdcg）；
      4. 灵枢 Python 大脑进程是否存在。

    更重的端到端验收（写入后读回）需要在会话里调用工具，见 docs/design.md。
#>
param(
    [string]$Profile = 'desktop',
    [string]$Workspace = (Get-Location).Path
)

$ErrorActionPreference = 'Continue'
$ok = 0
$fail = 0

function Check([string]$name, [bool]$passed, [string]$detail = '') {
    if ($passed) {
        Write-Host ("[OK]   {0}" -f $name) -ForegroundColor Green
        $script:ok++
    } else {
        Write-Host ("[FAIL] {0} {1}" -f $name, $detail) -ForegroundColor Red
        $script:fail++
    }
}

$dshHome = if ($env:DSH_HOME) { $env:DSH_HOME } else { Join-Path $HOME '.dsh' }
$patch = Join-Path $dshHome "profiles\$Profile\cordis.patch.yml"

Write-Host "DSH_HOME  = $dshHome"
Write-Host "workspace = $Workspace"
Write-Host ''

$patchText = if (Test-Path $patch) { Get-Content $patch -Raw } else { '' }
Check 'profile patch 存在' (Test-Path $patch) $patch
Check 'patch 含 meow-memory entry' ($patchText -match '(?m)^\s*-\s*id:\s*meow-memory') ''
Check 'patch 含灵枢 entry' ($patchText -match '(?m)^\s*-\s*id:\s*furongjun1999-dsh-memory') ''

$meowDb = Join-Path $Workspace '.dsh-meow\memory.db'
Check 'meow 记忆库已生成' (Test-Path $meowDb) $meowDb

$lingRoot = Join-Path $dshHome '.dsh-memory\data\mdcg'
Check '灵枢认知图根已生成' (Test-Path $lingRoot) $lingRoot

$py = Get-Process python -ErrorAction SilentlyContinue
Check '灵枢 Python 大脑进程在运行' ([bool]$py) '（未启动：检查 Python 是否在 PATH，或看 DSH 日志）'

Write-Host ''
Write-Host ("通过 {0} 项，失败 {1} 项。" -f $ok, $fail)
if ($fail -gt 0) { exit 1 }

# Check agent-job.ps1 without touching Task Scheduler or the real profile: the schedule maths,
# and a dry run in a temporary profile with a stub claude (prompt composition, per-job model
# and effort, state directory kept out of `git status`).
# usage: pwsh -NoProfile -File tests/test_agent_job.ps1 [path to agent-job.ps1]
param([string]$Script = (Join-Path $PSScriptRoot '..\plugins\dev-cycle\agent-jobs\agent-job.ps1'))
$ErrorActionPreference = 'Stop'
$Script = (Resolve-Path $Script).Path
$fail = 0
function Check([string]$Label, [bool]$Ok, [string]$Detail = '') {
    if ($Ok) { "ok   $Label" } else { "FAIL $Label $Detail"; $script:fail = 1 }
}

# 1. Schedule maths: the two functions, taken from the script text.
$tokens = $null; $errors = $null
$ast = [System.Management.Automation.Language.Parser]::ParseFile($Script, [ref]$tokens, [ref]$errors)
Check 'script parses' ($errors.Count -eq 0)
foreach ($name in 'ConvertTo-Minutes', 'Get-JobSchedule') {
    $fn = $ast.FindAll({ param($n) $n -is [System.Management.Automation.Language.FunctionDefinitionAst] -and $n.Name -eq $name }.GetNewClosure(), $true)[0]
    Invoke-Expression $fn.Extent.Text
}
function Installed($Interval, $Start) {
    [pscustomobject]@{ Triggers = @([pscustomobject]@{ Repetition = [pscustomobject]@{ Interval = $Interval }; StartBoundary = $Start }) }
}
function Expect($Label, $Plan, $Want) {
    $got = '{0} {1:d2}:{2:d2}' -f $Plan.Minutes, [int]$Plan.Hour, [int]$Plan.Minute
    Check "$Label -> $got" ($got -eq $Want) "(want $Want)"
}
Expect 'collect-issues default'          (Get-JobSchedule 'collect-issues' '' -1 -1 $null 0)   '360 00:00'
Expect 'collect-backlog default'         (Get-JobSchedule 'collect-backlog' '' -1 -1 $null 0)  '360 03:00'
Expect 'autodebug default'               (Get-JobSchedule 'autodebug' '' -1 -1 $null 0)        '30 00:07'
Expect 'autobacklog default, 1 other'    (Get-JobSchedule 'autobacklog' '' -1 -1 $null 1)      '30 00:22'
Expect 'reinstall keeps 30m and :07'     (Get-JobSchedule 'autodebug' '' -1 -1 (Installed 'PT30M' '2026-01-01T00:07:00') 1) '30 00:07'
Expect '-Every 60m places the start'     (Get-JobSchedule 'autodebug' '60m' -1 -1 (Installed 'PT30M' '2026-01-01T00:07:00') 1) '60 00:22'
Expect 'reinstall keeps 1h'              (Get-JobSchedule 'autodebug' '' -1 -1 (Installed 'PT1H' '2026-01-01T00:22:00') 1) '60 00:22'
Expect 'reinstall keeps 24h'             (Get-JobSchedule 'collect-issues' '' -1 -1 (Installed 'P1D' '2026-01-01T00:00:00') 0) '1440 00:00'
Expect '-Every 15'                       (Get-JobSchedule 'autobacklog' '15' -1 -1 $null 0)    '15 00:07'
Expect '-Every 2h'                       (Get-JobSchedule 'autobacklog' '2h' -1 -1 $null 1)    '120 00:22'
Expect 'collect-backlog -Every 1h'       (Get-JobSchedule 'collect-backlog' '1h' -1 -1 $null 0) '60 00:30'
Expect '12h with -Hour 5 -Minute 10'     (Get-JobSchedule 'collect-backlog' '12h' 10 5 $null 0) '720 05:10'
foreach ($bad in '45m', '7', '90m', '5h', '0', 'abc') {
    $rejected = $false; try { ConvertTo-Minutes $bad | Out-Null } catch { $rejected = $true }
    Check "-Every $bad rejected" $rejected
}

# 2. Dry run in a temporary profile. $HOME follows USERPROFILE in a new pwsh process.
$tmp = Join-Path ([IO.Path]::GetTempPath()) ("dc-test-" + [guid]::NewGuid().ToString('N').Substring(0, 8))
$home2 = Join-Path $tmp 'home'; $bin = Join-Path $tmp 'bin'; $repo = Join-Path $tmp 'repo'
New-Item -ItemType Directory -Force (Join-Path $home2 '.claude\plugins'), $bin, $repo | Out-Null
try {
    git -C $repo init -q
    $plugin = (Resolve-Path (Join-Path (Split-Path $Script) '..')).Path
    @{ plugins = @{ 'dev-cycle@test' = @(@{ installPath = $plugin }) } } | ConvertTo-Json -Depth 5 |
        Set-Content (Join-Path $home2 '.claude\plugins\installed_plugins.json') -Encoding utf8
    $pwsh = (Get-Process -Id $PID).Path
    # stub claude: record the arguments. The prompt is read from the file the runner feeds it.
    Set-Content (Join-Path $bin 'claude.cmd') "@echo off`r`necho %* > `"$tmp\claude.args`"`r`n" -Encoding ascii
    $old = $env:USERPROFILE, $env:PATH
    $env:USERPROFILE = $home2; $env:PATH = "$bin;$env:PATH"
    try {
        if ((& $pwsh -NoProfile -Command '$HOME') -ne $home2) { Check 'temporary profile is used' $false '($HOME did not follow USERPROFILE; dry run skipped)' }
        else {
            # the last case: a task installed before effort existed names a model only and keeps medium
            $cases = @(
                @{ Job = 'collect-issues'; Extra = @(); Want = '--model sonnet --effort high' },
                @{ Job = 'autodebug'; Extra = @(); Want = '--model opus --effort high' },
                @{ Job = 'autobacklog'; Extra = @(); Want = '--model opus --effort medium' },
                @{ Job = 'collect-issues'; Extra = @('-Model', 'opus'); Want = '--model opus --effort medium' })
            foreach ($c in $cases) {
                Remove-Item "$tmp\claude.args" -ErrorAction SilentlyContinue
                $logs = Join-Path $repo ".dev-cycle\jobs\$($c.Job)\logs"
                Remove-Item $logs -Recurse -Force -ErrorAction SilentlyContinue
                $extra = $c.Extra
                & $pwsh -NoProfile -File $Script -Action run -Job $c.Job -DryRun -Repo $repo @extra *> (Join-Path $tmp 'run.log')
                $callArgs = if (Test-Path "$tmp\claude.args") { Get-Content "$tmp\claude.args" -Raw } else { '' }
                $prompt = Get-ChildItem $logs -Filter '*.prompt.md' -ErrorAction SilentlyContinue | Select-Object -First 1
                $stdin = if ($prompt) { Get-Content $prompt.FullName -Raw } else { '' }
                $ok = $callArgs.Contains($c.Want) -and $stdin -match '(?m)^## Job: ' -and $stdin -match '(?m)^# Unattended dev-cycle job' -and
                    $stdin -match '(?m)^Mode: DRY RUN' -and $stdin -match "(?m)^Effort: "
                Check "run $($c.Job) $($c.Extra -join ' '): $($c.Want); prompt has header, common rules and job text" $ok "(args: $callArgs; log: $(Get-Content (Join-Path $tmp 'run.log') -Raw))"
            }
            Check 'state directory is not in git status' (-not (git -C $repo status --short))
            Check 'runner wrote a ledger row for the missing report' ((Get-Content (Join-Path $repo '.dev-cycle\jobs\autodebug\ledger.md') -Raw) -match 'report missing')
        }
    } finally { $env:USERPROFILE, $env:PATH = $old }
} finally { Remove-Item $tmp -Recurse -Force -ErrorAction SilentlyContinue }
exit $fail

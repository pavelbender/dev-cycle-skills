# Scheduled dev-cycle agent jobs on Windows Task Scheduler: autodebug and autobacklog work on
# items every 30 minutes; collect-issues and collect-backlog feed them every 6 hours.
# install/uninstall/pause/resume/status manage one task per repository and job in the
# \dev-cycle\ task folder. Each task runs the stable copy ~/.claude/agent-jobs/agent-job.ps1
# -Action run, which composes the prompt from the installed dev-cycle plugin at run time, so
# plugin updates need no reinstall.
param(
    [Parameter(Mandatory)][ValidateSet('install', 'uninstall', 'pause', 'resume', 'status', 'run')]
    [string]$Action,
    [ValidateSet('autodebug', 'autobacklog', 'collect-issues', 'collect-backlog')][string]$Job,
    [string]$Repo = '.',
    [int]$Minute = -1,       # install: first minute of the cycle; workers default to a spread, collectors to :00
    [int]$Hour = -1,         # install, collectors: first hour of the 6-hour cycle
    [switch]$DryRun,
    [int]$MaxAgents = 2,     # run: worker agents allowed at once on this machine, all repositories
    [string]$Model = 'opus'  # pinned, so a changed default model in the user's settings does not apply
)
$ErrorActionPreference = 'Stop'
$jobs = 'autodebug', 'autobacklog', 'collect-issues', 'collect-backlog'
$collectorHours = @{ 'collect-issues' = 0; 'collect-backlog' = 3 }   # 6-hour cycle, 3 hours apart
$taskPath = '\dev-cycle\'
$jobsHome = Join-Path $HOME '.claude\agent-jobs'
$stable = Join-Path $jobsHome 'agent-job.ps1'
$budget = New-TimeSpan -Hours 2       # hard kill of the agent process tree
$wrapUp = New-TimeSpan -Minutes 15    # the agent stops implementing this long before the kill

$top = git -C $Repo rev-parse --show-toplevel 2>$null
if ($LASTEXITCODE -eq 0) { $Repo = $top.Replace('/', '\'); $repoName = Split-Path $Repo -Leaf }
elseif ($Action -ne 'status') { throw "Not a git repository: $Repo" }
if ($Action -in 'install', 'run' -and -not $Job) { throw "-Job is required for $Action" }
$targets = if ($Job) { @($Job) } else { $jobs }

# `## Dev cycle` profile of the root AGENTS.md (or CLAUDE.md): `- key: value` lines.
function Read-Profile {
    $p = @{ jobs_state = '.dev-cycle/jobs/' }
    $file = 'AGENTS.md', 'CLAUDE.md' | ForEach-Object { Join-Path $Repo $_ } |
        Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $file) { return $p }
    $in = $false
    foreach ($line in Get-Content $file) {
        if ($line -match '^## ') { $in = $line -match '^## Dev cycle\s*$'; continue }
        if ($in -and $line -match '^- (\w+): (.+?)(\s{2,}#.*)?$') { $p[$Matches[1]] = $Matches[2].Trim() }
    }
    $p
}

function Get-PluginRoot {
    $installed = Join-Path $HOME '.claude\plugins\installed_plugins.json'
    $entry = (Get-Content $installed -Raw | ConvertFrom-Json).plugins.PSObject.Properties |
        Where-Object Name -like 'dev-cycle@*' | Select-Object -First 1
    if (-not $entry) { throw 'The dev-cycle plugin is not installed for Claude Code' }
    @($entry.Value)[0].installPath
}

if ($Repo -and $Action -ne 'status') {
    $prof = Read-Profile
    $stateRoot = Join-Path $Repo $prof.jobs_state
}

switch ($Action) {
    'install' {
        $rel = $prof.jobs_state.Replace('\', '/').TrimEnd('/')
        git -C $Repo check-ignore -q -- "$rel/$Job/ledger.md"
        if ($LASTEXITCODE -ne 0) {
            $exclude = Join-Path (git -C $Repo rev-parse --path-format=absolute --git-common-dir) 'info\exclude'
            Add-Content $exclude "/$rel/"
            "Added /$rel/ to $exclude"
        }
        New-Item -ItemType Directory -Force $jobsHome | Out-Null
        if ($PSCommandPath -ne $stable) { Copy-Item $PSCommandPath $stable -Force }

        $taskName = "$repoName $Job"
        $existing = @(Get-ScheduledTask -TaskPath $taskPath -ErrorAction SilentlyContinue)
        $mine = $existing | Where-Object TaskName -eq $taskName
        $was = if ($mine) { [datetime]$mine.Triggers[0].StartBoundary }
        if ($Minute -lt 0 -and $was) { $Minute = $was.Minute }
        if ($collectorHours.ContainsKey($Job)) {
            if ($Hour -lt 0) { $Hour = if ($was) { $was.Hour } else { $collectorHours[$Job] } }
            $Minute = [math]::Max($Minute, 0)
            $every = New-TimeSpan -Hours 6
        } else {
            if ($Minute -lt 0) {
                $n = @($existing | Where-Object { $_.TaskName -ne $taskName -and $_.TaskName -notmatch ' collect-' }).Count
                $Minute = (7 + 15 * $n + 5 * [math]::Floor($n / 2)) % 30   # pairs 15 min apart
            }
            $Hour = 0
            $every = New-TimeSpan -Minutes 30
        }
        $pwsh = (Get-Process -Id $PID).Path
        $taskAction = New-ScheduledTaskAction -Execute $pwsh -WorkingDirectory $Repo -Argument (
            "-NoProfile -NonInteractive -WindowStyle Hidden -File `"$stable`" -Action run -Job $Job -Repo `"$Repo`" -Model $Model")
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date.AddHours($Hour).AddMinutes($Minute) `
            -RepetitionInterval $every
        $settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew `
            -ExecutionTimeLimit ($budget + (New-TimeSpan -Minutes 30)) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
        Register-ScheduledTask -TaskPath $taskPath -TaskName $taskName -Action $taskAction -Trigger $trigger `
            -Settings $settings -Principal $principal -Force | Out-Null
        "{0}{1}: every {2} from {3:d2}:{4:d2}, next run {5}; state {6}" -f $taskPath, $taskName, $every, $Hour,
            $Minute, (Get-ScheduledTaskInfo -TaskPath $taskPath -TaskName $taskName).NextRunTime, (Join-Path $stateRoot $Job)
    }
    { $_ -in 'uninstall', 'pause', 'resume' } {
        foreach ($j in $targets) {
            $task = Get-ScheduledTask -TaskPath $taskPath -TaskName "$repoName $j" -ErrorAction SilentlyContinue
            if (-not $task) { continue }
            switch ($Action) {
                'uninstall' { $task | Unregister-ScheduledTask -Confirm:$false; "$repoName ${j}: removed" }
                'pause' { $task | Disable-ScheduledTask | Out-Null; "$repoName ${j}: paused" }
                'resume' { $task | Enable-ScheduledTask | Out-Null; "$repoName ${j}: resumed" }
            }
        }
    }
    'status' {
        Get-ScheduledTask -TaskPath $taskPath -ErrorAction SilentlyContinue | ForEach-Object {
            $i = $_ | Get-ScheduledTaskInfo
            [pscustomobject]@{ Task = $_.TaskName; State = $_.State; LastRun = $i.LastRunTime
                Result = $i.LastTaskResult; NextRun = $i.NextRunTime }
        } | Format-Table -AutoSize | Out-String
        if ($repoName) {
            $stateRoot = Join-Path $Repo (Read-Profile).jobs_state
            foreach ($j in $jobs) {
                $ledger = Join-Path $stateRoot "$j\ledger.md"
                if (Test-Path $ledger) { "== $j ($ledger)"; Get-Content $ledger -Tail 5 }
            }
        }
    }
    'run' {
        $state = Join-Path $stateRoot $Job
        foreach ($d in 'reports', 'logs', 'patches') { New-Item -ItemType Directory -Force (Join-Path $state $d) | Out-Null }
        $ledger = Join-Path $state 'ledger.md'
        if (-not (Test-Path $ledger)) {
            Set-Content $ledger "| stamp | item | status | branch | commit | report |`n| --- | --- | --- | --- | --- | --- |" -Encoding utf8
        }
        Get-ChildItem (Join-Path $state 'logs') -File |
            Where-Object LastWriteTime -lt (Get-Date).AddDays(-14) | Remove-Item -Force

        $root = Get-PluginRoot
        $latest = Join-Path $root 'agent-jobs\agent-job.ps1'
        if ($PSCommandPath -eq $stable -and (Get-FileHash $latest).Hash -ne (Get-FileHash $stable).Hash) {
            Copy-Item $latest $stable -Force   # takes effect from the next run
        }

        $start = Get-Date
        $stamp = $start.ToString('yyyyMMdd-HHmm')
        # ponytail: a stale lock whose PID was reused counts as running; clear running\ if runs stop.
        $running = New-Item -ItemType Directory -Force (Join-Path $jobsHome 'running')
        $live = @(Get-ChildItem $running -Filter *.lock | Where-Object {
            if (Get-Process -Id ([int](Get-Content $_.FullName)) -ErrorAction SilentlyContinue) { $true }
            else { Remove-Item $_.FullName; $false } })
        # Collectors run 4 times a day and are not capped, or busy workers would starve them.
        if (-not $collectorHours.ContainsKey($Job) -and $live.Count -ge $MaxAgents) {
            Add-Content (Join-Path $state 'logs\skipped.log') "${stamp}: busy ($($live.BaseName -join ', '))"
            return
        }
        $lock = Join-Path $running "$repoName-$Job.lock"
        Set-Content $lock $PID
        try {
            $deadline = $start + $budget
            $others = ($jobs | Where-Object { $_ -ne $Job } | ForEach-Object { "$_ = $(Join-Path $stateRoot $_)" }) -join '; '
            $notes = if ($prof.job_notes) { Join-Path $Repo $prof.job_notes }
            $header = @"
Job: $Job
Run stamp: $stamp
Started: $($start.ToString('s'))
Stop and wrap up by: $(($deadline - $wrapUp).ToString('s'))
Hard deadline: $($deadline.ToString('s')) (the process tree is killed then)
Mode: $(if ($DryRun) { 'DRY RUN' } else { 'FULL' })
Model: $Model
Repository (main checkout, operator's tree): $Repo
State directory: $state
State directories of the other jobs: $others
Job notes: $(if ($notes) { $notes } else { 'none' })
dev-cycle plugin root: $root


"@
            $jobText = ((Get-Content (Join-Path $root "skills\$Job\SKILL.md") -Raw) -split '<!-- job -->', 2)[1]
            $text = $header + (Get-Content (Join-Path $root 'agent-jobs\common.md') -Raw) + "`n" + $jobText
            if ($notes) { $text += "`n# Project job notes ($($prof.job_notes))`n`n" + (Get-Content $notes -Raw) }
            $promptFile = Join-Path $state "logs\$stamp.prompt.md"
            Set-Content $promptFile $text -Encoding utf8
            $log = Join-Path $state "logs\$stamp.jsonl"
            $err = Join-Path $state "logs\$stamp.err.log"

            $claude = (Get-Command claude -CommandType Application | Select-Object -First 1).Source
            Set-Location $Repo
            $p = Start-Process $claude -NoNewWindow -PassThru `
                -ArgumentList '-p', '--model', $Model, '--permission-mode', 'bypassPermissions', '--output-format', 'stream-json', '--verbose' `
                -RedirectStandardInput $promptFile -RedirectStandardOutput $log -RedirectStandardError $err
            $null = $p.Handle  # keeps ExitCode readable after WaitForExit
            if ($p.WaitForExit([int]$budget.TotalMilliseconds)) { $code = $p.ExitCode }
            else { taskkill /T /F /PID $p.Id | Out-Null; $code = 'timeout' }

            $reported = Get-ChildItem (Join-Path $state 'reports') -Filter "$stamp-*.md" -ErrorAction SilentlyContinue
            if ($code -ne 0 -or -not $reported) {
                Add-Content $ledger "| $stamp | (runner) | exit $code, report $(if ($reported) { 'written' } else { 'missing' }) | - | - | logs/$stamp.jsonl |" -Encoding utf8
            }
        } finally {
            Remove-Item $lock -ErrorAction SilentlyContinue
        }
    }
}

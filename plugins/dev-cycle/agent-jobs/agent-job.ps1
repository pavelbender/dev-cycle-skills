# Scheduled dev-cycle agent jobs on Windows Task Scheduler: autodebug and autobacklog work on
# items every 30 minutes by default; collect-issues and collect-backlog feed them every 6 hours
# by default. -Every sets another interval: 30m, 60m, 2h (plain number = minutes).
# install/uninstall/pause/resume/status manage one task per repository and job in the
# \dev-cycle\ task folder. Each task runs the stable copy ~/.claude/agent-jobs/agent-job.ps1
# -Action run, which composes the prompt from the installed dev-cycle plugin at run time, so
# plugin updates need no reinstall. Linux and macOS counterpart: agent-job.sh.
param(
    [Parameter(Mandatory)][ValidateSet('install', 'uninstall', 'pause', 'resume', 'status', 'run')]
    [string]$Action,
    [ValidateSet('autodebug', 'autobacklog', 'collect-issues', 'collect-backlog')][string]$Job,
    [string]$Repo = '.',
    [string]$Every,          # install: interval such as 30m, 60m, 2h; default 30m for workers, 6h for collectors
    [int]$Minute = -1,       # install: first minute of the cycle; default: a spread for workers, half an interval apart for collectors
    [int]$Hour = -1,         # install, intervals of 2h and more: first hour of the cycle
    [switch]$DryRun,
    [int]$MaxAgents = 2,     # run: worker agents allowed at once on this machine, all repositories
    [string]$Model,          # default per job, see below
    [ValidateSet('low', 'medium', 'high', 'xhigh', 'max')]
    [string]$Effort          # default per job, see below
)
$ErrorActionPreference = 'Stop'
$jobs = 'autodebug', 'autobacklog', 'collect-issues', 'collect-backlog'
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

# Model and effort are pinned per job, so a changed default in the user's settings does not
# apply. Collectors read and write documents; autodebug fixes bugs, where checking matters
# most; autobacklog builds scoped work. -Model and -Effort given at install go into the task;
# without them a job follows these defaults, also after a plugin update. A task that names a
# model and no effort (installs made before effort existed) runs at medium, as it did.
$pin = ''
if ($Model) { $pin += " -Model $Model" }
if ($Effort) { $pin += " -Effort $Effort" }
if ($Job) {
    $dm, $de = switch -Wildcard ($Job) { 'collect-*' { 'sonnet', 'high' } 'autodebug' { 'opus', 'high' } default { 'opus', 'medium' } }
    if ($Model) { $de = 'medium' } else { $Model = $dm }
    if (-not $Effort) { $Effort = $de }
}

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

# The interval in minutes. The same intervals as agent-job.sh, where cron needs an even repeat:
# a divisor of 60 minutes, or whole hours that divide a day.
function ConvertTo-Minutes([string]$Value) {
    if ($Value -notmatch '^(\d+)([mh]?)$') { throw "-Every ${Value}: use minutes or hours, e.g. 30m, 60m, 2h" }
    $n = [int]$Matches[1] * $(if ($Matches[2] -eq 'h') { 60 } else { 1 })
    if ($n -lt 1 -or 1440 % $n -or ($n -lt 60 -and 60 % $n) -or ($n -ge 60 -and $n % 60)) {
        throw "-Every ${Value}: use a divisor of an hour (5m, 10m, 15m, 20m, 30m) or whole hours that divide a day (1h, 2h, 3h, 4h, 6h, 8h, 12h, 24h)"
    }
    $n
}

# Interval and first start of a job. A new -Every places the start again; a reinstall without
# it keeps the installed interval and start. Collectors run half an interval apart; workers
# are spread over the half hour, pairs 15 minutes apart.
function Get-JobSchedule([string]$Job, [string]$Every, [int]$Minute, [int]$Hour, $Installed, [int]$OtherWorkers) {
    $was = $null
    if ($Every) { $min = ConvertTo-Minutes $Every }
    elseif ($Installed) {
        $min = [int][System.Xml.XmlConvert]::ToTimeSpan($Installed.Triggers[0].Repetition.Interval).TotalMinutes
        $was = [datetime]$Installed.Triggers[0].StartBoundary
    } else { $min = if ($Job -like 'collect-*') { 360 } else { 30 } }
    if ($Job -like 'collect-*') {
        $off = if ($Job -eq 'collect-backlog') { [math]::Floor($min / 2) } else { 0 }
        $dm = $off % 60; $dh = [math]::Floor($off / 60)
    } else { $dm = (7 + 15 * $OtherWorkers + 5 * [math]::Floor($OtherWorkers / 2)) % 30; $dh = 0 }
    if ($Minute -lt 0) { $Minute = if ($was) { $was.Minute } else { $dm } }
    if ($Hour -lt 0) { $Hour = if ($was) { $was.Hour } else { $dh } }
    if ($min -lt 60) { $Minute %= $min; $Hour = 0 } else { $Minute %= 60; $Hour %= [int]($min / 60) }
    [pscustomobject]@{ Minutes = $min; Minute = $Minute; Hour = $Hour }
}

# Keep the state directory out of the operator's `git status`. Called by install and by run,
# so a dry run before install leaves the checkout clean too.
function Add-StateExclude {
    $rel = $prof.jobs_state.Replace('\', '/').TrimEnd('/')
    git -C $Repo check-ignore -q -- "$rel/$Job/ledger.md"
    if ($LASTEXITCODE -eq 0) { return }
    $exclude = Join-Path (git -C $Repo rev-parse --path-format=absolute --git-common-dir) 'info\exclude'
    Add-Content $exclude "/$rel/"
    "Added /$rel/ to $exclude"
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
        Add-StateExclude
        New-Item -ItemType Directory -Force $jobsHome | Out-Null
        if ($PSCommandPath -ne $stable) { Copy-Item $PSCommandPath $stable -Force }

        $taskName = "$repoName $Job"
        $existing = @(Get-ScheduledTask -TaskPath $taskPath -ErrorAction SilentlyContinue)
        $mine = $existing | Where-Object TaskName -eq $taskName
        $others = @($existing | Where-Object { $_.TaskName -ne $taskName -and $_.TaskName -notmatch ' collect-' }).Count
        $plan = Get-JobSchedule $Job $Every $Minute $Hour $mine $others
        $interval = New-TimeSpan -Minutes $plan.Minutes
        $pwsh = (Get-Process -Id $PID).Path
        $taskAction = New-ScheduledTaskAction -Execute $pwsh -WorkingDirectory $Repo -Argument (
            "-NoProfile -NonInteractive -WindowStyle Hidden -File `"$stable`" -Action run -Job $Job -Repo `"$Repo`"$pin")
        $trigger = New-ScheduledTaskTrigger -Once -At (Get-Date).Date.AddHours($plan.Hour).AddMinutes($plan.Minute) `
            -RepetitionInterval $interval
        $settings = New-ScheduledTaskSettingsSet -MultipleInstances IgnoreNew `
            -ExecutionTimeLimit ($budget + (New-TimeSpan -Minutes 30)) -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
        $principal = New-ScheduledTaskPrincipal -UserId $env:USERNAME -LogonType Interactive -RunLevel Limited
        Register-ScheduledTask -TaskPath $taskPath -TaskName $taskName -Action $taskAction -Trigger $trigger `
            -Settings $settings -Principal $principal -Force | Out-Null
        "{0}{1}: every {2} from {3:d2}:{4:d2}, next run {5}; {6}, {7}; state {8}" -f $taskPath, $taskName, $interval, [int]$plan.Hour,
            [int]$plan.Minute, (Get-ScheduledTaskInfo -TaskPath $taskPath -TaskName $taskName).NextRunTime, $Model, $Effort, (Join-Path $stateRoot $Job)
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
        Add-StateExclude | Out-Null
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
        if ($Job -notlike 'collect-*' -and $live.Count -ge $MaxAgents) {
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
Effort: $Effort
Platform: Windows
Repository (main checkout, operator's tree): $Repo
State directory: $state
State directories of the other jobs: $others
Job notes: $(if ($notes) { $notes } else { 'none' })
dev-cycle plugin root: $root


"@
            $jobText = Get-Content (Join-Path $root "agent-jobs\jobs\$Job.md") -Raw
            $text = $header + (Get-Content (Join-Path $root 'agent-jobs\common.md') -Raw) + "`n" + $jobText
            if ($notes) { $text += "`n# Project job notes ($($prof.job_notes))`n`n" + (Get-Content $notes -Raw) }
            $promptFile = Join-Path $state "logs\$stamp.prompt.md"
            Set-Content $promptFile $text -Encoding utf8
            $log = Join-Path $state "logs\$stamp.jsonl"
            $err = Join-Path $state "logs\$stamp.err.log"

            $claude = (Get-Command claude -CommandType Application | Select-Object -First 1).Source
            Set-Location $Repo
            $p = Start-Process $claude -NoNewWindow -PassThru `
                -ArgumentList '-p', '--model', $Model, '--effort', $Effort, '--permission-mode', 'bypassPermissions', '--output-format', 'stream-json', '--verbose' `
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

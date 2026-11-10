# Probe notes template

Project specifics for `probe-paths`, kept in the file the profile names as `probe_notes`.
The skill is generic; this file makes it fit one product. Keep it in the repository so the
next session starts from it. Without it, iteration 1 drafts it into the state directory
and asks the owner to review and commit it.

```markdown
# Probe notes

## Stand
- Stand: <local compose project or URL>; start: <command>; never: <volume removal, …>
- Base URLs: API <url>, web <url>. Forbidden hosts: <production host, …>
- Auth: <cookie session / token>; registration: <open / invite only / seeded accounts>
- Email on the stand: <delivered to … / not delivered — flows that need it are blocked>

## Surfaces
| Surface | How to drive it | Limits |
| --- | --- | --- |
| Web UI | browser automation at <url> | one browser: one prober at a time |
| HTTP API | <schema file>; helper <script> | |
| CLI | build: <command>; isolation: <env vars and directories> | never from the repository root; forbidden commands: <…> |
| TUI | <needs a terminal: audit from <path>> | by-code only |
| Daemon | <foreground one-shot command> | never install, start or stop the installed service |
| MCP server | <stdio command> | only the prober's own process |

## Roles and permissions
- Source of truth: <permission catalog file>, <matrix document>
- Roles to play: <owner, admin, …, managed account, custom role with partial permissions>
- How to create each: <invite + register, provision managed, custom role>

## Test data
- Prefix for everything the probe creates: <uxprobe->
- Tenants to create: <one main; a second and third for cross-tenant identity>
- Source-control repository for client flows: <sandbox repository, or how the owner
  connects one; what breaks when it is faked>
- Shared stand data that may be read: <…>; that must not be changed: <…>

## Provider scenarios (GitHub, GitLab)
- Sandbox available: <organisation or group, what may be renamed, deleted, uninstalled>
- Not available: simulate by <local remote changes / test-tenant records>, else by-code

## Measurements
- Paths the client writes: <checkout paths, home paths, shared config files>
- Background poll: <default interval, back-off>; thresholds: <slow response, growth per day>

## Known answers
- <intended behaviour that looks like a defect, so it is not reported again>
- Where tracked issues live: <known_issues file>

## Owner decisions
- <date>: <what was allowed or forbidden>
```

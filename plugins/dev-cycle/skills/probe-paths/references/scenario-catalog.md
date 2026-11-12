# Scenario catalog

Families of scenarios for `probe-paths`. The catalog fits a product with a SaaS control
plane (tenants, roles, managed accounts), a developer-side client (CLI, TUI, background
daemon, local MCP server) and a source-control provider behind it. Drop the families whose
surface the project does not have; the probe notes say which exist.

A scenario is one row of `coverage.md`: role × area × action × surface (or surface pair).

## Axes

- Roles: tenant owner, administrator, regular member with a role, managed account
  (provisioned by an admin, no web login), custom role with partial permissions, a member
  without the needed permission, a removed member, a user with no tenant.
- Surfaces: web UI, HTTP API, CLI, TUI, background daemon, local MCP server, the files the
  product writes on the developer machine.
- Actions: create, edit, rename, enable, disable, archive, unarchive, delete, restore,
  assign, unassign, reassign, revoke, retry, repeat, transfer, leave.
- Areas: every noun of the product's permission catalog and route list.

## 1. Single-role paths

Walk one role through one area on one surface, first as a newcomer.

- Does every step say what happened and what to do next?
- Every visible control: works, is hidden, or is disabled with a reason that names the
  missing permission?
- Every refusal: does the text name the field, the permission, the conflicting object?
- Forms: validation text, lost input on navigation, duplicate names, a preview step that
  was promised.
- Unknown or deleted object URL, wrong tenant in the URL: a "not found" page with a way
  back, or a bare error?

## 2. Lifecycle symmetry

Build the table "action → reverse action" for every object from the route list and CLI
usage before walking. Then verify live.

- Create without delete; archive without unarchive; revoke without un-revoke; link without
  unlink; install without uninstall; assign without unassign.
- A wrongly created object: can it be removed, renamed, or does it hold its slug forever?
- An action named "archive" that deletes, or "delete" that archives.
- A state with no action left (failed preparation, pending forever, revoked).
- Records that only accumulate (revoked devices, used tokens, cancelled invites).
- The same class of object deletable in one place and not in another.

## 3. Permission matrix: UI versus API versus client

For each role, take the permission catalog and compare what each surface allows.

- Controls visible to a role that the API refuses after submit.
- Data closed by one route and open through another.
- A custom role that works through the API while the UI cannot resolve its permissions.
- An explanation endpoint (effective access, access check) that disagrees with the guard.
- Deny rules that do not deny; allow rules that do not allow.
- A role that can start something it cannot see or undo (enroll a device, never list it).
- Self-inflicted loss: a user demotes, removes or locks out themself; the last owner; a
  policy switch that removes everyone's access including the actor's.

## 4. Concurrent actors

Two or more actors on one object at the same instant. Use real parallelism (threads with
separate sessions), then repeat sequentially to tell a race from a missing check.

| Pair | Examples |
| --- | --- |
| SaaS + SaaS | parallel create with one slug or code; parallel edit (lost update, no version); replace-all lists (union instead of one set); archive versus bind; delete versus edit; role removed during a burst of writes; same delete twice |
| SaaS + CLI | device revoked, role lowered, asset disabled, binding removed, project archived or repository detached between and during CLI steps |
| SaaS + CLI + daemon | bindings change under a running daemon; member removed with an active device; two devices of one member; one checkout used by two devices |
| CLI + MCP + SaaS | plan made, state or permissions change, plan confirmed; same plan confirmed twice or from two processes; plan made by one device and confirmed by another; logout or revoke under a running MCP server |

Look for: duplicates, 5xx instead of 409, both callers told "done", dangling references,
success after permission loss, state that differs from every response.

## 5. Identity across tenants

One person, several tenants. Create the memberships deliberately.

- Same role in two tenants; different roles (owner in A, viewer in B); owner in A and
  managed account in B; regular in A and removed from B; invited to B while active in A.
- Tenant switching: is the selected tenant per session or per user; does a switch in one
  tab change another tab; what does a deep link to tenant B do while A is selected?
- Permission bleed: does the role of tenant A open anything in tenant B (lists, search,
  object IDs guessed across tenants, cached UI state after a switch)?
- Client side: one device credential and several tenants — which tenant does the CLI act
  in, is it shown, can it be chosen, what happens when the same repository is connected in
  both tenants (which one wins a link, is the user told)?
- Managed in one tenant and self-registered in another: can the person log in to the web
  at all, which tenant do they land in, does the managed restriction of B leak into A or
  the freedom of A leak into B (web access switch, MCP management tools, password reset)?
- Same-named tenants, invitations that do not identify the tenant, pending invitations to
  several tenants at once.
- Leaving: removed from the last tenant, removed from one of two while working in it, the
  sole owner of one tenant asking to delete the account that is a member elsewhere.
- Email identity: the same external account (source-control login, SSO subject) attached
  to two product users; invitation email differs from login email.

## 6. Many users in one tenant

Simulate a working team, not a pair. One scripted run = a swarm.

- 5–20 virtual users with mixed roles, each a separate session, acting for 1–3 minutes on
  a seeded random mix: readers listing and opening objects, writers creating, editing,
  assigning and archiving, an admin changing roles and memberships, clients polling.
- Record every request with actor, time, status. Keep the seed so a run can be replayed.
- After the run check invariants, not individual responses: unique slugs and codes, no
  binding or rule pointing at a deleted or archived object, no member twice in a project
  or team, counts in lists equal counts by ID, every object readable by its creator, no
  5xx, no response slower than the notes' threshold.
- Vary the mix: write-heavy on one object class; an admin revoking while everyone works;
  half the users in one project; bulk invitations accepted together.
- A swarm finding names the invariant, the seed and the smallest pair of actions that
  reproduces it sequentially or in parallel.

## 7. Source-control provider changes and failures

What the product does when GitHub or GitLab changes under it. Three ways to exercise it,
in order of preference; say which was used:

1. a disposable repository or group in a provider sandbox the notes allow;
2. local simulation in the test checkout (remote URL, branches, HEAD) and in the test
   tenant's own records when the owner allows;
3. reading the handling code (`by-code`).

Changes and failures:

- Repository renamed, transferred to another owner or group, archived, deleted, made
  private or public; default branch renamed; a tracked branch deleted or force-pushed;
  history rewritten; repository emptied.
- Integration: app uninstalled or suspended, repository removed from the app's selection,
  permissions reduced, token expired or revoked, the connecting user removed from the
  organisation, organisation renamed, SSO enforcement added.
- GitLab specifics: project moved between groups and subgroups, path changed without a
  rename, group access token rotated, self-hosted host unreachable or with a changed base
  URL, project access level lowered.
- Events: webhook missing, duplicated, delivered out of order or after the object is gone;
  rate limit reached; provider outage or slow answers during a sync.
- Local side: remote switched between SSH and HTTPS forms, a fork as origin with upstream
  elsewhere, two remotes, no remote, detached HEAD, worktrees, a branch unknown to the
  server, a shallow clone.

For each: what the admin sees in the product (a state, a reason, an action), what the
developer's client says, whether already delivered content stays, whether reconnecting
restores the previous configuration or starts empty, and whether a bare provider error code
is the only message.

## 8. Local footprint measurements

Measure what the product does to the developer machine. Numbers go into the finding.

- Snapshot the checkout and the client's home directory before and after each step
  (install, link, sync, deliver, repeat, change, remove, uninstall): files created,
  changed, left behind; entries added to shared config files and removed again.
- Idempotence: a second identical run writes nothing; a no-op poll writes nothing.
- Cleanup: after the reverse action the tree equals the snapshot, or the leftovers are
  listed to the user.
- User edits: a locally changed delivered file is backed up and announced; a read-only
  file, a missing file, a user file at an owned path, a corrupt state file.
- Growth: backups, logs and state per run and per day at the default poll rate; what
  prunes them.
- Cost: time of each command, requests and bytes per poll and per hour when nothing
  changes, CPU of the background process, behaviour when the server is unreachable (time
  to fail, retries).
- Version-control noise: which written paths show up in `git status`, which are ignored,
  whether the product edits ignore files.
- Report as a table: step, files +/~/−, bytes, seconds, requests; then the deviations.

## 9. Recovery and degraded state

- Corrupt, empty, missing or directory-instead-of-file for every local state file and the
  credential: does any command explain and repair, or does every command fail the same
  way?
- Server unreachable, slow, or answering 5xx: message, exit code, time to fail, whether
  the reason is distinguishable from "not authenticated".
- A step that fails after an irreversible server-side effect (a one-time token spent, a
  device registered) with nothing stored locally.
- Status commands that show a healthy state after a failed one.

## 10. Account and tenant lifecycle

Registration and invitation from the invitee's side (accept twice, decline then accept,
cancelled while open, wrong user), profile and password change (other sessions, sign out
everywhere), password recovery (rate limit, enumeration, invited but not registered),
privacy and deletion requests (identifier, status, cancel, the sole owner's tenant), a
user with no tenant, tenant rename and deletion, ownership transfer, managed-account
onboarding when email delivery does not work.

## 11. Session and navigation edges

Session expired or logged out in another tab while a form is open, an object deleted by
someone else while its form is open, two tabs editing one object, back button after a
destructive action, deep links for a role without access.

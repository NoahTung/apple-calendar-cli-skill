# Agent Routing And Calendar Expansion Design

## Summary

This project already provides a thin, reliable shell interface for Apple Calendar on macOS:

- `addcal`
- `listcal`
- `delcal`

The next iteration should preserve that small-surface CLI design while making the tool more useful for agents.

The main change is to add an agent-facing routing layer for event placement:

- users should still be able to explicitly choose a target calendar
- agents should be able to infer the likely calendar from event meaning
- if inference is weak or no matching calendar exists, the workflow should fall back safely

This iteration also formalizes first-run permission guidance discovered during Hermes validation, and it identifies the highest-value next commands beyond create/list/delete.

## Goals

1. Make event creation feel more natural for agents by supporting semantic routing such as personal vs work vs life.
2. Preserve explicit user control when a specific calendar is requested.
3. Keep the CLI thin and auditable instead of embedding heavy natural-language logic inside shell scripts.
4. Document first-run permissions clearly for Hermes and similar agent runtimes.
5. Define the next command expansion path in a way that supports scheduling workflows.

## Non-Goals

- Build a full natural-language scheduling engine inside the CLI.
- Replace Calendar.app concepts with a custom storage layer.
- Introduce a large configuration system in the first iteration.
- Add cross-platform calendar support.

## Current State

Today, `addcal` accepts a calendar name and writes directly to that Calendar.app calendar. The project already supports multiple calendars at the Apple Calendar level, but the agent has to decide which calendar name to use.

That works, but it leaves an agent-product gap:

- the agent may understand that "go to the gym" is personal
- the tool still expects the concrete calendar name
- the calendar names may differ across machines and languages

This means the useful abstraction for the next iteration is not "more calendar flags", but "agent-intent routing with a safe fallback to explicit calendar selection".

## User Experience Requirements

### Event creation priority order

When creating an event, calendar selection should follow this order:

1. If the user explicitly names a calendar, use that calendar.
2. Otherwise, let the agent infer a semantic bucket such as `personal`, `work`, or `life`.
3. Map that bucket to one of the user's real calendars if a confident match exists.
4. If the mapping is unclear, inspect the existing calendars and choose the closest match.
5. If no strong match exists, fall back to the default calendar.

### Agent behavior expectations

The skill should encourage the agent to reason like this:

- workouts, social plans, errands, meals, and family items usually route to personal
- coding, meetings, deadlines, focused work, and client tasks usually route to work
- household, routines, admin, and general day-planning can route to life when that calendar exists

This logic belongs primarily in the skill and workflow guidance, not in a fragile shell heuristic engine.

### Explicit override

If the user says something equivalent to "add this to Personal" or "put this in Work", that explicit instruction should override the inferred category.

## Proposed Approach Options

### Option 1: Documentation-only routing

Teach the agent through `SKILL.md` to inspect calendars and infer the correct target, but do not change the CLI interface.

Pros:

- smallest code change
- preserves the current tiny CLI

Cons:

- routing remains informal
- behavior can vary more across agents
- no stable interface for a future mapping layer

### Option 2: Recommended approach: thin routing-aware interface

Keep `--calendar` as the explicit control, and add a small agent-facing abstraction such as a semantic bucket or auto-routing hint.

Examples:

- `addcal --calendar "Work" ...`
- `addcal --bucket work ...`
- `addcal --intent auto ...`

The CLI remains thin, while the skill defines when to use explicit calendar names versus semantic buckets.

Pros:

- preserves explicit user control
- makes agent behavior more stable
- creates a clean bridge between semantic intent and real calendars

Cons:

- requires a small new interface surface
- needs a simple mapping policy

### Option 3: High-level natural-language command

Add a new command that accepts a natural-language event description and does categorization internally.

Pros:

- highly agent-native

Cons:

- pushes too much intelligence into shell scripts
- increases complexity sharply
- weakens the project's positioning as a thin CLI layer

## Chosen Design

Choose Option 2.

The project should add a thin routing-aware interface while keeping the intelligence primarily in the agent skill.

## Detailed Design

### 1. First-run permissions documentation

Add a short `First-run permissions` section to `README.md` and `SKILL.md`.

This section should explain that:

- macOS may ask for Calendar automation permission
- Hermes or similar agent runtimes may ask for permission to access Python, the script directory, or the current workspace folder
- those prompts are expected during first-run setup
- successful authorization should allow event creation to proceed normally

The tone should reduce anxiety and frame these prompts as expected setup rather than tool failure.

### 2. Semantic routing model

Introduce a small semantic layer for event creation.

Conceptually:

- real destination remains a Calendar.app calendar
- agent-level category is a routing hint
- explicit calendar names remain authoritative

Initial semantic buckets:

- `personal`
- `work`
- `life`

These are agent-facing concepts, not a replacement for Apple Calendar calendars.

### 3. Mapping behavior

The first iteration should support a simple mapping model:

- explicit `--calendar` wins
- semantic bucket maps to a matching real calendar when possible
- if needed, the agent should inspect available calendars first

Initial matching heuristics can remain simple and mostly live at the skill layer:

- `personal` prefers `个人` or `Personal`
- `work` prefers `工作` or `Work`
- `life` prefers `生活` or `Life`

The implementation should avoid pretending that every machine has these exact calendars. The workflow must acknowledge that many users will have custom names.

### 4. Where intelligence lives

Keep the boundary clear:

- `SKILL.md` should own semantic routing guidance, decision order, and fallback behavior
- CLI scripts should own concrete event operations and explicit arguments

This keeps the repo aligned with its current value proposition: small, local, shell-first tools for agents.

### 5. Next command expansion

Prioritize the next commands in this order:

1. `updatecal`
2. `getcal`
3. `freebusycal`
4. `movecal`

#### `updatecal`

Purpose:

- modify title
- modify start/end time
- optionally change target calendar

Why first:

- highest practical value after create/list/delete
- avoids delete-and-recreate workflows
- supports agent correction loops cleanly

#### `getcal`

Purpose:

- retrieve one event by id
- provide structured detail before updating or moving

Why second:

- complements `updatecal`
- gives agents a precise inspection step instead of relying only on broader list output

#### `freebusycal`

Purpose:

- answer whether a time range is occupied
- support scheduling and assistant planning workflows

Why third:

- very valuable for agent scheduling
- can build on the existing event query logic

#### `movecal`

Purpose:

- move an event from one calendar to another

Why fourth:

- useful for reclassification
- lower priority because some of its value is covered by future update behavior

## CLI Design Principles For The Next Iteration

- Keep command names obvious and narrow.
- Prefer explicit flags over magic positional behavior when adding new capabilities.
- Preserve id-based workflows for safe automation.
- Avoid forcing agents to parse locale-heavy human output when TSV or similarly structured output is possible.
- Do not add hidden persistence or background services.

## Risks

### Risk: too much intelligence in shell scripts

If semantic routing moves too far into Bash or AppleScript, the project will become harder to maintain and less predictable.

Mitigation:

- keep semantics mostly in `SKILL.md`
- keep CLI additions small and explicit

### Risk: false confidence in calendar matching

Users may not have calendars named `个人`, `工作`, `生活`, `Personal`, `Work`, or `Life`.

Mitigation:

- treat matching as a hint, not a guarantee
- preserve inspection and fallback steps

### Risk: documentation says "automatic" but behavior feels inconsistent

If the skill promises perfect inference, user trust will drop quickly.

Mitigation:

- document the priority order clearly
- describe semantic routing as a best-effort agent behavior with explicit override

## Implementation Outline

The next implementation phase should be split into:

1. Documentation updates for permissions and agent routing expectations.
2. `SKILL.md` updates for semantic routing rules and fallback order.
3. CLI interface changes for a thin routing-aware creation flow.
4. Follow-up command expansion starting with `updatecal`.

## Acceptance Criteria

- README explains first-run permissions for Hermes-like agents.
- `SKILL.md` tells agents how to route events by meaning before falling back to explicit calendar names.
- The design preserves explicit calendar override.
- The planned next command order is documented and justified.
- The project remains positioned as a thin agent-first CLI layer instead of a large automation framework.


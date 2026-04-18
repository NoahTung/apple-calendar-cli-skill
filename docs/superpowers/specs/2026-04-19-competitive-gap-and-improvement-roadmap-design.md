# Competitive Gap And Improvement Roadmap Design

## Summary

This project already has a stronger functional core than the newly discovered competitor:

- full local CRUD through separate commands
- machine-readable outputs for agent workflows
- batch import support
- ticket-to-calendar normalization through `img2cal`

However, the competitor highlights several areas where this repo still has product and integration gaps:

- simpler and more uniform event input
- clearer recurrence and all-day support
- stronger write-safety messaging
- better discoverability, packaging, and trust signals

The next iteration should not copy the competitor mechanically. Instead, it should absorb the parts that improve usability and integration while reinforcing the project's stronger position as an agent-safe Apple Calendar toolkit.

There is also a distribution asymmetry that should shape prioritization:

- the competitor appears aligned with the OpenClaw ecosystem
- this project is already being developed with Hermes usage in mind

That means the roadmap should not only ask "what features are missing?" It should also ask "which ecosystem should this repo win first?"

## Goals

1. Learn from competitor strengths without collapsing this repo's multi-command architecture.
2. Improve the skill so it is easier to discover, install, trust, and integrate.
3. Add the highest-value missing capabilities that reduce friction for agents and users.
4. Strengthen safety defaults for real Calendar.app writes.
5. Preserve and extend the repo's unique advantages in CRUD, batch workflows, and ticket normalization.
6. Establish an early distribution advantage in the Hermes skill ecosystem before the category becomes crowded.

## Non-Goals

- Replace the current multi-command design with a single monolithic script.
- Turn the CLI into an open-ended natural-language scheduler.
- Default to persistent event logs that may create unnecessary privacy risk.
- Chase feature parity for low-value packaging choices that do not improve correctness, safety, or agent usability.
- Split focus evenly across all agent ecosystems in the near term when one ecosystem-specific beachhead could create stronger early adoption.

## Current State

Today, the repo already covers more of the real Apple Calendar lifecycle than the competitor:

- `addcal` creates events with calendar routing hints, notes, location, URL, alarms, and simplified recurrence
- `listcal` lists events in `table`, `tsv`, or `json`
- `showcal` inspects a single event by id
- `editcal` updates existing events
- `delcal` deletes events, preferably by id
- `batchcal` imports planned JSON event sets with dry-run support
- `img2cal` converts structured ticket data into event drafts or created events

The core value proposition is already clear from the codebase:

`agent -> local CLI -> Calendar.app -> iCloud`

The main weakness is not functional depth. It is packaging and consistency:

- some useful behaviors are documented but not positioned as first-class product capabilities
- some interfaces are friendlier for humans than for agents, but not yet uniformly structured
- safety expectations exist in the skill guidance, but not all of them are enforced or highlighted at the command level

The current repo is also better aligned with Hermes than its public packaging suggests:

- the docs already discuss Hermes in first-run permission guidance
- the install location and workflow assumptions are local-agent friendly
- the project can be adapted into a Hermes-first skill more easily than many more generic calendar tools

## Competitor-Informed Gaps

The competitor suggests four real gaps worth addressing.

### 1. Uniform structured input

The competitor makes structured event creation feel simpler by leaning harder on a single structured input path.

This repo currently supports rich flags and JSON plans through `batchcal`, but the create and edit flows are still primarily argument-based.

Gap:

- there is no single, consistent JSON stdin interface across write operations
- sensitive values passed as command arguments may be visible to process inspection tools

### 2. Stronger event modeling

The competitor presents recurrence and all-day events as normal capabilities rather than edge cases.

This repo already supports a simplified repeat DSL such as `weekly 1,3,5`, but it does not yet clearly expose:

- full recurrence rule input
- all-day event creation and inspection as a first-class workflow

### 3. Write-safety visibility

This repo already cares about safe workflows, especially through `listcal` before mutation and id-based edits/deletes.

But the competitor surfaces write-safety more explicitly in the product story:

- writable vs read-only calendar distinction
- local-only execution framing
- logging and operational behavior clarity

Gap:

- writeability checks are not yet a visibly documented and enforced part of every mutation path
- privacy boundaries and logging policy are not yet expressed as clearly as they could be

### 4. Productization and discoverability

The competitor benefits from stronger marketplace packaging:

- clearer landing-page positioning
- more obvious install path
- stronger trust cues around local execution and permissions

Gap:

- this repo's README undersells its actual advantage
- install, versioning, release, and external metadata are not yet organized for easier distribution

### 5. Hermes-first distribution strategy

Hermes changes the strategic picture because its skill system is both local-first and highly visible.

Based on the Hermes docs:

- the Skills Hub aggregates hundreds of skills across registries
- installed skills live in `~/.hermes/skills/`
- installed skills become directly invokable slash commands
- the Apple category is still comparatively sparse

This creates a realistic wedge:

- shipping early into Hermes can make this project the default Apple Calendar skill for Hermes users
- the same work can later be adapted outward to other ecosystems if needed

Gap:

- this repo is not yet packaged and described as a Hermes-first public skill
- there is no explicit Hermes distribution checklist in the roadmap

## Design Options

### Option 1: Competitor parity first

Prioritize matching the competitor's visible feature set and packaging before improving the repo's unique strengths.

Pros:

- easy to explain
- fast external comparison

Cons:

- risks overfitting to the competitor
- delays investment in stronger differentiators already present here

### Option 2: Existing strengths first

Ignore most competitor-inspired work and focus on polishing current CRUD, batch, and ticket workflows.

Pros:

- protects the repo's unique direction
- avoids distraction

Cons:

- misses obvious usability gaps
- leaves distribution and trust deficits unresolved

### Option 3: Recommended approach: capability-layer roadmap

Use the competitor as an input, not a template. Organize improvements by capability layer:

- input and event modeling
- safety and correctness
- productization and discoverability
- differentiated agent workflows
- Hermes-first ecosystem distribution

Pros:

- absorbs the best competitor ideas without giving up architecture
- keeps cross-command consistency work together
- creates a clean bridge from design to implementation planning
- allows distribution work to follow a clear beachhead strategy instead of generic marketplace sprawl

Cons:

- requires more deliberate sequencing
- demands both product and engineering discipline

## Chosen Design

Choose Option 3.

The roadmap should be organized around capability layers instead of individual commands or direct competitor checklists.

Within that roadmap, Hermes should be treated as the primary early ecosystem target.

## Detailed Design

### 1. Input And Event Modeling Layer

This layer should reduce friction for agents and make write commands more uniform.

#### 1.1 Add JSON stdin support for direct mutations

Introduce a consistent structured input mode for at least:

- `addcal`
- `editcal`
- possibly `delcal` when deletion is driven by exact-match criteria rather than id

This should not replace the current flag-based CLI. It should add a parallel structured path.

Design principles:

- flags remain supported for shell convenience
- JSON stdin becomes the preferred path for agents
- field names should mirror existing output column names and command flags as closely as possible
- commands should reject ambiguous input when both JSON and conflicting flags are provided

Expected benefit:

- less argument parsing friction
- less risk of leaking long notes or URLs through process listings
- easier interop with agent-generated structured data

#### 1.2 Add first-class all-day support

Support all-day event creation, inspection, and editing as an explicit capability.

This should include:

- an input flag such as `--all-day`
- a corresponding JSON field
- clear behavior for whether `end` is required or inferred
- a stable representation in `listcal` and `showcal`

The design should prefer explicit semantics over hidden heuristics.

#### 1.3 Support native recurrence rules

Keep the friendly repeat interface, but add a lower-level escape hatch.

Recommended model:

- retain `--repeat "<friendly DSL>"`
- add `--rrule "<RFC-style recurrence string or Apple-compatible recurrence expression>"`

Priority rules must be explicit:

- `--rrule` overrides `--repeat`
- invalid recurrence input must fail fast with a clear error

This preserves beginner-friendly input while removing an unnecessary ceiling for advanced agent workflows.

### 2. Safety And Correctness Layer

This layer should make real-calendar mutations safer by default.

#### 2.1 Make writable calendar checks explicit

Before any mutation, the command path should verify that the target calendar exists and is writable.

Expected behavior:

- fail with a clear error when the chosen calendar is read-only
- surface writeability status in calendar listing output when feasible
- document this behavior in README and SKILL guidance

This is especially important for agents operating across mixed local, subscribed, or delegated calendars.

#### 2.2 Promote conflict detection to a stronger default

The project already encourages `listcal` before writing. The next step is to make conflict awareness feel built-in rather than optional guidance.

Possible behavior:

- `addcal` performs conflict checks by default when the resolved calendar is known
- users can bypass with an explicit override such as `--force` or `--no-check-conflict`
- conflict output should be machine-readable when requested

The design should still avoid blocking legitimate overlapping events when the user intentionally wants them.

#### 2.3 Clarify privacy and logging policy

The repo should document:

- whether commands log anything by default
- where any logs or temp files are stored
- whether event details appear in command-line arguments or shell history
- which permissions macOS may request on first run

Default policy recommendation:

- do not enable persistent event logging by default
- keep any future logging opt-in and minimal

### 3. Productization And Discoverability Layer

This layer should close the gap between real capability and external perception.

#### 3.1 Rewrite positioning in README

The README should lead with a sharper statement of value:

- this is not merely an event creator
- this is a local, agent-safe toolkit for real Apple Calendar data

The opening message should emphasize:

- full CRUD
- batch import
- machine-readable outputs
- ticket normalization
- iCloud-backed real-calendar writes through Calendar.app

#### 3.2 Improve installation and trust guidance

The docs should make first-run success more predictable.

This includes:

- clearer install commands
- permission guidance
- examples for both user shells and agent runtimes
- version or release guidance so users know what capability set they have

#### 3.3 Prepare external skill/distribution metadata

If the project is meant to compete in public skill ecosystems, it should package itself accordingly.

This may include:

- richer skill metadata
- marketplace-facing descriptions
- installation snippets tailored to agent environments
- release notes that highlight compatibility and new capabilities

This work is product-facing but still directly supports adoption.

### 4. Differentiated Agent Workflow Layer

This layer doubles down on what the repo already does better than the competitor.

#### 4.1 Strengthen id-first mutation workflows

The docs and command outputs should make the safe workflow obvious:

1. list events in machine-readable format
2. capture the exact event id
3. show or edit by id
4. delete by id when removal is needed

This is already mostly present, but it should be elevated from "good practice" to "core operating model."

#### 4.2 Expand `batchcal` toward idempotent planning

`batchcal` should move closer to a safe plan executor for agent-produced schedules.

Future improvements may include:

- duplicate detection
- dry-run diff summaries
- deterministic normalization before apply
- plan fingerprints or matching hints

The point is not to make it huge. The point is to make bulk calendar writes easier to trust.

#### 4.3 Deepen `img2cal` as a draft-confirm-apply workflow

`img2cal` is already a meaningful differentiator.

The next iteration should standardize its workflow:

1. normalize structured ticket fields
2. draft the event
3. check conflicts in the destination time range
4. apply only after confirmation

This is a strong agent-native workflow and should remain a headline feature.

### 5. Hermes-First Ecosystem Layer

This layer turns distribution strategy into concrete product work.

#### 5.1 Position the project explicitly for Hermes

The README, skill docs, and marketplace-facing copy should say clearly that this project is a strong fit for Hermes users who want to control real Apple Calendar data on macOS.

This should include:

- Hermes-specific install guidance
- Hermes-specific permission notes
- examples written in a Hermes-friendly command style when appropriate
- wording that matches how Hermes users think about skills and slash-invokable capabilities

This does not require excluding other agents. It requires leading with the audience most likely to adopt it first.

#### 5.2 Package the repo for Hermes skill expectations

The project should document and validate the expected Hermes installation shape, including:

- placement under `~/.hermes/skills/` when installed as a local skill
- any required executable paths
- how Hermes should discover or invoke the commands
- compatibility notes for local versus globally installed binaries

The goal is that a Hermes user can install and use the skill with minimal adaptation.

#### 5.3 Design for Hermes Hub discoverability

The public-facing description should be optimized for how Hermes users scan the Skills Hub.

This includes:

- a concise title and description that immediately mention Apple Calendar, macOS, and local CLI control
- category alignment with Apple and productivity-oriented workflows
- examples that show why this is safer and more capable than ad-hoc AppleScript snippets

#### 5.4 Defer broader ecosystem expansion until the Hermes wedge is secured

OpenClaw and other ecosystems are still relevant, but they should not dominate the near-term roadmap.

Priority rule:

- first become the obvious Hermes choice for Apple Calendar on macOS
- then reuse that packaging and maturity to expand outward

This sequencing reduces product diffusion and increases the chance of early category ownership.

## Phased Roadmap

### Phase 1: Hermes-first positioning, trust, and installability

Focus:

- Hermes-first packaging and messaging
- README repositioning
- permission and privacy guidance
- install and release clarity
- external metadata preparation

Success criteria:

- a Hermes user can immediately understand that this skill is built for their workflow
- a new user can understand why this repo is different within the first screen of the README
- a new user can install and verify the tools with minimal ambiguity
- trust boundaries are documented clearly

### Phase 2: Structured input and event-model parity upgrades

Focus:

- JSON stdin for direct mutations
- all-day events
- native recurrence rule support
- cross-command field consistency

Success criteria:

- agents can create and edit events through a consistent structured interface
- all-day and advanced recurrence are first-class documented capabilities

### Phase 3: Safer mutation defaults

Focus:

- writable calendar checks
- stronger default conflict checks
- clearer mutation error semantics

Success criteria:

- unsafe or invalid writes fail clearly
- overlapping events are surfaced before mutation unless explicitly overridden

### Phase 4: Differentiated workflow expansion

Focus:

- `batchcal` idempotence improvements
- stronger id-first workflows in docs and outputs
- richer `img2cal` draft-to-apply lifecycle
- outward ecosystem expansion only after Hermes packaging is solid

Success criteria:

- the repo is clearly better than lightweight competitors for multi-step agent workflows
- bulk and ticket-driven scheduling flows are easier to trust than direct one-shot creation
- the project has a defensible Hermes beachhead before broader marketplace expansion

## Testing Strategy

This roadmap implies both command-level and workflow-level testing.

The implementation plan should include:

- parser tests for new flags and JSON stdin behavior
- recurrence and all-day normalization tests
- read-only calendar and invalid-calendar behavior tests
- conflict-check behavior tests
- documentation verification for examples and command syntax
- regression tests for existing short-form command usage

Where direct Calendar.app state is expensive to validate, the plan should prefer isolating parse, validation, routing, and command assembly behavior in shell-testable units.

## Risks And Trade-Offs

### Risk: interface sprawl

Adding JSON stdin, all-day support, and RRULE input can make the CLI harder to reason about if each command evolves independently.

Mitigation:

- define a shared field model first
- keep precedence rules explicit
- centralize common parsing and validation behavior where practical

### Risk: overcorrecting toward the competitor

The repo could accidentally lose its own product identity by chasing parity too literally.

Mitigation:

- use competitor-inspired features only when they improve agent workflows or trust
- preserve multi-command structure and differentiated workflows

### Risk: hidden privacy regressions

Structured inputs and future diagnostics can create new data exposure paths.

Mitigation:

- prefer stdin for rich data
- keep logs opt-in
- document what is stored and what is not

## Implementation Readiness

This design is ready to convert into an implementation plan.

The plan should be organized around the four capability layers above rather than around individual scripts alone, because:

- JSON stdin and shared field semantics will affect multiple commands
- safety and error behavior must remain consistent across write paths
- productization work spans README, skill docs, install flow, and metadata
- differentiated workflows depend on shared mutation and inspection patterns

It should also include Hermes-specific packaging tasks early, because distribution and capability are intertwined for this project.

## Recommended Next Step

Write an implementation plan that breaks this roadmap into small, testable tasks across:

1. Hermes-first docs and productization
2. shared parsing/model changes
3. write-safety enforcement
4. differentiated workflow enhancements

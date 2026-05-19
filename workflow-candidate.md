# Workflow Candidate: BDD-Guided Agentic Migration Workflow

## Summary

This workflow describes a behavior-driven, human-gated agent workflow for large refactors, rewrites, migrations, or paradigm shifts. The central idea is to use Behavior Driven Development (BDD) specifications as explicit, human-readable acceptance criteria before implementation begins.

The workflow is designed for situations where a repository needs to be migrated into a new language, framework, architecture, or programming paradigm while preserving important behavior and keeping humans in control of acceptance decisions.

In short:

> Use repository understanding, planning, BDD specifications, executable tests, agent implementation, review loops, and human approval gates to make large migrations auditable and trustworthy.

## Starting Point

The workflow should start with a human-authored, structured, high-level specification before agents begin planning or writing BDD scenarios.

This specification should be stored as a durable artifact, for example:

```text
workflow/human-spec.md
```

or:

```text
workflow/project-brief.md
```

The purpose is to prevent agents from inferring product intent, user expectations, technology constraints, or acceptance criteria from incomplete context.

The human specification should include at least:

- goal of the migration, refactor, or rewrite,
- user personas / actors involved,
- behavioral requirements,
- behavior to preserve, change, or remove,
- non-functional requirements such as speed, complexity, reliability, maintainability, reproducibility, security, and privacy,
- target tech stack and constraints,
- required testing stack, for example `pytest`, `pytest-bdd`, `pytest-cov`, JAX, PyTorch, TensorFlow, or other relevant tools,
- acceptance expectations,
- explicit out-of-scope items,
- open questions.

A project skill such as `spec-intake` or `human-spec-validator` should validate this artifact against a template before the workflow continues.

The validator should return either:

```text
SPEC READY
```

or:

```text
SPEC NOT READY
Missing:
- <required missing item>

Ambiguous:
- <unclear requirement>

Questions:
1. <clarifying question>
```

The validator should not silently improve or invent the specification. It should identify missing information and ask clarifying questions. Planning should not begin until this specification is ready or the human explicitly accepts the remaining gaps.

This is gate zero of the workflow:

```text
human spec -> spec-intake validation -> human clarification/approval -> repository scouting and planning
```

## Core Assumption

The human stakeholder is the ultimate judge of acceptance.

The human does not necessarily need to understand every line of code, but does need enough understanding of:

- the problem domain,
- expected behavior,
- major architectural decisions,
- risks and tradeoffs,
- test evidence,
- and agent decisions

in order to approve or reject each step.

BDD helps because it expresses expected behavior in a form that is understandable to both humans and agents.

## High-Level Workflow

### 1. Repository scouting and context building

Starting point: a repository that should be refactored, rewritten, or migrated.

Use a repository overview step first, for example with `repo-overview`, to produce shared context for both humans and agents.

This should include:

- repository structure,
- module descriptions,
- entry points,
- current tests and fixtures,
- important classes/functions,
- architecture diagrams,
- tech stack,
- known constraints,
- risks and open questions.

The goal is that the human stakeholder and future agents share the same starting context.

A `context-builder`-style step can then turn this into a durable project context artifact used by later agents.

### 2. Planning and decomposition

A planner agent splits the migration/refactor into:

- modules,
- submodules,
- dependencies between modules,
- suggested implementation sequence,
- components that can be worked on in parallel,
- components that must remain sequential,
- known risks,
- open questions.

The plan should be reviewed and approved by a human before implementation begins.

The purpose of this gate is not only correctness, but also stakeholder understanding.

### 3. Behavior specification

For each module or feature, a specification agent writes BDD-style specifications.

These should capture externally important behavior, for example:

```gherkin
Feature: Dataset loading

Scenario: Load a valid dataset
  Given a dataset exists in the expected storage format
  When the loader reads the dataset
  Then it returns samples with the expected graph structure
  And each sample contains the required labels
```

BDD specifications should include:

- normal behavior,
- edge cases,
- error behavior,
- invariants,
- important side effects,
- compatibility requirements,
- expected inputs and outputs.

The specs should be human-readable and precise enough to become acceptance criteria.

### 4. Human approval of module specifications

Before executable tests or implementation are written, the human stakeholder reviews the module-level BDD specifications.

The human can:

- approve the specification,
- request clarification,
- add missing scenarios,
- reject incorrect behavior,
- mark behavior as intentionally changed from the legacy system.

This approval gate is important because the BDD specs become the contract that agents will implement against.

### 5. Test implementation

A tester agent converts the approved BDD specifications into executable tests.

Depending on the technology stack, this could use tools such as:

- `pytest-bdd`,
- `behave`,
- Cucumber,
- Jest/Cucumber integrations,
- custom test harnesses,
- ordinary unit/integration tests generated from BDD scenarios.

The test implementation should preserve the intent of the approved specification.

A reviewer agent should verify that the tests faithfully encode the specs and are not too weak or overfitted.

At this stage, the tests may fail because the migrated implementation does not exist yet. That is expected.

### 6. Development dispatch

Once a module has:

- approved BDD specs,
- executable tests,
- architectural constraints,
- known dependencies,
- and clear acceptance criteria,

it can be dispatched to a developer agent.

If modules are sufficiently independent, multiple developer agents can work in parallel.

Each developer agent receives only the relevant module context plus links to the global architecture/specification context.

### 7. Agent implementation and review loop

The developer agent implements the module until the relevant tests pass.

A reviewer agent then checks:

- whether the acceptance criteria are met,
- whether the architecture plan was followed,
- whether tests pass,
- whether code quality is acceptable,
- whether there is hidden scope creep,
- whether decisions were logged,
- whether new risks or open questions appeared.

If review fails, the reviewer sends actionable feedback to the developer agent.

This loops until the reviewer says the module is ready for human review.

### 8. Human approval and merge

After agent review passes, the human stakeholder receives a concise summary containing:

- what was implemented,
- what behavior was accepted,
- which tests pass,
- what changed from the original system,
- known risks,
- important decisions,
- links to issues and pull requests.

The human then approves, rejects, or requests changes.

The human remains the final judge of acceptance and merge readiness.

### 9. Integration-level BDD specifications

After enough modules are implemented, higher-level integration BDD specifications should be written.

These describe system-level behavior across modules.

Example:

```gherkin
Feature: End-to-end migration parity

Scenario: Train a model from a generated dataset
  Given a valid generated dataset exists
  And a valid training configuration is provided
  When the training pipeline runs for one epoch
  Then the model checkpoint is written
  And validation metrics are reported
  And no schema compatibility errors occur
```

These integration specs become final acceptance tests for the migrated system.

The same loop applies:

1. write integration BDD specs,
2. human approves them,
3. tester implements executable integration tests,
4. developer agent fixes implementation,
5. reviewer checks acceptance,
6. human approves final result.

## Recommended Additional Step: Characterization Tests

Before rewriting or migrating a legacy system, add characterization tests.

BDD specs describe intended behavior. Characterization tests capture actual current behavior.

Both are important.

Characterization tests help identify:

- undocumented edge cases,
- current API behavior,
- serialization formats,
- numerical tolerances,
- error behavior,
- legacy quirks that may or may not need to be preserved.

The workflow should explicitly mark each discovered behavior as one of:

- preserve,
- intentionally change,
- remove,
- unresolved / needs human decision.

## Behavioral vs Architectural Acceptance Criteria

BDD works well for externally observable behavior, but not all important constraints are behavioral.

Each module should have two kinds of acceptance criteria.

### Behavioral acceptance criteria

Examples:

- Given invalid input, validation fails.
- Given a valid dataset, the loader returns expected graph tensors.
- Given a missing config key, an error message identifies the missing key.

### Architectural acceptance criteria

Examples:

- This module must not import the legacy package.
- Public API names must remain stable.
- Data serialization format must remain compatible.
- Unit tests must not require network access.
- The implementation must avoid global mutable state.
- Runtime complexity must not regress beyond an agreed threshold.

Both kinds of criteria should be reviewed by agents and humans.

## Suggested Agent Roles

The workflow benefits from separating roles:

### Scout / context builder

Inspects the repository and creates the initial context artifact.

### Planner

Splits work into modules, submodules, dependencies, and sequence.

### Spec writer

Writes human-readable BDD scenarios and module behavior contracts.

### Test implementer

Turns approved specs into executable tests.

### Developer

Implements code against the tests and architecture constraints.

### Reviewer

Checks acceptance criteria, tests, code quality, architecture compliance, and decision logs.

### Human stakeholder

Approves plans, specs, important decisions, and final merge readiness.

## Auditability Requirements

Each workflow step should produce a short durable summary.

The summary should include:

- step name,
- agent or human responsible,
- input artifacts,
- output artifacts,
- tools used,
- agents used,
- skills used,
- files changed,
- tests run,
- decisions made,
- short rationale for each decision,
- risks discovered,
- unresolved questions,
- links to issues or pull requests.

This enables:

- debugging failed agent work,
- handoff between agents,
- human review,
- later audits,
- recovery after context compaction,
- reproducibility of decisions.

## GitHub Issue Integration

The workflow should tie into a GitHub repository.

Suggested structure:

```text
Epic: Migration / refactor project

  Meta issue: Data layer migration
    Issue: Data layer behavior specs
    Issue: Data layer characterization tests
    Issue: Data layer executable tests
    Issue: Data layer implementation
    Issue: Data layer review

  Meta issue: Model layer migration
    Issue: Model behavior specs
    Issue: Model tests
    Issue: Model implementation
    Issue: Model review

  Meta issue: Integration parity
    Issue: End-to-end BDD specs
    Issue: End-to-end integration tests
    Issue: Final migration review
```

Each issue should contain or link to:

- approved specs,
- acceptance criteria,
- architecture constraints,
- agent summaries,
- decision logs,
- test evidence,
- linked pull requests,
- human approval status.

This makes GitHub the durable coordination layer for humans and agents.

## Strengths of the Concept

This workflow is especially strong for:

- large refactors,
- language migrations,
- framework migrations,
- architecture rewrites,
- scientific or ML code modernization,
- legacy system preservation,
- public API compatibility work,
- multi-agent development,
- projects requiring auditability.

Key benefits:

- humans approve behavior before implementation,
- agents receive clear acceptance criteria,
- tests become executable contracts,
- parallel work becomes safer,
- architectural decisions are explicit,
- review has objective criteria,
- GitHub issues provide durable state,
- final acceptance remains human-controlled.

## Main Risks

### Vague BDD specifications

BDD specs can become too shallow if written poorly.

Bad example:

```gherkin
Scenario: The system works correctly
  Given valid input
  When the system runs
  Then the result is correct
```

Good specs should be concrete:

```gherkin
Scenario: Invalid config field is rejected
  Given a config file with an unknown field "foo"
  When the config loader validates the file
  Then validation fails
  And the error message includes "foo"
  And no output files are created
```

### Tests that do not faithfully encode specs

The test implementer might write tests that are too weak, too broad, or not aligned with the approved BDD scenarios.

A reviewer should explicitly compare tests against specs.

### Over-parallelization

Parallel module work is only safe when interfaces and dependencies are stable.

The planner should mark modules as:

- independent,
- dependent,
- blocked,
- integration-sensitive.

### Missing architectural constraints

BDD alone is not enough for architecture. Architectural acceptance criteria must be tracked separately.

### Human approval fatigue

Too many approval gates can overwhelm stakeholders.

The workflow should batch reviews where appropriate while preserving gates for important behavioral or architectural decisions.

## Proposed Per-Module Issue Template

```markdown
# Module: <name>

## Goal

Short description of what this module should do.

## Current implementation

Relevant files, classes, functions, and behavior in the existing system.

## Target implementation

Expected target language, architecture, or paradigm.

## Behavioral specifications

Approved BDD scenarios.

## Architectural constraints

Non-behavioral requirements and design constraints.

## Characterization findings

Legacy behaviors discovered and whether they should be preserved or changed.

## Executable tests

Links to test files and commands.

## Implementation summary

What was changed.

## Decisions

- Decision:
  - Rationale:
  - Approved by:

## Risks and open questions

Known concerns.

## Agent/tool audit log

- Agent:
- Tools used:
- Skills used:
- Files read:
- Files changed:
- Tests run:

## Review status

- Spec approved: yes/no
- Tests approved: yes/no
- Implementation reviewed: yes/no
- Human accepted: yes/no
```

## Overall Assessment

The concept is sound.

BDD makes sense in agent workflows when it is used as a human-readable acceptance contract rather than merely as a test style.

The strongest version of this workflow is:

1. build repository context,
2. create characterization tests,
3. plan module decomposition,
4. write BDD specs,
5. get human approval,
6. implement executable tests,
7. dispatch dev agents,
8. run reviewer/dev loops,
9. get human approval and merge,
10. finish with integration-level BDD acceptance tests.

This should provide a practical and auditable structure for agent-assisted refactoring and migration work.

## Possible Workflow Implementation

In `pi-subagents`, this workflow should probably not be implemented as one large chain. The full process contains feedback loops, human approval gates, and state transitions, so it is better understood as a parent-orchestrated state machine.

Recommended division of responsibility:

```text
chains = repeatable phase templates
parent orchestrator = loop controller and decision maker
human = approval gate and final acceptance authority
GitHub issues = durable workflow state
```

### Use chains for straight-line phases

Saved `.chain.md` workflows are useful for repeatable linear phases such as:

- repository context building,
- migration planning,
- module-level BDD specification writing,
- executable test implementation,
- integration-level BDD specification writing,
- GitHub issue breakdown or issue update preparation.

Possible project chains:

```text
.pi/chains/bdd-context-plan.chain.md
.pi/chains/bdd-spec-module.chain.md
.pi/chains/bdd-tests-module.chain.md
.pi/chains/bdd-integration-spec.chain.md
.pi/chains/github-issue-breakdown.chain.md
```

Example phases:

```text
context-builder -> planner
context-builder -> BDD spec writer
worker -> reviewer for test implementation
context-builder -> integration spec writer
```

Each chain should write durable artifacts such as:

```text
context/repo-context.md
plans/migration-plan.md
specs/module-bdd-spec.md
handoffs/test-implementation.md
reviews/test-review.md
```

Use `{task}`, `{previous}`, and `{chain_dir}` to pass information between chain steps. Use `outputMode: file-only` for large artifacts so the parent receives compact file references rather than full reports.

### Keep feedback loops in the parent session

The implementation and review loop should not be encoded as a static saved chain. The parent orchestrator should control it explicitly.

Typical loop:

```text
worker implements approved module
-> parallel fresh-context reviewers inspect the diff
-> parent synthesizes reviewer findings
-> if blockers or fixes worth doing now exist:
       worker applies accepted fixes
       repeat review, up to max round count
   else:
       ask human for acceptance
```

This matches the normal `pi-subagents` review-loop pattern: one writer, several review-only agents, parent synthesis, then one fix worker.

The loop should stop when:

- reviewers find no blockers or fixes worth doing now,
- remaining feedback is optional or intentionally deferred,
- an unapproved product, scope, or architecture decision appears,
- the configured maximum review round count is reached,
- or the human decides to stop.

Default maximum review rounds: 3.

### Human gates should be explicit stop points

The workflow should pause for human approval after major artifacts are produced.

Suggested gates:

```text
repository context + migration plan written -> human approves plan
module BDD specs written -> human approves specs
executable tests written -> human approves tests when needed
module implementation reviewed -> human accepts or requests changes
integration BDD specs/tests written -> human approves final acceptance criteria
final integration review complete -> human approves merge/release
```

Chains can produce the artifacts for these gates, but they should not silently proceed past them unless the human has already authorized that mode.

### Suggested project agents

Initially, the builtin agents may be enough:

- `context-builder`,
- `planner`,
- `worker`,
- `reviewer`,
- `oracle`,
- `scout`.

As the workflow matures, project-specific agents could be added under `.pi/agents/`:

```text
bdd-spec-writer.md
bdd-test-writer.md
acceptance-reviewer.md
architecture-reviewer.md
issue-manager.md
```

These agents should have narrow roles. Child agents should not orchestrate subagents themselves; the parent session owns the workflow.

### Suggested parent orchestration pattern

For each approved module:

```text
1. run module context/spec chain
2. ask human to approve BDD specs
3. run test implementation chain
4. ask human to approve or acknowledge tests
5. dispatch worker to implement against approved tests/specs
6. run parallel reviewers for:
   - BDD acceptance criteria,
   - test quality and validation,
   - architecture constraints and maintainability
7. synthesize reviewer findings
8. dispatch one fix worker if needed
9. repeat review/fix loop if warranted
10. ask human for module acceptance
11. update GitHub issue state and decision log
```

Parallel development across modules should only happen when dependencies are clear and the modules are sufficiently independent. If multiple writer agents are used, isolate them with git worktrees.

### GitHub issue integration

GitHub issues should act as durable state for the workflow. A meta issue can represent the migration, with child issues for modules and phases.

Each issue should track:

- approved BDD specs,
- characterization findings,
- architecture constraints,
- executable tests,
- implementation status,
- reviewer findings,
- human approval status,
- decision log,
- linked pull requests.

An `issue-manager` agent or chain could prepare issue bodies and updates, but the parent or human should remain responsible for final state transitions.

### When chains are not enough

If the workflow needs fully automated state tracking, dynamic loops, max-round enforcement, issue transitions, and approval checkpoint handling, saved chains alone are not enough.

Possible next implementation levels:

1. project chains plus parent-agent instructions,
2. a project skill that teaches the parent this workflow,
3. prompt templates wrapping common phases,
4. a custom Pi extension implementing the workflow as a real state machine.

Recommended starting point: use project chains plus a project skill. Build a custom extension only after the workflow has stabilized through manual use.

### Human gates without a custom extension

A custom Pi extension is not required for deterministic human gates. The initial implementation can rely on skills, chains, agents, artifacts, and parent-session discipline.

The role separation is:

```text
agents = role identity, purpose, default context, and tool permissions
skills = task-specific expertise and operating procedure
chains = linear workflow fragments
parent session = orchestration, branching, human gates, and loop control
human = final approval authority
```

The most important structural rule is:

> Do not put steps after a human gate in the same chain.

Each chain should stop exactly where human approval is required.

Recommended chain boundaries:

```text
bdd-context-plan.chain.md
  -> produces repository context and migration plan
  -> STOP for human approval

bdd-spec-module.chain.md
  -> produces module BDD specs
  -> STOP for human approval

bdd-tests-module.chain.md
  -> produces executable tests or test plan
  -> STOP for human approval when needed

worker implementation + review loop
  -> produces reviewed implementation
  -> STOP for human acceptance and merge
```

This is safer than one long chain because there is no automated path across the approval boundary.

#### Artifact-based approvals

Each gated phase should produce a durable artifact, for example:

```text
workflow/context/repo-context.md
workflow/plans/migration-plan.md
workflow/specs/module-x.bdd.md
workflow/tests/module-x-test-plan.md
workflow/decisions/module-x-decisions.md
```

The human approval should reference the artifact explicitly, for example:

```text
APPROVED: workflow/specs/module-x.bdd.md
scope: module-x
version/hash: <optional git hash or file hash>
```

The next phase should only start after the parent session has received this explicit approval.

A stronger version is to use approval marker files such as:

```text
workflow/approvals/plan-approved.md
workflow/approvals/module-x-spec-approved.md
workflow/approvals/module-x-tests-approved.md
```

However, these are only useful as deterministic gates if agents cannot create or modify them. Ideally, approval files are created manually by the human, committed by the human, or represented as GitHub labels/comments controlled by humans.

#### Preventing agents from overstepping

Planning, specification, and review agents should be read-only whenever possible.

For example, their agent definitions can omit write/edit tools:

```yaml
tools: read, grep, find, ls
```

Avoid giving these agents `write`, `edit`, or unrestricted `bash` unless necessary. If they need to produce reports, prefer chain-level `output:` files so the subagent wrapper saves their response rather than the child agent modifying the repository directly.

Example:

```md
## planner
output: workflow/plans/migration-plan.md
outputMode: file-only

Create a migration plan. Do not edit repository files.
```

The implementation worker should only run after approval. Its prompt should include the approved artifacts as hard preconditions:

```text
Implement module-x only.

Approved inputs:
- Spec: workflow/specs/module-x.bdd.md
- Approval: workflow/approvals/module-x-spec-approved.md
- Tests: workflow/tests/module-x/

Do not modify behavior outside the approved module.
If implementation requires unapproved scope, stop and report the decision needed.
```

Reviewer agents can check whether artifacts and implementations satisfy approval criteria, but they should not own approval authority.

Reviewer output should answer questions such as:

```text
Spec matches approved plan: yes/no
Tests match approved spec: yes/no
Implementation matches acceptance criteria: yes/no
Architecture constraints respected: yes/no
Unapproved scope detected: yes/no
```

The reviewer can recommend acceptance, but only the human approves the gate.

#### Minimal deterministic gate setup

The minimal setup is:

1. use read-only planner/spec/review agents,
2. split chains at every human approval point,
3. write durable artifacts for every phase,
4. require explicit human approval messages or human-created approval files,
5. give workers only approved artifacts,
6. require workers to stop on unapproved scope or architecture decisions,
7. use reviewers as compliance checkers, not approval owners,
8. have the parent session refuse to continue without approval.

The deterministic boundary is structural:

> A chain must never contain both “produce artifact” and “act on approved artifact” if human approval is required between them.


Think of the different elements of the workflow as this:

   agent  = function with a role/personality + tool permissions
   skill  = reusable procedure/library/helper instructions
   chain  = function composition / pipeline
   parent = caller / control flow / state machine
   human  = external authority / oracle

 That analogy is useful because it clarifies the boundary:

 - Don’t abstract too early.
 - Don’t build generators before the pattern stabilizes.
 - Make small reusable pieces first.
 - Compose them manually until repetition becomes obvious.
 - Only automate when the “function signature” is clear.

 So for now, the right move is probably:

   define the few agents
   define the few skills
   define the chains
   try one module manually
   then adjust

 The workflow artifacts are your “API surface.” Once those stabilize, automation becomes much
 easier.
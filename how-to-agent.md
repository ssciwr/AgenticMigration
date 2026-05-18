# Building Reusable Agentic Workflows in Pi

This guide summarizes how to turn a repeated multi-stage agent workflow into reusable Pi assets: chains, agents, and skills.

## Useful documentation

- Pi README: `/home/hmack/.nvm/versions/node/v22.10.0/lib/node_modules/@earendil-works/pi-coding-agent/README.md`
- Skills docs: `/home/hmack/.nvm/versions/node/v22.10.0/lib/node_modules/@earendil-works/pi-coding-agent/docs/skills.md`
- Custom models docs: `/home/hmack/.nvm/versions/node/v22.10.0/lib/node_modules/@earendil-works/pi-coding-agent/docs/models.md`
- Subagents skill docs: `/home/hmack/.nvm/versions/node/v22.10.0/lib/node_modules/pi-subagents/skills/pi-subagents/SKILL.md`
- Agent Skills specification: https://agentskills.io/specification
- Pi website: https://pi.dev

## The core concepts

### 1. Chain: the workflow

Use a **chain** when you want to define the sequence of stages in an n-stage process.

A chain answers:

- What happens first, second, third, etc.?
- Which stages run sequentially?
- Which stages run in parallel?
- What output from one stage is passed to the next?
- Which stages should write artifacts?
- Which stages are review-only?

Typical reusable chain locations:

```text
.pi/chains/my-workflow.chain.md              # project-local
~/.pi/agent/chains/my-workflow.chain.md      # global/user-level
```

Run a saved chain with:

```text
/run-chain my-workflow -- your task here
```

### 2. Agent: the role

Use an **agent** when you need a reusable role with stable behavior.

Examples:

- `domain-scout`
- `migration-planner`
- `security-reviewer`
- `test-author`
- `release-hardening-worker`

Agent locations:

```text
.pi/agents/agent-name.md              # project-local
~/.pi/agent/agents/agent-name.md      # global/user-level
```

You often do **not** need custom agents at first. Pi-subagents already provides built-in roles such as:

- `scout`
- `planner`
- `worker`
- `reviewer`
- `researcher`
- `context-builder`
- `oracle`

Start with built-ins and only create custom agents when a role needs persistent specialized behavior.

### 3. Skill: the method or expertise package

Use a **skill** when you need reusable specialized instructions, procedures, references, or helper scripts.

A skill answers:

- How should this kind of work be performed?
- What checklist or methodology should the agent follow?
- What domain references should it load?
- What scripts or tools support this task?

Examples:

- `threat-modeling`
- `red-green-refactor`
- `api-compatibility-review`
- `performance-benchmarking`
- `docs-style-guide`

Skill locations:

```text
.pi/skills/my-skill/SKILL.md              # project-local
~/.pi/agent/skills/my-skill/SKILL.md      # global/user-level
```

You do **not** need one skill per agent. A chain defines the order, agents define roles, and skills define specialized techniques.

## Recommended design process

### Step 1: Describe the workflow in plain language

Write the workflow as stages before creating any files.

Example:

```text
1. Gather local code context.
2. Research external API behavior.
3. Produce an implementation plan.
4. Ask for user approval.
5. Implement the approved plan.
6. Run focused validation.
7. Run three parallel reviews.
8. Apply accepted review fixes.
9. Summarize final result.
```

For each stage, specify:

- Input
- Output
- Agent role
- Whether it can edit files
- Whether it needs user approval
- Validation expectations
- Whether it runs in fresh or forked context

### Step 2: Decide what should be a chain

If the workflow has multiple repeatable stages, make it a chain.

Use chain variables:

- `{task}` — the original task passed to the chain
- `{previous}` — output from the previous stage
- `{chain_dir}` — shared temporary directory for chain artifacts

Example conceptual chain shape:

```text
scout -> planner -> worker -> parallel reviewers -> worker fixes
```

### Step 3: Reuse built-in agents first

Start with the built-in subagent roles:

```text
scout            fast codebase reconnaissance
planner          implementation planning
worker           implementation
reviewer         code/diff review
researcher       external/web research
context-builder  structured handoff context
oracle           advisory review with forked conversation context
```

Only create custom agents if a built-in role plus a good prompt is not specific enough.

### Step 4: Add skills only for reusable methods

Create a skill when you have a repeatable methodology that multiple agents or workflows should share.

Good skill candidates:

- a regulatory review checklist
- a domain-specific architecture rubric
- a testing discipline
- a release checklist
- a benchmark procedure
- an API migration playbook

Not good skill candidates:

- one step in a chain
- a one-off prompt
- a role name with no reusable method behind it

### Step 5: Decide context strategy

Use **fresh context** when you want independent review or reduced bias.

Good for:

- adversarial reviewers
- independent architecture critique
- sanity checks

Use **forked context** when the subagent should inherit the conversation history.

Good for:

- `oracle` advisory review
- implementation handoff after detailed clarification
- continuing a prior reasoning thread

### Step 6: Keep writing single-threaded by default

A safe default pattern is:

```text
one writer + many advisors
```

That means:

- one `worker` edits files
- multiple `reviewer`, `scout`, or `researcher` agents can advise
- the parent session synthesizes decisions
- a final `worker` applies accepted fixes

Use parallel writing only when tasks are independent. If parallel agents may edit, use git worktree isolation.

### Step 7: Add approval gates for important decisions

For workflows with product, architecture, migration, or destructive changes, add an approval stage before implementation.

Example:

```text
scout -> planner -> user approval -> worker -> review -> worker fixes
```

The chain can produce the plan, then stop for human approval before a separate implementation run.

### Step 8: Save artifacts deliberately

For longer workflows, have stages write artifacts under `{chain_dir}` or named output files.

Useful artifacts:

```text
context.md
research.md
plan.md
review-correctness.md
review-tests.md
review-maintainability.md
final-summary.md
```

This keeps large handoffs out of the chat transcript and makes the workflow auditable.

## Example reusable workflow blueprint

```text
Name: feature-hardening

Stage 1: scout
- Goal: map relevant files, tests, and constraints for `{task}`.
- Output: context summary.
- Edits: no.

Stage 2: planner
- Goal: produce implementation plan from scout output.
- Input: `{previous}`.
- Output: plan with risks and validation.
- Edits: no.

Stage 3: worker
- Goal: implement the approved plan.
- Input: `{previous}`.
- Output: changed files and validation summary.
- Edits: yes.

Stage 4: parallel reviewers
- Reviewer A: correctness and regressions.
- Reviewer B: tests and validation.
- Reviewer C: simplicity and maintainability.
- Edits: no.
- Context: fresh.

Stage 5: worker
- Goal: apply only accepted review fixes.
- Input: synthesized review findings.
- Edits: yes.

Stage 6: final validation
- Goal: run focused tests/checks and summarize final state.
```

## Example project structure

```text
.pi/
├── chains/
│   └── feature-hardening.chain.md
├── agents/
│   ├── security-reviewer.md
│   └── migration-planner.md
└── skills/
    ├── threat-modeling/
    │   └── SKILL.md
    └── api-compatibility-review/
        └── SKILL.md
```

## Practical rule of thumb

Use this decision table:

| Need | Use |
|---|---|
| Repeatable sequence of stages | Chain |
| Repeatable role/persona | Agent |
| Repeatable method/checklist/expertise | Skill |
| One-off instruction | Prompt text in the chain stage |
| External model/server choice | `~/.pi/agent/models.json` |
| Project conventions | `AGENTS.md` or `.pi/settings.json` |

## Minimal path to start

1. Write the workflow stages in plain English.
2. Implement it as a saved chain using built-in agents.
3. Run it on one real task.
4. Note where prompts are vague or repeated.
5. Extract repeated role behavior into custom agents.
6. Extract repeated methodology into skills.
7. Add approval gates and artifact outputs where needed.
8. Iterate until the workflow is boring and reliable.

## Security and review notes

- Review any third-party Pi package or skill before installing it.
- Skills can instruct agents to run code, so treat them as executable trust boundaries.
- Prefer one writer thread unless you intentionally use isolated worktrees.
- Keep destructive operations behind explicit approval gates.
- Use fresh-context reviewers for independent critique.

## Next step

To create your own reusable workflow, define:

1. Workflow name
2. Ordered stages
3. Agent for each stage
4. Whether each stage can edit
5. Parallel stages, if any
6. Approval gates
7. Output artifacts
8. Required skills or custom agents
9. Validation commands
10. Whether the chain is project-local or global

Once those are clear, create the chain under `.pi/chains/` or `~/.pi/agent/chains/` and run it with `/run-chain`.



## For complex workflows
 Recommended design for complex recurrent workflows:

clarify
   → define validation contract
   → worker
   → parallel fresh reviewers/validators
   → parent synthesis
   → fix worker if needed
   → repeat review/fix up to N rounds
   → final parent validation

 For your own workflow, I’d probably define:

 - several custom role agents in .pi/agents/
 - one or more reusable one-pass chains in .pi/chains/
 - a prompt template that describes the recurrent orchestration logic and stop conditions.
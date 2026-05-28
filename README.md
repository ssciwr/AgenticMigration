# Agentic Migration Workflow

An agentic workflow for migrating legacy scientific codebases — Fortran, C++, legacy Python — to modern target languages and stacks.

This repository does not define a fully autonomous AI 'magic wand' that lets you turn arbitrary legacy code into a fully fledged modern implementation in one go. Rather, it's a structured workflow designed for a human supervisor/designer and an AI agent as an executive function that encourages collaboration between the two parties and to support human engagement.

## Overview
This workflow is split into three phases: discovery, behavior characterization and implementation, each built on top of the **explore → plan → code → commit** agentic coding workflow. We try to use the original code as an oracle and implement validation (are we building the right product?) of the migrated code into the workflow by requiring human verification at each important handoff- and decision point. Software verification (are we building the product right?) we try to enforce by using behavior driven development which defines the observed behavior of the software to be built first, translates it into a set of automatically runable tests and uses this behavioral surface as acceptance criteria for the written code.
Decisions are documented as files in an /artifacts and /implementation-reports directory, depending on the step in the workflow we are in.

# Spec driven development
Spec-driven development is the main basis of this workflow.
This design makes the specifications the central part of the whole workflow. Making sure they are specific and correct with respect to the goal is central to the success of the workflow. The workflow forces you to decide on dependencies, architecture requirements and user base early. Specs are then written in the Gherkin format as executable specifications, which can be turned into executable tests, e.g., with pytest-bdd if you are working with python as target language.

Specs are not a fire-and-forget weapon to ensure correctness, they are a set of living documents that evolve with the code. It might turn out that you need to tighten some specs while you run the implementation part or that later the goal widens to include a different user class. It's worthhwile to take time and review specifications, migration plan and supplied requirements thoroughly, and iterate with the agent until a clear mental model of the product emerges. Because these specs are the central source of truth for the entire workflow, it is vulnerable to insufficiently defined or misspecified specs.

It is necessary to stay in the loop and make sure that your the written specifications and behavioral tests represent your requirements and that important parts are not underspecified. You can use the 'oracle' subagent of pi-subagents to critically review your specs and try to 'think outside the box' and find loopholes or issues with specificity or emphasis.

# Architecture
The workflow is built on a 'plan top-down, migrate bottom-up' approach, in which the migration plan consists of a tree of tasks and subtasks which the agent works on in a breadth first manner. This can require iteration across two levels to fix possible misalignment if the specs are not tight enough to fixate behavior, dependencies or interfaces.

![Workflow diagram](workflow.png)

The diagram is also available as an editable [workflow.drawio](workflow.drawio) file.

---

## Requirements

- [Pi coding agent](https://pi.dev/)
- [pi-subagents](https://github.com/nicobailon/pi-subagents) plugin
- An LLM provider configured in Pi (cloud or local).

---
## Installation
Copy `agents/`, `prompts/`, and `skills/` into any directory that your agent reads from (`~/.pi/agent/` for Pi, `~/.claude/` for Claude Code, etc.).

---

## Workflow elements

### Agents

Agents define role identity, tool permissions, and scope constraints. This defines 'who' the agent is. It's identity, not procedural memory as such. Procedural information about how to do something lives in 'Skills'.

| Agent | Phase | Role |
|-------|-------|------|
| `characterization-tester` | Discovery | Characterizes legacy behavior; writes golden-file and assertion tests into the repo |
| `bdd-spec-writer` | BDD | Writes Gherkin-style BDD specifications from plan module entries |

The builtin pi-subagents agents (`scout`, `worker`, `reviewer`, `oracle`, `planner`) are used directly throughout where appropriate.

### Prompts

Prompts are top-level entrypoints that wire agents and skills together for a specific task. Call them from an agent session to kick off a phase.

| Prompt | Phase | What it does |
|--------|-------|--------------|
| `prompts/migration-workflow.md` | All | Full three-phase entrypoint: discovery → BDD → implementation. Delegates to the phase prompts below. |
| `prompts/discovery.md` | Discovery | Characterizes the source repository, gathers requirements, and produces a reviewed migration plan. Delegates to `characterization-tester`, `scout`, `requirements-intake`, `migration-planner`, and `oracle`. |
| `prompts/bdd-loop.md` | BDD | Breadth-first spec and test writing loop over the approved plan. Delegates to `bdd-spec-writer`  via the `bdd-review-loop` skill. |
| `prompts/implementation-loop.md` | Implementation | Bottom-up implementation loop over approved BDD specs and tests. Delegates to `worker` and `reviewer` via the `implementation-loop` skill. |

### Skills

Skills are reusable methodologies — imperative instructions about *how* to do a class of work, independent of which agent applies them. Expertise lives here.

| Skill | Phase | What it encodes |
|-------|-------|-----------------|
| `characterization-methodology` | Discovery | How to observe and record legacy behavior without modifying it; golden-file pattern; environment documentation; report structure |
| `repo-overview` | Discovery | How to generate an HTML structural overview of an unfamiliar codebase |
| `requirements-intake` | Discovery | How to elicit and validate migration requirements; uses characterization report and overview as evidence before asking the human anything |
| `migration-planner` | Discovery | How to decompose a migration into a dependency tree of modules with interface contracts defined top-down and implementation ordered bottom-up |
| `bdd-writing-quality` | BDD | What good BDD specs and tests look like; scenario coverage checklist; traceability rules |
| `bdd-review-loop` | BDD | Breadth-first traversal of the plan tree for spec and test writing; per-level human gates; why siblings are reviewed as a group |
| `implementation-loop` | Implementation | Bottom-up traversal of the plan tree; worker→tests→reviewer iteration per module; per-level human gates; implementation report protocol |

Some of these skills are useful outside of code migration (repo overview for example), others are more tightly tied to the workflow we have here.

### References

Example files in `skills/*/references/` show concrete patterns: golden-file tests in Python, Rust, and Julia; example BDD feature files; example plan module entries (meta-issue and leaf issue).

---

## Human gates

The workflow has gates at every major transition. The human's role is to be the domain authority, not a rubber stamp:

1. **After requirements intake** — approve scope, architecture, behavioral decisions, constraints
2. **After migration planning + oracle review** — approve the module plan and resolve oracle's concerns before any specification begins
3. **After each BDD level** (per level, top-down) — approve sibling specs as a group; incompatibilities between siblings are caught here
4. **After each implementation level** (per level, bottom-up) — review implementation reports; resolve flagged decisions before ascending

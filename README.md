# Agentic Migration Workflow

An agentic workflow for migrating legacy scientific codebases — Fortran, C++, legacy Python — to modern target languages and stacks.

Scientific code presents a specific challenge: the correct behavior is often not documented, not tested, and not fully understood by the people doing the migration. Domain experts know what "correct" means numerically, but LLMs do not. This workflow addresses that by building on the standard **explore → plan → code → commit** loop with two additions: a **characterization phase** that captures observable behavior before anything is changed, and **behavior-driven development** as the contract layer between the legacy system and the new implementation. Human scientists gate each major stage because they are the authority on what correctness means.

See `workflow.drawio` or `workflow.svg` for the full workflow diagram.

---

## Requirements

- [Pi coding agent](https://pi.dev/)
- [pi-subagents](https://github.com/nicobailon/pi-subagents) plugin
- An LLM provider configured in Pi (cloud or local)

---
## Installation
You can install the workflow locally or globally. For global installation, put the prompts, skills and agents directories in the `~/.pi/` directory. For local installation, put them in the `.pi/` directory of your project.

---
## Running the workflow

**Phase 1 — Discovery** (automated chain with human gates):
```
/run-chain discovery -- /path/to/legacy/repo
```

**Phase 2 — BDD specs and tests** (apply skill from parent session):
```
Apply the bdd-review-loop skill to the repository at /path/to/legacy/repo.
```

**Phase 3 — Implementation** (apply skill from parent session):
```
Apply the implementation-loop skill to the repository at /path/to/legacy/repo.
```

See `prompts/migration-workflow.md` for the full prompt including human gate descriptions.

---

## Workflow elements

### Agents

Agents define role identity, tool permissions, and scope constraints. They are narrow by design — expertise lives in skills.

| Agent | Phase | Role |
|-------|-------|------|
| `characterization-tester` | Discovery | Characterizes legacy behavior; writes golden-file and assertion tests into the repo |
| `bdd-spec-writer` | BDD | Writes Gherkin-style BDD specifications from plan module entries |
| `bdd-test-writer` | BDD | Converts approved BDD specs into executable tests |

The builtin pi-subagents agents (`scout`, `worker`, `reviewer`, `oracle`, `planner`) are used directly throughout.

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

### Chain

| Chain | Covers |
|-------|--------|
| `discovery.chain.md` | The full discovery phase: characterization → repo overview → requirements intake → migration planning → oracle review |

The BDD and implementation phases are invoked directly from the parent session (not as a chain) so the orchestrating agent retains the `subagent` tool and can delegate to `bdd-spec-writer`, `bdd-test-writer`, `worker`, and `reviewer` freely.

### References

Example files in `skills/*/references/` show concrete patterns: golden-file tests in Python, Rust, and Julia; example BDD feature files; example plan module entries (meta-issue and leaf issue).

---

## Human gates

The workflow has gates at every major transition. The human's role is to be the domain authority, not a rubber stamp:

1. **After requirements intake** — approve scope, architecture, behavioral decisions, constraints
2. **After migration planning + oracle review** — approve the module plan and resolve oracle's concerns before any specification begins
3. **After each BDD level** (per level, top-down) — approve sibling specs as a group; incompatibilities between siblings are caught here
4. **After each implementation level** (per level, bottom-up) — review implementation reports; resolve flagged decisions before ascending

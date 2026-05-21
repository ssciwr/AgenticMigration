---
name: discovery
description: >
  First stage of the migration workflow. Characterizes the legacy codebase,
  generates a repository overview, then gathers and validates human requirements.
  Produces characterization-report.md, scout/overview.html, and requirements.md.
  Run as: /run-chain discovery -- /path/to/legacy/repo
---

## characterization-tester
output: {chain_dir}/characterization-report.md
outputMode: file-only

Characterize the current observable behavior of the legacy codebase at: {task}

You are authorized to write characterization tests. Write golden-file or assertion-based
tests that capture the current observable behavior of the legacy system. Place them in
the existing test structure of the repository. These tests are the behavioral oracle:
they will be rerun against the new implementation to verify behavioral equivalence.

Produce a complete characterization report covering all observable entry points,
data formats, numerical tolerances, error behavior, and decision candidates.
Write the report to the output path.

## scout
skills: repo-overview
output: {chain_dir}/overview-summary.md
outputMode: file-only

Generate a repository overview for the codebase at: {task}

Follow the repo-overview skill workflow exactly. Write the HTML overview to
scout/overview.html inside the target repository. Then write a compact summary
of key findings (modules, entry points, tech stack, dominant paradigms) to the
output path for the next step.

## worker
reads: {chain_dir}/characterization-report.md, scout/overview.html
skills: requirements-intake
progress: true

Apply the requirements-intake skill.

Your inputs are:
- Characterization report: {chain_dir}/characterization-report.md (pre-read)
- Repository overview HTML: scout/overview.html (pre-read)
- Overview summary: {previous}

Read and internalize all three before asking the human anything. Only ask about
items those artifacts do not already answer. When asking, cite the specific
finding that prompted the question.

Use contact_supervisor with reason "need_decision" to ask the human clarifying
questions, grouped by checklist category. Wait for each reply before continuing.

When all checklist items are covered and the human confirms the requirements are
complete, write requirements.md to the current working directory.


## planner
reads: requirements.md, scout/overview.html, {chain_dir}/characterization-report.md
skills: migration-planner
progress: true

Apply the migration-planner skill to produce a structured migration plan.

Your inputs are:
- Requirements: requirements.md (pre-read) — approved migration goal, architectural
  requirements, behavioral requirements, and constraints.
- Repository overview: scout/overview.html (pre-read) — legacy codebase structure,
  entry points, tech stack, and open questions.
- Characterization report: {chain_dir}/characterization-report.md (pre-read) —
  observed legacy behavior, decision candidates, and behavior inventory.

Read all three before planning anything.

Produce the migration plan as a set of markdown files under plan/ in the current
working directory. Structure the plan as described in the migration-planner skill:
interface contracts defined top-down, implementation order bottom-up, each module
entry self-contained enough for the BDD-review-loop to work from independently.

Flag unresolved decisions or ambiguities as open questions in the affected module
entry. Do not decide them yourself.

## oracle
reads: requirements.md, {chain_dir}/characterization-report.md, scout/overview.html
progress: false

Review the migration plan that was just produced. Read the plan files under plan/
and the characterization tests written into the repository before forming any opinion.

Look for:
- modules that appear to be missing or whose scope is unclear or overlapping,
- interface contracts that are underdefined or likely to cause integration problems,
- implementation ordering with hidden dependencies the plan has not made explicit,
- characterization findings or requirements that the plan has not addressed,
- characterization tests that cover behaviors not reflected in any module plan entry,
- alternative decompositions worth raising with the human.

Return a concise review document. Flag concerns with enough specificity that the
human can act on them. Do not modify the plan files or the characterization tests.
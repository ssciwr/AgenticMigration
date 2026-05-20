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

You are running in report-only mode. Do not write tests or modify the repository.

Characterize the current observable behavior of the legacy codebase at: {task}

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
reads: {chain_dir}/requirements.md, scout/overview.html, {chain_dir}/characterization-report.md
skills: migration-planning
progress: true

Apply the migration-planning skill to create a migration plan.

Your inputs are:
TODO

what to do goes here: TODO

how to end goes here: TODO
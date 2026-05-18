# Using Pi for a Semi-Automated Machine Learning Experiment Loop

Pi is advertised as a coding agent, but its underlying infrastructure is general enough to coordinate structured experimentation workflows. A machine learning experiment loop is a good example: it combines code edits, config changes, shell commands, logs, metrics, decision gates, and summaries.

The goal does **not** have to be full autonomy. A safer and more practical target is **human-supervised automation**: Pi prepares, runs, evaluates, and summarizes, while explicit gates keep expensive or risky decisions under user control.

## Example workflow

```text
1. Set up experiment
2. Run training
3. Evaluate results
4. Check whether results are suitable for an Optuna sweep
5. If enough useful parameter evidence exists, run Optuna sweep
6. Summarize outcome and next recommendations
```

## Why Pi can do this

Pi can coordinate this loop because it can:

- read and edit repository files
- inspect experiment configs
- run shell commands
- launch training/evaluation scripts
- parse logs and metrics
- write reports
- delegate stages to subagents
- preserve reusable workflows as chains
- use skills for domain-specific methods
- ask for approval before expensive steps

So while the surface use case is “coding,” the primitives are closer to a programmable agentic workbench.

## Suggested Pi structure

A reusable project-local setup could look like this:

```text
.pi/
├── chains/
│   └── ml-experiment-loop.chain.md
├── agents/
│   ├── experiment-planner.md
│   ├── training-worker.md
│   ├── evaluator.md
│   ├── sweep-gate.md
│   └── optuna-worker.md
└── skills/
    ├── ml-experiment-design/
    │   └── SKILL.md
    ├── metric-analysis/
    │   └── SKILL.md
    └── optuna-sweep/
        └── SKILL.md
```

You do not need all of these at first. A good first version can be just a chain using built-in agents such as `scout`, `planner`, `worker`, `reviewer`, and `context-builder`.

## Stage-by-stage design

### Stage 1: Set up experiment

Role: `experiment-planner` or built-in `planner`

Responsibilities:

- inspect the repository’s experiment structure
- find config files, training entrypoints, evaluation scripts, and output directories
- identify the baseline configuration
- propose a concrete experiment setup
- document assumptions and expected metrics

Human gate recommended: **yes**

Before training starts, the user should confirm:

- objective
- dataset/sample
- budget
- parameter changes
- success criteria
- output location

### Stage 2: Run training

Role: `training-worker` or built-in `worker`

Responsibilities:

- apply the approved config changes
- run the training command
- capture logs
- record artifact paths
- avoid overwriting previous runs unless explicitly allowed

Human gate recommended: optional, depending on cost

For long-running jobs, Pi can start a job and later inspect logs/results rather than trying to keep everything inside a single chat turn.

### Stage 3: Evaluate

Role: `evaluator` or built-in `worker` / `context-builder`

Responsibilities:

- run evaluation scripts
- extract metrics
- compare against the baseline
- identify regressions
- write an evaluation summary

Useful outputs:

```text
metrics.json
comparison.md
evaluation-summary.md
```

### Stage 4: Optuna readiness gate

Role: `sweep-gate` or built-in `planner`

Responsibilities:

- decide whether the current evidence justifies an Optuna sweep
- check whether enough meaningful parameters have been identified
- verify that the objective metric is clear
- verify that the search space is bounded
- verify that training/evaluation are reproducible enough
- estimate compute cost

Human gate recommended: **yes**

Example gate rule:

```text
Run Optuna only if:
- the evaluation pipeline is working,
- the objective metric is unambiguous,
- there are at least N plausible parameters to tune,
- parameter ranges are justified,
- the expected compute budget is acceptable,
- the user approves the sweep.
```

If the gate fails, Pi should summarize why the sweep is premature and recommend the next smaller experiment.

### Stage 5: Run Optuna sweep

Role: `optuna-worker` or built-in `worker`

Responsibilities:

- create or update Optuna config/search space
- run the sweep command
- monitor failures
- collect best trial parameters
- preserve logs, database files, and artifacts

Human gate recommended: **yes**, especially for expensive sweeps

### Stage 6: Summarize outcome

Role: `summarizer`, `context-builder`, or built-in `planner`

Responsibilities:

- report best parameters
- report best metrics
- compare against baseline
- list failed trials or instability
- identify overfitting or suspicious results
- recommend next action
- point to all relevant artifacts

Suggested final summary format:

```markdown
# Experiment Summary

## Objective

## Setup

## Training Runs

## Evaluation Metrics

## Optuna Readiness Decision

## Sweep Results

## Best Parameters

## Risks / Caveats

## Recommended Next Step

## Artifact Paths
```

## A safe semi-automated loop

A practical first version should keep the user in control:

```text
Pi scouts repo
→ Pi proposes experiment
→ user approves
→ Pi runs training
→ Pi evaluates
→ Pi proposes whether to sweep
→ user approves or rejects sweep
→ Pi runs sweep if approved
→ Pi summarizes results
```

This avoids pretending the system is autonomous while still removing a lot of repetitive coordination work.

## Where chains, agents, and skills fit

| Need | Pi asset |
|---|---|
| Repeat the whole experiment process | Chain |
| Stable role such as evaluator or sweep gate | Agent |
| Reusable methodology for experiment design or metric analysis | Skill |
| Repository-specific commands and conventions | `AGENTS.md` or chain prompts |
| Human approval before expensive work | Explicit chain boundary / user prompt |

## Why this suggests infrastructure convergence

The same infrastructure needed for coding agents is useful for ML experimentation:

- file editing becomes config management
- test execution becomes training/evaluation execution
- code review becomes result review
- planning becomes experiment design
- logs and diffs become metrics and artifacts
- subagents become specialized research, evaluation, and sweep roles
- chains become reproducible experiment protocols

So the distinction between “coding agent,” “research assistant,” “experiment runner,” and “workflow orchestrator” is becoming thinner. Pi’s extensibility makes that convergence visible: the same harness can support software development and structured scientific/ML iteration, as long as the workflow is designed with clear gates, artifacts, and validation.

## Recommended starting point

Start small:

1. Create a single project-local chain: `.pi/chains/ml-experiment-loop.chain.md`
2. Use built-in agents first.
3. Add explicit approval before training and before Optuna.
4. Save metrics and summaries to files.
5. After two or three real runs, extract repeated logic into custom agents or skills.

The first goal should be reliability and traceability, not autonomy.

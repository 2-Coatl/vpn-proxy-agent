# UC01 – Bootstrap Standard Install

## Overview
The bootstrap automation without manual intervention prepares a workstation or VM by validating requirements, selecting an installation profile, and orchestrating provisioning tasks defined in `bootstrap.sh`.

## Actors
- DevOps engineer triggering provisioning
- CI automation invoking non-interactive bootstrap
- Target Ubuntu host environment

## Preconditions
- Repository cloned with executable permissions on helper scripts
- Required environment variables (e.g., `BOOTSTRAP_AUTO`) configured for automation when needed
- Network connectivity to fetch packages and dependencies

## Postconditions
- Installation type resolved (quick, standard, or complete)
- System requirements validated and logged
- Provisioning workflows triggered or simulated (in dry-run mode)
- Log file stored under `logs/` with execution transcript

## High-Level Flow
1. Detect automation and dry-run flags.
2. Resolve installation type from CLI arguments or environment variables.
3. Validate system requirements using utilities in `utils/`.
4. Execute or simulate provisioning phases (environment prep, SSH, MCP, etc.).
5. Summarize results and emit log paths for operators.

## Low-Level Flow
- `bootstrap.sh` sources `env.sh`, `logging.sh`, `validation.sh`, and `common.sh` for reusable helpers.
- The script evaluates `BOOTSTRAP_AUTO`, `CI`, and terminal interactivity to decide on automation mode.
- `resolve_install_type` normalizes CLI and environment inputs before falling back to interactive selection.
- Requirement checks invoke `run_requirement_checks` which aggregates disk, RAM, command availability, and OS validation steps.
- Depending on dry-run toggles, `log_dry_run_action` mirrors the actions without mutating the host.

## UML Activity Diagram
```plantuml
@startuml
start
:Detect automation and dry-run flags;
if (Install type resolved?) then (Defaults)
  :Apply automation defaults;
else (Prompt)
  :Request install type from operator;
endif
:Run requirement validation;
if (Dry run enabled?) then (Yes)
  :Simulate provisioning actions;
else (No)
  :Execute provisioning scripts;
endif
:Summarize outcome and persist log;
stop
@enduml
```

## UML Sequence Diagram
```plantuml
@startuml
actor Operator
participant "bootstrap.sh" as Bootstrap
participant "validation helpers" as Validation
participant "Provisioners" as Provisioner

Operator -> Bootstrap: Invoke ./bootstrap.sh --standard
Bootstrap -> Bootstrap: auto_mode_enabled()
Bootstrap -> Bootstrap: resolve_install_type()
Bootstrap -> Validation: run_requirement_checks()
Validation --> Bootstrap: Results summary
Bootstrap -> Provisioner: dispatch_installation_plan()
Provisioner --> Bootstrap: Stage outcomes
Bootstrap --> Operator: Final report & log path
@enduml
```

## Related Artifacts
- `bootstrap.sh`
- `utils/logging.sh`
- `utils/validation.sh`

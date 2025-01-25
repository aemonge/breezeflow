# BreezeFlow - A Lighter AirFlow - Task Orchestration

`breezeflow` is a lightweight task orchestration tool designed for
efficient and safe execution of concurrent tasks. It is inspired by
Apache Airflow but is optimized for simplicity, performance, and
cross-platform compatibility.

## Features

-   **Performance**: Optimized for large-scale task orchestration.
-   **Safety**: Gleam's strong type system ensures reliability and
    prevents runtime\
    errors.
-   **Concurrency**: Efficient parallel execution with Gleam's
    concurrency model.
-   **Cross-platform**: Portable binaries for all major OSes.
-   **Extensibility**: Integration with Gleam's growing ecosystem.

## Usage

`breezeflow` orchestrates tasks with options for concurrent execution,
success/failure callbacks, and retries. Below is an overview of its
functionality.

### Options

-   `--during <command>`: Command to run concurrently with the main
    command.
-   `--on-succeed <command>`: Command to run if the main command
    succeeds.
-   `--on-fail <command>`: Command to run if the main command fails.
-   `--delay <seconds>`: (default: 1) Delay between retry attempts for
    during, on-succeed, and on-fail.
-   `--max-attempts <number>`: (default: 3) Maximum retry attempts for
    during, on-succeed, and on-fail.

### Examples

1.  Run a long command with a "during" command:

`{bash} breezeflow 'sleep 2' --during 'echo "Main command is running..."'`

2.  Simulate success with a callback:

`{bash} breezeflow 'sleep 2 && true' \    --during 'echo "Main command is running..."' \    --on-succeed 'echo "Success!"'`

3.  Simulate failure with retries:

`{bash} breezeflow 'sleep 2 && false' \    --during 'echo "Main command is running..."' \    --on-fail 'echo "Failure!"' \    --delay 2 --max-attempts 5`

### Notes

-   The tool returns the exit code of the main command for caller
    feedback.
-   Commands can be shell commands or exported functions.

## Why Gleam?

The choice of Gleam brings several advantages:

-   **Performance**: Gleam's lightweight runtime ensures efficient task
    execution.
-   **Safety**: Gleam's strong type system and immutability prevent
    runtime errors.
-   **Concurrency**: Gleam's actor-based concurrency model enables
    efficient parallelism.
-   **Cross-platform**: Gleam's portability simplifies deployment across
    OSes.
-   **Extensibility**: Integration with Gleam's ecosystem enhances
    functionality.

## Getting Started

To use `breezeflow`, clone the repository and build the project:

    git clone https://github.com/aemonge/breezeflow.git
    cd breezeflow
    gleam build

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for
guidelines.

## License

breezeflow is licensed under the MIT License. See [LICENSE](LICENSE) for
details.

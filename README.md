# BreezeFlow - A Lighter AirFlow - Task Orchestration

`breezeflow` is a lightweight task orchestration tool designed for efficient and safe
execution of concurrent tasks. It is inspired by Apache Airflow but is optimized for
simplicity, performance, and cross-platform compatibility.

## Features

- **Performance**: Optimized for large-scale task orchestration with minimal overhead.
- **Concurrency**: Efficient parallel execution concurrency model.
- **Retry Logic**: Configurable retries with customizable delays and maximum attempts.
- **Callbacks**: Execute success or failure callbacks based on task outcomes.
- **Verbose Logging**: Detailed output for debugging and monitoring.
- **Cross-Platform**: Works seamlessly across Linux, macOS, and Windows (via WSL).
- **Security**: Input sanitization and safe command execution to prevent injection
  attacks.

## Usage

`breezeflow` orchestrates tasks with options for concurrent execution, success/failure
callbacks, and retries. Below is an overview of its functionality.

### Options

- `-w, --while <command>`: Command to run concurrently with the main command.
- `-s, --succeed <command>`: Command to run if the main command succeeds.
- `-f, --fail <command>`: Command to run if the main command fails.
- `--delay <seconds>`: (default: 1) Delay between retry attempts for `--while`,
  `--succeed`, and `--fail`.
- `--max-attempts <number>`: (default: 3) Maximum retry attempts for `--while`,
  `--succeed`, and `--fail`.
- `-v, --verbose`: Enable verbose output for debugging.

### Examples

1. **Run a long command without a “while” command**:

```{bash}
breezeflow 'sleep 2'
```

2. **Run a command with a “while” command to monitor progress**:

```{bash}
breezeflow 'sleep 5' -w 'echo "Main command is running..."'
```

3. **Simulate success with a callback**:

```{bash}
breezeflow 'sleep 2 && true' -s 'echo "Success!"'
```

4. **Simulate failure with retries**:

```{bash}
breezeflow 'sleep 2 && false' -f 'echo "Failure!"' \
   --delay 2 --max-attempts 5
```

5. **Combine all options with verbose output**:

```{bash}
breezeflow 'sleep 5' -w 'echo "Monitoring..."' \
   -s 'echo "Done!"' -f 'echo "Failed!"' \
   --delay 1 --max-attempts 3 -v
```

### Notes

- The tool returns the exit code of the main command for caller feedback.
- Commands can be shell commands or exported functions.
- Use `-v, --verbose` to enable debug output for retries and progress.

<!-- ## Why Gleam? -->

<!-- The choice of Gleam brings several advantages: -->

<!-- - **Performance**: Gleam’s lightweight runtime ensures efficient task execution. -->
<!-- - **Safety**: Gleam’s strong type system and immutability prevent runtime errors. -->
<!-- - **Concurrency**: Gleam’s actor-based concurrency model enables efficient parallelism. -->
<!-- - **Cross-platform**: Gleam’s portability simplifies deployment across OSes. -->
<!-- - **Extensibility**: Integration with Gleam’s ecosystem enhances functionality. -->

## Contributing

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

## License

breezeflow is licensed under the MIT License. See [LICENSE](LICENSE) for details.

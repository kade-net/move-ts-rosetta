# Move Package Transpiler

## Overview
This CLI tool simplifies the process of transpiling a Move package from a source folder into a TypeScript library in a target folder. It also allows specifying a contract address for the Move package.

---

## Command: `run`

### Description
The `run` command transpiles a Move package from the specified source folder to a TypeScript library in the target folder.

### Syntax
```bash
move-ts-rosetta run -t <TargetFolder> -s <SourceFolder> -a <ContractAddress>
```

### Options
| Option               | Alias | Description                              | Required |
|----------------------|-------|------------------------------------------|----------|
| `--target <TargetFolder>` | `-t` | Path to the target folder where the transpiled TypeScript library will be saved. | Yes |
| `--source <SourceFolder>` | `-s` | Path to the source folder containing the Move package. | Yes |
| `--address <ContractAddress>` | `-a` | Contract address for the Move package. | Yes |

---

### Example Usage

1. **Basic Transpilation**
   ```bash
   move-ts-rosetta run -t lib -s contract -a 0x1
   ```

    - Transpiles the Move package from `contract` into the TypeScript library located in `lib`.
    - Specifies the contract address as `0x1`.

2. **Using Full Option Names**
   ```bash
   move-ts-rosetta run --target ./output-lib --source ./move-source --address 0x12345
   ```

    - Transpiles the Move package from `./move-source` to `./output-lib`.
    - Specifies the contract address as `0x12345`.

---

### Help Command
To view help information for the `run` command:
```bash
move-ts-rosetta run --help
```

**Output**:
```plaintext
Usage: move-ts-rosetta run [options]

Transpile a MOVE package from the source folder to a ts lib in the dest folder

Options:
  -t, --target <TargetFolder>    Target Folder
  -s, --source <SourceFolder>    Source folder
  -a, --address <ContractAddress> Contract address
  -h, --help                     Display help for command
```

---

### Notes
- Ensure the `TargetFolder` and `SourceFolder` paths are accessible and writable.
- The `ContractAddress` should be a valid address for your Move package.
- If any required option is missing, the tool will prompt you to provide it.

This tool is ideal for Move developers who need a quick and efficient way to integrate Move packages into TypeScript projects.
# setup-swiftly

GitHub Action to install and cache Swiftly for Swift toolchain management.

## Usage

```yaml
- uses: ./.github/actions/setup-swiftly
  with:
    swiftly-version: '1.0.1'  # Optional, defaults to 1.0.1

- name: Install Swift toolchain
  run: swiftly install
```

## Inputs

| Input | Description | Default |
|-------|-------------|---------|
| `swiftly-version` | Version of Swiftly to install | `1.0.1` |

## Caching

This action automatically caches Swiftly installations to speed up subsequent runs.
# Cached Build Runner

Cached Build Runner is a Dart package that optimizes the build_runner by caching generated code for unchanged .dart files. This package can be used as a dev_dependency and provides a cached version of the build_runner, which caches generated files instead of generating them every time.

## Usage

```bash
cached_build_runner <command> [arguments]
```

### Usage
Global options:
-h, --help    Print this usage information.

Available commands:
* **build**:  Performs a single build on the specified targets and then exits.
* **watch**:   Builds the specified targets, watching the file system for updates and rebuilding as appropriate.

Available arguments:
* -h, --help: Print out usage instructions.
* -v, --verbose: Enables verbose logs.
* -d, --debug: Enables even more verbose logs.
* -p, --[no]prune: Enable pruning cache directory when pubspec.lock was changed since last build. Defaults true.

* -c, --cache-directory: Provide the directory where this tool can keep the caches.

# Cached Build Runner
Add the package to your pubspec.yaml file under dev_dependencies:

```yaml
dev_dependencies:
  build_runner: ^latest_version
  cached_build_runner: ^latest_version
```
**Please note that you have to add `build_runner` as a mandatory dependency in your project for `cached_build_runner` to work properly.**

Replace latest_version with the latest available version of the package.


---
Original work done by @jyotirmoy-paul.
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
* -q, --quiet: Disables printing out logs during the build.
* -r, --redis: Use Redis database if installed on the system. Using Redis allows multiple instance access and is ideal for usage in pipelines. The default implementation uses a file system storage (Hive), which is ideal for usage in local systems.
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

# License

```
MIT License

Copyright (c) 2021 Jyotirmoy Paul

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```
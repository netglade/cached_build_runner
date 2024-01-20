## 0.1.0
- Upgrade to Dart 3
- Add prunning option - prune when pubspec.lock was changed
- Change how dependencies are determined - just by imported files
- Support other generated files, not just .g.dart

## 0.0.7

- Fix a major bug where a class's dependencies were not considered while generating digest, so any change in the super classes caused wrong output.
- Remove option to set projectDirectory, the current directory is always considered the projectDirectory.
- Minor error handling improvements.

## 0.0.6

- Minor bug fix, refactors build to check for .dart file before working on code generations in test directory. This will make sure any unnecessary files are ignored.

## 0.0.5

- Add support for watching code changes in project directory, and generate code files when needed.
- Make cached_build_runner similar to build_runner, now **build** & **watch** commands are available.
- Remove the -t, --generate-test-mock flag, as it was unnecessary.
- Update code to use native dart regex instead of relying on grep tool.

## 0.0.4

- Minor code changes were done, nothing functionality wise, but addition of better formatting & addition of dartdocs.

## 0.0.3

- Initial version.

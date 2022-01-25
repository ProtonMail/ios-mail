fastlane documentation
----

# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```sh
xcode-select --install
```

For _fastlane_ installation instructions, see [Installing _fastlane_](https://docs.fastlane.tools/#installing-fastlane)

# Available Actions

## iOS

### ios build

```sh
[bundle exec] fastlane ios build
```

Build the app and upload to testflight

### ios enterprise

```sh
[bundle exec] fastlane ios enterprise
```

Build enterprise app

### ios bump_major

```sh
[bundle exec] fastlane ios bump_major
```



### ios bump_minor

```sh
[bundle exec] fastlane ios bump_minor
```



### ios bump_patch

```sh
[bundle exec] fastlane ios bump_patch
```



### ios unit_test

```sh
[bundle exec] fastlane ios unit_test
```

Run unit test and get test coverage

### ios ui_test

```sh
[bundle exec] fastlane ios ui_test
```

Run ui test and get test coverage

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

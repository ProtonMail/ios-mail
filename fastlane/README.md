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

### ios decode_distribution_certificate

```sh
[bundle exec] fastlane ios decode_distribution_certificate
```



### ios build_release_app

```sh
[bundle exec] fastlane ios build_release_app
```

Build the release app

### ios tests

```sh
[bundle exec] fastlane ios tests
```

Run unit tests

### ios setup_uitests_assets

```sh
[bundle exec] fastlane ios setup_uitests_assets
```

Setup UI Tests assets

### ios uitests_smoke

```sh
[bundle exec] fastlane ios uitests_smoke
```

Run UI Smoke Tests

### ios uitests_full_regression

```sh
[bundle exec] fastlane ios uitests_full_regression
```

Run UI Full Regression Tests

### ios deploy

```sh
[bundle exec] fastlane ios deploy
```

Deploy to Test Flight

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.

More information about _fastlane_ can be found on [fastlane.tools](https://fastlane.tools).

The documentation of _fastlane_ can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew install fastlane`

# Available Actions
## iOS
### ios build
```
fastlane ios build
```
Build the app and upload to testflight
### ios enterprise
```
fastlane ios enterprise
```
Build enterprise app
### ios bump_major
```
fastlane ios bump_major
```

### ios bump_minor
```
fastlane ios bump_minor
```

### ios bump_patch
```
fastlane ios bump_patch
```

### ios unit_test
```
fastlane ios unit_test
```
Run unit test and get test coverage

----

This README.md is auto-generated and will be re-generated every time [_fastlane_](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).

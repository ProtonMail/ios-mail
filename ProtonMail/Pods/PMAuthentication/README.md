
# PMAuthentication

This framework is designated to perform API calls of authentication flow, for now they are:
- `authenticate(username:password:completion:)`
- `confirm2FA(_:context:completion:)`
- `refreshCredential(_:completion:)`

Pluggable settings should be passed to `Authenticator` as `Configuration`:
- `trust` - a Swift closure for integration with TrustKit
- `clientVersion` - "iOS_1.12.0"
- `scheme`, `host`, `apiPath` - "https", "protonmail.blue", "/api"

API endpoints participating:
* /auth/info
* /auth
* /auth/2fa

## Dependencies
- [PMCrypto](https://gitlab.protontech.ch/apple/shared/pmcrypto)

## Linter
We use SwiftLint to enforce consistent styling across codebase. 
Linter is installed as cocoapod. 
Configuration is in a  hidden file `.swiftlint.yml`.

## Unit tests
This project has number of unit tests, automatically run via Fastlane by GitLab CI.
Configuration of CI: hidden file `.gitlab-ci.yml`.
Configuration of fastlane: `/fastlane/Fastfile`.
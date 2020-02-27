
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
 😎 NO!

 ## Linter
 We use SwiftLint to enforce consistent styling across codebase.
 Install (command line): `brew install swiftlint`
 Configuration: hidden file `.swiftlint.yml`
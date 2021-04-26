# <img src="https://user-images.githubusercontent.com/19360256/34930442-5ed005d4-fa04-11e7-8aea-44179368fcde.png" alt="Logo" width="36" height="36"> SwiftOTP

[![Build Status](https://travis-ci.org/lachlanbell/SwiftOTP.svg?branch=master)](https://travis-ci.org/lachlanbell/SwiftOTP)
[![Version](https://img.shields.io/cocoapods/v/SwiftOTP.svg?style=flat)](http://cocoapods.org/pods/SwiftOTP)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/SwiftOTP.svg?style=flat)](http://cocoapods.org/pods/SwiftOTP)
[![Platform](https://img.shields.io/cocoapods/p/SwiftOTP.svg?style=flat)](http://cocoapods.org/pods/SwiftOTP)
![Swift Version](https://img.shields.io/badge/Swift-5.0-orange.svg)

SwiftOTP is a Swift library for generating One Time Passwords (OTP) commonly used for two factor authentication. SwiftOTP supports both HMAC-Based One Time Passwords (HOTP) and Time Based One Time Passwords (TOTP) defined in [RFC 4226](https://tools.ietf.org/html/rfc4226) and [RFC 6238](https://tools.ietf.org/html/rfc6238) respectively.
## Installation
### CocoaPods
SwiftOTP is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'SwiftOTP'
```
Then run `pod install` in the project directory to install.

### Carthage
SwiftOTP is available through [Carthage](https://github.com/Carthage/Carthage). To install it, simply add the following line to your Cartfile:

```
github "lachlanbell/SwiftOTP"
```
Then run `carthage update` in the project directory and add the resulting frameworks to your project.

### Swift Package Manager
You can use [Swift Package Manager](https://swift.org/package-manager/) and specify dependency in `Package.swift` by adding this:

```swift
dependencies: [
    .package(url: "https://github.com/lachlanbell/SwiftOTP.git", .upToNextMinor(from: "2.0.0"))
]
```

## Usage
### TOTP (Time-Based One Time Password)

#### Creation of a TOTP Object:
```swift
let totp = TOTP(secret: data)
```
A TOTP Object can be created with the default settings (6 digits, 30sec time interval and using HMAC-SHA-1) as shown above, or the individual parameters can be set as shown below:
```swift
let totp = TOTP(secret: data, digits: 6, timeInterval: 30, algorithm: .sha1)
```
#### Generating TOTP Passwords
After creating a TOTP object, a password can be generated for a point in time, either by using a `Date` object or a Unix time value using the `generate()` function

For example, to get a password for the current time using a `TOTP` object named `totp`:

```swift
if let totp = TOTP(secret: data) {
    let otpString = totp.generate(time: Date)
}
```


Or from Unix time (i.e. seconds elapsed since 01 Jan 1970 00:00 UTC):
```swift
if let totp = TOTP(secret: data) {
    let otpString = totp.generate(secondsPast1970: 1234567890)
}
```
Note: only `Int` values are accepted by this function, and must be positive.

### HOTP (HMAC-Based One Time Password (counter-based))

In addition to TOTP, SwiftOTP also supports the generation of counter-based HOTP passwords.
#### Creation of an HOTP Object:
```swift
let hotp = HOTP(secret: data)
```
A HOTP Object can be created with the default settings (6 digits, using HMAC-SHA-1) as shown above, or the individual parameters can be set as shown below:
```swift
let hotp = HOTP(secret: data, digits: 6, algorithm: .sha1)
```
#### Generating HOTP Passwords
After creating a TOTP object, a password can be generated for a counter value (`UInt64`) by using the `generate()` function, for example (where `hotp` is a `HOTP` object):
```swift
if let hotp = HOTP(secret: data) {
    let otpString = hotp.generate(counter: 42)
}
```

### Base32
Most secret keys for generating one time passwords use Base32 encoding. As such, SwiftOTP includes a [Base32 Helper](https://github.com/norio-nomura/Base32) to decode a Base32 string to `Data`.

For example:
```swift
base32DecodeToData("ABCDEFGHIJKLMNOP")!
```

Or in use:
```swift
guard let data = base32DecodeToData("ABCDEFGHIJKLMNOP") else { return }

if let hotp = HOTP(secret: data) {
    print(hotp.generate(42))
}
```

### Supported parameters
#### Hash Functions
SwiftOTP supports HMAC with SHA1 as specified in [RFC 4226](https://tools.ietf.org/html/rfc4226), as well as SHA256 and SHA512 added in [RFC 6238](https://tools.ietf.org/html/rfc6238). MD5 is **not** supported, due to its insufficient hash length.

#### Digit Length
Both the `TOTP` and `HOTP` objects only accept a digit length value between 6 and 8, as specified in [RFC 4226](https://tools.ietf.org/html/rfc4226). Both objects will be `nil` if an invalid digit length value is provided.

## Older Swift Versions
Use the corresponding branch for using an older Swift version (4.0 and greater). For example:
```ruby
pod 'SwiftOTP', :git => 'https://github.com/lachlanbell/SwiftOTP.git', :branch => 'swift-4.0'
```

## License
SwiftOTP is available under the MIT license. See the LICENSE file for more info.

### Acknowledgements
SwiftOTP depends on the following open-source projects:

* [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) by Marcin Krzyżanowski ([License](https://github.com/krzyzanowskim/CryptoSwift/tree/master/LICENSE))
* [Base32](https://github.com/norio-nomura/Base32) by Norio Nomura ([License](https://github.com/norio-nomura/Base32/blob/master/LICENSE))

Some parts of the password generator code were adapted from the [old Google Authenticator source](https://github.com/google/google-authenticator).

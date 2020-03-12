Elliptic Curve Key Pair
=======================

Sign, verify, encrypt and decrypt using the Secure Enclave on iOS and MacOS.

![](https://raw.githubusercontent.com/wiki/agens-no/EllipticCurveKeyPair/iphonex-decrypt-w-background.gif)

![macOS 10.12.1 support](https://img.shields.io/badge/macOS-10.12.1%2B-brightgreen.svg)
![iOS 9 support](https://img.shields.io/badge/iOS-9.0%2B-brightgreen.svg)
![Swift 3 and 4 support](https://img.shields.io/badge/swift-3%20|%204-brightgreen.svg)
![Carthage compatible](https://img.shields.io/badge/carthage-compatible-brightgreen.svg)
![Cocoapods compatible](https://img.shields.io/badge/cocoapods-compatible-brightgreen.svg)

## Features

- create a private public keypair
- store the private key on the secure enclave
- store the public key in keychain
- each time you use the private key the user will be prompted with FaceID, TouchID, device pass code or application password
- export the public key as X.509 DER with proper ASN.1 header / structure
- verify the signature with openssl in command line easily

Supports FaceID, TouchID, device pass code and application password.


## About

Using the Security Framework can be a little bit confusing. That’s why I created this. You may use it as example code and guidance or you may use it as a micro framework.

I found it tricky to figure out how to use the `SecKeyRawVerify`, `SecKeyGeneratePair` and `SecItemCopyMatching` C APIs in Swift 3, but the implementation is quite straight forward thanks to awesome Swift features.



## Installation

#### Manual

Just drag [`Sources/EllipticCurveKeyPair.swift`](Sources/EllipticCurveKeyPair.swift) and [`Sources/SHA256.swift`](Sources/SHA256.swift) file into your Xcode project.

#### Cocoapods

```ruby
pod EllipticCurveKeyPair
```

#### Carthage

```ruby
github "agens-no/EllipticCurveKeyPair"
```


## Use cases

There are lots of great possibilities with Secure Enclave. Here are some examples

### Encrypting

1. Encrypt a message using the public key
1. Decrypt the message using the private key – only accessible with FaceID / TouchID / device pin

Only available on iOS 10 and above

### Signing

1. Sign some data received by server using the private key – only accessible with FaceID / TouchID / device pin
1. Verify that the signature is valid using the public key

A use case could be

1. User is requesting a new agreement / purchase
1. Server sends a push with a session token that should be signed
1. On device we sign the session token using the private key - prompting the user to confirm with touch id
1. The signed token is then sent to server
1. Server already is in possession of the public key and verifies the signature using the public key
1. Server is now confident that user signed this agreement with touch id



## Examples

For more examples see demo app.

### Creating a keypair manager

```swift
struct KeyPair {
    static let manager: EllipticCurveKeyPair.Manager = {
        let publicAccessControl = EllipticCurveKeyPair.AccessControl(protection: kSecAttrAccessibleAlwaysThisDeviceOnly, flags: [])
        let privateAccessControl = EllipticCurveKeyPair.AccessControl(protection: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, flags: [.userPresence, .privateKeyUsage])
        let config = EllipticCurveKeyPair.Config(
            publicLabel: "payment.sign.public",
            privateLabel: "payment.sign.private",
            operationPrompt: "Confirm payment",
            publicKeyAccessControl: publicAccessControl,
            privateKeyAccessControl: privateAccessControl,
            token: .secureEnclave)
        return EllipticCurveKeyPair.Manager(config: config)
    }()
}
```

You can also gracefully fallback to use keychain if Secure Enclave is not available by using different access control flags:
```swift
let privateAccessControl = EllipticCurveKeyPair.AccessControl(protection: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly, flags: {
    return EllipticCurveKeyPair.Device.hasSecureEnclave ? [.userPresence, .privateKeyUsage] : [.userPresence]
}())
```

In that case you need to remember to set `token` variable in `Config` object to `.secureEnclaveIfAvailable`.

### Getting the public key in DER format

```swift
do {
    let key = try KeyPair.manager.publicKey().data().DER // Data
} catch {
    // handle error
}
```
See demo app for working example

### Getting the public key in PEM format

```swift
do {
    let key = try KeyPair.manager.publicKey().data().PEM // String
} catch {
    // handle error
}
```

### Signing

```swift
do {
    let digest = "some text to sign".data(using: .utf8)!
    let signature = try KeyPair.manager.sign(digest, hash: .sha256)
} catch {
    // handle error
}
```
You may also pass a LAContext object when signing

### Encrypting

```swift
do {
    let digest = "some text to encrypt".data(using: .utf8)!
    let encrypted = try KeyPair.manager.encrypt(digest, hash: .sha256)
} catch {
    // handle error
}
```

### Encrypting on a different device/OS/platform

You can also encrypt on a different device/OS/platform using the public key. If you want to know all the details about how to encrypt in a format the Secure Enclave understands, then you need definitely need to read this great write up by [@dschuetz](https://github.com/dschuetz)!

https://darthnull.org/security/2018/05/31/secure-enclave-ecies/

### Decrypting

```swift
do {
    let encrypted = ...
    let decrypted = try KeyPair.manager.decrypt(encrypted, hash: .sha256)
    let decryptedString = String(data: decrypted, encoding: .utf8)
} catch {
    // handle error
}
```
You may also pass a LAContext object when decrypting

## Error handling

The most common thing is to catch error related to
- Secure Enclave not being available
- User cancels fingerprint dialog
- No fingerprints enrolled

With `do/catch`:
```swift
do {
    let decrypted = try KeyPair.manager.decrypt(encrypted)
} catch EllipticCurveKeyPair.Error.underlying(_, let underlying) where underlying.code == errSecUnimplemented {
    print("Unsupported device")
} catch EllipticCurveKeyPair.Error.authentication(let authenticationError) where authenticationError.code == .userCancel {
    print("User cancelled/dismissed authentication dialog")
} catch {
    print("Some other error occurred. Error \(error)")
}
```

With `if let`:
```swift
if case let EllipticCurveKeyPair.Error.underlying(_, underlying) = error, underlying.code == errSecUnimplemented {
    print("Unsupported device")
} else if case let EllipticCurveKeyPair.Error.authentication(authenticationError), authenticationError.code == .userCancel {
  print("User cancelled/dismissed authentication dialog")
} else {
  print("Some other error occurred. Error \(error)")
}
```


## Debugging

In order to inspect the queries going back and forth to Keychain you may print to console every mutation this library does on Keychain like this
```swift
EllipticCurveKeyPair.logger = { print($0) }
```



## Verifying a signature

In the demo app you’ll see that each time you create a signature some useful information is logged to console.

Example output

```sh
#! /bin/sh
echo 414243 | xxd -r -p > dataToSign.dat
echo 3046022100842512baa16a3ec9b977d4456923319442342e3fdae54f2456af0b7b8a09786b022100a1b8d762b6cb3d85b16f6b07d06d2815cb0663e067e0b2f9a9c9293bde8953bb | xxd -r -p > signature.dat
cat > key.pem <<EOF
-----BEGIN PUBLIC KEY-----
MFkwEwYHKoZIzj0CAQYIKoZIzj0DAQcDQgAEdDONNkwaP8OhqFTmjLxVcByyPa19
ifY2IVDinFei3SvCBv8fgY8AU+Fm5oODksseV0sd4Zy/biSf6AMr0HqHcw==
-----END PUBLIC KEY-----
EOF
/usr/local/opt/openssl/bin/openssl dgst -sha256 -verify key.pem -signature signature.dat dataToSign.dat
```

In order to run this script you can

1. Paste it in to a file: `verify.sh`
1. Make the file executable: `chmod u+x verify.sh`
1. Run it: `./verify.sh`

Then you should see
```sh
Verified OK
```

PS: This script will create 4 files in your current directory.



## Keywords
Security framework, Swift 3, Swift 4, Swift, SecKeyRawVerify, SecKeyGeneratePair, SecItemCopyMatching, secp256r1, Elliptic Curve Cryptography, ECDSA, ECDH, ASN.1, Apple, iOS, Mac OS, kSecAttrKeyTypeECSECPrimeRandom, kSecAttrKeyTypeEC, kSecAttrTokenIDSecureEnclave, LAContext, LocalAuthentication, FaceID, Face ID, TouchID, Touch ID, Application Password, Device Pin, Devicepin



## Acknowledgements and credits

### TrailOfBits

[TrailOfBits](https://github.com/trailofbits/) published some objective-c code a while back which was to great help! Thanks for [sharing](https://blog.trailofbits.com/2016/06/28/start-using-the-secure-enclave-crypto-api/) Tidas and [SecureEnclaveCrypto](https://github.com/trailofbits/SecureEnclaveCrypto). They also got some other most interesting projects. Check them out!

### Quinn “the Eskimo!”, Apple

He shared som [very valuable insights](https://forums.developer.apple.com/message/84684#84684) with regards to exporting the public key in the proper DER X.509 format.

### SHA256

The `SHA256` class (originally `SHA2.swift`) is found in the invaluable [CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift) library by [Marcin Krzyżanowski](http://www.krzyzanowskim.com/). The class has been heavily altered in order to strip it down to its bare minimum for what we needed in this project.



## FAQ

**Why am I not being prompted with touch id / device pin on simulator?**  
> The simulator doesn’t possess any secure enclave and therefore trying to access it would just lead to errors. If you set `fallbackToKeychainIfSecureEnclaveIsNotAvailable` to `true` then the private key will be stored in keychain on simulator making it easy to test your application on simulator as well.

**Where can I learn more?**  
> Check out this video on [WWDC 2015](https://developer.apple.com/videos/play/wwdc2015/706/) about Security in general or [click here](https://developer.apple.com/videos/play/wwdc2015/706/?time=2069) to skip right to the section about the Secure Enclave.

**Why is it wrapped in an enum?**
> I try to balance drag-and-drop the files you need into xcode and supporting dependency managers like carthage and cocoapods at the same time. If you have better ideas or don't agree with this decision I'm happy to discuss alternatives :)



## Feedback

We would 😍 to hear your opinion about this library. Wether you like or don’t. Please file an issue if there’s something you would like to see improved. You can reach me as [@hfossli](https://twitter.com/hfossli) on twitter and elsewhere. 😀

[<img src="http://static.agens.no/images/agens_logo_w_slogan_avenir_medium.png" width="340" />](http://agens.no/)

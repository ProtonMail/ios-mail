# ProtonCore iOS

The set of core iOS modules used by Proton Technologies AG.


## Table of Contents

- [Modules](#modules)
- [Examples](#examples)
- [License](#license)
- [Contributing notice](#contributing-notice)


## Modules

### Account Switcher

UI components for showing the list of logged in account, switch between them, log out, log in another.

Podspec: [ProtonCore-AccountSwitcher.podspec](ProtonCore-AccountSwitcher.podspec)

Sources: [libraries/AccountSwitcher](libraries/AccountSwitcher)

Platforms supported: iOS


### APIClient

API clients for a subset of small, common Proton APIs.

Podspec: [ProtonCore-APIClient.podspec](ProtonCore-APIClient.podspec)

Sources: [libraries/APIClient](libraries/APIClient)

Platforms supported: iOS, macOS

Variants: 
* `ProtonCore-APIClient/Alamofire`
* `ProtonCore-APIClient/AFNetworking`


### Authentication

API client for the Proton Authentication API.

Podspec: [ProtonCore-Authentication.podspec](ProtonCore-Authentication.podspec)

Sources: [libraries/Authentication](libraries/Authentication)

Platforms supported: iOS, macOS

Variants: 
* `ProtonCore-Authentication/UsingCrypto+Alamofire`
* `ProtonCore-Authentication/UsingCrypto+AFNetworking`
* `ProtonCore-Authentication/UsingCryptoVPN+Alamofire`
* `ProtonCore-Authentication/UsingCryptoVPN+AFNetworking`


### Authentication-KeyGeneration

Extension to the [Authentication](#authentication) module for the key generation operations.

Podspec: [ProtonCore-Authentication-KeyGeneration.podspec](ProtonCore-Authentication-KeyGeneration.podspec)

Sources: [libraries/Authentication-KeyGeneration](libraries/Authentication-KeyGeneration)

Platforms supported: iOS, macOS

Variants: 
* `ProtonCore-Authentication-KeyGeneration/UsingCrypto+Alamofire`
* `ProtonCore-Authentication-KeyGeneration/UsingCrypto+AFNetworking`
* `ProtonCore-Authentication-KeyGeneration/UsingCryptoVPN+Alamofire`
* `ProtonCore-Authentication-KeyGeneration/UsingCryptoVPN+AFNetworking`


### Challenge

Gathering information used by the anti-abuse filters to limit fraud and abuse.

Podspec: [ProtonCore-Challenge.podspec](ProtonCore-Challenge.podspec)

Sources: [libraries/Challenge](libraries/Challenge)

Platforms supported: iOS


### Common

Architectural sketch. A set of protocols and basic types to base the architecture on.

Podspec: [ProtonCore-Common.podspec](ProtonCore-Common.podspec)

Sources: [libraries/Common](libraries/Common)

Platforms supported: iOS, macOS (very limited subset of sources)

Variants: 
* `ProtonCore-Common/Alamofire`
* `ProtonCore-Common/AFNetworking`


### CoreTranslation

Localized strings.

Podspec: [ProtonCore-CoreTranslation.podspec](ProtonCore-CoreTranslation.podspec)

Sources: [libraries/CoreTranslation](libraries/CoreTranslation)

Platforms supported: iOS, macOS


### Crypto

Wrapper and delivery mechanism for the go crypto libraries, built into `vendor/Crypto/Crypto.xcframework`. 
More info in [Crypto README](libraries/Crypto/Readme.md).

Podspec: [ProtonCore-Crypto.podspec](ProtonCore-Crypto.podspec)

Sources: [libraries/Crypto](libraries/Crypto)

Uses and deliveres framework: [Crypto.xcframework](vendor/Crypto/Crypto.xcframework)

Platforms supported: iOS, macOS


### Crypto-VPN

Wrapper and delivery mechanism for the go crypto libraries, built into `vendor/Crypto_VPN/Crypto_VPN.xcframework`. 
More info in [Crypto README](libraries/Crypto/Readme.md).

Podspec: [ProtonCore-Crypto-VPN.podspec](ProtonCore-Crypto-VPN.podspec)

Sources: [libraries/Crypto](libraries/Crypto)

Uses and deliveres framework: [Crypto_VPN.xcframework](vendor/Crypto_VPN/Crypto_VPN.xcframework)

Platforms supported: iOS, macOS


### DataModel

Basic data objects used in various modules.

Podspec: [ProtonCore-DataModel.podspec](ProtonCore-DataModel.podspec)

Sources: [libraries/DataModel](libraries/DataModel)

Platforms supported: iOS, macOS


### DoH

Basic logic for DNS over HTTPS feature.

Podspec: [ProtonCore-DoH.podspec](ProtonCore-DoH.podspec)

Sources: [libraries/DoH](libraries/DoH)

Platforms supported: iOS, macOS


### Features

Common cross-app user features. 
Right now only single one: email sending.

Podspec: [ProtonCore-Features.podspec](ProtonCore-Features.podspec)

Sources: [libraries/Features](libraries/Features)

Platforms supported: iOS, macOS

Variants: 
* `ProtonCore-Features/UsingCrypto+Alamofire`
* `ProtonCore-Features/UsingCrypto+AFNetworking`
* `ProtonCore-Features/UsingCryptoVPN+Alamofire`
* `ProtonCore-Features/UsingCryptoVPN+AFNetworking`


### ForceUpgrade

Logic for handling force upgrade.

Podspec: [ProtonCore-ForceUpgrade.podspec](ProtonCore-ForceUpgrade.podspec)

Sources: [libraries/ForceUpgrade](libraries/ForceUpgrade)

Platforms supported: iOS, macOS (very limited subset of sources)

Variants: 
* `ProtonCore-ForceUpgrade/Alamofire`
* `ProtonCore-ForceUpgrade/AFNetworking`


### Foundations

Helpers for common tasks. Not really well defined.

Podspec: [ProtonCore-Foundations.podspec](ProtonCore-Foundations.podspec)

Sources: [libraries/Foundations](libraries/Foundations)

Platforms supported: iOS, macOS (very limited subset of sources)


### GoSRP

Delivery mechanism for the SRP library, built into `vendor/Srp/SRP.xcframework`. 
No actual Swift sources here.

Podspec: [ProtonCore-GoSRP.podspec](ProtonCore-GoSRP.podspec)

Uses and deliveres framework: [GoSRP.xcframework](vendor/Srp/GoSRP.xcframework)

Platforms supported: iOS, macOS


### HumanVerification

Human verification handling with the UI.

Podspec: [ProtonCore-HumanVerification.podspec](ProtonCore-HumanVerification.podspec)

Sources: [libraries/HumanVerification](libraries/HumanVerification)

Platforms supported: iOS, macOS

Variants: 
* `ProtonCore-HumanVerification/Alamofire`
* `ProtonCore-HumanVerification/AFNetworking`


### Keymaker

Logic related to storing keys and maintaining access to them.

Podspec: [ProtonCore-Keymaker.podspec](ProtonCore-Keymaker.podspec)

Sources: [libraries/Keymaker](libraries/Keymaker)

Platforms supported: iOS, macOS

Variants: 
* `ProtonCore-Keymaker/UsingCrypto`
* `ProtonCore-Keymaker/UsingCryptoVPN`


### KeyManager

Crypto operations using keys.

Podspec: [ProtonCore-KeyManager.podspec](ProtonCore-KeyManager.podspec)

Sources: [libraries/KeyManager](libraries/KeyManager)

Platforms supported: iOS, macOS

Variants: 
* `ProtonCore-KeyManager/UsingCrypto`
* `ProtonCore-KeyManager/UsingCryptoVPN`


### Log

Logging events. File-backed.

Podspec: [ProtonCore-Log.podspec](ProtonCore-Log.podspec)

Sources: [libraries/Log](libraries/Log)

Platforms supported: iOS, macOS


### Login

Login and signup services. 
Setting the right account state during login.

Podspec: [ProtonCore-Login.podspec](ProtonCore-Login.podspec)

Sources: [libraries/Login](libraries/Login)

Platforms supported: iOS, macOS

Variants: 
* `ProtonCore-Login/UsingCrypto+Alamofire`
* `ProtonCore-Login/UsingCrypto+AFNetworking`
* `ProtonCore-Login/UsingCryptoVPN+Alamofire`
* `ProtonCore-Login/UsingCryptoVPN+AFNetworking`


### LoginUI

Login and signup UI.

Podspec: [ProtonCore-LoginUI.podspec](ProtonCore-LoginUI.podspec)

Sources: [libraries/LoginUI](libraries/LoginUI)

Platforms supported: iOS

Variants: 
* `ProtonCore-LoginUI/UsingCrypto+Alamofire`
* `ProtonCore-LoginUI/UsingCrypto+AFNetworking`
* `ProtonCore-LoginUI/UsingCryptoVPN+Alamofire`
* `ProtonCore-LoginUI/UsingCryptoVPN+AFNetworking`


### Networking

Common networking objects and protocols. 

Podspec: [ProtonCore-Networking.podspec](ProtonCore-Networking.podspec)

Sources: [libraries/Networking](libraries/Networking)

Platforms supported: iOS, macOS

Variants: 
* `ProtonCore-Networking/Alamofire`
* `ProtonCore-Networking/AFNetworking`


### ObfuscatedConstants

A wrapper for sensitive data like test user accounts 
or internal testing environments that are not available publicly.

Podspec: [ProtonCore-ObfuscatedConstants.podspec](ProtonCore-ObfuscatedConstants.podspec)

Sources: [libraries/ObfuscatedConstants](libraries/ObfuscatedConstants)

Platforms supported: iOS, macOS


### OpenPGP

Delivery mechanism for the OpenPGP library, built into `vendor/OpenPGP/OpenPGP.xcframework`. 
No actual Swift sources here.

Podspec: [ProtonCore-OpenPGP.podspec](ProtonCore-OpenPGP.podspec)

Uses and deliveres framework: [OpenPGP.xcframework](vendor/OpenPGP/OpenPGP.xcframework)

Platforms supported: iOS, macOS


### Payments

Payments services and logic.

Podspec: [ProtonCore-Payments.podspec](ProtonCore-Payments.podspec)

Sources: [libraries/Payments](libraries/Payments)

Platforms supported: iOS, macOS

Variants: 
* `ProtonCore-Payments/UsingCrypto+Alamofire`
* `ProtonCore-Payments/UsingCrypto+AFNetworking`
* `ProtonCore-Payments/UsingCryptoVPN+Alamofire`
* `ProtonCore-Payments/UsingCryptoVPN+AFNetworking`


### PaymentsUI

Payments UI.

Podspec: [ProtonCore-PaymentsUI.podspec](ProtonCore-PaymentsUI.podspec)

Sources: [libraries/PaymentsUI](libraries/PaymentsUI)

Platforms supported: iOS

Variants: 
* `ProtonCore-PaymentsUI/UsingCrypto+Alamofire`
* `ProtonCore-PaymentsUI/UsingCrypto+AFNetworking`
* `ProtonCore-PaymentsUI/UsingCryptoVPN+Alamofire`
* `ProtonCore-PaymentsUI/UsingCryptoVPN+AFNetworking`


### Services

Actual network engine. Uses either AFNetworking or Alamofire under the hood.

Podspec: [ProtonCore-Services.podspec](ProtonCore-Services.podspec)

Sources: [libraries/Services](libraries/Services)

Platforms supported: iOS, macOS

Variants: 
* `ProtonCore-Services/Alamofire`
* `ProtonCore-Services/AFNetworking`


### Settings

UI component for limited app settings.

Podspec: [ProtonCore-Settings.podspec](ProtonCore-Settings.podspec)

Sources: [libraries/Settings](libraries/Settings)

Platforms supported: iOS


### SRP

Basic hash algo types.

Podspec: [ProtonCore-SRP.podspec](ProtonCore-SRP.podspec)

Sources: [libraries/SRP](libraries/SRP)

Platforms supported: iOS, macOS


# TestingToolkit

A number of things helping with unit and UI testing of modules. Submodule-based.

Podspec: [ProtonCore-TestingToolkit.podspec](ProtonCore-TestingToolkit.podspec)

Sources: [libraries/TestingToolkit](libraries/TestingToolkit)

Platforms supported: iOS, macOS


# UIFoundations

Colors, styles and common UI components.

Podspec: [ProtonCore-UIFoundations.podspec](ProtonCore-UIFoundations.podspec)

Sources: [libraries/UIFoundations](libraries/UIFoundations)

Platforms supported: iOS, macOS (very limited subset of sources)


# Utilities

A number of common helpers and extensions used in various modules.

Podspec: [ProtonCore-Utilities.podspec](ProtonCore-Utilities.podspec)

Sources: [libraries/Utilities](libraries/Utilities)

Platforms supported: iOS, macOS


# VCard

Delivery mechanism for the VCard library, built into `vendor/VCard/VCard.xcframework`. 
No actual Swift sources here.

Podspec: [ProtonCore-VCard.podspec](ProtonCore-VCard.podspec)

Uses and deliveres framework: [VCard.xcframework](vendor/VCard/VCard.xcframework)

Platforms supported: iOS, macOS


## Example app

The example app is located in [the example-app directory](example-app).

## License

The code and data files in this distribution are licensed under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. See [GNU General Public License](https://www.gnu.org/licenses/gpl-3.0.html) for a copy of this license.

See [LICENSE](LICENSE) file.

This product includes software developed by the "Marcin Krzyzanowski" (http://krzyzanowskim.com/).

## Contributing notice

By contributing to the ProtonCore iOS you accept the [CONTRIBUTION_POLICY](CONTRIBUTION_POLICY.md). Please read and understand before making a contribution.
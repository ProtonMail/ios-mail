
# iOS Mail

## Table of Contents

<!-- TOC depthFrom:3 -->
- [Introduction](#introduction)
- [Project setup](#project-setup)
- [Running Proton Mail](#running-proton-mail)
- [Dependencies](#dependencies)
    - [Internal](#internal)
    - [Third Party](#third-party)
- [Articles](#articles)
- [License](#license)
- [Download from the Apple Store](#download-from-the-Apple-Store)
- [Our Team](#our-team)
<!-- /TOC -->

## Introduction

Proton Mail iOS client for encrypted email.

The application contains the following features among others (some are only available to paid users): create new accounts, sign in to multiple accounts, read and compose emails, schedule emails to be sent at a specific time, protect emails with a password, set emails expiration time, organise emails with labels and folders, manage contacts, change account settings, and many more...

Currently the application supports iOS version 14 and above

## Project setup

1. As a first step, you have to have macOS up to date and install Xcode 14+

2. The project uses [Mint](https://github.com/yonaskolb/mint) as a package manager. If you don't have it installed, you can do it via [Homebrew](https://brew.sh/) by `brew bundle --file="ProtonMail/Brewfile" --no-upgrade`. Once you have it ready, in order to install dependecies run:

`mint bootstrap`

3. [DOMPurify](https://github.com/cure53/DOMPurify) and Cocoapods are pre-downloaded. We are using git submodules for tracking DOMPurifier. After cloning the repository run these two commands:

`git submodule init`
`git submodule update`

4. We are using [XcodeGen](https://github.com/yonaskolb/XcodeGen) to generate Xcode project. To create the corresponding project files run:

`sh ProtonMail/xcodeGenHelper.sh`

## Running Proton Mail

1. In order to run the project you will need first to set your own provisioning profile. You can do that in the `Signing & Capabilities` settings of the `ProtonMail` target.

## Dependencies

### Internal

- [gopenpgp](https://github.com/ProtonMail/gopenpgp)
- [OpenPGP](https://github.com/ProtonMail/cpp-openpgp)
- [VCard](https://github.com/ProtonMail/cpp-openpgp)
- [go-srp](https://github.com/ProtonMail/go-srp)

### Third Party

[Acknowledgements](Acknowledgements.md)

## Articles

These are some articles from our [blog](https://proton.me/blog) that you might find useful:

- [Proton Mail iOS app goes open source!](https://proton.me/blog/ios-open-source)
- [Proton Mail iOS client security](https://proton.me/blog/ios-security-model)

## License

The code and data files in this distribution are licensed under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. See <https://www.gnu.org/licenses/> for a copy of this license.

See [LICENSE](LICENSE) file

## Download from the Apple Store

You can follow this link to download Proton Mail from the [Apple Store](https://apps.apple.com/app/protonmail-encrypted-email/id979659905)

## Our Team

- [Anson](https://github.com/xxi511)
- [Mustapha](https://github.com/justarandomdev)
- [Steven](https://github.com/Linquas)
- [Jacek](https://github.com/jacekkra)
- [Xavi](https://github.com/xavigil)

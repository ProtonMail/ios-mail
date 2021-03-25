
# iOS-mail

## Introduction

iOS-mail — ProtonMail iOS client app

The app is intended for all users of the ProtonMail service. Whether they are paid or free, they can compose and read emails, manage folders and labels, manage some account settings and create a new account. The app supports iOS 11-14.

## License

The code and data files in this distribution are licensed under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version. See <https://www.gnu.org/licenses/> for a copy of this license.

See [LICENSE](LICENSE) file

## Table of Contents

<!-- TOC depthFrom:3 -->
- [Introduction](#Introduction)
- [License](#License)
- [Architecture](#Architecture)
- [Dependencies](#Dependencies)
    - [Internal](#Internal)
    - [Third Party](#Third-Party)
- [Content Explanation](#Content-Explanation)
- [Setup](#setup)
- [Live version](#live-version)
- [Articles](#Articles)
- [Our Team](#our-team)
- [TODO](#todo)
<!-- /TOC -->

## Architecture

[MVVM-C](mvvmc.png) with services. Model-View-ViewModel architecture, plus the Coordinator pattern.

## Dependencies

### Internal

- [gopenpgp](https://github.com/ProtonMail/gopenpgp)
- [OpenPGP](https://github.com/ProtonMail/cpp-openpgp)
- [VCard](https://github.com/ProtonMail/cpp-openpgp)
- [go-srp](https://github.com/ProtonMail/go-srp)

### Third Party

[Acknowledgements](Acknowledgements.md)

## Content Explanation

<!-- TOC depthFrom:3 -->
- [OpenPGP](OpenPGP/README.md)
- [Keymaker](ProtonMail/Keymaker/README.md)
- [ProtonMail](ProtonMail/ProtonMail/README.md)
- [ProtonMailCommon](ProtonMail/ProtonMailCommon/README.md)
- [Push](ProtonMail/Push/README.md)
- [PushService](ProtonMail/PushService/README.md)
- [Share](ProtonMail/Share/README.md)
- [Siri](ProtonMail/Siri/README.md)
- [Scripts](Scripts/README.md)
- [Trust Model](ProtonMail/README.md#Trust-Model)
- [Local Data Protection](ProtonMail/README.md#Local-Data)
<!-- /TOC -->

## Setup

1. Have macOS up to date and install Xcode 11.1
2. We use xUnique (ver 4.1.4) in order to prevent merge conflicts in the ProtonMail.xcodeproj file. Each shared scheme has a post-build action, and builds will fail on machines with no xUnique installed. Please follow xUnique's [installation instructions](https://github.com/truebit/xUnique)
3. `DOMPurify`(@b06b6b2ac8) and Cocoapods are pre-downloaded. We are using git submodules for tracking DOMPurifier, so after cloning you have to run `git submodule init` and `git submodule update` to fetch it. Theory here: https://git-scm.com/book/en/v2/Git-Tools-Submodules
4. Open `ProtonMail/ProtonMail.xcworkspace` and click the run button

## Live version

Current live version 1.11.13

- [Changelogs](Changelog.md)
- [Apple Store](https://apps.apple.com/app/protonmail-encrypted-email/id979659905)

## Articles

- [Open sourcing](https://protonmail.com/blog/ios-open-source)
- [Security model](https://protonmail.com/blog/ios-security-model)

## Our Team

- [Feng](https://github.com/zhj4478)
- [Anatoly](https://github.com/abjurato)
- [Henry](https://github.com/henrybear327)
- [Emil](https://github.com/emnproton)

## TODO

 - [ ] UI redesign
 - [ ] multiple user support
 - [ ] share frameworks

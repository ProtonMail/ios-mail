![AwaitKit](http://yannickloriot.com/resources/AwaitKit-Arista-Banner.png)

[![Carthage Compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Supported Platforms](https://cocoapod-badges.herokuapp.com/p/AwaitKit/badge.svg)](http://cocoadocs.org/docsets/AwaitKit/) [![Version](https://cocoapod-badges.herokuapp.com/v/AwaitKit/badge.svg)](http://cocoadocs.org/docsets/AwaitKit/)
[![Build Status](https://travis-ci.org/yannickl/AwaitKit.svg?branch=master)](https://travis-ci.org/yannickl/AwaitKit)
[![codecov.io](http://codecov.io/github/yannickl/AwaitKit/coverage.svg?branch=master)](http://codecov.io/github/yannickl/AwaitKit?branch=master)
[![codebeat badge](https://codebeat.co/badges/212dd077-388c-4b0a-8829-9ccf16d0a200)](https://codebeat.co/projects/github-com-yannickl-awaitkit)
[![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/sindresorhus/awesome)

Have you ever dream to write asynchronous code like its synchronous counterpart?

_AwaitKit_ is a powerful Swift library inspired by the [Async/Await specification in ES8 (ECMAScript 2017)](https://github.com/tc39/ecmascript-asyncawait) which provides a powerful way to write asynchronous code in a sequential manner.

Internally it uses [PromiseKit](https://github.com/mxcl/PromiseKit) v6.10 to create and manage promises.

<p align="center">
    <a href="#requirements">Requirements</a> • <a href="#getting-started">Getting Started</a> • <a href="#usage">Usage</a> • <a href="#installation">Installation</a> • <a href="#contribution">Contribution</a> • <a href="#contact">Contact</a> • <a href="#license-mit">License</a>
</p>

## Requirements

- iOS 8.0+
- Xcode 8.0+
- Swift 4.0+

## Getting Started

If you want have a quick overview of the project take a look to this [blog post](http://yannickloriot.com/2016/05/awaitkit/).

Put simply, write this:

```swift
let user = try! await(signIn(username: "Foo", password: "Bar"))
try! await(sendWelcomeMailToUser(user))
try! await(redirectToThankYouScreen())

print("All done!")
```

Instead of:

```swift
signIn(username: "Foo", password: "Bar")
  .then { user in
    return self.sendWelcomeMailToUser(user)
  }
  .then { _ in
    return self.redirectToThankYouScreen()
  }
  .then { _ in
    print("All done!")
  }
```

Or worse, using the completion block imbrication hell style:

```swift
signIn(username: "Foo", password: "Bar") { user in
  self.sendWelcomeMailToUser(user) { _ in
    self.redirectToThankYouScreen() { _ in
      print("All done!")
    }
  }
}
```

## Usage

### Async

The `async` method yields the execution to its closure which will run in a background queue and returns a promise which will be resolved at this end of block.

Here a small example :

```swift
func setupNewUser(name: String) -> Promise<User> {  
  return async {
    let newUser = try await(self.createUser(name))
    let friends = try await(self.getFacebookFriends(name))

    newUser.addFriends(friends)

    return newUser
  }
}
```

Here the `setupNewUser` returns a promise with a user as value. If the end of `async` block is executed the promise will be resolved, otherwise if an error occurred inside the async block the promise will be rejected with the corresponding error.

The `async` block will catch the error thrown to reject the promise so you don't need to manage the `await` exceptions. But if necessary, you can:

```swift
async {
  do {
    try await(self.loginOrThrown(username: "yannickl"))
  }
  catch {
    print(error)
  }

  try await(self.clearCache())
}
```

### Await

The `await` method will executes the given promise or block and await until it resolved or failed.

```swift
do {
  let name: String = try await {
    Thread.sleep(forTimeInterval: 0.2)

    if Int(arc4random_uniform(2) + 1) % 2 == 0 {
      return "yannickl"
    }
    else {
      throw NSError()
    }
  }

  print(name)
}
catch {
  print(error)
}
```

### Custom queues

The `async` and `await` methods runs by default on a background concurrent queue. Of course, you can choose your own queues and call the following methods:

```swift
DispatchQueue.global(qos: .default).ak.async {

}

try DispatchQueue.global(qos: .default).ak.await {

}
```

When you use these methods and you are doing asynchronous, be careful to do nothing in the main thread, otherwise you risk to enter in a deadlock situation.

## Installation

The recommended approach to use _AwaitKit_ in your project is using the [CocoaPods](http://cocoapods.org/) package manager, as it provides flexible dependency management and dead simple installation.

### CocoaPods

Install CocoaPods if not already available:

``` bash
$ [sudo] gem install cocoapods
$ pod setup
```
Go to the directory of your Xcode project, and Create and Edit your Podfile and add _AwaitKit_:

``` bash
$ cd /path/to/MyProject
$ touch Podfile
$ edit Podfile
source 'https://github.com/CocoaPods/Specs.git'
platform :ios, '8.0'
pod 'AwaitKit', '~> 5.2.0'
```

Install into your project:

``` bash
$ pod install
```

If CocoaPods did not find the `PromiseKit 6.10` dependency execute this command:

```bash
$ pod repo update
```

Open your project in Xcode from the .xcworkspace file (not the usual project file)

``` bash
$ open MyProject.xcworkspace
```

### Swift Package Manager

You can use [The Swift Package Manager](https://swift.org/package-manager) to install `AwaitKit` by adding the proper description to your `Package.swift` file:

```swift
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .Package(url: "https://github.com/yannickl/AwaitKit.git")
    ]
)
```

Note that the [Swift Package Manager](https://swift.org/package-manager) is still in early design and development, for more information checkout its [GitHub Page](https://github.com/apple/swift-package-manager).

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that builds your dependencies and provides you with binary frameworks.

You can install Carthage with [Homebrew](http://brew.sh/) using the following command:

```bash
$ brew update
$ brew install carthage
```

To integrate AwaitKit into your Xcode project using Carthage, specify it in your `Cartfile`:

```ogdl
github "yannickl/AwaitKit" ~> 5.2.0
```

Run `carthage update` to build the framework and drag the built `AwaitKit.framework` into your Xcode project.

### Manually

[Download](https://github.com/YannickL/AwaitKit/archive/master.zip) the project and copy the `AwaitKit` folder into your project to use it in. Note that you also need to download the [PromiseKit](https://github.com/mxcl/PromiseKit) v6.7 library and import it to your project.

## Contribution

Contributions are welcomed and encouraged *♡*.

## Contact

Yannick Loriot
 - [https://21.co/yannickl/](https://21.co/yannickl/)
 - [https://twitter.com/yannickloriot](https://twitter.com/yannickloriot)

## License (MIT)

Copyright (c) 2016-present - Yannick Loriot

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
THE SOFTWARE.

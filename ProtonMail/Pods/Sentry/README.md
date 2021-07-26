<p align="center">
    <a href="https://sentry.io" target="_blank" align="center">
        <img src="https://sentry-brand.storage.googleapis.com/sentry-logo-black.png" width="280">
    </a>
<br/>
    <h1>Official Sentry SDK for iOS/macOS/tvOS/watchOS<sup>(1)</sup>.</h1>
</p>

[![Travis](https://img.shields.io/travis/getsentry/sentry-cocoa.svg?maxAge=2592000)](https://travis-ci.com/getsentry/sentry-cocoa)
[![codecov.io](https://codecov.io/gh/getsentry/sentry-cocoa/branch/master/graph/badge.svg)](https://codecov.io/gh/getsentry/sentry-cocoa)
[![CocoaPods compadible](https://img.shields.io/cocoapods/v/Sentry.svg)](https://cocoapods.org/pods/Sentry)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![SwiftPM compatible](https://img.shields.io/badge/spm-compatible-brightgreen.svg?style=flat)](https://swift.org/package-manager)
![platforms](https://img.shields.io/cocoapods/p/Sentry.svg?style=flat)
[![Twitter](https://img.shields.io/badge/twitter-@getsentry-blue.svg?style=flat)](http://twitter.com/getsentry)



This SDK is written in Objective-C but also works for Swift projects.

```swift
import Sentry

func application(application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [NSObject: AnyObject]?) -> Bool {

    // Create a Sentry client and start crash handler
    do {
        Client.shared = try Client(dsn: "___PUBLIC_DSN___")
        try Client.shared?.startCrashHandler()
    } catch let error {
        print("\(error)")
        // Wrong DSN or KSCrash not installed
    }

    return true
}
```

- [Installation](https://docs.sentry.io/clients/cocoa/#installation)
- [Documentation](https://docs.sentry.io/clients/cocoa/)

<sup>(1)</sup>limited symbolication support

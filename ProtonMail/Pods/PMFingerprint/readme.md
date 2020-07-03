# Fingerprint

收集使用者在註冊時的操作行為與裝置資訊，協助 anti-abuse 做判斷

## Dependency
* `UIKit`
* `Foundation`
* `CoreTelephony`

## Reference
* [iOS fingerprints](https://confluence.protontech.ch/pages/viewpage.action?spaceKey=PRODUCT&title=iOS+fingerprints)
* [Fingerprinting in Today’s iOS](https://nshipster.com/device-identifiers/#fingerprinting-in-todays-ios)

## Test app
* first page: Do nothing, simulate user start the signup process
* second page: some form to simulate user fill in signup data, don't forget to click `send sms` button before filling `smsverify` textField
* third page: show collected data, and it mess, so you can copy the value through the right-top button and open online JSON parser

## How to use
### Life cycle
```swift
/// Get shared instance, thread safe
public static func shared() -> PMFingerprint

/// Release shared instance
public static func release()

/// Or if you don't prefer singleton
let fingerprint = PMFingerprint()
```

### usage
```swift
/// Reset collected data
public func reset()

/// Export collected fingerprint data, and reset collected data
public func export() -> PMFingerprint.Fingerprint

/**
 Start observe given textfield, will ignore redundant function called
 - Parameter textField: textField will be observe
 - Parameter type: The usage of this textField
 - Parameter ignoreDelegate: Should ignore textField delegate missing error?
 */
public func observeTextField(_ textField: UITextField, type: TextFieldType, ignoreDelegate: Bool = false) throws

/// Stop observe given textField, call this function when viewcontroller pushed
public func stopObserveTextField(_ textField: UITextField)

/// Record username that checks availability
public func appendCheckedUsername(_ username: String)

/// Record user start request verification time
public func requestVerify()
```

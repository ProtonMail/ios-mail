# iOS Monkey

**ios-monkey** is the lightweight and easy to use Monkey UI testing framework built on top of Apple. This project is a framework for generating randomised user input in iOS apps. This kind of monkey testing is useful for stress-testing apps and finding rare crashes.


### Table of contents
1. [Installation](#installation)
2. [Usage](#usage)
    - [Examle Monkey XCTest](#monkey)

### Installation <a name="installation"></a>
#### CocoaPods

```ruby
pod 'ios-monkey'
```

### Usage <a name="usage"></a>


#### Example Monkey XCTest <a name="monkey"></a>

Can define environment variables 
1. MONKEY_NUMBER_OF_STEPS = 500 // by default 50
2. MONKEY_SCREENSHOT_OUTPUT_DIRECTORY = full path of the screenshot // screenshots are saved for the last 10 actions leading to a crash

![Alt text](./screenshots.png?raw=true "Monkey screenshots")

```swift
import XCTest

class MonkeyTests : BaseMonkey {

    override var app: XCUIApplication { get { return XCUIApplication(bundleIdentifier: "com.apple.mobilesafari") } }
    override var stack: ScreenshotStack { get { return ScreenshotStack(size: 10) } }
    override var numberOfSteps: Int {
        var numberOfSteps: Int = 10
        if let numberOfStepsArgument = ProcessInfo.processInfo.environment["MONKEY_NUMBER_OF_STEPS"], let overriddenNumberOfSteps = Int(numberOfStepsArgument) {
            numberOfSteps = overriddenNumberOfSteps
        }

        return numberOfSteps
    }
    override var screenshotOutputDirectory: String { get { return ProcessInfo.processInfo.environment["MONKEY_SCREENSHOT_OUTPUT_DIRECTORY"] ?? "" } }
    
    func testMonkey() {
        randomTouches()
    }

}
```

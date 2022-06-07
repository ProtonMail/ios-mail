## pmtest

**pmtest** is the lightweight and easy to use UI testing framework built on top of Apple [**xctest**](https://developer.apple.com/documentation/xctest). Developed with readability and reliability in mind it brings the following features:    

- Builder like syntax reduces the test code boilerplate.
- Multiple `XCUIElement` matchers can be applied in a single line of code to locate desired element. 
- Built in explicit waits will ensure that the `XCUIElement` is in desired state before doing an action or performing an assertion on it.
- Already implemented functions like `swipeDownUntilVisible()`, `swipeUpUntilVisible()` and `waitUntilGone()` eliminate the need to implement them on your own.
- Easy to use `onChild()` and `onDescendant()` functions allow you to point your actions or assertions to the desired `XCUIElement` that belongs to the located ancestor.
- Simplified UI interruption mechanism makes it easier to add UI interruptions monitor for a single element or group of elements of the same type.

### Table of contents
1. [Installation](#installation)
2. [Usage](#usage)
    - [Getting started](#getting_started)cell(cellIdentifier).checkDoesNotExist()
    - [Locating the element](#locate)
    - [Performing actions on element](#act)
    - [Checking element states](#check)
    - [Waiting for element states](#wait)
    - [Working with UI interruption monitor](#monitor)

### Installation <a name="installation"></a>
#### CocoaPods
**pmtest** is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod 'pmtest'
```
Then run `pod install` in the project directory to install.

### Usage <a name="usage"></a>

#### Getting started <a name="getting_started"></a>

To start using the `pmtest` you should select one of the below options:
1. Extend your test class with `CoreTestCase` class which extends XCTestCase class and then access any element by its type.
   ```swift
   class SampleTestCase: CoreTestCase {
   
      func testLoginSample() {
         /// Type text into TextField.
         textField(usernameTextFieldlocator).typeText("username")
   
         /// Tap, clear text and then type text into SecureTextField.
         secureTextField(passwordSecureTextFieldidentifier).tap().clearText().typeText("password")
   
         /// Tap login button and wait until it is gone.
         button(loginButtonidentifier).tap().waitUntilGone()
   
         /// Check that login successful Static text exists.
         staticText(loggedInStaticTextidentifier).checkExists()
      }
   }
   ```
   
2. If you follow a page object test design pattern extend your page class with `CoreElements`. Afterwards you will have direct access to all element types:

   ```swift
   class LoginRobot: CoreElements {

      func typePassword(_ password: String) -> LoginRobot {
         secureTextField(passwordTextFieldIdentifier).tap().typeText(password)
         return self
      }
    
      func typeUsername(_ username: String) -> LoginRobot {
         textField(loginTextFieldIdentifier).tap().typeText(username)
         return self
      }
    
      func signIn() -> MainRobot() {
         button(signInButtonIdentifier).tap()
         return MainRobot()
      }
   }
   ```

#### Locating the element <a name="locate"></a>

Different strategies can be applied in order to locate the UI element depending on layout hierarchy complexity:

1. Locating element **by index**:

   ```swift
   button().byIndex(1).tap()
   ```
   
2. Locating element by **`label`**, **`accessibilityIdentifier`** or **`predicate`** may be used in case of simple layout. Here it is enough to call the function that represents the element type, providing `label`, `accessibilityIdentifier` or `predicate` as a parameter:     
   
   ```swift
   button(signInButtonLabel).tap()
   ```
   ```swift
   textField(loginTextFieldAccessibilityIdentifier).typeText(username)
   ```
   
3. In more complex layout case when many UI elements may share the same identifiers multiple matchers can be applied to locate the element:

   ```swift
   button("nonUniqueButtonIdentifier").isEnabled().hasLabel("buttonLabel").tap()
   ```
   
   Here each additional matcher narrows down the search applying different matchers to the same element type.
   When this is not enough, you can use the `.byIndex(n)` matcher narrowing down the search query to the single element.

   ```swift
   button("nonUniqueButtonIdentifier").hasLabel("buttonLabel").byIndex(2).tap()
   ```

> NOTE: Ideally each actionable UI element should have the accessibility identifier assigned. Having it in place makes test automation more robust, easy to maintain and provides multi-language support.    

4. Locating the **child** element:
   - Identify parent element and then provide a child `UiElement` instance as a parameter to `onChild()` function:

     ```swift
     cell(cellIdentifier).onChild(button(childButtonIdentifier)).tap()
     ```
     
   - Other examples:
     ```swift
     cell().byIndex(0).onChild(button(childButtonIdentifier)).tap()
     ```
     ```swift
     cell(cellIdentifier).onChild(button(childButtonIdentifier).isEnabled()).tap()
     ```
     ```swift
     cell(cellIdentifier).onChild(button().byIndex(0)).tap()
     ```
   
5. Locating **descendant** element:
   - Similar to `onChild()` function you can locate the ancestor descendant using the `onDescendant()` function:
     ```swift
     cell(cellIdentifier).onDescendant(button(childButtonIdentifier)).tap()
     ```
     ```swift
     cell(cellIdentifier).onDescendant(button(childButtonIdentifier).isEnabled()).tap()
     ```

List of all available matchers:
- `byIndex(_ index: Int)` - matches element by index.
- `isEnabled()` - matches enabled element.
- `isDisabled()` - matches disabled element.
- `isHittable()` - matches hittable element.
- `inTable(_ table: UiElement)` - specifies in which table to perform an action. Used in combination with ***swipe*** actions.
- `matchesPredicate(_ matchedPredicate: NSPredicate)` - matches an element matched by `NSPredicate`.
- `hasLabel(_ label: String)` - matches an element that has given **label**.
- `hasLabel(_ labelPredicate: NSPredicate)` - matches an element that has **label** matched by `NSPredicate`.
- `hasTitle(_ title: String)` - matches an element that has given **title**.
- `hasTitle(_ titlePredicate: NSPredicate)` - matches an element that has **title** matched by `NSPredicate`.
- `hasValue(_ value: String)` - matches an element that has given **value**.
- `hasValue(_ valuePredicate: NSPredicate)` - matches an element that has **value** matched by `NSPredicate`.

#### Performing actions on element <a name="act"></a>

**pmtest** supports the majority of actions available in **xctest** framework. Actions should follow the element locator and can be bundled one after another. For example:

```swift
secureTextField(passwordSecureTextFieldidentifier).tap().clearText().typeText("password")
```

Actions will be executed in the same order as they are applied to the element.

Before each action **pmtest** framework explicitly waits for element existence up to 10 seconds timeout (adjustable). If element does not exist when timeout is reached an attempt to click non-existing element will be made and test will fail.
In case element exists - test will immediately proceed.

List of available actions:
- `adjust(to value: String)` - adjusts picker wheel to provided value. 

- `clearText()` - deletes text from text field.

- `doubleTap()` - double tap the element.

- `multiTap(_ count: Int)` - tap the element multiple times.

- `forceTap()` - gets the element coordinates and triggers tap action on them. 

- `longPress(_ timeInterval: TimeInterval = 2)` - long press the element with provided time interval. Default value is 2 seconds.

- `swipeDown()` - swipes element down.

- `swipeLeft()` - swipes element left.

- `swipeRight()` - swipes element right.

- `swipeUp()` - swipes element up.

- `tap()` - taps element.

- `typeText(_ text: String)` - types text into the element.

- `swipeUpUntilVisible(maxAttempts: Int = 5)` - swipes up inside the table view until element is visible on the screen. Default max attempts amount = 5. If there is more than one table view in layout hierarchy, `inTable()` matcher should be applied to specify in which table to swipe.

    ```swift
    cell(cellIdentifier).swipeUpUntilVisible()
   ```

    ```swift
    cell(cellIdentifier).inTable(table(tableIdentifier)).swipeUpUntilVisible()
   ```

    ```swift
    cell(cellIdentifier).inTable(table().byIndex(1)).swipeUpUntilVisible(10)
   ```

- `swipeDownUntilVisible(maxAttempts: Int = 5)` - swipes down inside the table view until element is visible on the screen. Default max attempts amount = 5. If there is more than one table view in layout hierarchy, `inTable()` matcher should be applied to specify in which table to swipe.

#### Checking element states <a name="check"></a>

List of available check functions:
- `checkExists()` - checks that element exists.
- `checkIsHittable()` - checks that element is hittable - i.e. a hit point can be computed for the element for the purpose of synthesizing events.
```swift
cell(cellIdentifier).checkIsHittable()
```
- `checkDoesNotExist()` - checks that element does not exist.
```swift
cell(cellIdentifier).checkDoesNotExist()
```
- `checkHasChild(_ childElement: UiElement)` - checks that element has a direct child specified by `UiElement` parameter.
```swift
cell(cellIdentifier).checkHasChild(button(buttonIdentifier))
```
- `checkHasDescendant(_ descendantElement: UiElement)` - checks that element has a descendant specified by `UiElement` parameter.
- `checkHasLabel(_ label: String)` - checks that element has label equal to the one provided.
- `checkHasValue(_ value: String)` - checks that element has value equal to the one provided.
- `checkHasTitle(_ title: String)` -  checks that element has title equal to the one provided.

> NOTE: All checks are executed immediately without waiting for element states. You have to use one of the wait functions when you expect specific element state.

#### Waiting for element states <a name="wait"></a>
Waits can be used for validation purposes or when specific element state is needed before performing an action, or when checking that element does not exist.
List of available wait functions:
- `wait(time: TimeInterval = 10.0)` - explicitly waits for element existence. Default timeout 10 seconds. Immediately returns `UiElement` instance when element exists.
- `waitForHittable(time: TimeInterval = 10.0)` - explicitly waits for element to be hittable. Default timeout 10 seconds. Immediately returns `UiElement` instance when element exists.
- `waitForEnabled(time: TimeInterval = 10.0)` - explicitly waits for element to be enabled. Default timeout 10 seconds. Immediately returns `UiElement` instance when element exists.
- `waitForDisabled(time: TimeInterval = 10.0)` - explicitly waits for element to be disabled. Default timeout 10 seconds. Immediately returns `UiElement` instance when element exists.
- `waitUntilGone(time: TimeInterval = 10.0` - explicitly waits for element to disappear. Default timeout 10 seconds.

```swift
button(buttonIdentifier).waitForHittable().tap()
```

```swift
cell(cellIdentifier).waitUntilGone(5)
```

#### Working with UI interruption monitor <a name="monitor"></a>
From Apple [**xctest**](https://developer.apple.com/documentation/xctest) documentation:
>A "UI interruption" is any element which unexpectedly blocks access to an element with which a UI test is trying to interact. Interrupting elements are most commonly alerts, dialogs, or other windows, but can be of other types as well. Interruptions are unexpected or at least not deterministic: the appearance of an alert in direct response to a test action such as clicking a button is not an interruption and should not be handled using a UI interruption monitor. Instead, it's simply part of the UI and should be found using standard queries and interacted with using standard event methods. Note that some interruptions are part of the app's own UI, others are presented on behalf of system apps and services, so queries for these elements must be constructed with the right process at their root.

**pmtest** simplifies a way to register UI interruption monitor. You can add it in two ways:
1. `addUIMonitor(elementToTap: XCUIElement)` - register a single element to monitor for and tap on it when it blocks other element.
2. `addUIMonitor(elementsQuery: XCUIElementQuery, identifiers: [String])` - register the type of the elements to monitor for together with an array of their locators (labels, accessibility identifiers) and tap on monitored element when it blocks test code execution.

```swift
import XCTest

class SampleTestCase: XCTestCase {
    
    var okButtonMonitor: NSObjectProtocol? = nil
    var buttonsToMonitor: NSObjectProtocol? = nil
    
    open override func setUp() {
        super.setUp()
        okButtonMonitor = addUIMonitor(elementToTap: XCUIApplication().buttons["OK"])
        buttonsToMonitor = addUIMonitor(elementsQuery: XCUIApplication().buttons, identifiers: ["OK", "Allow"])
    }

    open override func tearDown() {
        if okButtonMonitor != nil { removeUIInterruptionMonitor(okButtonMonitor!) }
        if buttonsToMonitor != nil { removeUIInterruptionMonitor(buttonsToMonitor!) }
        super.tearDown()
    }
}
```

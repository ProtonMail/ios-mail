## fusion

**fusion** is a lightweight and easy-to-use UI testing framework built on top of Apple XCTest. Developed with readability and reliability in mind, it brings the following features:

- Builder-like syntax reduces test code boilerplate.
- Multiple XCUIElement matchers can be applied in a single line of code to locate the desired element.
- Built-in explicit waits ensure that the XCUIElement is in the desired state before performing an action or assertion on it.
- Pre-implemented functions like `swipeDownUntilVisible()`, `swipeUpUntilVisible()`, and `waitUntilGone()` eliminate the need to implement them on your own.
- Easy-to-use `onChild()` and `onDescendant()` functions allow you to target actions or assertions to desired XCUIElement(s) that belong to the located ancestor.
- A simplified UI interruption mechanism makes it easier to add UI interruption monitors for a single element or a group of elements of the same type.

## Contributing
If you would like to contribute, please keep in mind the following rules:
- Try to stick to the project's existing code style and naming conventions

By making a contribution to this project you agree to the following:
- [x] I assign any and all copyright related to the contribution to Proton Technologies AG;
- [x] I certify that the contribution was created in whole by me;
- [x] I understand and agree that this project and the contribution are public and that a record of the contribution (including all personal information I submit with it) is maintained indefinitely and may be redistributed with this project or the open source license(s) involved.


## Table of Contents

- [Installation](#installation)
- [Usage](#usage)
  - [Getting Started](#getting-started)
  - [Getting Started on macOS](#getting-started-on-macos)
  - [Locating the Element](#locating-the-element)
  - [Performing Actions on Element](#performing-actions-on-element)
  - [Checking Element States](#checking-element-states)
  - [Waiting for Element States](#waiting-for-element-states)
  - [Working with UI Interruption Monitor](#working-with-ui-interruption-monitor)

### Installation <a name="installation"></a>
#### CocoaPods

1) `fusion` is available through CocoaPods. To install it, simply add the following line to your Podfile:

```ruby
   pod 'fusion'
```
Then run `pod install` in the project directory to install.

#### Swift Package Manager

2) `fusion` is available through SPM. To install it, simply add this github url to your project under the package dependencies. 

### Usage <a name="usage"></a>

#### Getting started <a name="getting-started"></a>

To start using `fusion`, you have two options:

Extend your test class with `CoreTestCase`, which extends XCTestCase. This allows you to access any element by its type.

```swift
import fusion

class SampleTestCase: CoreTestCase {

   func testLoginSample() {
      // Type text into TextField.
      textField(usernameTextFieldLocator).typeText("username")

      // Tap, clear text, and then type text into SecureTextField.
      secureTextField(passwordSecureTextFieldIdentifier).tap().clearText().typeText("password")

      // Tap the login button and wait until it is gone.
      button(loginButtonidentifier).tap().waitUntilGone()

      // Check that the login successful Static text exists.
      staticText(loggedInStaticTextidentifier).checkExists()
   }
}

```
Follow the page object test design pattern
2) If you follow the page object test design pattern, extend your page class with `CoreElements`. Afterward, you will have direct access to all element types.


```swift
import fusion

class LoginRobot: CoreElements {

   func typePassword(_ password: String) -> LoginRobot {
      secureTextField(passwordTextFieldIdentifier).tap().typeText(password)
      return self
   }
 
   func typeUsername(_ username: String) -> LoginRobot {
      textField(loginTextFieldIdentifier).tap().typeText(username)
      return self
   }
 
   func signIn() -> MainRobot {
      button(signInButtonIdentifier).tap()
      return MainRobot()
   }
}

```
#### Getting Started on macOS <a name="getting-started-on-macos"></a>


To start using `fusion` on macOS, follow the same options as for iOS.

##### Locating the element <a name="locating-the-element"></a>
Different strategies can be applied to locate the UI element depending on the layout hierarchy complexity.

Locating element by index:
```swift
button().byIndex(1).tap()
```
Locating element by label, accessibilityIdentifier, or predicate:
```swift
button(signInButtonLabel).tap()

textField(loginTextFieldAccessibilityIdentifier).typeText(username)
```
Applying multiple matchers to locate the element:

```swift
button("nonUniqueButtonIdentifier").isEnabled().hasLabel("buttonLabel").tap()
```
Locating the child element:
Identify the parent element and then provide a child UiElement instance as a parameter to onChild() function:

```swift
cell(cellIdentifier).onChild(button(childButtonIdentifier)).tap()
```
Locating the descendant element:
Similar to onChild() function, you can locate the ancestor's descendant using the onDescendant() function:

```swift
cell(cellIdentifier).onDescendant(button(childButtonIdentifier)).tap()
```

#### Performing Actions on Element <a name="performing-actions-on-element"></a>

`fusion` supports the majority of actions available in XCTest framework. Actions should follow the element locator and can be bundled one after another. For example:

```swift
secureTextField(passwordSecureTextFieldIdentifier).tap().clearText().typeText("password")
```
Actions will be executed in the same order as they are applied to the element. Before each action, fusion framework explicitly waits for element existence with a timeout of 10 seconds (adjustable). If the element does not exist when the timeout is reached, an attempt to interact with the non-existing element will be made, and the test will fail. If the element exists, the test will proceed immediately.

#### Checking Element States <a name="checking-element-states"></a>

`fusion` provides various check functions to validate the state of an element.

```swift
cell(cellIdentifier).checkExists()

cell(cellIdentifier).checkIsHittable()

cell(cellIdentifier).checkDoesNotExist()

cell(cellIdentifier).checkHasChild(button(buttonIdentifier))

cell(cellIdentifier).checkHasDescendant(button(childButtonIdentifier))
```

#### Waiting for Element States <a name="waiting-for-element-states"></a>
Waits can be used for validation purposes or when waiting for a specific element state before performing an action or checking the non-existence of an element.

```swift
button(buttonIdentifier).waitForHittable().tap()

cell(cellIdentifier).waitUntilGone(5)

staticText(staticTextIdentifier).waitUntilExists().checkExists()
```

#### Working with UI Interruption Monitor <a name="working-with-ui-interruption-monitor"></a>

`fusion` simplifies the process of registering a UI interruption monitor, which allows you to handle elements that unexpectedly block access to other elements during UI testing.

You can register a UI interruption monitor in two ways:

Registering a single element to monitor:
```swift
addUIMonitor(elementToTap: XCUIApplication().buttons["OK"])
```
This registers a single element to monitor and taps on it when it blocks other elements.

Registering a group of elements to monitor:
```swift
addUIMonitor(elementsQuery: XCUIApplication().buttons, identifiers: ["OK", "Allow"])
```
This registers the type of elements to monitor (e.g., buttons) together with an array of their locators (labels, accessibility identifiers) and taps on the monitored element when it blocks the test code execution.

Remember to remove the UI interruption monitors in the tearDown() method of your test class to clean up after the test.

```swift
removeUIInterruptionMonitor(okButtonMonitor!)

removeUIInterruptionMonitor(buttonsToMonitor!)
```


```swift

    override func setUp() {
       ... setup multiple things
       handleInterruption()
    }
    
    func handleInterruption() {
        let labels = ["Allow", "Don’t Allow"]
        /// Adds UI interruption monitor that queries all buttons and clicks if identifier is in the labels array. It is triggered when system alert interrupts the test execution.
        addUIMonitor(elementQueryToTap: XCUIApplication(bundleIdentifier: "com.apple.springboard").buttons, identifiers: labels)
    }
```
These examples provide an overview of how to use fusion for UI testing.

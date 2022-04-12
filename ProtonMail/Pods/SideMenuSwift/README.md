# ![](https://github.com/kukushi/SideMenu/blob/develop/Images/Logo.png?raw=true)

[![Version](https://img.shields.io/cocoapods/v/SideMenuSwift.svg?style=flat-square)](http://cocoapods.org/pods/SideMenuSwift)
![Swift5](https://img.shields.io/badge/Swift-5.0-orange.svg?style=flat%22)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat-square)](https://github.com/Carthage/Carthage)
[![License](https://img.shields.io/cocoapods/l/SideMenuSwift.svg?style=flat-square)](http://cocoapods.org/pods/SideMenuSwift)
[![Platform](https://img.shields.io/cocoapods/p/SideMenuSwift.svg?style=flat-square)](http://cocoapods.org/pods/SideMenuSwift)

## Overview

*SideMenu* is an easy-to-use side menu container controller written in Swift 5.

Besides all the features a *Side Menu* should have, it supports:

- Four kinds of status bar behaviors (iOS 12 and earlier)
- Three different menu position
- Both storyboard and programmatically
- Caching the content view controller and lazy initialization
- Rubber band effect while panning
- Custom transition animation
- RTL supports
- [API References](https://kukushi.github.io/SideMenu)

## Preview

Menu Position / Status Menu Behavior

| Above + None | Below + Slide |
| --- | --- |
| ![](https://raw.githubusercontent.com/kukushi/SideMenu/master/Images/Above%2BNone.gif) | ![](https://raw.githubusercontent.com/kukushi/SideMenu/master/Images/Below%2BSlide.gif) |

| SideBySide + Fade | SideBySide + HideOnMenu |
| --- | --- |
| ![](https://raw.githubusercontent.com/kukushi/SideMenu/master/Images/SideBySide%2BFade.gif) | ![](https://raw.githubusercontent.com/kukushi/SideMenu/master/Images/SideBySide%2BHideOnMenu.gif) |

We call the left/right view controller as the **menu** view controller, the central view controller as **content** view controller.

## Installation

For Swift 5, please use 2.0.0 or later version.

> For Swift 4.0, please using 0.5.1 or earlier version.
> For Swift 4.2, please using 1.x

### CocoaPods

To install `SideMenu` with [CocoaPods](http://cocoapods.org/), add the below line in your `Podfile`:

```ruby
pod 'SideMenuSwift'
# Note it's NOT 'SideMenu'
```
### Carthage

To install `SideMenu` with [Carthage](https://github.com/Carthage/Carthage), add the below line in your `Cartfile`:

```
github "kukushi/SideMenu" "master"
```

## Usages

### Storyboard

<details>
<summary>
To set up `SideMenu` in storyboard:
</summary>


1. Open the view controller's *Identity inspector*. Change its **Class** to `SideMenuController` and **Module** to `SideMenuSwift`.
2. Set up the menu view controller and the initial content view controller in your Storyboard. Add a **Custom** segue from the `SideMenuController` to each of them.
    - Change the menu segue's identifier to `SideMenu.Menu`, **Class** to `SideMenuSegue` and **Module** to `SideMenuSwift`.
    - Change the content segue's identifier to `SideMenu.Content`, **Class** to `SideMenuSegue` and **Module** to `SideMenuSwift`.
4. (Optional) If you want to use custom segue identifier:
   - Open the `SideMenuController`'s *Attribute inspector*.
   - In the **Side Menu Controller** section, modify the *Content SegueID/Menu SegueID* to the desired value and change the corresponding segue's identifier.
5. It's done. Check [this screenshot](https://github.com/kukushi/SideMenu/blob/develop/Images/StoryboardSample.png?raw=true) a for clear view.
</details>

### Programmatically

<details>
<summary>
To start the app with `SideMenu` programmatically:
</summary>

```swift
import UIKit
import SideMenuSwift
// If you are using Carthage, uses `import SideMenu`

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    @objc func applicationDidFinishLaunching(_ application: UIApplication) {
        let contentViewController = ...
        let menuViewController = ...

        window = UIWindow(frame: UIScreen.main.bounds)
        window?.rootViewController = SideMenuController(contentViewController: contentViewController, 
        menuViewController: menuViewController)
        
        window?.makeKeyAndVisible()
        return true
    }
}
```
</details>

Use the `sideMenuController` method which provided in `UIViewController`'s extension to get the parent `SideMenuController`:

```swift
viewController.sideMenuController?.revealMenu()
```

### Preferences

All the preferences of SideMenu can be found in `SideMenuController.preferences`. Its recommend to check out the `Example` to see how those options will take effect.

```swift
SideMenuController.preferences.basic.menuWidth = 240
SideMenuController.preferences.basic.statusBarBehavior = .hideOnMenu
SideMenuController.preferences.basic.position = .below
SideMenuController.preferences.basic.direction = .left
SideMenuController.preferences.basic.enablePanGesture = true
SideMenuController.preferences.basic.supportedOrientations = .portrait
SideMenuController.preferences.basic.shouldRespectLanguageDirection = true

// See a lot more options on `Preferences.swift`.
```

### Caching the Content

One of the coolest features of SideMenu is caching. 

```swift
// Cache the view controllers somewhere in your code
sideMenuController?.cache(viewController: secondViewController, with: "second")
sideMenuController?.cache(viewController: thirdViewController, with: "third")

// Switch to it when needed
sideMenuController?.setContentViewController(with: "second")
```

What about the content view controller initialized from the Storyboard? We can use the preferences to apply a default key for it!

```swift
SideMenuController.preferences.basic.defaultCacheKey = "default"
```

What if we can't want to load all the content view controllers so early? We can use lazy caching:

```Swift
sideMenuController?.cache(viewControllerGenerator: { self.storyboard?.instantiateViewController(withIdentifier: "SecondViewController") }, with: "second")
sideMenuController?.cache(viewControllerGenerator: { self.storyboard?.instantiateViewController(withIdentifier: "ThirdViewController") }, with: "third")
```

## Requirements

- Xcode 10 or later
- iOS 9.0 or later

## License

SideMenu is available under the MIT license. See the LICENSE file for more info.

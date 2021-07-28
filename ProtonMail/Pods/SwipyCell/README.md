SwipyCell
---------
[![Awesome](https://cdn.rawgit.com/sindresorhus/awesome/d7305f38d29fed78fa85652e3a63e154dd8e8829/media/badge.svg)](https://github.com/sindresorhus/awesome)
[![Build Status](https://travis-ci.org/moritzsternemann/SwipyCell.svg)](https://travis-ci.org/moritzsternemann/SwipyCell)
[![Swift Copatibility](https://img.shields.io/endpoint?url=https%3A%2F%2Fswiftpackageindex.com%2Fapi%2Fpackages%2Fmoritzsternemann%2FSwipyCell%2Fbadge%3Ftype%3Dswift-versions)](https://swiftpackageindex.com/moritzsternemann/SwipyCell)
[![CocoaPods Compatible](https://img.shields.io/cocoapods/v/SwipyCell.svg)](https://github.com/moritzsternemann/SwipyCell)
[![Platform](https://img.shields.io/cocoapods/p/SwipyCell.svg)](https://github.com/moritzsternemann/SwipyCell)
[![GitHub license](https://img.shields.io/badge/license-MIT-blue.svg)](https://raw.githubusercontent.com/moritzsternemann/SwipyCell/master/LICENSE)
[![Twitter](https://img.shields.io/badge/twitter-@strnmn-blue.svg?style=flat)](https://twitter.com/strnmn)

*Swipeable UITableViewCell inspired by the popular [Mailbox App](http://mailboxapp.com), implemented in [Swift](https://github.com/apple/swift).*

<p align="center"><img src=".github/images/swipycell-hero.jpg" width="50%"/></p>

## Preview

### Exit Mode

The `.exit` mode is the original behavior, known from the Mailbox app.
<p align="center"><img src=".github/images/swipycell-exit.gif" width="50%"/></p>

### Toggle Mode

The `.toggle` is another behavior where the cell will bounce back after swiping it.
<p align="center"><img src=".github/images/swipycell-switch.gif" width="50%"/></p>

## Installation

### Swift Package Manager (recommended)
[Swift Package Manger](https://github.com/apple/swift-package-manager) is Apples first party tool for managing distribution of source code, aimed at making it easy to share your code and reuse others’ code.

To use the `SwipyCell` library in a SwiftPM project, add the following line to the dependencies in your `Package.swift` file:

```swift
.package(url: "https://github.com/moritzsternemann/SwipyCell", .upToNextMinor(from: "4.1.0")),
```

### CocoaPods
[CocoaPods](https://cocoapods.org) is a dependency manager for Cocoa projects.

To integrate SwipyCell into your project using CocoaPods, add it to your `Podfile`:
```
pod 'SwipyCell', '~> 4.1'
```

### Carthage
[Carthage](https://github.com/Carthage/Carthage) is a decentralized dependency manager that automates the process of adding frameworks to your Cocoa application.

To integrate SwipyCell into your project using Carthage, add it to your `Cartfile`:
```
github "moritzsternemann/SwipyCell" >= 4.1
```

## Usage
### Example
A complete example is available in the [Example](https://github.com/moritzsternemann/SwipyCell/tree/master/Example) directory.
The following code is a very basic example:
```swift
override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! SwipyCell
    cell.selectionStyle = .gray
    cell.contentView.backgroundColor = UIColor.white

    let checkView = viewWithImageName("check")
    let greenColor = UIColor(red: 85.0 / 255.0, green: 213.0 / 255.0, blue: 80.0 / 255.0, alpha: 1.0)

    let crossView = viewWithImageName("cross")
    let redColor = UIColor(red: 232.0 / 255.0, green: 61.0 / 255.0, blue: 14.0 / 255.0, alpha: 1.0)

    let clockView = viewWithImageName("clock")
    let yellowColor = UIColor(red: 254.0 / 255.0, green: 217.0 / 255.0, blue: 56.0 / 255.0, alpha: 1.0)

    let listView = viewWithImageName("list")
    let brownColor = UIColor(red: 206.0 / 255.0, green: 149.0 / 255.0, blue: 98.0 / 255.0, alpha: 1.0)

    cell.defaultColor = tableView.backgroundView?.backgroundColor
    cell.delegate = self

    cell.textLabel?.text = "Switch Mode Cell"
    cell.detailTextLabel?.text = "Swipe to switch"

    cell.addSwipeTrigger(forState: .state(0, .left), withMode: .toggle, swipeView: checkView, swipeColor: greenColor, completion: { cell, trigger, state, mode in
        print("Did swipe \"Checkmark\" cell")
    })

    cell.addSwipeTrigger(forState: .state(1, .left), withMode: .toggle, swipeView: crossView, swipeColor: redColor, completion: { cell, trigger, state, mode in
        print("Did swipe \"Cross\" cell")
    })

    cell.addSwipeTrigger(forState: .state(0, .right), withMode: .toggle, swipeView: clockView, swipeColor: yellowColor, completion: { cell, trigger, state, mode in
        print("Did swipe \"Clock\" cell")
    })

    cell.addSwipeTrigger(forState: .state(1, .right), withMode: .toggle, swipeView: listView, swipeColor: brownColor, completion: { cell, trigger, state, mode in
        print("Did swipe \"List\" cell")
    })

    return cell
}
```

### SwipyCellState
SwipyCellState represents a sliding state, for example the first state to the left of the cell.<br>
The possible values are
 - `.none` - center position of the cell
 - `.state(index, side)` - *index* of the state from near to far and *side* of the state, each relative to the cell

### SwipyCellMode
SwipyCellMode as shown above.

### SwipyCellTriggerBlock
SwipyCellTriggerBlock is a typealias for
```
(SwipyCell, SwipyCellTrigger, SwipyCellState, SwipyCellMode) -> Void
```

### Add swipe triggers to cells
Adding swipe triggers to cells is easy using this method:
```swift
func addSwipeTrigger(forState: SwipyCellState, withMode: SwipyCellMode, swipeView: UIView, swipeColor: UIColor, completion: SwipyCellTriggerBlock)
```
- `forState` at which the trigger should activate
- `withMode` for the trigger
- `swipeView`: e.g. display an icon
- `swipeColor`: backgroundColor of the swipeView
- `completion`: called after the swipe gesture has ended, only if the trigger point was reached

### Delegate
SwipyCell provides three delegate methods in order to track the users behaviors.
```swift
// When the user starts swiping the cell this method is called
func swipyCellDidStartSwiping(_ cell: SwipyCell)

// When the user ends swiping the cell this method is called
func swipyCellDidFinishSwiping(_ cell: SwipyCell, atState state: SwipyCellState, triggerActivated activated: Bool)

// When the user is dragging, this method is called with the percentage from the border
func swipyCell(_ cell: SwipyCell, didSwipeWithPercentage percentage: CGFloat, currentState state: SwipyCellState, triggerActivated activated: Bool)
```


### Configuration
All configurable options are defined in the `SwipyCellConfig.shared` singleton object. Every new cell has these options set as defaults. To alter the defaults simply change the variables of the `SwipyCellConfig` singleton object.


#### Trigger Points
Trigger points are defined in the `triggerPoints<CGFloat, SwipyCellState>` dictionary in either the configuration singleton or each cell individually.<br>
Each key marks the swiping percentage for a trigger point; the corresponding value is an identifier to reference the trigger point later. A negative key marks a point on the right side of the cell (slide to the left), a positive key marks a point on the left side of the cell (slide to the right).<br>
To modify the trigger points there are a couple of methods available on every cell as well as the configuration singleton:
```swift
// Set a new trigger point for the given state
func setTriggerPoint(forState state: SwipyCellState, at point: CGFloat)

// Set a new trigger point for the given index on BOTH sides of the cell
func setTriggerPoint(forIndex index: Int, at point: CGFloat)

// Overwrite all existing trigger points with the given new ones
func setTriggerPoints(_ points: [CGFloat: SwipyCellState])
// The Integer parameter is the index for BOTH sides of the cell
func setTriggerPoints(_ points: [CGFloat: Int])

// Overwrite all existing trigger points with new ones in order of the array on BOTH sides
func setTriggerPoints(points: [CGFloat])

// Get all existing trigger points
func getTriggerPoints() -> [CGFloat: SwipyCellState]

// Clear all existing trigger points
func clearTriggerPoints()
```
*Defaults: 25% and 75% on each side*

#### swipeViewPadding
```swift
var swipeViewPadding: CGFloat
```
swipeViewPadding is the padding between the swipe view and and the outer edge of the cell.

*Default: `24.0`*

#### shouldAnimateSwipeViews
```swift
var shouldAnimateSwipeViews: Bool
```
`shouldAnimateSwipeViews` sets if the swipeView should move with the cell while sliding or stay at the outer edge.

*Default: `true`*

#### defaultSwipeViewColor
```swift
var defaultSwipeViewColor: UIColor
```
`defaultSwipeViewColor` is the color of the swipe when the current state is `.none`.

*Default: `UIColor.white`*

### Resetting the cell position
You can animate the cell back to it's default position when using `.exit` mode using the `swipeToOrigin(_:)` method. This could be useful if your app asks the user for confirmation and the user want's to cancel the action.
```swift
cell.swipeToOrigin {
    print("Swiped back")
}
```

## Author
I'm [Moritz Sternemann](https://github.com/moritzsternemann), a computer-science student at [Technical University of Munich](https://www.tum.de/en/).
- Email: [opensource@moritzsternemann.de](mailto:opensource@moritzsternemann.de)
- Twitter: [@strnmn](https://twitter.com/strnmn)
- LinkedIn: [/in/moritzsternemann](https://www.linkedin.com/in/moritzsternemann)

## License
SwipyCell is available under the MIT license. See LICENSE file for more info.

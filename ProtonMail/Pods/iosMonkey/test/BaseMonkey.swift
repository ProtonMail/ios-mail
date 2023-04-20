//
//  BaseMonkey.swift
//
//  ProtonMail - Created on 12.09.22.
//
//  The MIT License
//
//  Copyright (c) 2022 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.

import XCTest

class RandomAction {
    var app: XCUIApplication
    var type: ActionType

    init(app: XCUIApplication, type: ActionType) {
        self.app = app
        self.type = type
    }

    func perform() {
        switch type {
        case .tap:
            let randomCoordinate = app.coordinate(withNormalizedOffset: generateRandomVector())

            if app.buttons["Crash"].exists {

                let button = app.buttons["Crash"]

                // Get the starting and ending screen points for the element
                let startingScreenPoint = button.coordinate(withNormalizedOffset: CGVector(dx: 0.0, dy: 0.0)).screenPoint
                let endingScreenPoint = button.coordinate(withNormalizedOffset: CGVector(dx: 1.0, dy: 1.0)).screenPoint

                let randomCoordinateScreenPoint = randomCoordinate.screenPoint

                if startingScreenPoint.x <= randomCoordinateScreenPoint.x && randomCoordinateScreenPoint.x <= endingScreenPoint.x && startingScreenPoint.y <= randomCoordinateScreenPoint.y && randomCoordinateScreenPoint.y <= endingScreenPoint.y {
                    // Random coordinate is within the horizontal and vertical range of the button element
                    break // should not click
                }
            }

            randomCoordinate.tap()

        case .burgermenu:
            let burgerMenu = app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.1))
            burgerMenu.tap()

        case .swipe:
            let rightEdge = app.coordinate(withNormalizedOffset: CGVector(dx: 1, dy: 0.5))
            let toCoordinate = app.coordinate(withNormalizedOffset: CGVector(dx: 0.4, dy: 0.5))
            rightEdge.press(forDuration: 0, thenDragTo: toCoordinate)

        case .contextMenu:
            let fromCoordinate = app.coordinate(withNormalizedOffset: generateRandomVector())
            fromCoordinate.press(forDuration: 1.5)
            if app.exists && app.menuItems.element.exists && app.menuItems.element.isHittable {
                UIPasteboard.general.string = "[_)(*&%!@]"
                if app.menuItems["Paste"].isHittable {
                    app.menuItems["Paste"].tap()
                }
            }

        case .goLeft:
            let arrowLeft = app.buttons["ic arrow left"]
            if arrowLeft.exists && arrowLeft.isHittable {
                arrowLeft.tap()
            }
        }
    }

    private func generateRandomVector() -> CGVector {
        let x = CGFloat(arc4random()) / CGFloat(UINT32_MAX)
        let y = CGFloat(arc4random()) / CGFloat(UINT32_MAX)
        return CGVector(dx: x, dy: y)
    }
}

enum ActionType {
    case tap
    case burgermenu
    case swipe
    case contextMenu
    case goLeft
}

open class BaseMonkey : XCTestCase{

    open var app: XCUIApplication { get { return XCUIApplication() } }
    open var stack: ScreenshotStack { ScreenshotStack(size: 10) }
    open var numberOfSteps: Int { get { return 50 } }
    open var screenshotOutputDirectory: String { get { return "" } }

    open func randomTouches() {
        let actions = [
            RandomAction(app: app, type: .tap),
            RandomAction(app: app, type: .burgermenu),
            RandomAction(app: app, type: .swipe),
            RandomAction(app: app, type: .contextMenu),
            RandomAction(app: app, type: .goLeft),
        ]

        for i in 1...numberOfSteps {
            let randomIndex = Int.random(in: 0..<actions.count)
            let randomAction = actions[randomIndex]
            app.activate()
            randomAction.perform()
            takeScreenshot(i)
        }
    }

    private func takeScreenshot(_ i: Int) {
        let screen = XCUIScreen.main
        let fullscreenshot = screen.screenshot()
        let imageData = fullscreenshot.image

        if let testRun = testRun {
            let testName = testRun.test.name
            let monkeyScreenshotName = testName + "-" + String(i)
            stack.add(MonkeyScreenshot(image: imageData, name: monkeyScreenshotName))
        }
    }

    private func tryPasteTestWordWithContextualMenu(with fromCoordinate: XCUICoordinate) {
        fromCoordinate.press(forDuration: 1.5)
        if app.exists && app.menuItems.element.exists && app.menuItems.element.isHittable {
            UIPasteboard.general.string = "[_)(*&%!@]"
            if app.menuItems["Paste"].isHittable {
                app.menuItems["Paste"].tap()
            }
        }
    }

    open func handleInterruption() -> Bool {
        addUIInterruptionMonitor(withDescription: "*") { (alert) -> Bool in
            self.tapButton(on: alert, with: "Don’t Allow")
            self.tapButton(on: alert, with: "Not Now")
            self.tapButton(on: alert, with: "Cancel")
            return true
        }
        return false
    }

    func tapButton(on alert: XCUIElement, with title: String) {
        let button = alert.buttons[title]
        if button.exists {
            button.tap()
        }
    }

    open override func tearDown() {
        if let testRun = testRun {
            if testRun.failureCount > 0 {
                Thread.callStackSymbols.forEach{print($0)}
                saveImages()
            }
        }
        super.tearDown()
        app.terminate()
    }

    func saveImages() {
        for screenshot in stack.screenshots.enumerated() {
            savePNG(imageName: screenshot.element.name, directoryName: "Screenshots", image: screenshot.element.image)
        }
    }

    public func savePNG(imageName: String, directoryName: String, image: UIImage) {
        let defaultPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let outputDirectoryURL: URL
        if !screenshotOutputDirectory.isEmpty {
            outputDirectoryURL = URL(fileURLWithPath: screenshotOutputDirectory)
        } else {
            outputDirectoryURL = defaultPath
        }
        let screenshotsDirectoryURL = outputDirectoryURL.appendingPathComponent(directoryName)
        var screenshotURL = defaultPath
        screenshotURL = screenshotsDirectoryURL.appendingPathComponent("\(imageName).png")

        // Create screenshot directory if necessary
        _ = try? FileManager.default.createDirectory(at: screenshotsDirectoryURL, withIntermediateDirectories: false, attributes: nil)
        // Remove existing file with the same name
        _ = try? FileManager.default.removeItem(at: screenshotURL)

        do {
            try image.pngData()?.write(to: screenshotURL, options: [.atomic])
            print("\(imageName) saved to \(screenshotURL)")
        } catch {
            print("Cannot save image to \(screenshotURL) \nError: \(error)")
        }
    }
}


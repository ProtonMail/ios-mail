// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Mail.
//
// Proton Mail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Mail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Mail. If not, see https://www.gnu.org/licenses/.

import SnapshotTesting
import SwiftUI
import XCTest

public func assertSelfSizingSnapshot(
    of view: some View,
    styles: Set<UIUserInterfaceStyle> = [.light, .dark],
    drawHierarchyInKeyWindow: Bool = false,
    preferredWidth: CGFloat = ViewImageConfig.iPhoneX.size!.width,
    named name: String? = nil,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
) {
    let view = UIHostingController(rootView: view).view.unsafelyUnwrapped

    assertCustomHeightSnapshot(
        matching: view,
        styles: styles,
        drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
        preferredHeight: view.calculatePreferredHeight(preferredWidth: preferredWidth),
        preferredWidth: preferredWidth,
        named: name,
        record: recording,
        timeout: timeout,
        file: file,
        testName: testName,
        line: line
    )
}

public func assertSnapshots(
    matching controller: @autoclosure () throws -> UIViewController,
    on configurations: [(String, ViewImageConfig)],
    named name: String? = nil,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
) {
    configurations.forEach { (configurationName, configuration) in
        let name = [name, configurationName].compactMap { $0 }.joined(separator: "_")
        let styles: [UIUserInterfaceStyle] = [.light, .dark]

        try? styles.forEach { style in
            let controller = try controller()
            controller.overrideUserInterfaceStyle = style

            assertSnapshot(
                of: controller,
                as: .image(on: configuration),
                named: suffixedName(name: name, withStyle: style),
                record: recording,
                timeout: timeout,
                file: file,
                testName: testName,
                line: line
            )
        }
    }
}

public func assertCustomHeightSnapshot(
    matching view: UIView,
    styles: Set<UIUserInterfaceStyle> = [.light, .dark],
    drawHierarchyInKeyWindow: Bool = false,
    preferredHeight: CGFloat,
    preferredWidth: CGFloat = ViewImageConfig.iPhoneX.size!.width,
    named name: String? = nil,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
) {
    styles.forEach { style in
        view.overrideUserInterfaceStyle = style

        assertSnapshot(
            of: view,
            as: .image(
                drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
                size: .init(width: preferredWidth, height: preferredHeight)
            ),
            named: suffixedName(name: name, withStyle: style),
            record: recording,
            timeout: timeout,
            file: file,
            testName: testName,
            line: line
        )
    }
}

public func assertSnapshotsOnIPhoneX(
    of view: some View,
    named name: String? = nil,
    drawHierarchyInKeyWindow: Bool = false,
    precision: Float = 1,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
) {
    let styles: [UIUserInterfaceStyle] = [.light, .dark]
    styles.forEach { style in
        assertSnapshotOnIPhoneX(
            of: UIHostingController(rootView: view),
            style: style,
            drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
            named: name,
            precision: precision,
            record: recording,
            timeout: timeout,
            file: file,
            testName: testName,
            line: line
        )
    }
}

// MARK: - Private

private func assertSnapshotOnIPhoneX(
    of controller: UIViewController,
    style: UIUserInterfaceStyle = .light,
    drawHierarchyInKeyWindow: Bool = false,
    named name: String? = nil,
    precision: Float = 1,
    record recording: Bool = false,
    timeout: TimeInterval = 5,
    file: StaticString = #file,
    testName: String = #function,
    line: UInt = #line
) {
    controller.overrideUserInterfaceStyle = style
    let strategy: Snapshotting<UIViewController, UIImage> = drawHierarchyInKeyWindow ? .image(
        drawHierarchyInKeyWindow: drawHierarchyInKeyWindow,
        precision: precision,
        size: ViewImageConfig.iPhoneX.size
    ) : .image(on: .iPhoneX(.portrait), precision: precision)

    assertSnapshot(
        of: controller,
        as: strategy,
        named: suffixedName(name: name, withStyle: style),
        record: recording,
        timeout: timeout,
        file: file,
        testName: testName,
        line: line
    )
}

private func suffixedName(name: String?, withStyle style: UIUserInterfaceStyle) -> String? {
    [name, style.humanReadable]
        .compactMap { $0 }
        .joined(separator: "_")
}

private extension UIUserInterfaceStyle {

    var humanReadable: String {
        switch self {
        case .dark:
            return "dark"
        case .light:
            return "light"
        case .unspecified:
            return "unspecified"
        @unknown default:
            return "unknown"
        }
    }

}

private extension UIView {
    func calculatePreferredHeight(preferredWidth: CGFloat) -> CGFloat {
        let widthConstraint = NSLayoutConstraint(
            item: self,
            attribute: .width,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: preferredWidth
        )
        addConstraint(widthConstraint)
        let height = systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        removeConstraint(widthConstraint)
        return height
    }

    func systemLayoutSizeFitting(width: CGFloat) -> CGSize {
        systemLayoutSizeFitting(
            .init(width: width, height: 1),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .defaultLow
        )
    }
}

extension Array where Element == (String, ViewImageConfig) {

    public static var allPhones: [Element] {
        return [
            ("iPhoneSe", .iPhoneSe),
            ("iPhoneX", .iPhoneX),
            ("iPhone13ProMax", .iPhone13ProMax)
        ]
    }

}

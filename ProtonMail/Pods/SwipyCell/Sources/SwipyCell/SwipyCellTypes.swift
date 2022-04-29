//
//  SwipyCellTypes.swift
//  SwipyCell
//
//  Created by Moritz Sternemann on 20.01.16.
//  Copyright © 2016 Moritz Sternemann. All rights reserved.
//

import UIKit

fileprivate struct Defaults {
    static let stop1: CGFloat               = 0.25  // Percentage limit to trigger the first action
    static let stop2: CGFloat               = 0.75  // Percentage limit to trigger the second action
    static let swipeViewPadding: CGFloat    = 24.0  // Padding of the swipe view (space between cell and swipe view)
    static let shouldAnimateSwipeViews      = true
    static let defaultSwipeViewColor        = UIColor.white
}

public typealias SwipyCellTriggerBlock = (SwipyCell, SwipyCellTrigger, SwipyCellState, SwipyCellMode) -> Void

public protocol SwipyCellDelegate: AnyObject {
    func swipyCellDidStartSwiping(_ cell: SwipyCell)
    func swipyCellDidFinishSwiping(_ cell: SwipyCell, atState state: SwipyCellState, triggerActivated activated: Bool)
    func swipyCell(_ cell: SwipyCell, didSwipeWithPercentage percentage: CGFloat, currentState state: SwipyCellState, triggerActivated activated: Bool)
}

public class SwipyCellTrigger {
    init(mode: SwipyCellMode, color: UIColor, view: UIView, block: SwipyCellTriggerBlock?) {
        self.mode = mode
        self.color = color
        self.view = view
        self.block = block
    }

    public var mode: SwipyCellMode
    public var color: UIColor
    public var view: UIView
    public var block: SwipyCellTriggerBlock?

    func executeTriggerBlock(withSwipyCell cell: SwipyCell, state: SwipyCellState) {
        block?(cell, self, state, mode)
    }
}

public enum SwipyCellState: Hashable {
    case none
    case state(Int, SwipyCellDirection)

    public func hash(into hasher: inout Hasher) {
        hasher.combine(integerRepresentation)
    }

    static public func ==(lhs: SwipyCellState, rhs: SwipyCellState) -> Bool {
        return lhs.integerRepresentation == rhs.integerRepresentation
    }

    private var integerRepresentation: Int {
        switch self {
        case .none:
            return 0
        case .state(let stateNum, let stateDirection):
            // add one because state(0,...) would always be 0
            if stateDirection == .left {
                return stateNum + 1
            } else if stateDirection == .right {
                return -(stateNum + 1)
            }
        }

        return 0
    }
}

public enum SwipyCellMode: UInt {
    case none = 0
    case exit
    case toggle
}

public enum SwipyCellDirection: UInt {
    case left = 0
    case center
    case right
}

public protocol SwipyCellTriggerPointEditable: class {
    var triggerPoints: [CGFloat: SwipyCellState] { get set }

    func setTriggerPoint(forState state: SwipyCellState, at point: CGFloat)
    func setTriggerPoint(forIndex index: Int, at point: CGFloat)
    func setTriggerPoints(_ points: [CGFloat: SwipyCellState])
    func setTriggerPoints(_ points: [CGFloat: Int])
    func setTriggerPoints(points: [CGFloat])
    func getTriggerPoints() -> [CGFloat: SwipyCellState]
    func clearTriggerPoints()
}
extension SwipyCellTriggerPointEditable {

    public func setTriggerPoint(forState state: SwipyCellState, at point: CGFloat) {
        var p = abs(point)
        if case .state(_, let direction) = state, direction == .right {
            p = -p
        }
        triggerPoints[p] = state
    }

    public func setTriggerPoint(forIndex index: Int, at point: CGFloat) {
        let p = abs(point)
        triggerPoints[p] = SwipyCellState.state(index, .left)
        triggerPoints[-p] = SwipyCellState.state(index, .right)
    }

    public func setTriggerPoints(_ points: [CGFloat: SwipyCellState]) {
        triggerPoints = points
    }

    public func setTriggerPoints(_ points: [CGFloat: Int]) {
        triggerPoints = [:]
        _ = points.map { point, index in
            let p = abs(point)
            triggerPoints[p] = SwipyCellState.state(index, .left)
            triggerPoints[-p] = SwipyCellState.state(index, .right)
        }
    }

    public func setTriggerPoints(points: [CGFloat]) {
        triggerPoints = [:]
        for (index, point) in points.enumerated() {
            let p = abs(point)
            triggerPoints[p] = SwipyCellState.state(index, .left)
            triggerPoints[-p] = SwipyCellState.state(index, .right)
        }
    }

    public func getTriggerPoints() -> [CGFloat: SwipyCellState] {
        return triggerPoints
    }

    public func clearTriggerPoints() {
        triggerPoints = [:]
    }
}

public class SwipyCellConfig: SwipyCellTriggerPointEditable {
    public static let shared = SwipyCellConfig()

    public var triggerPoints: [CGFloat: SwipyCellState]
    public var swipeViewPadding: CGFloat
    public var shouldAnimateSwipeViews: Bool
    public var defaultSwipeViewColor: UIColor

    init() {
        triggerPoints = [:]
        triggerPoints[Defaults.stop1] = .state(0, .left)
        triggerPoints[Defaults.stop2] = .state(1, .left)
        triggerPoints[-Defaults.stop1] = .state(0, .right)
        triggerPoints[-Defaults.stop2] = .state(1, .right)

        swipeViewPadding = Defaults.swipeViewPadding
        shouldAnimateSwipeViews = Defaults.shouldAnimateSwipeViews
        defaultSwipeViewColor = Defaults.defaultSwipeViewColor
    }
}

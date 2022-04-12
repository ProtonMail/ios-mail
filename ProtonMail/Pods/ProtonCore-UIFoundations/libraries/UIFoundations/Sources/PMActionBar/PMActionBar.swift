//
//  PMActionBar.swift
//  ProtonCore-UIFoundations - Created on 29.07.20.
//
//  Copyright (c) 2020 Proton Technologies AG
//
//  This file is part of Proton Technologies AG and ProtonCore.
//
//  ProtonCore is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonCore is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonCore.  If not, see <https://www.gnu.org/licenses/>.

import UIKit

public final class PMActionBar: UIView {

    /// These constants specify width config of the action bar
    public enum Width {
        /// Width of the action bar will fit content
        case fit
        /// Width of the action bar is 80% of parent view's width
        case extend
        /// Width of the action bar is defined by given value
        case custom(CGFloat)
    }

    // MARK: Constants
    private let TAG_OFFSET: Int = 10
    /// Padding between bar item
    private let PADDING: CGFloat = 4
    /// MULTIPLIER used in case Width.extend
    private let WIDTH_MULTIPLIER: CGFloat = 0.8
    /// Size of button bar item
    private var BUTTON_SIZE: CGFloat {
    	min(40, height - (2 * PADDING))
    }

    // MARK: Variables
    private var items: [PMActionBarItem] = []
    /// The floating distance between the action bar and the bottom of the screen
    private var floatingHeight: CGFloat = 48
    /// Auto adjust bottom inset of scrollview based element to prevent shade or not
    private var autoInset: Bool = true
    /// Width config of the action bar
    private var width: Width = .extend
    /// Height of the action bar
    private var height: CGFloat = 48
    /// Bottom constraint of the action bar
    private var bottomConstraint: NSLayoutConstraint!
    /// The pressed button. There should only be one pressed item at a time.
    private weak var pressedButton: UIButton?
    /// The previous selected button. Used when one wants to restore the prvious selecting states.
    private weak var prevSelectedButton: UIButton?

    /// Initializer of the action bar
    /// - Parameters:
    ///   - items: Bar items array
    ///   - backgroundColor: Background color of the action bar
    ///   - floatingHeight: The floating distance between the action bar and the bottom of the screen, default value is `48`.
    ///   - width: Width config of the action bar, default value is `.extend`
    ///   - height: Height of the action bar, default value is `48`
    ///   - autoInset: Auto adjust bottom inset of scrollview based element to prevent shade or not
    public convenience init(items: [PMActionBarItem],
                            backgroundColor: UIColor = ColorProvider.FloatyBackground,
                            floatingHeight: CGFloat = 48,
                            width: Width = .extend,
                            height: CGFloat = 48,
                            autoInset: Bool = true) {
        self.init(frame: .zero)
        self.backgroundColor = backgroundColor
        self.items = items
        self.floatingHeight = floatingHeight
        self.height = height
        self.autoInset = autoInset
        self.width = width
    }

    override private init(frame: CGRect) {
        super.init(frame: frame)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override public func layoutSubviews() {
        guard self.autoInset,
              let parent = self.superview else {
            return
        }
        self.handleBottomInset(at: parent)
    }
}

// MARK: Public functions
extension PMActionBar {
    /// Presnet the action bar at given UIViewControler
    public func show(at parentVC: UIViewController) {
        self.setupActionBar()
        self.setupActionBarConstraint(at: parentVC.view)
        let stack = self.setupStackContainer()
        self.appendItems(items: self.items, at: stack)
    }

    /// Dismisses the action bar that was presented.
    public func dismiss() {
        guard let parent = self.superview, self.autoInset else {
            self.removeFromSuperview()
            return
        }

        for subView in parent.subviews {
            guard let scrollElement = subView as? UIScrollView else {
                continue
            }
            let frame = scrollElement.frame
            let scrollBottom = frame.size.height + frame.origin.y
            let overlap = scrollBottom - self.frame.origin.y
            if overlap <= 0 {
                // There is no overlap
                continue
            }
            scrollElement.contentInset.bottom = 0
        }
        self.removeFromSuperview()
    }
    
    /// End the animation of indicator, restore the previous text/icon, and set the button state as selected if succeed.
    /// If succeed is false and shouldRestore is true, then restore the previous selected barItem.
    public func endSpinning(succeed: Bool, shouldRestore: Bool = false) {
        guard let button = self.pressedButton else {
            return
        }
        if succeed {
            self.setup(button: button, for: .selected)
        } else {
            self.setup(button: button, for: .normal)
            if shouldRestore, let prevButton = self.prevSelectedButton {
                self.setup(button: prevButton, for: .selected)
            }
        }
    }
}

// MARK: Private functions
extension PMActionBar {
    @objc private func clickItem(sender: UIButton) {
        guard self.pressedButton == nil else { return }
        
        let idx = sender.tag - TAG_OFFSET
        let item = self.items[idx]
        item.handler?(item)
        guard let stack = self.subviews.first(where: { $0 is UIStackView }) as? UIStackView else {
            return
        }
        for view in stack.arrangedSubviews {
            if let btn = view as? UIButton {
                if btn == sender {
                    if item.shouldSpin {
                        self.setup(button: btn, for: .reserved)
                    } else {
                        self.setup(button: btn, for: .selected)
                    }
                } else {
                    self.setup(button: btn, for: .normal)
                }
            }
        }
    }
}

// MARK: UI Relative
extension PMActionBar {
    /// Setting some appearance of the action bar
    private func setupActionBar() {
        self.roundCorner(self.height / 2)
    }

    /// Set constraints of action bar
    private func setupActionBarConstraint(at parent: UIView) {
        parent.addSubview(self)
        self.translatesAutoresizingMaskIntoConstraints = false
        self.centerXAnchor.constraint(equalTo: parent.centerXAnchor).isActive = true
        self.heightAnchor.constraint(equalToConstant: self.height).isActive = true
        switch self.width {
        case .fit:
            self.widthAnchor.constraint(greaterThanOrEqualToConstant: self.height).isActive = true
        case .extend:
            self.widthAnchor.constraint(equalTo: parent.widthAnchor, multiplier: WIDTH_MULTIPLIER).isActive = true
        case .custom(let width):
            self.widthAnchor.constraint(equalToConstant: width).isActive = true
        }

        let safeBottom = parent.safeGuide.bottom
        // make sure bottom always on the top of safeArea
        let bottom = max(1 + safeBottom, self.floatingHeight)
        self.bottomConstraint = self.bottomAnchor.constraint(equalTo: parent.bottomAnchor, constant: -1 * bottom)
        self.bottomConstraint.isActive = true
    }

    /// Create stack view and setting constraints
    private func setupStackContainer() -> UIStackView {
        let stack = UIStackView(.horizontal, alignment: .fill, distribution: .fill, useAutoLayout: true)
        stack.spacing = PADDING
        self.addSubview(stack)
        stack.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        stack.leadingAnchor.constraint(equalTo: self.leadingAnchor, constant: 2 * PADDING).isActive = true
        stack.trailingAnchor.constraint(equalTo: self.trailingAnchor, constant: -2 * PADDING).isActive = true
        stack.heightAnchor.constraint(equalToConstant: BUTTON_SIZE).isActive = true
        return stack
    }

    /// Append bar items to given stack view
    private func appendItems(items: [PMActionBarItem], at stack: UIStackView) {
        for (idx, item) in items.enumerated() {
            switch item.type {
            case .label:
                guard let text = item.text else { continue }
                let label = UILabel(text, font: .systemFont(ofSize: 13), textColor: item.itemColor, alignment: item.alignment)
                label.backgroundColor = item.backgroundColor
                stack.addArrangedSubview(label)
                if idx == items.count - 1 {
                    let spacer = self.createSpacer()
                    stack.addArrangedSubview(spacer)
                }
            case .button:
                var btn: UIButton!
                if item.icon != nil && item.text != nil {
                    btn = createRichButton(item: item, idx: idx)
                } else if item.icon != nil {
                    btn = createIconButton(item: item, idx: idx)
                } else {
                    btn = createPlainButton(item: item, idx: idx)
                }
                if let indicator = item.activityIndicator {
                    btn.addSubview(indicator)
                    indicator.centerInSuperview()
                }
                stack.addArrangedSubview(btn)
            case .separator:
                guard let width = item.userInfo?["width"] as? CGFloat,
                      let padding = item.userInfo?["verticalPadding"] as? CGFloat else {
                    continue
                }
                let view = self.createSeparatorView(width: width,
                                                    color: item.backgroundColor.withAlphaComponent(0.2),
                                                    vPadding: padding)
                stack.addArrangedSubview(view)
            }
        }
    }

    /// Create icon button for given item.
    /// - Parameters:
    ///   - item: Bar item config
    ///   - idx: Index of item
    /// - Returns: button
    private func createIconButton(item: PMActionBarItem, idx: Int) -> UIButton {
        let btn = UIButton()
        btn.setImage(item.icon!, for: .normal)
        btn.tintColor = item.itemColor
        btn.backgroundColor = item.backgroundColor
        btn.roundCorner(BUTTON_SIZE / 2)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.widthAnchor.constraint(equalToConstant: BUTTON_SIZE).isActive = true
        btn.tag = TAG_OFFSET + idx
        btn.addTarget(self, action: #selector(self.clickItem(sender:)), for: .touchUpInside)
        return btn
    }

    /// Create plain button for given item.
    /// - Parameters:
    ///   - item: Bar item config
    ///   - idx: Index of item
    /// - Returns: button
    private func createPlainButton(item: PMActionBarItem, idx: Int) -> UIButton {
        let btn = UIButton()
        btn.setTitle(item.text, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 15)
        btn.roundCorner(BUTTON_SIZE / 2)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.sizeToFit()
        btn.widthAnchor.constraint(equalToConstant: btn.bounds.size.width + 2 * PADDING).isActive = true
        btn.tag = TAG_OFFSET + idx
        let state: UIButton.State = item.isSelected ? .selected: .normal
        self.setup(button: btn, for: state)
        btn.addTarget(self, action: #selector(self.clickItem(sender:)), for: .touchUpInside)
        return btn
    }

    private func createRichButton(item: PMActionBarItem, idx: Int) -> UIButton {
        let btn = UIButton()
        btn.setImage(item.icon!, for: .normal)
        btn.imageView?.contentMode = .scaleAspectFit
        btn.tintColor = item.itemColor
        btn.backgroundColor = item.backgroundColor
        btn.setTitle(item.text, for: .normal)
        btn.titleLabel?.font = .systemFont(ofSize: 14)
        btn.contentEdgeInsets = .init(top: 0, left: 4, bottom: 0, right: 11)
        btn.titleEdgeInsets = .init(top: 0, left: 7, bottom: 0, right: 0)
        btn.roundCorner(BUTTON_SIZE / 2)
        btn.translatesAutoresizingMaskIntoConstraints = false
        btn.sizeToFit()
        btn.widthAnchor.constraint(equalToConstant: btn.bounds.size.width + 2 * PADDING).isActive = true
        btn.tag = TAG_OFFSET + idx
        let state: UIButton.State = item.isSelected ? .selected: .normal
        self.setup(button: btn, for: state)
        btn.addTarget(self, action: #selector(self.clickItem(sender:)), for: .touchUpInside)
        return btn
    }

    private func createSeparatorView(width: CGFloat, color: UIColor, vPadding: CGFloat) -> UIView {
        let container = UIView(frame: .zero)
        container.translatesAutoresizingMaskIntoConstraints = false

        let separator = UIView(frame: .zero)
        separator.backgroundColor = color
        separator.translatesAutoresizingMaskIntoConstraints = false
        container.addSubview(separator)

        NSLayoutConstraint.activate([
            separator.topAnchor.constraint(equalTo: container.topAnchor, constant: vPadding),
            separator.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            separator.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            separator.bottomAnchor.constraint(equalTo: container.bottomAnchor, constant: -1 * vPadding),
            separator.widthAnchor.constraint(equalToConstant: width)
        ])
        return container
    }

    private func setup(button: UIButton, for state: UIButton.State) {
        let idx = button.tag - TAG_OFFSET
        let item = self.items[idx]
        
        // record the previous selected button
        if item.isSelected, state == .normal {
            self.prevSelectedButton = button
        }
        
        // restore the previous-set image & title
        if item.isPressed, state != .reserved {
            if let image = item.icon {
                button.setImage(image, for: .normal)
            }
            button.setTitle(item.text, for: .normal)
            item.activityIndicator?.stopAnimating()
            self.items[idx].isPressed = false
            self.pressedButton = nil
        }
        switch state {
        case .normal:
            button.backgroundColor = item.backgroundColor
            button.tintColor = item.itemColor
            button.setTitleColor(item.itemColor, for: .normal)
            self.items[idx].isSelected = false
        case .selected:
            button.backgroundColor = item.selectedBgColor ?? item.backgroundColor
            button.tintColor = item.selectedItemColor ?? item.itemColor
            button.setTitleColor(item.selectedItemColor ?? item.itemColor, for: .normal)
            self.items[idx].isSelected = true
        case .reserved:
            button.backgroundColor = item.pressedBackgroundColor ?? item.backgroundColor
            button.setImage(nil, for: .normal)
            button.setTitle("", for: .normal)
            item.activityIndicator?.isHidden = false
            item.activityIndicator?.startAnimating()
            self.items[idx].isPressed = true
            self.pressedButton = button
        default: break
        }
    }

    /// Create spacer
    private func createSpacer() -> UIView {
        let view = UIView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.widthAnchor.constraint(equalToConstant: 0).isActive = true
        return view
    }

    /// Setting bottom inset of scrollview based element if needed.
    private func handleBottomInset(at parent: UIView) {
        guard self.autoInset else {
            // Developer will handle bottom inset of scrollView based element by himself.
            return
        }

        for subView in parent.subviews {
            guard let scrollElement = subView as? UIScrollView else {
                continue
            }
            let frame = scrollElement.frame
            let scrollBottom = frame.size.height + frame.origin.y
            let screenHeight = parent.frame.size.height
            let barTop = screenHeight + self.bottomConstraint.constant - self.height
            let overlap = scrollBottom - barTop
            if overlap <= 0 {
                // There is no overlap
                continue
            }
            scrollElement.contentInset.bottom = overlap + 1
        }
    }
}

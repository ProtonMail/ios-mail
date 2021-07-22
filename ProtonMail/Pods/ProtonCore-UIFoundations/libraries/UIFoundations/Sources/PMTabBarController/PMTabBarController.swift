//
//  PMTabBarController.swift
//  ProtonCore-UIFoundations - Created on 15.07.20.
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

public final class PMTabBarController: UITabBarController {
    // MARK: Constant
    private let TAGOFFSET = 10
    private let PADDING: CGFloat = 7
    private let FONTSIZE: CGFloat = 15
    private var FLOATMARGIN: CGFloat {
        return self.tabBarConfig?.floatingHeight ?? 0
    }

    // MARK: Customize variable
    private(set) var tabBarConfig: PMTabBarConfig?
    private(set) var tabBarContainer: UIView?
    private(set) var barButtons: [UIButton] = []

    // MARK: Override variable
    override public var viewControllers: [UIViewController]? {
        willSet {
            self.setViewControllers(newValue, animated: false)
        }
    }

    override public var selectedIndex: Int {
        didSet {
            self.highlightButton(tag: selectedIndex + self.TAGOFFSET)
        }
    }

    override public func viewDidLayoutSubviews() {
        var tabBarFrame = self.tabBar.frame
        tabBarFrame.size.height = self.tabBarConfig!.height
        tabBarFrame.origin.y = self.view.frame.size.height - self.tabBarConfig!.height
        self.tabBar.frame = tabBarFrame

        guard let config = self.tabBarConfig else { return }
        self.tabBar.isHidden = config.isFloat
    }
}

// MARK: Public functions
extension PMTabBarController {
    override public func setViewControllers(_ viewControllers: [UIViewController]?, animated: Bool) {
        guard self.viewControllers == nil else {
            fatalError(PMTabBarError.cannotUpdate.localizedDescription)
        }

        if let config = self.tabBarConfig,
            let vcs = viewControllers,
            config.items.count != vcs.count {
            fatalError(PMTabBarError.countNotEqual.localizedDescription)
        }
        super.setViewControllers(viewControllers, animated: animated)
    }

    /// Returns the bottom inset value for the UIEdgeInset
    public func getBottomInsetValue() -> CGFloat {
        guard let config = self.tabBarConfig, config.isFloat else {
                return 0
        }

        return self.FLOATMARGIN + config.height
    }
}

// MARK: Internal functions
extension PMTabBarController {
    func setupConfig(_ config: PMTabBarConfig) throws {
        if let vcs = self.viewControllers, vcs.count != config.items.count {
            throw PMTabBarError.countNotEqual
        }
        self.tabBarConfig = config
        try self.setupTabbar()
    }
}

// MARK: Private functions
extension PMTabBarController {
    @objc private func clickTab(sender: UIButton) {
        self.selectedIndex = sender.tag - self.TAGOFFSET
    }
}

// MARK: UI Relative
extension PMTabBarController {
    private func setupTabbar() throws {
        guard let config = self.tabBarConfig else {
            throw PMTabBarError.configMissing
        }

        self.tabBarContainer = nil
        let container = self.setupTabbarContainer(config: config)
        let stack = self.setupStack(container: container, height: config.height, isFloatBar: config.isFloat)
        self.setupItems(stack: stack, items: config.items, tabbarHeight: config.height)
        self.tabBarContainer = container
    }

    private func setupTabbarContainer(config: PMTabBarConfig) -> UIView {
        let barView = UIView()
        barView.backgroundColor = config.backgroundColor
        barView.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(barView)

        if config.isFloat {
            self.setupFloatTabbarConstraint(barView, config: config)
        } else {
            self.setupFixedTabbarConstraint(barView, config: config)
        }

        return barView
    }

    private func setupFixedTabbarConstraint(_ barView: UIView, config: PMTabBarConfig) {
        barView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor).isActive = true
        barView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor).isActive = true
        barView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor).isActive = true

        let safeGuide = UIDevice.safeGuide
        if safeGuide.bottom == 0 {
            // Device has physical home button
            barView.heightAnchor.constraint(equalToConstant: config.height).isActive = true
        } else {
            let safeHeight = safeGuide.bottom
            let height = safeHeight + config.height
            barView.heightAnchor.constraint(equalToConstant: height).isActive = true
        }
    }

    private func setupFloatTabbarConstraint(_ barView: UIView, config: PMTabBarConfig) {
        barView.roundCorner(config.height / 2)
        let bottomConstraint = -1 * self.FLOATMARGIN
        barView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
        barView.heightAnchor.constraint(equalToConstant: config.height).isActive = true
        barView.widthAnchor.constraint(greaterThanOrEqualTo: self.view.widthAnchor, multiplier: 0.75, constant: 0).isActive = true
        barView.widthAnchor.constraint(lessThanOrEqualTo: self.view.widthAnchor, multiplier: 0.99).isActive = true

        let safeGuide = UIDevice.safeGuide
        if safeGuide.bottom == 0 {
            // Device has physical home button
            barView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: bottomConstraint).isActive = true
        } else {
            let safeHeight = -1 * safeGuide.bottom
            let height = min(safeHeight, bottomConstraint)
            barView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor, constant: height).isActive = true
        }
    }

    private func setupStack(container: UIView, height: CGFloat, isFloatBar: Bool) -> UIStackView {
        let padding = isFloatBar ? self.PADDING: 22
        let stack = UIStackView(.horizontal, alignment: .center, distribution: .fillProportionally, useAutoLayout: true)
        stack.spacing = 8
        container.addSubview(stack)

        stack.topAnchor.constraint(equalTo: container.topAnchor).isActive = true
        stack.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: padding).isActive = true
        stack.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -1 * padding).isActive = true
        stack.heightAnchor.constraint(equalToConstant: height).isActive = true
        return stack
    }

    private func setupItems(stack: UIStackView, items: [PMTabBarItem], tabbarHeight: CGFloat) {
        self.barButtons = []
        for (idx, item) in items.enumerated() {
            let btn = UIButton()
            btn.translatesAutoresizingMaskIntoConstraints = false
            btn.tag = idx + TAGOFFSET
            btn.titleLabel?.font = .systemFont(ofSize: self.FONTSIZE)
            let buttonHeight = tabbarHeight - self.PADDING * 2
            btn.roundCorner(buttonHeight / 2)
            btn.heightAnchor.constraint(equalToConstant: buttonHeight).isActive = true
            if let title = item.title {
                btn.setTitle(title, for: .normal)
                btn.setTitleColor(item.color, for: .normal)
            } else {
                btn.setImage(item.icon, for: .normal)
                btn.tintColor = item.color
            }
            btn.addTarget(self, action: #selector(self.clickTab(sender:)), for: .touchUpInside)
            stack.addArrangedSubview(btn)
            self.barButtons.append(btn)
        }
    }

    private func highlightButton(tag: Int) {
        guard let config = self.tabBarConfig else { return }
        for (idx, btn) in self.barButtons.enumerated() {
            let item = config.items[idx]
            if btn.tag == tag {
                btn.backgroundColor = item.selectedBgColor
                btn.setTitleColor(item.selectedColor, for: .normal)
                btn.tintColor = item.selectedColor
            } else {
                btn.backgroundColor = .clear
                btn.setTitleColor(item.color, for: .normal)
                btn.tintColor = item.color
            }
        }
    }
}

// Copyright (c) 2023 Proton Technologies AG
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

import ProtonCoreUIFoundations
import UIKit

final class PromotionView: UIView {
    private let containerView = SubviewsFactory.containerView()
    private let upperView = SubviewsFactory.upperView
    private let closeButton = SubviewsFactory.closeButton
    private let titleLabel = SubviewsFactory.titleLabel
    private let contentLabel = SubviewsFactory.contentLabel
    private let upgradeButton = SubviewsFactory.upgradeButton
    private let planScrollView = SubviewsFactory.planScrollView()

    private let upgradeContainerView = SubviewsFactory.upgradeContainerView()
    private let scrollContentView = UIView()
    private let planStackView = SubviewsFactory.planStackView()

    private var containerBottomConstraint: NSLayoutConstraint?
    private var didClickUpgrade: Bool = false

    var presentPaymentUpgradeView: (() -> Void)?
    var viewWasDismissed: (@MainActor () -> Void)?

    init() {
        super.init(frame: .zero)
        backgroundColor = ColorProvider.BlenderNorm.withAlphaComponent(0.46)

        addSubviews()
        setupLayout()
        setupFunction()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func present(on view: UIView, type: PromotionType) {
        updateContent(type: type)
        view.addSubview(self)
        self.fillSuperview()
        view.layoutIfNeeded()

        UIView.animate(withDuration: 0.25) {
            self.containerBottomConstraint?.constant = 0
            self.layoutIfNeeded()
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        titleLabel.font = .adjustedFont(forTextStyle: .title2, weight: .bold)
        contentLabel.font = .adjustedFont(forTextStyle: .subheadline)
        planStackView.arrangedSubviews.forEach { view in
            for label in view.subviews.compactMap({ $0 as? UILabel }) {
                label.font = .adjustedFont(forTextStyle: .subheadline)
            }
        }
    }
}

// MARK: - View update
extension PromotionView {
    private func addSubviews() {
        addSubview(containerView)

        containerView.addSubview(upperView)
        containerView.addSubview(closeButton)

        containerView.addSubview(titleLabel)
        containerView.addSubview(contentLabel)
        containerView.addSubview(upgradeContainerView)

        upgradeContainerView.addSubview(upgradeButton)
        upgradeContainerView.addSubview(planScrollView)
        planScrollView.addSubview(scrollContentView)

        scrollContentView.addSubview(planStackView)
    }

    // swiftlint:disable:next function_body_length
    private func setupLayout() {
        let bottomConstraint = containerView.bottomAnchor.constraint(
            equalTo: safeAreaLayoutGuide.bottomAnchor,
            constant: 700
        )
        containerBottomConstraint = bottomConstraint
        [
            bottomConstraint,
            containerView.leadingAnchor.constraint(equalTo: leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ].activate()

        [
            upperView.topAnchor.constraint(equalTo: containerView.topAnchor),
            upperView.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),
            upperView.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),
            upperView.heightAnchor.constraint(equalToConstant: 156),
            closeButton.widthAnchor.constraint(equalToConstant: 40),
            closeButton.heightAnchor.constraint(equalTo: closeButton.widthAnchor),
            closeButton.topAnchor.constraint(equalTo: containerView.topAnchor, constant: 18),
            closeButton.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 8)
        ].activate()

        [
            titleLabel.topAnchor.constraint(equalTo: upperView.bottomAnchor, constant: 16),
            titleLabel.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -16),
            contentLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 4),
            contentLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            contentLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            upgradeContainerView.topAnchor.constraint(equalTo: contentLabel.bottomAnchor, constant: 16),
            upgradeContainerView.leadingAnchor.constraint(equalTo: contentLabel.leadingAnchor),
            upgradeContainerView.trailingAnchor.constraint(equalTo: contentLabel.trailingAnchor),
            upgradeContainerView.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -16)
        ].activate()

        [
            upgradeButton.bottomAnchor.constraint(equalTo: upgradeContainerView.bottomAnchor, constant: -16),
            upgradeButton.leadingAnchor.constraint(equalTo: upgradeContainerView.leadingAnchor, constant: 16),
            upgradeButton.trailingAnchor.constraint(equalTo: upgradeContainerView.trailingAnchor, constant: -16),
            upgradeButton.heightAnchor.constraint(equalToConstant: 48.0),
            planScrollView.topAnchor.constraint(equalTo: upgradeContainerView.topAnchor),
            planScrollView.trailingAnchor.constraint(equalTo: upgradeContainerView.trailingAnchor),
            planScrollView.leadingAnchor.constraint(equalTo: upgradeContainerView.leadingAnchor),
            planScrollView.bottomAnchor.constraint(equalTo: upgradeButton.topAnchor),
            planScrollView.heightAnchor.constraint(lessThanOrEqualToConstant: 300)
        ].activate()

        [
            scrollContentView.topAnchor.constraint(equalTo: planScrollView.contentLayoutGuide.topAnchor),
            scrollContentView.leadingAnchor.constraint(equalTo: planScrollView.contentLayoutGuide.leadingAnchor),
            scrollContentView.trailingAnchor.constraint(equalTo: planScrollView.contentLayoutGuide.trailingAnchor),
            scrollContentView.bottomAnchor.constraint(equalTo: planScrollView.contentLayoutGuide.bottomAnchor),
            scrollContentView.widthAnchor.constraint(equalTo: planScrollView.widthAnchor)
        ].activate()

        [
            planStackView.topAnchor.constraint(equalTo: scrollContentView.topAnchor, constant: 16),
            planStackView.leadingAnchor.constraint(equalTo: scrollContentView.leadingAnchor, constant: 16),
            planStackView.trailingAnchor.constraint(equalTo: scrollContentView.trailingAnchor, constant: -16),
            planStackView.bottomAnchor.constraint(equalTo: scrollContentView.bottomAnchor, constant: -16)
        ].activate()
    }

    private func setupFunction() {
        closeButton.addTarget(self, action: #selector(self.dismiss), for: .touchUpInside)
        upgradeButton.addTarget(self, action: #selector(self.handleUpgrade), for: .touchUpInside)

        let gesture = UITapGestureRecognizer(target: self, action: #selector(self.dismiss))
        gesture.delegate = self
        addGestureRecognizer(gesture)
    }

    private func updateContent(type: PromotionType) {
        titleLabel.text = type.title
        contentLabel.text = type.contentDesc

        type.plans.forEach { plan in
            let planView = SubviewsFactory.createPlanView(plan: plan)
            planStackView.addArrangedSubview(planView)
        }

        let verticalPadding: CGFloat = 16
        let planSpace: CGFloat = 8
        let planHeight: CGFloat = 24
        let contentHeight: CGFloat = CGFloat(type.plans.count) * planHeight +
        CGFloat(type.plans.count - 1) * planSpace +
        verticalPadding * 2
        [
            scrollContentView.heightAnchor.constraint(greaterThanOrEqualToConstant: contentHeight),
            planScrollView.heightAnchor.constraint(equalTo: scrollContentView.heightAnchor)
        ].activate()
    }
}

// MARK: - IBAction
extension PromotionView {
    @objc
    private func dismiss() {
        UIView.animate(
            withDuration: 0.25,
            animations: {
                self.containerBottomConstraint?.constant = 700
                self.layoutIfNeeded()
            }, completion: { _ in
                self.removeFromSuperview()
            }
        )
        viewWasDismissed?()
    }

    @objc
    private func handleUpgrade() {
        if didClickUpgrade { return }
        didClickUpgrade = true
        removeFromSuperview()
        presentPaymentUpgradeView?()
    }
}

extension PromotionView: UIGestureRecognizerDelegate {
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        if gestureRecognizer is UITapGestureRecognizer {
            // Check user tap position is gray overlay or container view
            let point = gestureRecognizer.location(in: containerView)
            // tap gray overlay
            if point.y < 0 {
                return true
            }
        }
        return false
    }
}

extension PromotionView {
    enum PromotionType {
        case scheduleSend, snooze

        var title: String {
            switch self {
            case .scheduleSend:
                return L10n.ScheduledSend.upSellTitle
            case .snooze:
                return L10n.Snooze.promotionTitle
            }
        }

        var contentDesc: String {
            switch self {
            case .scheduleSend:
                return L10n.ScheduledSend.upSellContent
            case .snooze:
                return L10n.Snooze.promotionDesc
            }
        }

        var plans: [SubviewsFactory.Plan] {
            switch self {
            case .scheduleSend:
                return [.schedule, .folder, .storage, .addresses, .domains, .aliases]
            case .snooze:
                return [.storage, .snoozeAddresses, .snoozeFolder, .snoozeDomains]
            }
        }
    }
}

extension PromotionView {
    enum SubviewsFactory {
        enum Plan: CaseIterable {
            case schedule
            case folder
            case storage
            case addresses
            case domains
            case aliases
            case snoozeAddresses
            case snoozeDomains
            case snoozeFolder

            var icon: UIImage {
                switch self {
                case .schedule:
                    return IconProvider.clockPaperPlane
                case .folder, .snoozeFolder:
                    return IconProvider.folders
                case .storage:
                    return IconProvider.storage
                case .addresses, .snoozeAddresses:
                    return IconProvider.envelopes
                case .domains, .snoozeDomains:
                    return IconProvider.globe
                case .aliases:
                    return IconProvider.eyeSlash
                }
            }

            var title: String {
                switch self {
                case .schedule:
                    return L10n.ScheduledSend.itemSchedule
                case .folder:
                    return L10n.PremiumPerks.unlimitedFoldersAndLabels
                case .storage:
                    return L10n.ScheduledSend.itemStorage
                case .addresses:
                    return L10n.ScheduledSend.itemAddresses
                case .domains:
                    return L10n.ScheduledSend.itemDomain
                case .aliases:
                    return L10n.ScheduledSend.itemAliases
                case .snoozeAddresses:
                    return L10n.Snooze.addressBenefit
                case .snoozeFolder:
                    return L10n.Snooze.folderBenefit
                case .snoozeDomains:
                    return L10n.Snooze.domainBenefit
                }
            }
        }

        static func containerView() -> UIView {
            let view = UIView()
            view.backgroundColor = ColorProvider.BackgroundNorm
            view.roundCorner(8.0)
            return view
        }

        static var closeButton: UIButton = {
            let button = UIButton()
            button.setImage(IconProvider.cross, for: .normal)
            button.tintColor = .white
            return button
        }()

        static var upperView: UIImageView = {
            let view = UIImageView(image: Asset.upsellPromotion.image)
            return view
        }()

        static var titleLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.text = L10n.ScheduledSend.upSellTitle
            label.font = .adjustedFont(forTextStyle: .title2, weight: .bold)
            label.textAlignment = .center
            label.adjustsFontForContentSizeCategory = true
            label.adjustsFontSizeToFitWidth = false
            return label
        }()

        static var contentLabel: UILabel = {
            let label = UILabel()
            label.numberOfLines = 0
            label.text = L10n.ScheduledSend.upSellContent
            label.textAlignment = .center
            label.font = .adjustedFont(forTextStyle: .subheadline)
            label.adjustsFontForContentSizeCategory = true
            label.adjustsFontSizeToFitWidth = false
            return label
        }()

        static func upgradeContainerView() -> UIView {
            let view = UIView()
            view.layer.borderWidth = 1
            view.layer.borderColor = ColorProvider.BrandNorm
            view.roundCorner(12.0)
            return view
        }

        static var upgradeButton: ProtonButton = {
            let button = ProtonButton()
            button.setMode(mode: .solid)
            button.setTitle(L10n.ScheduledSend.upgradeTitle, for: .normal)
            return button
        }()

        static func planScrollView() -> UIScrollView {
            let scrollView = UIScrollView()
            scrollView.bounces = false
            scrollView.showsHorizontalScrollIndicator = false
            scrollView.showsVerticalScrollIndicator = false
            return scrollView
        }

        static func planStackView() -> UIStackView {
            let stackView = UIStackView()
            stackView.axis = .vertical
            stackView.alignment = .fill
            stackView.spacing = 8

            return stackView
        }

        static func createPlanView(plan: Plan) -> UIView {
            let view = UIView()
            let icon = UIImageView(image: plan.icon)
            icon.tintColor = ColorProvider.InteractionNorm
            let text = UILabel()
            text.text = plan.title
            text.font = .adjustedFont(forTextStyle: .subheadline)
            text.adjustsFontForContentSizeCategory = true
            text.adjustsFontSizeToFitWidth = true
            view.addSubview(icon)
            view.addSubview(text)

            [
                icon.heightAnchor.constraint(equalTo: icon.widthAnchor),
                icon.heightAnchor.constraint(equalTo: view.heightAnchor),
                icon.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                icon.topAnchor.constraint(equalTo: view.topAnchor),
                icon.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                text.leadingAnchor.constraint(equalTo: icon.trailingAnchor, constant: 12),
                text.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                text.topAnchor.constraint(equalTo: view.topAnchor),
                text.bottomAnchor.constraint(equalTo: view.bottomAnchor)
            ].activate()
            return view
        }
    }
}

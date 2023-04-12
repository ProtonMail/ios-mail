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

import ProtonCore_UIFoundations
import ProtonCore_Utilities
import UIKit

final class StorageLimitCell: UITableViewCell {
    private let stackView = SubviewFactory.stackView
    private let titleLabel = SubviewFactory.titleLabel
    private let slider = SubviewFactory.slider
    private let currentSelectionLabel = SubviewFactory.smallLabel
    weak var delegate: StorageLimitCellDelegate?

    private let sliderNumOfSteps: Int = 6
    private let sliderStepValue: Float = 200_000_000 // 200 MB
    private var lastStepValue: Float = 0

    private enum Layout {
        static let hMargin = 16.0
        static let vMargin = 12.0
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setUpView()
        setUpConstraints()
    }

    private func setUpView() {
        slider.minimumValue = sliderStepValue
        slider.maximumValue = sliderStepValue * Float(sliderNumOfSteps)
        slider.addTarget(self, action: #selector(onSliderValueChange(_:)), for: .valueChanged)
        [titleLabel, slider, currentSelectionLabel].forEach {
            stackView.addArrangedSubview($0)
        }
        contentView.addSubview(stackView)
    }

    @objc
    private func onSliderValueChange(_ sender: UISlider) {
        setSliderValue(sender.value)
    }

    private func setSliderValue(_ value: Float) {
        let newStepValue = stepValue(for: value)
        let valueHasChanged = newStepValue != lastStepValue
        slider.value = newStepValue
        lastStepValue = newStepValue
        if valueHasChanged {
            updateCurrentSelection()
            let newLimit = slider.value == slider.maximumValue ? .max : Int(slider.value)
            delegate?.didChangeStorageLimit(newLimit: newLimit)
        }
    }

    private func stepValue(for value: Float) -> Float {
        let newStep: Float = roundf(value / sliderStepValue)
        return max(min(newStep * sliderStepValue, slider.maximumValue), slider.minimumValue)
    }

    private func updateCurrentSelection() {
        if slider.value == slider.maximumValue {
            currentSelectionLabel.text = L11n.EncryptedSearch.downloaded_messages_storage_limit_no_limit
        } else {
            currentSelectionLabel.text = L11n.EncryptedSearch.downloaded_messages_storage_limit_selection
            + Int(slider.value).toByteCount
        }
    }

    private func setUpConstraints() {
        [
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor)
        ].activate()
    }

    func configure(storageLimit: ByteCount) {
        setSliderValue(Float(storageLimit))
    }
}

extension StorageLimitCell {

    private enum SubviewFactory {

        static var defaultLabel: UILabel {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.adjustsFontForContentSizeCategory = true
            label.textColor = ColorProvider.TextNorm
            label.numberOfLines = 0
            return label
        }

        static var stackView: UIStackView {
            let stack = UIStackView()
            stack.translatesAutoresizingMaskIntoConstraints = false
            stack.axis = .vertical
            stack.distribution = .equalSpacing
            stack.alignment = .fill
            stack.layoutMargins = UIEdgeInsets(
                top: Layout.vMargin,
                left: Layout.hMargin,
                bottom: Layout.vMargin,
                right: Layout.hMargin
            )
            stack.isLayoutMarginsRelativeArrangement = true
            stack.spacing = 8
            return stack
        }

        static var titleLabel: UILabel {
            let label = defaultLabel
            label.font = .adjustedFont(forTextStyle: .headline)
            label.text = LocalString._settings_title_of_storage_limit
            return label
        }

        static var slider: UISlider {
            let slider = UISlider()
            slider.translatesAutoresizingMaskIntoConstraints = false
            slider.minimumTrackTintColor = ColorProvider.BrandNorm
            return slider
        }

        static var smallLabel: UILabel {
            let label = UILabel()
            label.font = .adjustedFont(forTextStyle: .footnote)
            label.textColor = ColorProvider.TextWeak
            return label
        }
    }
}

protocol StorageLimitCellDelegate: AnyObject {
    func didChangeStorageLimit(newLimit: ByteCount)
}

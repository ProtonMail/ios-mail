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
import UIKit

final class EncryptedSearchDownloadProgressCell: UITableViewCell {
    private let stackView: UIStackView = SubviewFactory.stackView
    private let title: UILabel = SubviewFactory.titleLabel
    private let instructionsLabel: UILabel = SubviewFactory.instructionsLabel
    private let downloadingNewMessages: UIView = SubviewFactory.downloadingNewMessagesView
    private let downloadProgress = DownloadMessagesProgressView()
    private let pauseButton = SubviewFactory.button
    private let resumeButton = SubviewFactory.button

    weak var delegate: EncryptedSearchDownloadProgressCellDelegate?

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
        selectionStyle = .none
        pauseButton.setTitle(L11n.EncryptedSearch.pause_button, for: .normal)
        resumeButton.setTitle(L11n.EncryptedSearch.resume_button, for: .normal)
        pauseButton.addTarget(self, action: #selector(onPauseTap), for: .touchUpInside)
        resumeButton.addTarget(self, action: #selector(onResumeTap), for: .touchUpInside)
        [title, downloadingNewMessages, downloadProgress, instructionsLabel, pauseButton, resumeButton].forEach {
            stackView.addArrangedSubview($0)
        }
        contentView.addSubview(stackView)
    }

    private func setUpConstraints() {
        let progressConstraint = downloadProgress.trailingAnchor.constraint(
            equalTo: stackView.trailingAnchor,
            constant: -Layout.hMargin
        )
        progressConstraint.priority = .defaultHigh
        [
            stackView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            stackView.topAnchor.constraint(equalTo: contentView.topAnchor),
            stackView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            stackView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            progressConstraint
        ].activate()
    }

    @objc
    private func onPauseTap() {
        delegate?.didTapPause()
    }

    @objc
    private func onResumeTap() {
        delegate?.didTapResume()
    }

    func configureWith(state: DownloadingState) {
        downloadingNewMessages.isHidden = true
        downloadProgress.isHidden = true
        instructionsLabel.isHidden = true
        pauseButton.isHidden = true
        resumeButton.isHidden = true

        switch state {
        case .fetchingNewMessages:
            downloadingNewMessages.isHidden = false
        case let .downloading(progress):
            updateDownloadingProgress(progress: progress)
            downloadProgress.isHidden = false
            pauseButton.isHidden = false
        case let .manuallyPaused(progress):
            updateDownloadingProgress(progress: progress)
            downloadProgress.isHidden = false
            resumeButton.isHidden = false
        case let .error(error):
            showErrorDownloadProgress(error: error)
        }
    }

    /// Call this function after configuring the `downloading` state to update the progress
    func updateDownloadingProgress(progress: DownloadingProgress) {
        downloadProgress.set(aboveText: progress.messagesDownloaded)
        downloadProgress.set(belowText: progress.timeRemaining)
        downloadProgress.set(progressPercentage: progress.percentageDownloaded)
    }

    private func showErrorDownloadProgress(error: DownloadingProgressError) {
        downloadProgress.set(belowText: error.message, useErrorColor: true)
        downloadProgress.set(progressPercentage: error.percentageDownloaded, useErrorColor: true)
        instructionsLabel.text = error.instructions
        downloadProgress.isHidden = false
        instructionsLabel.isHidden = false
        resumeButton.isHidden = !error.showResumeButton
    }
}

extension EncryptedSearchDownloadProgressCell {

    private enum SubviewFactory {

        static var stackView: UIStackView {
            let stack = UIStackView()
            stack.axis = .vertical
            stack.distribution = .equalSpacing
            stack.alignment = .leading
            stack.layoutMargins = UIEdgeInsets(
                top: Layout.vMargin,
                left: Layout.hMargin,
                bottom: Layout.vMargin,
                right: Layout.hMargin
            )
            stack.isLayoutMarginsRelativeArrangement = true
            stack.spacing = 16
            return stack
        }

        static var titleLabel: UILabel {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .adjustedFont(forTextStyle: .body)
            label.adjustsFontForContentSizeCategory = true
            label.textColor = ColorProvider.TextNorm
            label.numberOfLines = 0
            label.text = LocalString._settings_title_of_downloaded_messages_progress
            return label
        }

        static var instructionsLabel: UILabel {
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .adjustedFont(forTextStyle: .footnote)
            label.adjustsFontForContentSizeCategory = true
            label.numberOfLines = 0
            return label
        }

        static var button: UIButton {
            let button = UIButton()
            button.translatesAutoresizingMaskIntoConstraints = false
            button.contentEdgeInsets = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
            button.backgroundColor = ColorProvider.InteractionWeak
            button.setTitleColor(ColorProvider.TextNorm, for: .normal)
            button.tintColor = ColorProvider.InteractionWeak
            button.titleLabel?.font = .adjustedFont(forTextStyle: .footnote)
            button.titleLabel?.adjustsFontForContentSizeCategory = true
            button.titleLabel?.numberOfLines = 1
            button.layer.cornerRadius = 8
            return button
        }

        static var downloadingNewMessagesView: UIView {
            let view = UIView()
            view.translatesAutoresizingMaskIntoConstraints = false
            let spinner = UIActivityIndicatorView()
            spinner.translatesAutoresizingMaskIntoConstraints = false
            spinner.startAnimating()
            let label = UILabel()
            label.translatesAutoresizingMaskIntoConstraints = false
            label.font = .adjustedFont(forTextStyle: .footnote)
            label.adjustsFontForContentSizeCategory = true
            label.textColor = ColorProvider.TextWeak
            label.numberOfLines = 0
            label.text = L11n.EncryptedSearch.settings_refresh_index
            view.addSubview(spinner)
            view.addSubview(label)
            [
                spinner.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                spinner.centerYAnchor.constraint(equalTo: view.centerYAnchor),
                label.leadingAnchor.constraint(equalTo: spinner.trailingAnchor, constant: 12.0),
                label.centerYAnchor.constraint(equalTo: spinner.centerYAnchor),
                label.trailingAnchor.constraint(equalTo: view.trailingAnchor),
                view.topAnchor.constraint(equalTo: label.topAnchor),
                view.bottomAnchor.constraint(equalTo: label.bottomAnchor)
            ].activate()
            return view
        }
    }
}

extension EncryptedSearchDownloadProgressCell {

    enum DownloadingState {
        case fetchingNewMessages
        case downloading(progress: DownloadingProgress)
        case manuallyPaused(progress: DownloadingProgress)
        case error(error: DownloadingProgressError)
    }

    struct DownloadingProgress {
        let messagesDownloaded: String
        let timeRemaining: String
        let percentageDownloaded: Int
    }

    struct DownloadingProgressError {
        let message: String
        let instructions: String
        let percentageDownloaded: Int
        let showResumeButton: Bool
    }
}

protocol EncryptedSearchDownloadProgressCellDelegate: AnyObject {
    func didTapPause()
    func didTapResume()
}

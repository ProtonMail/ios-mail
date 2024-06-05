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

import Combine
import ProtonCoreUIFoundations
import UIKit

final class ApplicationLogsViewController: UIViewController {
    private let viewModel: ApplicationLogsViewModelProtocol
    private let textView: UITextView = SubviewFactory.textView
    private var subscribers: [AnyCancellable] = []

    init(viewModel: ApplicationLogsViewModelProtocol) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        setUpConstraints()
        setUpBindings()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        viewModel.input.viewDidAppear()
    }

    private func setUpUI() {
        navigationItem.title = L10n.Settings.applicationLogs
        let barButtonItem = UIBarButtonItem(barButtonSystemItem: .action, target: self, action: #selector(share))
        navigationItem.rightBarButtonItem = barButtonItem
        view.addSubview(textView)
    }

    private func setUpConstraints() {
        [
            textView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            textView.topAnchor.constraint(equalTo: view.topAnchor),
            textView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            textView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ].activate()
    }

    private func setUpBindings() {
        viewModel
            .output
            .content
            .receive(on: DispatchQueue.main)
            .assign(to: \.text, on: textView)
            .store(in: &subscribers)

        viewModel
            .output
            .fileToShare
            .receive(on: DispatchQueue.main)
            .sink { [weak self] file in
                self?.showShareView(for: file)
            }
            .store(in: &subscribers)

        viewModel
            .output
            .emptyContentReason
            .receive(on: DispatchQueue.main)
            .sink { [weak self] reason in
                self?.showEmptyContentAlert(reason: reason)
            }
            .store(in: &subscribers)
    }

    @objc
    private func share() {
        viewModel.input.didTapShare()
    }

    private func showShareView(for file: URL) {
        let activityVC = UIActivityViewController(activityItems: [file], applicationActivities: nil)
        activityVC.popoverPresentationController?.barButtonItem = navigationItem.rightBarButtonItem
        activityVC.completionWithItemsHandler = { [weak self] _, _, _, _ in
            self?.viewModel.input.shareViewDidDismiss()
        }
        navigationController?.present(activityVC, animated: true)
    }

    private func showEmptyContentAlert(reason: String) {
        let alert = UIAlertController(
            title: LocalString._general_error_alert_title,
            message: reason,
            preferredStyle: .alert
        )
        alert.addOKAction()
        navigationController?.present(alert, animated: true)
    }
}

extension ApplicationLogsViewController {

    private enum SubviewFactory {
        static var textView: UITextView {
            let textView = UITextView()
            textView.translatesAutoresizingMaskIntoConstraints = false
            textView.adjustsFontForContentSizeCategory = true
            textView.font = .adjustedFont(forTextStyle: .footnote)
            textView.textColor = ColorProvider.TextNorm
            textView.isEditable = false
            textView.isSelectable = false
            return textView
        }
    }
}

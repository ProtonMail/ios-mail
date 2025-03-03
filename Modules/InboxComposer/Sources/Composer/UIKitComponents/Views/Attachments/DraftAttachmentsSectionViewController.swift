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

import InboxDesignSystem
import InboxCore
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

struct DraftAttachmentUIModel: Hashable {
    let attachment: AttachmentMetadata
    let status: DraftAttachmentStatus
}

enum DraftAttachmentStatus {
    case offline
    case uploading
    case uploaded
    case error
}

enum DraftAttachmentsSectionEvent {
    case onTap(uiModel: DraftAttachmentUIModel)
    case onRemove(uiModel: DraftAttachmentUIModel)
}

final class DraftAttachmentsSectionViewController: UIViewController {
    private let stack = SubviewFactory.stack
    var uiModels: [DraftAttachmentUIModel] = [] {
        didSet { updateUI() }
    }
    var onEvent: ((DraftAttachmentsSectionEvent) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        updateUI()
    }

    private func setUpUI() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.large),
            stack.topAnchor.constraint(equalTo: view.topAnchor),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.large),
            view.bottomAnchor.constraint(equalTo: stack.bottomAnchor),
        ])
    }

    private func updateUI() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for uiModel in uiModels {
            let view = DraftAttachmentView(onEvent: { [weak self] event, uiModel in
                switch event {
                case .onViewTap:
                    self?.onEvent?(.onTap(uiModel: uiModel))
                case .onButtonTap:
                    self?.showRemoveConfirmation(uiModel: uiModel)
                }
            })
            stack.addArrangedSubview(view)
            view.configure(uiModel: uiModel)
        }
    }

    private func showRemoveConfirmation(uiModel: DraftAttachmentUIModel) {
        let alertController = UIAlertController(
            title: String.empty,
            message: uiModel.attachment.name,
            preferredStyle: .actionSheet
        )

        let remove = UIAlertAction(title: L10n.Attachments.removeAttachmentConfirmation.string, style: .default) { [weak self] _ in
            self?.onEvent?(.onRemove(uiModel: uiModel))
        }
        let cancel = UIAlertAction(title: L10n.Attachments.cancelAttachmentConfirmation.string, style: .cancel)
        alertController.addAction(remove)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }
}

extension DraftAttachmentsSectionViewController {

    private enum SubviewFactory {

        static var stack: UIStackView {
            let view = UIStackView()
            view.translatesAutoresizingMaskIntoConstraints = false
            view.axis = .vertical
            view.alignment = .fill
            view.distribution = .fill
            view.spacing = DS.Spacing.standard
            return view
        }
    }
}

#Preview {
    enum Model {
        static func makeUIModel(name: String, cat: MimeTypeCategory, size: UInt64, status: DraftAttachmentStatus)
        -> DraftAttachmentUIModel {
            let mimeType = AttachmentMimeType(mime: "", category: cat)
            let attachment = AttachmentMetadata(id: .random(), disposition: .attachment, mimeType: mimeType, name: name, size: size)
            return DraftAttachmentUIModel(attachment: attachment, status: status)
        }

        static let uiModels: [DraftAttachmentUIModel] = [
            Model.makeUIModel(name: "meeting_minutes_for_last_friday.pdf", cat: .pdf, size: 36123512, status: .uploading),
            Model.makeUIModel(name: "budget.xls", cat: .excel, size: 263478, status: .uploaded),
            Model.makeUIModel(name: "photo_1.jpg", cat: .image, size: 7824333, status: .offline),
            Model.makeUIModel(name: "photo_2_this_one_a_bit_closer.jpg", cat: .image, size: 6123512, status: .error),
        ]
    }

    final class WrapController: UIViewController {
        let section: DraftAttachmentsSectionViewController = DraftAttachmentsSectionViewController()

        required init?(coder: NSCoder) { nil }

        init() {
            super.init(nibName: nil, bundle: nil)
            section.uiModels = Model.uiModels
            section.onEvent = { event in
                switch event {
                case .onTap(let uiModel):
                    print("tap \(uiModel.attachment.name)")
                case .onRemove(let uiModel):
                    print("remove \(uiModel.attachment.name)")
                    self.remove(uiModel: uiModel)
                }
            }
        }

        private func remove(uiModel: DraftAttachmentUIModel) {
            section.uiModels.removeAll(where: { $0.attachment.id == uiModel.attachment.id })
        }

        override func viewDidLoad() {
            super.viewDidLoad()
            view.addSubview(section.view)
            NSLayoutConstraint.activate([
                section.view.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
                section.view.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
                section.view.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            ])
        }
    }
    return WrapController()
}

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

import Collections
import InboxDesignSystem
import InboxCore
import InboxCoreUI
import proton_app_uniffi
import SwiftUI

struct DraftAttachmentUIModel: Hashable {
    let attachment: AttachmentMetadata
    let status: DraftAttachmentStatus
}

struct DraftAttachmentStatus: Hashable {
    let modifiedAt: Int64
    let state: DraftAttachmentState
}

enum DraftAttachmentsSectionEvent {
    case onTap(uiModel: DraftAttachmentUIModel)
    case onRemove(uiModel: DraftAttachmentUIModel)
    case onRetryAttachmentUpload(uiModel: DraftAttachmentUIModel)
}

final class DraftAttachmentsSectionViewController: UIViewController {
    private let stack = SubviewFactory.stack
    private var topConstraint: NSLayoutConstraint?
    var uiModels: [DraftAttachmentUIModel] = [] {
        didSet { updateUI() }
    }
    private var attachmentErrorAlerts = AttachmentErrorAlertState()
    var onEvent: ((DraftAttachmentsSectionEvent) -> Void)?

    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
        updateUI()
    }

    private func setUpUI() {
        view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)

        let constraint = stack.topAnchor.constraint(equalTo: view.topAnchor)
        topConstraint = constraint
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: DS.Spacing.large),
            constraint,
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -DS.Spacing.large),
            view.bottomAnchor.constraint(equalTo: stack.bottomAnchor),
        ])
    }

    private func updateUI() {
        topConstraint?.constant = uiModels.isEmpty ? 0 : DS.Spacing.large
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }

        for uiModel in uiModels {
            let view = DraftAttachmentView(onEvent: { [weak self] event, uiModel in
                switch event {
                case .onViewTap:
                    // FIXME: when we work on inline attachments
//                    self?.onEvent?(.onTap(uiModel: uiModel))
                    break
                case .onButtonTap:
                    self?.showRemoveConfirmation(uiModel: uiModel)
                }
            })
            stack.addArrangedSubview(view)
            view.configure(uiModel: uiModel)
        }
        // avoid undesired animations caused by re-adding subviews with `addArrangedSubview`
        stack.layoutIfNeeded()

        Task {
            for uiModel in uiModels where uiModel.status.state == .error {
                await enqueueAttachmentErrorAlert(uiModel: uiModel)
            }
        }
    }

    private func showRemoveConfirmation(uiModel: DraftAttachmentUIModel) {
        let alertController = UIAlertController(
            title: String.empty,
            message: uiModel.attachment.name,
            preferredStyle: .actionSheet
        )

        let remove = UIAlertAction(title: L10n.Attachments.removeAttachment.string, style: .default) { [weak self] _ in
            self?.onEvent?(.onRemove(uiModel: uiModel))
        }
        let cancel = UIAlertAction(title: L10n.Attachments.cancelAttachment.string, style: .cancel)
        alertController.addAction(remove)
        alertController.addAction(cancel)
        present(alertController, animated: true)
    }

    private func enqueueAttachmentErrorAlert(uiModel: DraftAttachmentUIModel) async {
        await attachmentErrorAlerts.enqueue(uiModel: uiModel)
        await showNextAttachmentErrorAlertIfNeeded()
    }

    private func makeAttachmentErrorAlert(uiModel: DraftAttachmentUIModel) -> UIAlertController {
        let message = L10n.Attachments.attachmentFailAlertTitle(name: uiModel.attachment.name).string
        let retryTitle = L10n.Attachments.retryAttachmentUpload.string
        let removeTitle = L10n.Attachments.removeAttachment.string

        let alertController = UIAlertController(title: String.empty, message: message, preferredStyle: .alert)
        alertController.addAction(makeAttachmentErrorAlertAction(title: retryTitle, uiModel: uiModel) { [weak self] in
            self?.onEvent?(.onRetryAttachmentUpload(uiModel: uiModel))
        })
        alertController.addAction(makeAttachmentErrorAlertAction(title: removeTitle, uiModel: uiModel) { [weak self] in
            self?.onEvent?(.onRemove(uiModel: uiModel))
        })
        return alertController
    }

    private func makeAttachmentErrorAlertAction(
        title: String,
        uiModel: DraftAttachmentUIModel,
        completion: @escaping () -> Void
    ) -> UIAlertAction {
        UIAlertAction(title: title, style: .default) { [weak self] _ in
            Task {
                completion()
                await self?.attachmentErrorAlerts.setIsAlertPresented(value: false)
                await self?.showNextAttachmentErrorAlertIfNeeded()
            }
        }
    }

    private func showNextAttachmentErrorAlertIfNeeded() async {
        let isAlertPresented = await attachmentErrorAlerts.isAlertPresented
        let isQueueEmpty = await attachmentErrorAlerts.isQueueEmpty()
        guard
            !isAlertPresented && !isQueueEmpty,
            let uiModel = await attachmentErrorAlerts.dequeue()
        else { return }

        await attachmentErrorAlerts.setIsAlertPresented(value: true)
        present(makeAttachmentErrorAlert(uiModel: uiModel), animated: true) {
            let message = "Attachment failed alert: id = \(uiModel.attachment.id), status timestamp = \(uiModel.status.modifiedAt)"
            AppLogger.log(message: message, category: .composer, isError: true)
        }
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

private actor AttachmentErrorAlertState {
    private var queue: OrderedSet<DraftAttachmentUIModel> = []
    private var alreadySeen: OrderedSet<DraftAttachmentUIModel> = []
    private(set) var isAlertPresented = false

    func setIsAlertPresented(value: Bool) {
        isAlertPresented = value
    }

    func isQueueEmpty() async -> Bool {
        queue.isEmpty
    }

    func enqueue(uiModel: DraftAttachmentUIModel) async {
        guard uiModel.status.state == .error, !alreadySeen.contains(uiModel) else { return }
        queue.append(uiModel)
    }

    func dequeue() async -> DraftAttachmentUIModel? {
        guard !queue.isEmpty else { return nil }
        let uiModel = queue.removeFirst()
        alreadySeen.append(uiModel)
        return uiModel
    }
}

#Preview {
    enum Model {
        static func makeUIModel(
            id: UInt64,
            name: String,
            cat: MimeTypeCategory,
            size: UInt64,
            status: DraftAttachmentState, timestamp: Int64 = 1740954885
        ) -> DraftAttachmentUIModel {
            let mimeType = AttachmentMimeType(mime: "", category: cat)
            let attachment = AttachmentMetadata(id: .init(value: id), disposition: .attachment, mimeType: mimeType, name: name, size: size)
            return DraftAttachmentUIModel(attachment: attachment, status: .init(modifiedAt: timestamp, state: status))
        }

        static let uiModels: [DraftAttachmentUIModel] = [
            Model.makeUIModel(id: 1, name: "meeting_minutes_for_last_friday.pdf", cat: .pdf, size: 36123512, status: .uploading),
            Model.makeUIModel(id: 2, name: "budget.xls", cat: .excel, size: 263478, status: .uploaded),
            Model.makeUIModel(id: 3, name: "photo_1.jpg", cat: .image, size: 7824333, status: .offline),
            Model.makeUIModel(id: 4, name: "photo_2_this_one_a_bit_closer.jpg", cat: .image, size: 6123512, status: .uploaded),
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
                case .onRetryAttachmentUpload(let uiModel):
                    print("retry \(uiModel.attachment.name)?")
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

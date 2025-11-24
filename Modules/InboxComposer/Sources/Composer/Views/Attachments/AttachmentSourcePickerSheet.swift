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

import InboxCoreUI
import InboxDesignSystem
import SwiftUI

struct AttachmentSourcePickerSheet: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject private var model: AttachmentSourcePickerSheetModel = .init()
    private let options: [AttachmentSource] = [.photoGallery, .camera, .files]
    var pickerState: Binding<AttachmentPickersState>

    var body: some View {
        ClosableScreen {
            ScrollView {
                VStack(spacing: .zero) {
                    ForEach(options) { option in
                        listItemView(image: option.image, title: option.title, separator: option != options.last) {
                            if model.isAuthorized(source: option) {
                                switch option {
                                case .photoGallery:
                                    pickerState.wrappedValue.isPhotosPickerPresented = true
                                case .camera:
                                    pickerState.wrappedValue.isCameraPresented = true
                                case .files:
                                    pickerState.wrappedValue.isFileImporterPresented = true
                                }

                                dismiss()
                            } else {
                                if option == .camera {
                                    model.setAlertModelForMissingCameraPermission()
                                }
                            }
                        }
                    }
                }
                .clipShape(.rect(cornerRadius: DS.Radius.extraLarge))
            }
            .padding(.all, DS.Spacing.large)
            .navigationTitle(L10n.Attachments.addAttachments.string)
            .navigationBarTitleDisplayMode(.inline)
            .background(DS.Color.BackgroundInverted.norm)
        }
        .alert(model: $model.alertModel)
        .presentationDetents([.fraction(0.4)])
    }

    private func listItemView(image: ImageResource, title: String, separator: Bool, action: @escaping () -> Void) -> some View {
        VStack(spacing: .zero) {
            Button(action: action) {
                HStack(spacing: DS.Spacing.large) {
                    Image(image)
                        .resizable()
                        .square(size: 24)
                        .foregroundStyle(DS.Color.Icon.weak)

                    Text(title)
                        .lineLimit(1)
                        .foregroundStyle(DS.Color.Text.weak)
                        .padding(.trailing, DS.Spacing.large)

                    Spacer()
                }
                .frame(height: 52)
                .padding(.leading, DS.Spacing.large)
            }
            .buttonStyle(RegularButtonStyle())

            if separator {
                Divider().frame(height: 1)
            }
        }
    }
}

enum AttachmentSource: Int, Identifiable {
    case photoGallery
    case camera
    case files

    var id: Int {
        rawValue
    }
}

private extension AttachmentSource {

    var image: ImageResource {
        switch self {
        case .photoGallery:
            DS.Icon.icImage
        case .camera:
            DS.Icon.icCamera
        case .files:
            DS.Icon.icFolderOpen
        }
    }

    var title: String {
        switch self {
        case .photoGallery:
            L10n.Attachments.attachmentFromPhotoLibrary.string
        case .camera:
            L10n.Attachments.attachmentFromCamera.string
        case .files:
            L10n.Attachments.attachmentImport.string
        }
    }
}

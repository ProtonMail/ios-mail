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
import proton_app_uniffi
import SwiftUI

struct ScheduleSendPickerSheet: View {
    enum SheetScreen {
        case main
        case datePicker
    }

    @State private var currentScreen: SheetScreen = .main
    @State private var detent: PresentationDetent = .medium
    @State private var allowedDetents: Set<PresentationDetent> = [.medium, .large]

    private let dateFormatter: ScheduleSendDateFormatter
    private let predefinedTimeOptions: ScheduleSendTimeOptions
    private let isCustomOptionAvailable: Bool
    private let onTimeSelected: (Date) async -> Void

    init(
        predefinedTimeOptions: ScheduleSendTimeOptions,
        isCustomOptionAvailable: Bool,
        dateFormatter: ScheduleSendDateFormatter = .init(),
        onTimeSelected: @escaping (Date) async -> Void
    ) {
        self.dateFormatter = dateFormatter
        self.predefinedTimeOptions = predefinedTimeOptions
        self.isCustomOptionAvailable = isCustomOptionAvailable
        self.onTimeSelected = onTimeSelected
    }

    var body: some View {
        VStack {
            switch currentScreen {
            case .main:
                ScheduleSendTimeOptionsView(
                    predefinedTimeOptions: predefinedTimeOptions,
                    isCustomOptionAvailable: isCustomOptionAvailable,
                    dateFormatter: dateFormatter,
                    onTimeSelected: onTimeSelected
                ) {
                    withAnimation(.easeInOut) {
                        currentScreen = .datePicker
                        detent = .large
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        allowedDetents = [.large]
                    }
                }

            case .datePicker:
                DatePickerView(
                    configuration: ScheduleDatePickerConfiguration(dateFormatter: dateFormatter),
                    onCancel: {
                        withAnimation(.easeInOut) {
                            currentScreen = .main
                            detent = .medium
                            allowedDetents = [.medium, .large]
                        }
                    },
                    onSelect: { date in
                        Task {
                            await onTimeSelected(date)
                        }
                    }
                )
            }
        }
        .animation(.easeInOut, value: currentScreen)
        .transition(.identity)
        .presentationDetents(allowedDetents, selection: $detent)
        .interactiveDismissDisabled(currentScreen == .datePicker)
    }
}

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

import InboxCore
import InboxDesignSystem
import SwiftUIIntrospect
import SwiftUI

public struct DatePickerView: View {
    @State private var selectedDate: Date
    @State private var configuration: DatePickerViewConfiguration
    private let onCancel: () -> Void
    private let onSelect: (Date) -> Void
    private let datePickerDefaultLabelColor = Color(UIColor.label)
    private let datePickerDefaultLabelBackgroundColor = Color(UIColor.tertiarySystemFill)

    public init(configuration: DatePickerViewConfiguration, onCancel: @escaping () -> Void, onSelect: @escaping (Date) -> Void) {
        self.onCancel = onCancel
        self.onSelect = onSelect
        self.selectedDate = configuration.resolvedInitialDate
        self.configuration = configuration
    }

    public var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Spacing.large) {
                HStack {
                    Button(CommonL10n.cancel.string, action: onCancel)
                        .foregroundStyle(DS.Color.Text.accent)
                        .font(.body)
                        .fontWeight(.regular)

                    Spacer()
                    Text(configuration.title)
                        .lineLimit(1)
                        .foregroundStyle(DS.Color.Text.norm)
                        .font(.body)
                        .fontWeight(.semibold)

                    Spacer()
                    Button(configuration.selectTitle.string) {
                        onSelect(selectedDate)
                    }
                    .foregroundStyle(DS.Color.InteractionBrand.norm)
                    .font(.body)
                    .fontWeight(.semibold)
                }
                .padding(.bottom, DS.Spacing.standard)

                DatePicker(
                    CommonL10n.time.string,
                    selection: $selectedDate,
                    in: configuration.range,
                    displayedComponents: .hourAndMinute
                )
                .introspect(.datePicker, on: SupportedIntrospectionPlatforms.datePicker) {
                    $0.minuteInterval = Int(configuration.minuteInterval)
                }
                .tint(DS.Color.Brand.norm)
                .padding(.horizontal, DS.Spacing.large)
                .padding(.vertical, DS.Spacing.standard)
                .background(RoundedRectangle(cornerRadius: DS.Radius.extraLarge).fill(DS.Color.Background.norm))

                VStack {
                    HStack {
                        Text(CommonL10n.date.string)
                            .font(.body)
                            .fontWeight(.regular)
                            .foregroundStyle(datePickerDefaultLabelColor)

                        Spacer()
                        Text(configuration.formatDate(selectedDate))
                            .font(.body)
                            .fontWeight(.regular)
                            .foregroundStyle(datePickerDefaultLabelColor)
                            .padding(.horizontal, DS.Spacing.medium)
                            .padding(.vertical, DS.Spacing.standard)
                            .background(RoundedRectangle(cornerRadius: DS.Radius.medium).fill(datePickerDefaultLabelBackgroundColor))
                    }
                    .padding(.horizontal, DS.Spacing.large)
                    .padding(.top, DS.Spacing.standard)
                    .padding(.bottom, DS.Spacing.tiny)

                    DS.Color.BackgroundInverted.border
                        .frame(height: 1)
                        .padding(.horizontal, DS.Spacing.large)

                    DatePicker(
                        CommonL10n.date.string,
                        selection: $selectedDate,
                        in: configuration.range,
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .tint(DS.Color.Brand.norm)
                    .padding(.horizontal, DS.Spacing.small)
                }
                .background(RoundedRectangle(cornerRadius: DS.Radius.extraLarge).fill(DS.Color.Background.norm))

                Spacer()
            }
            .padding(DS.Spacing.large)
        }
        .background(DS.Color.Background.secondary)
    }
}

#Preview {
    struct DummyDatePickerConfiguration: DatePickerViewConfiguration {
        private let dateFormatter = {
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter
        }()

        let title: LocalizedStringResource = "Date Picker".stringResource
        let selectTitle: LocalizedStringResource = "Select".stringResource
        let minuteInterval: TimeInterval = 15

        var rangeStart: Date { Calendar.current.date(byAdding: .minute, value: 15, to: .now)! }

        var rangeEnd: Date {
            Calendar.current.date(byAdding: .day, value: 180, to: .now)!
        }

        var range: ClosedRange<Date> {
            let start = Calendar.current.date(byAdding: .minute, value: 15, to: .now)!
            let end = Calendar.current.date(byAdding: .day, value: 180, to: .now)!
            return start...end
        }

        var initialSelectedDate: Date? {
            range.lowerBound
        }

        func formatDate(_ date: Date) -> String {
            dateFormatter.string(from: date)
        }
    }
    return DatePickerView(configuration: DummyDatePickerConfiguration(), onCancel: {}, onSelect: { _ in })
}

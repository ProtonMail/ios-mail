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

@testable import ProtonMail

extension EventDetails {
    static func make(
        startDate: Date = .init(timeIntervalSince1970: .random(in: 0...(.greatestFiniteMagnitude))),
        endDate: Date = .init(timeIntervalSince1970: .random(in: 0...(.greatestFiniteMagnitude))),
        status: EventStatus = .confirmed
    ) -> Self {
        .init(
            title: "Team Collaboration Workshop",
            startDate: startDate,
            endDate: endDate,
            calendar: .init(name: "My Calendar", iconColor: "#FFEEEE"),
            location: .init(name: "Zoom call"),
            participants: [
                .init(email: "boss@example.com", isOrganizer: true, status: .attending),
                .init(email: "participant.1@proton.me", isOrganizer: false, status: .attending),
                .init(email: "participant.2@proton.me", isOrganizer: false, status: .attending),
                .init(email: "participant.3@proton.me", isOrganizer: false, status: .attending)
            ],
            status: status,
            calendarAppDeepLink: URL(string: "ProtonCalendar://events/foo")!
        )
    }
}
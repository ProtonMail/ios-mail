// Copyright (c) 2022 Proton Technologies AG
//
// This file is part of Proton Technologies AG and Proton Calendar.
//
// Proton Calendar is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Calendar is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Calendar. If not, see https://www.gnu.org/licenses/.

import ProtonInboxICal

public enum EventType {
    case singleEdit(SingleEdit)
    case nonRecurring
    case recurring(RecurrenceDetails)
    case encrypted

    public enum SingleEdit: Equatable {
        case regular(editInfo: EditInfo)
        case orphan

        public enum EditCount: Equatable {
            case one
            case moreThanOne
        }

        public struct EditInfo: Equatable {
            public let editCount: EditCount
            public let deletionCount: UInt

            public init(editCount: EditCount, deletionCount: UInt) {
                self.editCount = editCount
                self.deletionCount = deletionCount
            }
        }
    }

    public struct RecurrenceDetails {
        public let mainOccurrence: ICalEvent
        public let singleEdits: [ICalEvent]

        public init(mainOccurrence: ICalEvent, singleEdits: [ICalEvent]) {
            self.mainOccurrence = mainOccurrence
            self.singleEdits = singleEdits
        }
    }
}

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

@testable import ProtonCoreICS
import Quick
import Nimble

final class ICSEventParserSpec: QuickSpec {

    override func spec() {
        describe("ICSEventsParser") {
            var parser: ICSEventParser!

            beforeEach {
                parser = ICSEventParser()
            }

            afterEach {
                parser = nil
            }

            describe("parsing ICS string") {
                var icsString: String!
                var result: [ICSEvent]!

                afterEach {
                    icsString = nil
                    result = nil
                }

                context("with single event data") {
                    beforeEach {
                        icsString = """
                            BEGIN:VEVENT
                            UID:123456
                            END:VEVENT
                        """
                        result = parser.parse(icsString: icsString)
                    }

                    it("parses single event")  {
                        expect(result).to(haveCount(1))
                    }

                    it("parses event UID")  {
                        expect(result.first?.uid).to(equal("123456"))
                    }
                }

                context("with multiple events data") {
                    beforeEach {
                        icsString = """
                            BEGIN:VEVENT
                            UID:123456
                            END:VEVENT
                            BEGIN:VEVENT
                            UID:789012
                            END:VEVENT
                        """
                        result = parser.parse(icsString: icsString)
                    }

                    it("parses all events")  {
                        expect(result).to(equal([
                            ICSEvent(uid: "123456"),
                            ICSEvent(uid: "789012")
                        ]))
                    }
                }

                context("with VCALENDAR component") {
                    beforeEach {
                        icsString = """
                          BEGIN:VCALENDAR
                          VERSION:2.0
                          METHOD:REPLY
                          CALSCALE:GREGORIAN
                          BEGIN:VEVENT
                          DTSTART;TZID=Europe/Zurich:20210907T193617
                          DTEND;TZID=Europe/Zurich:20210907T203617
                          SEQUENCE:0
                          ORGANIZER;CN=john:mailto:john.doe@proton.ch
                          SUMMARY:John Doe meeting
                          UID:fT9gy2ARxK5VOzSmhcvKJ6yaqKQB@proton.me
                          DTSTAMP:20210907T153617Z
                          END:VEVENT
                          END:VCALENDAR
                        """
                        result = parser.parse(icsString: icsString)
                    }

                    it("parses event")  {
                        expect(result).to(equal([ICSEvent(uid: "fT9gy2ARxK5VOzSmhcvKJ6yaqKQB@proton.me")]))
                    }
                }

                context("with complex ICS containing recurring event") {
                    beforeEach {
                        icsString = complexICSWithRecurringEvent
                        result = parser.parse(icsString: icsString)
                    }

                    it("parses all events")  {
                        expect(result).to(equal([
                            ICSEvent(uid: "Event1"),
                            ICSEvent(uid: "Event2"),
                            ICSEvent(uid: "Event3")
                        ]))
                    }
                }

                context("with invalid ICS") {
                    beforeEach {
                        icsString = "InvalidICSString"
                    }

                    it("returns empty array") {
                        result = parser.parse(icsString: icsString)
                        expect(result).to(beEmpty())
                    }

                    context("with incomplete event") {
                        beforeEach {
                            icsString = "BEGIN:VEVENT\nUID:EventUID\n"
                        }

                        it("returns empty array") {
                            result = parser.parse(icsString: icsString)
                            expect(result).to(beEmpty())
                        }
                    }
                }
            }
        }
    }

}

private let complexICSWithRecurringEvent = """
    BEGIN:VCALENDAR
    VERSION:2.0
    PRODID:-//Company//App//EN
    CALSCALE:GREGORIAN
    BEGIN:VEVENT
    UID:Event1
    SUMMARY:Meeting with Client
    DESCRIPTION:Discuss project updates and milestones.
    LOCATION:Conference Room A
    DTSTART:20230101T100000
    DTEND:20230101T120000
    STATUS:CONFIRMED
    SEQUENCE:0
    BEGIN:VALARM
    TRIGGER:-PT15M
    DESCRIPTION:Meeting Reminder
    ACTION:DISPLAY
    END:VALARM
    END:VEVENT
    BEGIN:VEVENT
    UID:Event2
    SUMMARY:Team Building
    DESCRIPTION:Fun team-building activities and games.
    LOCATION:Outdoor Park
    DTSTART:20230115T140000
    DTEND:20230115T170000
    STATUS:CONFIRMED
    SEQUENCE:0
    RRULE:FREQ=WEEKLY;COUNT=10;BYDAY=TU,TH
    END:VEVENT
    BEGIN:VEVENT
    UID:Event3
    SUMMARY:Product Launch
    DESCRIPTION:Launch event for new product line.
    LOCATION:Convention Center
    DTSTART:20230201T180000
    DTEND:20230201T220000
    STATUS:CONFIRMED
    SEQUENCE:0
    BEGIN:VALARM
    TRIGGER:-PT30M
    DESCRIPTION:Product Launch Reminder
    ACTION:DISPLAY
    END:VALARM
    END:VEVENT
    END:VCALENDAR
"""

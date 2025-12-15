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

import Foundation

enum UITestLoginType {
    case loggedIn(UITestUser)
    case loggedOut
}

extension UITestLoginType {
    enum Unmocked {
        enum Black {
            enum Free {
                static let Free = UITestLoginType.loggedIn(
                    UITestUser(
                        id: "free",
                        username: "freefreefree",  // 'free' is upgraded for some reason
                        password: "password"
                    )
                )
            }

            enum Paid {
                static let Plus = UITestLoginType.loggedIn(
                    UITestUser(
                        id: "plus",
                        username: "plus",
                        password: "plus"
                    )
                )
            }
        }
    }

    enum Mocked {
        enum Free {
            static let SleepyKoala = UITestLoginType.loggedIn(
                UITestUser(id: "slpkla", username: "sleepykoala", password: "password")
            )

            static let ChirpyFlamingo = UITestLoginType.loggedIn(
                UITestUser(id: "crpfgo", username: "chirpyflamingo", password: "password")
            )
        }

        enum Paid {
            static let FancyCapybara = UITestLoginType.loggedIn(
                UITestUser(
                    id: "fncyra",
                    username: "fancycapybara@proton.black",
                    password: "password"
                )
            )
            static let YoungBee = UITestLoginType.loggedIn(
                UITestUser(
                    id: "yngbee",
                    username: "youngbee@proton.black",
                    password: "password"
                )
            )
            static let TinyBarracuda = UITestLoginType.loggedIn(
                UITestUser(
                    id: "tnybcd",
                    username: "tinybarracuda@proton.black",
                    password: "password"
                )
            )
        }

        enum External {
            static let StrangeWalrus = UITestLoginType.loggedIn(
                UITestUser(id: "stgwrs", username: "strangewalrus", password: "password")
            )
        }

        enum Deprecated {
            static let GrumpyCat = UITestLoginType.loggedIn(
                UITestUser(id: "gmpcat", username: "grumpycat@proton.black", password: "password")
            )
        }
    }
}

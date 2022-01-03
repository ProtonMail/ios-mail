// Copyright (c) 2021 Proton Technologies AG
//
// This file is part of ProtonMail.
//
// ProtonMail is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// ProtonMail is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with ProtonMail. If not, see https://www.gnu.org/licenses/.

import Foundation
@testable import ProtonMail

final class EncryptionKitProviderMock: EncryptionKitProvider {
    static let UID = "mockUID"
    private let passphrase = "39FA7B74-C560-4E56-A427-B3B2D59FCC5C"
    private let privateKey = """
    -----BEGIN PGP PRIVATE KEY BLOCK-----
    Version: GopenPGP 2.2.4
    Comment: https://gopenpgp.org

    xYYEYbc+LxYJKwYBBAHaRw8BAQdAK3wLeMTY8W4vo1BpHhcKS4eFrQxqqSqckChK
    SOZf5GP+CQMIH88+OLAAR1FgaoAgW11D+HLfanDz9NRX2bGSFsplRM0qdSsk3tf9
    OidMSdhP9M0xYEgHvQJeHLueBCfA5G9oWwxi5zP6qB8vHoT7ueH8s81aRDYyOEYw
    RTUtNUExNC00MkU1LTlEMEUtNUQwOTIxQTY5NTY1IDxENjI4RjBFNS01QTE0LTQy
    RTUtOUQwRS01RDA5MjFBNjk1NjVAcHJvdG9ubWFpbC5jb20+wowEExYIAD4FAmG3
    Pi8JkOrAqfckqsOEFqEEWRi/OzkXh8FmRO2y6sCp9ySqw4QCGwMCHgECGQEDCwkH
    AhUIAxYAAgIiAQAAgm8BAO8c5JoeAF/t+74W7YFNDhDQ8XVQ70dsBfarRNuyyDKp
    AQCp2nPOyA0kOj5CQu0V0yDZgHAbwfzO9DkrUt7cgVUbCseLBGG3Pi8SCisGAQQB
    l1UBBQEBB0CyBv2X02nvfmrSLxURbAjxdee726Yx/xfPG9yz9/goGQMBCgn+CQMI
    xWtBs7tBMZNgdyFqp6fQjqdJFk2jTIJwbTCZeBZCrOD0Zhm9/W6aZAhAnR9il4SR
    5ZixsMkX1gFKCgZn3J+MWBhewu024cOcabZDqbJufsJ4BBgWCAAqBQJhtz4vCZDq
    wKn3JKrDhBahBFkYvzs5F4fBZkTtsurAqfckqsOEAhsMAACJ+gD/cOZxJ4uvJRNB
    naO1lfOZoueS7TQzSiTDWJF6VgoFWGIA/0SYMWd6KUWmY1LH5QojoDsLO0RuCg3J
    NbD6OofenqYD
    =Vxyd
    -----END PGP PRIVATE KEY BLOCK-----
    """
    let publicKey = """
    -----BEGIN PGP PUBLIC KEY BLOCK-----
    Version: GopenPGP 2.2.4
    Comment: https://gopenpgp.org

    xjMEYbc+LxYJKwYBBAHaRw8BAQdAK3wLeMTY8W4vo1BpHhcKS4eFrQxqqSqckChK
    SOZf5GPNWkQ2MjhGMEU1LTVBMTQtNDJFNS05RDBFLTVEMDkyMUE2OTU2NSA8RDYy
    OEYwRTUtNUExNC00MkU1LTlEMEUtNUQwOTIxQTY5NTY1QHByb3Rvbm1haWwuY29t
    PsKMBBMWCAA+BQJhtz4vCZDqwKn3JKrDhBahBFkYvzs5F4fBZkTtsurAqfckqsOE
    AhsDAh4BAhkBAwsJBwIVCAMWAAICIgEAAIJvAQDvHOSaHgBf7fu+Fu2BTQ4Q0PF1
    UO9HbAX2q0TbssgyqQEAqdpzzsgNJDo+QkLtFdMg2YBwG8H8zvQ5K1Le3IFVGwrO
    OARhtz4vEgorBgEEAZdVAQUBAQdAsgb9l9Np735q0i8VEWwI8XXnu9umMf8Xzxvc
    s/f4KBkDAQoJwngEGBYIACoFAmG3Pi8JkOrAqfckqsOEFqEEWRi/OzkXh8FmRO2y
    6sCp9ySqw4QCGwwAAIn6AP9w5nEni68lE0Gdo7WV85mi55LtNDNKJMNYkXpWCgVY
    YgD/RJgxZ3opRaZjUsflCiOgOws7RG4KDck1sPo6h96epgM=
    =zmIB
    -----END PGP PUBLIC KEY BLOCK-----
    """
    func encryptionKit(forSession uid: String) -> EncryptionKit? {
        guard uid == Self.UID else { return nil }
        return EncryptionKit(passphrase: passphrase, privateKey: privateKey, publicKey: publicKey)
    }

    func markForUnsubscribing(uid: String) {}
}

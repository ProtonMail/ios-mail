// Copyright (c) 2021 Proton AG
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

struct ContactParserTestData {
    static let plainTextData = """
    BEGIN:VCARD
    VERSION:4.0
    PRODID:-//Proton AG//Easy Switch vCard 1.0//EN
    FN:Test 1 yoooo 陳 sir
    UID:proton-import-c4acbb1b
    item1.EMAIL;PREF=1;TYPE=工作:iamtest@aaa.bbb
    END:VCARD
    """

    static let encryptedOnlyData = """
    -----BEGIN PGP MESSAGE-----
    Version: ProtonMail

    wV4D1dl2VeO1wN4SAQdAvb6AgajnDEznpQwgl1KBg70Kw5l32RA+/qLQL8et
    UiYw9IqGQROb0Am6h0KU/hvAHQqEJaH+saE9LqyCMKp0nraK5xNt++03s9OS
    0uZJGnoi0sBaAQKKbTSomH59Z/eZ+iYuNsseC7dhXSi4hEjE3FwC574Dp2zk
    8L0WeKlNVQiS8HECsqPafnGD4sDExHW3DCkPQscqdVOXHg7pkb9rkRZqr2TI
    Y1qCYSsTnVqlpwtLdS4CY2EjchM+95NUM+PKPaVtJPM9M3n5WFGLqna1O3v9
    i+raOViZrPX2Z3Glh0ED8QQeyLQvB61j50sqlAOnh50CrXw0jkFQZvhZJF7p
    J7HSuZSWMNDFf9Xiyj7R0nDt546gVPi5WpeNPvl8XXFujSg148nsOSbLzxHJ
    +gQnbWEmjYZSbw78wwwrpbSrTosBBY4Qp3iap62BUFB6XkJ4mtf0t2PRqaF0
    nDjXdfH0geJwuAyrsWTiywfp7TQ7
    =kuIg
    -----END PGP MESSAGE-----
    """

    static let passphrase = "Q0FzNt.aLUZFrZEqTLUHa./jj6b1Fm."

    static let privateKey = """
    -----BEGIN PGP PRIVATE KEY BLOCK-----
    Version: ProtonMail

    xYYEYbb4shYJKwYBBAHaRw8BAQdAltSgDcsJKEQJ+QwzbIlC64FYZO4eZZIy
    MCQGN5Td07b+CQMI3Xr8x77BDdFga1A/pti4vw3GsAEAZR3rpVu5QCALFb8f
    QSqbKyQ/ezT67B0cJ+cXEa1s9cPLf9cRHJ8siyHZcWbZx3shKHgHOWI3+Pgs
    Tc07bm90X2Zvcl9lbWFpbF91c2VAZG9tYWluLnRsZCA8bm90X2Zvcl9lbWFp
    bF91c2VAZG9tYWluLnRsZD7CjwQQFgoAIAUCYbb4sgYLCQcIAwIEFQgKAgQW
    AgEAAhkBAhsDAh4BACEJEMny2Xa+3tX5FiEEQ/CmNttsDx5snpTxyfLZdr7e
    1fkGAwEAvimEwhCoVF8vTqkWVv4BmOxVtrZ3R6r6GSY0U6/5ydkBAP1e33p7
    ik/uleB4PL5320LSBYqxPcFzPcHuntBmg5UCx4sEYbb4shIKKwYBBAGXVQEF
    AQEHQMO/gC3PXQLSo2C6X0b9t+96W6IlSchK/E369TQFVfZoAwEIB/4JAwgH
    KtaoLWcU7GDAQqUZUqMNSUo8H1/p2Nd+shGGvgrv6K2uDlcgO07HLn/FmZJr
    ekEOL+XexJkB4EztKL/cn/JU8rujhiksi6qF/XOPpWsGwngEGBYIAAkFAmG2
    +LICGwwAIQkQyfLZdr7e1fkWIQRD8KY222wPHmyelPHJ8tl2vt7V+R41AQDS
    pCfMHADEFX0V4pWYuqY0+cXk+CeZuzU7KCcxs8nsiAD/UPYo0uexR5Fj1HQe
    oTUOSDkIz7FqfbgtF7xQqzylPw4=
    =hpdD
    -----END PGP PRIVATE KEY BLOCK-----
    """

    static let signedOnlySignature = """
    -----BEGIN PGP SIGNATURE-----
    Version: ProtonMail

    wnUEARYKAAYFAmG3Fj0AIQkQyfLZdr7e1fkWIQRD8KY222wPHmyelPHJ8tl2
    vt7V+YajAPwPEUIIlMQDePsYWgKtx0jdV4SXAoNzGw0ci1HrrIJlbwD/XdNt
    VTHLuUUYOx9Ubm83BX/d1l89vh/B54Ar8is66Q8=
    =K1wR
    -----END PGP SIGNATURE-----
    """

    static let signedOnlyData = """
    BEGIN:VCARD
    VERSION:4.0
    FN;PREF=1:Full field
    ITEM1.EMAIL;PREF=1:emaile@aaa.bbb
    ITEM2.EMAIL;TYPE=home;PREF=2:home@aaa.bbb
    ITEM3.EMAIL;TYPE=work;PREF=3:work@aaa.bbb
    ITEM4.EMAIL;TYPE=other;PREF=4:other@aaa.bbb
    UID:proton-web-4bdbbabd-1ac2-2850-a809-42d673d7771a
    END:VCARD
    """

    static let signAndEncryptSignature = """
    -----BEGIN PGP SIGNATURE-----
    Version: ProtonMail

    wnUEARYKAAYFAmG3Fj0AIQkQyfLZdr7e1fkWIQRD8KY222wPHmyelPHJ8tl2
    vt7V+VXrAP42XP8Shmu+6nUJYKcOFbug3jkNJV3O5mEvvD+afVT9aQD9E/K3
    BropYQlzmjh23NkNwJQFV5tnXSy3RjH0OcdH9Ac=
    =rZvS
    -----END PGP SIGNATURE-----
    """

    static let signAndEncryptData = """
    -----BEGIN PGP MESSAGE-----
    Version: ProtonMail

    wV4D1dl2VeO1wN4SAQdAu22/U5+176/XrFIdUJDAFyiDc80kysdNUKionjS0
    aAIwfpdnkx9uMmBtc5TPe0wMcy8v772cNBf8orn+TeeTt34498Hpoxo7/Uxe
    BwvLmNil0sIqAUpIN7TKwHOu31GdKU2umrQgZ7RbcfihzFIh2hJBifYq7ltz
    MKMeGe+Ygx22CTehJd8UA3h0JDISobHjiaitN+o9SzIbR8FGWaydaEoqRNIY
    kTUoU0DnO3tDkLcJN1zqMAFnnO8rplzaa6uORGAnylMyVh/Y5MpwhgNhk9Sl
    FzMskRQRU39jYqVSuKOfOanhVkLEsZ1IMuZBDAUqnWyKkYbxU1aSaLdFWFI/
    bP1bNBUWFOqBhbhFlICL/iNLsYyw9Y8voUTn8+IRtQ8LT28jMCS6oCv8qK1R
    KV3+EXVA++RJegx6BxwngBoQIthucZr3b1kLh8Rz91jZbWsV1YztlvWQtbNX
    7rIuL+xtIwbbBaQrmevkLR2TbptKN4RqRw5P0YiOMyJVvV5pb9VT+1OVFhPE
    4/4mt0JYsYsd0h4SPB9hN35W2oVHOAosyuR/wcNlQGo5AO7/cqu8ZQqybny5
    Vx38L3IYYChah/EyHAfFSbOJr+YXC7lfh65HsLwEatIWH3adIvlqdFKkBxOy
    rWmtDxQgLNxVz1fX2qPzOptykJkec8DSeyyP2mzwL3FCxuZyh/QTrC6P9knq
    B7S76Jy9VwgrcUhao2C31/PiyVIApUxJOZMPA3MFYAtlA+Z+UrNRO6BOAOUh
    0BUf5VGi8EYUkAGPWZYwxBY8VpG2SU8YlFplh0S0v/6Jwh32h5GB0ZGr9OLj
    OgGnjwSM401Jwb5GMjNuf4dO8yH/t9GKju3jTjAQ2syyYwuVKYrN1qTnb6Gi
    TcbeVj7Tom3g0cnR5CN83sSgwtbGbikXzzG8V+v47aNcxsfUjZKXWFalvm6T
    df250W1Xx4+/MEYXD3jpLgIKoFSIF5CHtlEntJlMwsfG3UMU6e1wH0/FbjE0
    8RfhALxbrLdIegXV8E5u++H2vvDY7S4p4pwxSRHaIVtetxpCvOe4DXhq/F8Z
    4YkwQKEg+pVR1G8KlHy+hZK/0iLCSj3bxiI1K6b5YoDvxW8=
    =ZIDA
    -----END PGP MESSAGE-----
    """
}

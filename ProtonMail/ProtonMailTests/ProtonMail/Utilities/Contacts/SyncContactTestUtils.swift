// Copyright (c) 2023 Proton Technologies AG
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
import ProtonCoreDataModel
import ProtonCoreCrypto

enum SyncContactTestUtils {

    /**
     This is the content that should be in the contact card data:

     BEGIN:VCARD
     VERSION:3.0
     PRODID:-//Apple Inc.//iPhone OS 17.0//EN
     N:Bell;Kate;;;
     FN:Kate Bell
     ORG:Creative Consulting;
     TITLE:Producer
     EMAIL;type=INTERNET;type=WORK;type=pref:kate-bell@mac.com
     TEL;type=MAIN;type=pref:(415) 555-3695
     TEL;type=CELL;type=VOICE:(555) 564-8583
     item1.ADR;type=WORK;type=pref:;;165 Davis Street;Hillsborough;CA;94010;
     item1.X-ABADR:us
     item2.URL;type=pref:www.icloud.com
     item2.X-ABLabel:_$!<HomePage>!$_
     BDAY:1978-01-20
     END:VCARD
     */
    static var contactCardData: String {
        "[{\"Signature\":\"-----BEGIN PGP SIGNATURE-----\\nVersion: ProtonMail\\n\\nwnUEARYKACcFAmVp8BQJEDpWGY8tUvWiFiEEkwjBgOxaE4Ws92l+OlYZjy1S\\n9aIAAHigAQChQNRcuoGjc15HUOB4NB665uSW\\/wFmpQI+NpFTQLbSJQEAlBiZ\\nHjt0xZIcKreucx9QWHYWr5QTGeYp\\/E1txRWfmwo=\\n=bRKB\\n-----END PGP SIGNATURE-----\\n\",\"Type\":2,\"Data\":\"BEGIN:VCARD\\r\\nVERSION:4.0\\r\\nPRODID:pm-ez-vcard 0.0.1\\r\\nUID:protonmail-ios-EABDB6DD-7633-48F6-A58D-3506FAF07015\\r\\nFN:Kate Bell\\r\\nItem1.EMAIL;TYPE=INTERNET:kate-bell@mac.com\\r\\nEND:VCARD\\r\\n\"},{\"Signature\":\"-----BEGIN PGP SIGNATURE-----\\nVersion: ProtonMail\\n\\nwnUEARYKACcFAmVp8BQJEDpWGY8tUvWiFiEEkwjBgOxaE4Ws92l+OlYZjy1S\\n9aIAAPavAP9Gyg5zXmsdIt28Ap3z41k0sy20qiinwqsJbvQ3Xt40SgD\\/Qg0Q\\nP3daJDgY9VXswEZ2rDO8zY4k\\/KVuGyg2JhmEyw8=\\n=13AW\\n-----END PGP SIGNATURE-----\\n\",\"Type\":3,\"Data\":\"-----BEGIN PGP MESSAGE-----\\nVersion: ProtonMail\\n\\nwV4Ds2QhTCgZJYYSAQdAPaet9HkFCQ8lWtAXx+wvGxGSomZpw87D6GFtmIRB\\nmVkwhg7tqClgT6UXGTSYhDIs9ob17wzZIAdln4jxgmv7CgtYbB3OSrwF8qOS\\nXLDLlc1M0sCVAQYvm\\/GBPoWYKXZlgPcM+LRpk0vHpx5VIqznJPlP915i6OZ9\\n5tBkIFLwcn6WU7qZN610Ck28GcBFm2GiFYvyb3qthYqhSdpdahAb+ijRR\\/tc\\nMWxMi6M0qgk7qQtxlgvRTq1lIANDOaRwI7wIzE8RaeZ8hsJ8pAH2mToDRmkO\\nDkv4GCTxETXpMWMPk0E00y3rxAfUm44paykcNTJF57WLPivcj\\/jYRRbR\\/LwZ\\nAX7ghHj9rT5eaJNNqO27xNdjiOeVbsaZjOQ28iVa6cIxRwf6B8O1DLICt+Ls\\nHCoP45A3IgsxGwzAeyOlno724vgDFScTWQk8UPd\\/\\/wu6Z0bUdnUi8nW+wFv4\\nw32rO2KyvNK\\/M8mPn1UcareSjM+Y1rBF820UmzrK7OjHMxb2WuJpPQgJWDPS\\nMimPieldNLV0g7e+T6yTbrVgQ\\/YjXkQ5qpiZWd57g7R4nHA=\\n=Yhx1\\n-----END PGP MESSAGE-----\\n\"}]"
    }
    
    /// private key for `contactCardData`
    static var privateKey: String {
        """
        -----BEGIN PGP PRIVATE KEY BLOCK-----
        Version: ProtonMail

        xYYEZUUC7RYJKwYBBAHaRw8BAQdADAS6LPy3U4JZMVSb8yKXc/L2BLL2BhW2
        0n/eNrw83Dj+CQMIZd6bvwVRDSpgXZAB8wEgbYyJb9ICRq77lm96BfCe4EoX
        YK89W3ypZwrWT/CPJM0f+kBn2jnZFnBW4HwX/4M3BqAkZdpBVNXTsC8fwYuW
        Yc0leGF2aXFhMkBwcm90b24ubWUgPHhhdmlxYTJAcHJvdG9uLm1lPsKPBBMW
        CABBBQJlRQLtCRA6VhmPLVL1ohYhBJMIwYDsWhOFrPdpfjpWGY8tUvWiAhsD
        Ah4BAhkBAwsJBwIVCAMWAAIFJwkCBwIAABjUAPsGqhKj0zOSL8SOaqb1dsW6
        ZDWRT0SFs9mMRnCQC9CpiAEArI7RzYoliTnzzNNsbhG5T6as1GQNJi/eOaoN
        do/UNQfHiwRlRQLtEgorBgEEAZdVAQUBAQdAcBYvWvM52G+dmzGdMmcakzus
        vbLqKE4mqeoLwDfkpFADAQoJ/gkDCMp4bpOEHumvYHLWEqksOBxIBBo74wsE
        E84TE4HMuTv1T7tbjogi6yiB6Tr3XUjuvNVkxWiJcRbVvfS8loFE1YbADQaG
        oG8GgZ9u1/4dtz/CeAQYFggAKgUCZUUC7QkQOlYZjy1S9aIWIQSTCMGA7FoT
        haz3aX46VhmPLVL1ogIbDAAAUEwBAJ+V7L31vCR2TqkyCW3aRZ4gACLbqDxe
        oYdnlCUqEckRAQCyj8Ymn2PZyUbA5LY6zNK8tz6lYg7Xb8suppkBd4YYCg==
        =7X7G
        -----END PGP PRIVATE KEY BLOCK-----
        """
    }

    /// passphrase for `contactCardData`
    static var passphrase: Passphrase {
        Passphrase(value: "mYxL20.KfmFnGJOivxCh3qBKAud/iEe")
    }
}

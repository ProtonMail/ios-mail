//
//  OpenPGPDefines.swift
//  ProtonMailTests - Created on 5/7/18.
//
//
//  Copyright (c) 2019 Proton Technologies AG
//
//  This file is part of ProtonMail.
//
//  ProtonMail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  ProtonMail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with ProtonMail.  If not, see <https://www.gnu.org/licenses/>.


import XCTest

enum OpenPGPTestsDefine : Resource, CaseIterable {
    case keyring_privateKey
    case keyring_publicKey
    case mime_publicKey
    case message_signed
    case message_plaintext
    case attachment_keypacket
}

class OpenPGPDefines {
    
    static let modulus = "\n-----BEGIN PGP SIGNED MESSAGE-----\nHash: SHA256\n\nM/4QRYJDmHOsZ/rYstBZ8oYRBU41aIvkpMpQCwrwb0Naex6JwtX7nsgF5ixRI3D6crwmnV/r1tRzO/veCmUBnPrY9d9QE6cjwkgrXWSkTNcX/VuGBIkkTWEpCvvk3I2GxlokEm5/vovfgbF3GRwrU4mAtyut62jEynLx5mQ7H+/GdTFG8Lavr7A5cAYNajibnOBdZ/H7oHgQbca0HHzRBCRKw54hCmElkazPD6M0d6IoxIUePIa6lgrUWt+2UFMkDto1626RKvWvBFcuSKPOOug/i8MbSgsJO21aFRvhFuaNzvuXLL2QieAMW5UUnBgaA2uoO/JTX8cwP3Xb34Aq1g==\n-----BEGIN PGP SIGNATURE-----\nVersion: OpenPGP.js v1.2.0\nComment: http://openpgpjs.org\n\n\n=twTO\n-----END PGP SIGNATURE-----\n"
    
    
    static let public_key_feng100 = "-----BEGIN PGP PUBLIC KEY BLOCK-----\n" +
                                    "\n" +
                                    "mQENBFlewwUBCACX0HZ5EqxFh+4es4YSGZKbbxlFo+Jj/2BQxs7iH4VPzvDVxanV" + "\n" +
                                    "BD5D7NFywyQ8ud4X8eM81dhP9oGXs+BHNOJ9/Xf72V43lBzBSEOjnoY5VTBWTYE4" + "\n" +
                                    "IxkBDZWU4xoLch3DhTgWUHfKECdg/1VBpJzH9pkko0o2l8uLaz2q6HWFntipsxgw" + "\n" +
                                    "xc/Dr6r/HbkAFBh7+/Eow5PoDv5a//juWG+0rUu0PrYt1XuH9XBOiHgOmYxaoDhC" + "\n" +
                                    "4osXIFBGRqwVbtZa92yO2WQ7t4AznSPk4XSJO77DQUwlIhNodbMCLq94P6fhy0gT" + "\n" +
                                    "grptZmaQ9nWno+mBxW0m3+xC9jAnJeuu7MMtABEBAAG0L2ZlbmcxMDBAcHJvdG9u" + "\n" +
                                    "bWFpbC5jb20gPGZlbmcxMDBAcHJvdG9ubWFpbC5jb20+iQE1BBABCAApBQJZXsMG" + "\n" +
                                    "BgsJBwgDAgkQbcmZsUYjT0AEFQgKAgMWAgECGQECGwMCHgEAAPisB/47Cv9DMuit" + "\n" +
                                    "xImo9iBKTG2Av7dpvj7s6AVNvQVjMW4Yo4FHu8UqF9h/MCdMLAwNelcoUCieuvem" + "\n" +
                                    "H5FICyDWtKory33eXnA+pI3brdCfyoO58t4kiapfjQBdBaB+wjpnAIEQ6yfp9vSG" + "\n" +
                                    "/qM0PbwgAy+HJPkvjtZi1PJK4mv2fFjYozXB4yTVIV7i5Yl5PbWNzZEjpaeYZRhH" + "\n" +
                                    "+s9xZTHYSo/M8s9xdjTQ9/kdegqTlLRP8m+/iAheIxIrWJma/jjovN+2OCEj7nyB" + "\n" +
                                    "VV5a2yfBoCJ6OdZAeANJGQ7UNFsjjwCFoToY2uU3U40WFAcq4wTxXhp/UHmWu+Bb" + "\n" +
                                    "ozJj4+tWuef8uQENBFlewwUBCADI/Byo35dRWbcOLBFZWh2xghd3FLHPsT/JaB8v" + "\n" +
                                    "r1Acm8UqRV2yoperkzof+QdtFaMgh1u8Za6tdRl5lBsisx6Mcb3Bag6X/TO7sj7h" + "\n" +
                                    "jeb9xR5s44DvXywZATqTsdrzC05K56Mk7mr+S11k/U+hcLeb9vt+juMorlHxSr+j" + "\n" +
                                    "YRdC8w3EcTIuhD3DszaqhSC2ioSd9sCfg5chY3i/UOy2sPistIWjWkF9KjERTWg7" + "\n" +
                                    "T7AQNGad6uWiRqrF6ClzTUkShfgFM0oA2gH5u279AIEfAiogol5IllTfTljnQr6k" + "\n" +
                                    "W91JDeMKQjZgBX9s0MAgLiiIzX1ipw8EU4EwqcszYMSte3kNABEBAAGJAR8EGAEI" + "\n" +
                                    "ABMFAllewwYJEG3JmbFGI09AAhsMAAC9kwf/Rfh8mUvm8TlBl5DOQWLHfpQYP4Y4" + "\n" +
                                    "AI66zYCSLGh9W8K07DYODGdHD9Otxrb3IR6ItD3+3pA2LgiWq7AHCoqh8iei1q75" + "\n" +
                                    "+a11xzFI/RPct7coxPUPHSMf0nKZ+FtP/B4/06CCRAv9EMTB9UI7HCNaut0jLmT/" + "\n" +
                                    "qeQ0C8DjeHXrM055tvaRz72KXMs95bCnMVahehFRUoWugkSBwqnVeRIXjyPYQRmL" + "\n" +
                                    "CobzmtZFcoo59LK+pM5SNw43uPb6EYvFxEzts49UIchNOy2VDJyGuW5aC+ZPknpf" + "\n" +
                                    "3W+RnxgboqChY1RdksiECjJ+19ZrhcGdZW7Pr0TSvGhdqZbL3BmZoO+eXw==" + "\n" +
                                    "=Sk1q" + "\n" +
                                    "-----END PGP PUBLIC KEY BLOCK-----"
    
    
    static let feng100_private_key_1 =
    "-----BEGIN PGP PRIVATE KEY BLOCK-----" + "\n" +
    "Version: GnuPG v1" + "\n" +
    "" + "\n" +
    "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" + "\n" +
    "rLKWGpju144Zj3G3V3fn1/c=" + "\n" +
    "=s9c+" + "\n" +
    "-----END PGP PRIVATE KEY BLOCK-----"
    
    static let feng100_passphrase_1 = "test"
    
 
    
    static let privateKey = "-----BEGIN PGP PRIVATE KEY BLOCK-----\r\nVersion: OpenPGP.js v0.9.0\r\nComment: http://openpgpjs.org\r\n\r\n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\nPPekG4ttm6z3/BqqVplanIRSXlsqyp6J8A==\r\n=Pyb1\r\n-----END PGP PRIVATE KEY BLOCK-----\r\n"
    
    static let passphrase = "123"
    
    static let publicKey = "-----BEGIN PGP PUBLIC KEY BLOCK-----\nVersion: OpenPGP.js v0.7.1\nComment: http://openpgpjs.org\n\nxsBNBFSjdRkBB/9slBPGNrHAMbYT71AnxF4a0W/fcrzCP27yd1nte+iUKGyh\nyux3xGQRIHrwB9zyYBPFORXXwaQIA3YDH73YnE0FPfjh+fBWENWXKBkOVx1R\nefPTytGIyATFtLvmN1D65WkvnIfBdcOc7FWj6N4w5yOajpL3u/46Pe73ypic\nhe10XuwO4198q/8YamGpTFgQVj4H7QbtuIxoV+umIAf96p9PCMAxipF+piao\nD8LYWDUCK/wr1tSXIkNKL+ZCyuCYyIAnOli7xgIlKNCWvC8csuJEYcZlmf42\n/iHyrWeusyumLeBPhRABikE2ePSo+XI7LznD/CIrLhEk6RJT31+JR0NlABEB\nAAHNBlVzZXJJRMLAcgQQAQgAJgUCVKN1JAYLCQgHAwIJEH0tU95Lz7QEBBUI\nAgoDFgIBAhsDAh4BAAAXCgf8CsNCB0tKdLrwGe+dDLTGGdgyYr33Jz6GVta6\nJMl4rccf5T8QiRPkOIWITITpi5maxrn1w7yOUI3xkqCLCEO9vqLhIRr1/aBq\nvVUI+0L7goJoVrx6ynSR1KNNHM/hkttA+t1t894qgug6hooUfxtFWU8KesKK\ngdMFOxst3ODTeZxzO6xmiaf9Mof/y1M5y1fsKuUH57AJRzkJYviZmpEWMAxI\nmmiCPv/iMRUeR7hX9+spG2O9A0Ny46g89T59Wkerggu6/ulgX0O6MAhsuBY3\n+10TgajGyub5oJTLKVDY/nlVvmaEA+4IthepIQs+L3380oQz3GEtr/UfB1PB\nD/VfTM7ATQRUo3UkAQf/dcKxn9bt+fDMxuQT6sxSWjX4ptf6W0QbucDA/5Dw\n2vCFvCGakDdsczduFJ23QI7iZHHig5Fyp5M2MV+1DM/EJs9OZxMK6k0I4M4r\niucSf2L2XPv8m2Q5/nn7+gdvH6mO8POsDu766A0fMNhN36eHa5730dahJlIR\nYP+wOunUkQ3wzTPE4MZh878eCvkaeelMTMPNnQu9ONgxVyaO8GG09M0uJCxV\nqQ6PXBMtYSBydrYUscAeHQrreyfECNPobWgXRafTwftk/n9aGIzLViv4zo36\nGwuk7JzC3AF2PANxYus6EACPckwsjpbMVLpIpSvjDGdlYg9BPtNk0Fd4qZt2\nzwARAQABwsBfBBgBCAATBQJUo3UmCRB9LVPeS8+0BAIbDAAAgzcH/1kyh+20\ntcUGMRrT3akfhVv3o4d9C4j0Ja7PQMKwZNiSdFSbQ8ZE9xbR5cKB/Z33emMw\n+54CeJsanj7lOeefRqoHUynpirANguPLmp8SW4Dor4rwSOs4gfO1ttzw7+8M\nIeFG8p8OQ5B+J3+KCUdiuB+6zdxGW3rIfA9OAPYAObQUJ7quS/lmoNrOzKVm\nJWa7x4f9cS2Wls/vt/jeEn2j0x/GqN0KI8P2PjixiBY5Ogf6FRHvWWUD4SYx\n8YHf6rvFXGHW3tdMRRb24miP0UuhbOyUUiQm1xNIe2fJ+IUCD9cumgWbGXof\nGjz3pBuLbZus9/waqlaZWpyEUl5bKsqeifA=\n=LhM4\n-----END PGP PUBLIC KEY BLOCK-----"
    
    static let cleartext_one = "We\'ve received your order <head>  <style type=\"text/css\"> <IMG height=93 alt=\"\" src=\"\" width=531></A></DIV></TD></TR> --></TBODY></TABLE><!-- footerimage end --> </table>"
    
}


class OpenPGPDefinesTests: XCTestCase {
    
    func testEnumReadTestFile() {
        for define in OpenPGPTestsDefine.allCases {
            let value = define.rawValue
            XCTAssertNotNil(value)
            XCTAssertFalse(value!.isEmpty)
        }
    }

}

//
//  ContactTestData.swift
//  ProtonMailTests
//
//
//  Copyright (c) 2021 Proton AG
//
//  This file is part of Proton Mail.
//
//  Proton Mail is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  Proton Mail is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with Proton Mail.  If not, see <https://www.gnu.org/licenses/>.

import Foundation

let testSingleContactData = """
[{\"UID\":\"protonmail-ios-8260FE2E-B019-4B18-B901-787F95131063\",\"ModifyTime\":1614488759,\"ID\":\"_9E6ypCp6i9m7sUDdX9sYi3WDmPGUkidbhpA-d3qszlhMaglnj-OvfJLk2zdUsTaNy3ZavFFW3JvFn_VE_2wdg==\",\"ContactEmails\":[{\"Defaults\":1,\"ContactID\":\"_9E6ypCp6i9m7sUDdX9sYi3WDmPGUkidbhpA-d3qszlhMaglnj-OvfJLk2zdUsTaNy3ZavFFW3JvFn_VE_2wdg==\",\"LastUsedTime\":0,\"Type\":[],\"Order\":1,\"Name\":\"Test\",\"LabelIDs\":[],\"ID\":\"MnKxz4PrgGnJ1tkDsPmtJ16_s22fowqAL-eIZSBOrgydoOrwXbfrk21zA4apEb5pQ5P6Z8ywl8m7IcJbqueCYg==\",\"Email\":\"test@test.com\"}],\"Cards\":[{\"Type\":2,\"Signature\":\"-----BEGIN PGP SIGNATURE-----\\nVersion: GopenPGP 2.1.3\\nComment: https:\\/\\/gopenpgp.org\\n\\nwsBzBAABCgAnBQJgOySzCRBWRx+SquDI6BYhBH1iPl3sKPKRrnFgC1ZHH5Kq4Mjo\\nAADgYAgA3XXJ88i\\/AMxL1OZpx\\/fB\\/WTXalqzLmKq7TUrQienSLs8v9t32mbzpWqP\\nmqsQV9FHKNSOvGTSZ8nsQy6tZtFZfK5gE2m2fK8o+1brCVE3g4oACJ1mHoI4JatC\\ncpAgR4EXN4Dw3glwzNvLs\\/Ly2Oj99gNjORAI3kvpW655b9av+jKWA94Dn661ZMFd\\nicCJV43XhgDcYn0zrYkgOIZXR2awdMuGcQNqC65tkaBkE1OIMF0cJ43u5ugKnGkd\\ncm8LqiLW+cvpqev+59kBnAng2XpbbBnA3SxepbpQUdxegOimatW0pWsM2c+Vn3kU\\nbfB2elX7xAXdTI5bnYYQoqeqyIozJw==\\n=95OA\\n-----END PGP SIGNATURE-----\",\"Data\":\"BEGIN:VCARD\\r\\nVERSION:4.0\\r\\nPRODID:pm-ez-vcard 0.0.1\\r\\nUID:protonmail-ios-8260FE2E-B019-4B18-B901-787F95131063\\r\\nFN:Test\\r\\nItem1.EMAIL;TYPE=:test@test.com\\r\\nEND:VCARD\\r\\n\"}],\"Name\":\"Test\",\"LabelIDs\":[],\"CreateTime\":1614488759,\"Size\":162}]
"""

let testUpdatedContactData = """
     {
            "ID": "_9E6ypCp6i9m7sUDdX9sYi3WDmPGUkidbhpA-d3qszlhMaglnj-OvfJLk2zdUsTaNy3ZavFFW3JvFn_VE_2wdg==",
            "Name": "New Test",
            "UID": "protonmail-ios-8260FE2E-B019-4B18-B901-787F95131063",
            "Size": 287,
            "CreateTime": 1614488759,
            "ModifyTime": 1614606860,
            "ContactEmails": [{
                "ID": "rHP2s6EdxsD55zGQOWRV_uedRMRbyi3A1L9iOwVJhb0l_2BtEM-VPm0GQ1Mb9d8iAUs2RuyIw3AWRkOW3CVdYg==",
                "Name": "New Test",
                "Email": "test@test.com",
                "Type": [],
                "Defaults": 1,
                "Order": 1,
                "LastUsedTime": 0,
                "ContactID": "_9E6ypCp6i9m7sUDdX9sYi3WDmPGUkidbhpA-d3qszlhMaglnj-OvfJLk2zdUsTaNy3ZavFFW3JvFn_VE_2wdg==",
                "LabelIDs": []
            }],
            "LabelIDs": []
        }
"""

let testUpdatedContactCardData = """
[{\"Data\":\"BEGIN:VCARD\\r\\nVERSION:4.0\\r\\nPRODID:pm-ez-vcard 0.0.1\\r\\nITEM1.CATEGORIES:\\r\\nEND:VCARD\\r\\n\",\"Type\":0,\"Signature\":\"\"},{\"Data\":\"BEGIN:VCARD\\r\\nVERSION:4.0\\r\\nPRODID:pm-ez-vcard 0.0.1\\r\\nItem1.EMAIL;TYPE=:test@test.com\\r\\nFN:New Test\\r\\nUID:protonmail-ios-8260FE2E-B019-4B18-B901-787F95131063\\r\\nEND:VCARD\\r\\n\",\"Signature\":\"-----BEGIN PGP SIGNATURE-----\\nComment: https:\\/\\/gopenpgp.org\\nVersion: GopenPGP 2.1.3\\n\\nwsBzBAABCgAnBQJgPPNgCRBWRx+SquDI6BYhBH1iPl3sKPKRrnFgC1ZHH5Kq4Mjo\\nAADYNgf\\/QD+tlKy1x9VCTjbVD9xtXfIT+8kOHalUIsOjcVFGX9eQvt3XJn+zm3rG\\nRL0XUYCxuwEQpPpzdTBFKTK4cyl2AatHNd7HuTtDB\\/E1Zo\\/2NtByIFVT37\\/k6GSD\\nIXqNbWqHFAsGvuSXuXXxJMBjV+61rQ1QadmY0girHqsiu8ua\\/eUKxhGUiJSpy8KY\\nDiIc9ttiqJkSns\\/x2YFM1CtCfjPFXoOVOsFQnknEx3P6jKvXb4zxXFfHSZW2rW1E\\nXI2EF1xTN9\\/2V1UkDze3krJFXjVgMjnWTI\\/vksP\\/19yoa9mvedIjTTCS2+RJFF0x\\nTtZiooFSt\\/BLy\\/1e8ZZL+BiQLkWIYQ==\\n=0S7Q\\n-----END PGP SIGNATURE-----\",\"Type\":2},{\"Type\":3,\"Signature\":\"-----BEGIN PGP SIGNATURE-----\\nVersion: GopenPGP 2.1.3\\nComment: https:\\/\\/gopenpgp.org\\n\\nwsBzBAABCgAnBQJgPPNgCRBWRx+SquDI6BYhBH1iPl3sKPKRrnFgC1ZHH5Kq4Mjo\\nAADvogf9FE1MwxUHaCDg3at\\/q7mKH3Kk4CXzN4o+At3unkLHm+ouzwo\\/pR95RvoD\\ncteamDH8VfdfbaQFyU19\\/GZVADPToNH+FuqR0qxg9OnTWLdCMfKGLVUsZ\\/0vh6AU\\nPGD3wySHrxCwRYDDSnpeRA5Ni\\/c9d4TtWzanIV62WSMey9CRzNOl08cCKHPbnSNk\\n57jlKtDOd8sKQWeY5a1+EySybHuOxaiv9CqnJD3T0nNPYiOA0hAPDQqCrqyTc6Dg\\ngPmnnGi3sjs59eck3YGWKu5y3bWkSnTpMBdWdmZWCrdDvKI+UomO5a84nVSkyWbI\\nw+q3ofg9Q7aoPT7ldQo6ccdA1JP88w==\\n=riKy\\n-----END PGP SIGNATURE-----\",\"Data\":\"-----BEGIN PGP MESSAGE-----\\nVersion: GopenPGP 2.1.3\\nComment: https:\\/\\/gopenpgp.org\\n\\nwcBMAw1+lDnEDORyAQf\\/cH32oTUAYQ80spNbnFJNal7JzEpzULNOQ6lwAKIwqeOU\\nUrAR89p4kubWzH678tW0WvVS5XHdc7sk\\/ozv456osvKTWQcU9YubZPfII\\/\\/EarDP\\nmFNB47Arx7UulCbpCXlkMtWFQZT8cUouABRGtRUUwEtMnxGIRLdMZWKq4MKmq8VJ\\ns2zPsbEzG1sKI2i5ochyqCQBvmcWoFIM4TcCZGQfcXMFbmLyJj8HvWmsFI6djE6G\\nQB6n7HIIkQUc2ARWG3YrJGNCylhyzuEw4I3LcaZovYL1rLf9NgBk\\/tg8dufqYAdx\\npsaGOhUUuKSzkiLmPSWUBbo3XTSVmgKB1ZMpPCt149J3AYI7BD1\\/pz5WjTWnxo1N\\n6b92G\\/oAPC1SHumc5dvmJ7q0viYi9sbT6q0SgnyD2Kllvx2I5yDuj0v\\/rRl\\/RD7r\\nAAgnxVYzeJ28f3qJ7ORNmzsvskdIyLgB5W+DWPQh+sPU1HcZjNLwX0agDC69LO1\\/\\nS7jUlJeJDVE=\\n=WqeQ\\n-----END PGP MESSAGE-----\"}]
"""

let testContactDetailData = """
    {
           "ID": "_9E6ypCp6i9m7sUDdX9sYi3WDmPGUkidbhpA-d3qszlhMaglnj-OvfJLk2zdUsTaNy3ZavFFW3JvFn_VE_2wdg==",
           "Name": "New Test",
           "UID": "protonmail-ios-8260FE2E-B019-4B18-B901-787F95131063",
           "Size": 287,
           "CreateTime": 1614488759,
           "ModifyTime": 1614607200,
           "Cards": [{\"Data\":\"BEGIN:VCARD\\r\\nVERSION:4.0\\r\\nPRODID:pm-ez-vcard 0.0.1\\r\\nItem1.EMAIL;TYPE=:test@test.com\\r\\nFN:New Test\\r\\nUID:protonmail-ios-8260FE2E-B019-4B18-B901-787F95131063\\r\\nEND:VCARD\\r\\n\",\"Signature\":\"-----BEGIN PGP SIGNATURE-----\\nComment: https:\\/\\/gopenpgp.org\\nVersion: GopenPGP 2.1.3\\n\\nwsBzBAABCgAnBQJgPPNgCRBWRx+SquDI6BYhBH1iPl3sKPKRrnFgC1ZHH5Kq4Mjo\\nAADYNgf\\/QD+tlKy1x9VCTjbVD9xtXfIT+8kOHalUIsOjcVFGX9eQvt3XJn+zm3rG\\nRL0XUYCxuwEQpPpzdTBFKTK4cyl2AatHNd7HuTtDB\\/E1Zo\\/2NtByIFVT37\\/k6GSD\\nIXqNbWqHFAsGvuSXuXXxJMBjV+61rQ1QadmY0girHqsiu8ua\\/eUKxhGUiJSpy8KY\\nDiIc9ttiqJkSns\\/x2YFM1CtCfjPFXoOVOsFQnknEx3P6jKvXb4zxXFfHSZW2rW1E\\nXI2EF1xTN9\\/2V1UkDze3krJFXjVgMjnWTI\\/vksP\\/19yoa9mvedIjTTCS2+RJFF0x\\nTtZiooFSt\\/BLy\\/1e8ZZL+BiQLkWIYQ==\\n=0S7Q\\n-----END PGP SIGNATURE-----\",\"Type\":2}
        , {\"Type\":3,\"Signature\":\"-----BEGIN PGP SIGNATURE-----\\nVersion: GopenPGP 2.1.3\\nComment: https:\\/\\/gopenpgp.org\\n\\nwsBzBAABCgAnBQJgPPNgCRBWRx+SquDI6BYhBH1iPl3sKPKRrnFgC1ZHH5Kq4Mjo\\nAADvogf9FE1MwxUHaCDg3at\\/q7mKH3Kk4CXzN4o+At3unkLHm+ouzwo\\/pR95RvoD\\ncteamDH8VfdfbaQFyU19\\/GZVADPToNH+FuqR0qxg9OnTWLdCMfKGLVUsZ\\/0vh6AU\\nPGD3wySHrxCwRYDDSnpeRA5Ni\\/c9d4TtWzanIV62WSMey9CRzNOl08cCKHPbnSNk\\n57jlKtDOd8sKQWeY5a1+EySybHuOxaiv9CqnJD3T0nNPYiOA0hAPDQqCrqyTc6Dg\\ngPmnnGi3sjs59eck3YGWKu5y3bWkSnTpMBdWdmZWCrdDvKI+UomO5a84nVSkyWbI\\nw+q3ofg9Q7aoPT7ldQo6ccdA1JP88w==\\n=riKy\\n-----END PGP SIGNATURE-----\",\"Data\":\"-----BEGIN PGP MESSAGE-----\\nVersion: GopenPGP 2.1.3\\nComment: https:\\/\\/gopenpgp.org\\n\\nwcBMAw1+lDnEDORyAQf\\/cH32oTUAYQ80spNbnFJNal7JzEpzULNOQ6lwAKIwqeOU\\nUrAR89p4kubWzH678tW0WvVS5XHdc7sk\\/ozv456osvKTWQcU9YubZPfII\\/\\/EarDP\\nmFNB47Arx7UulCbpCXlkMtWFQZT8cUouABRGtRUUwEtMnxGIRLdMZWKq4MKmq8VJ\\ns2zPsbEzG1sKI2i5ochyqCQBvmcWoFIM4TcCZGQfcXMFbmLyJj8HvWmsFI6djE6G\\nQB6n7HIIkQUc2ARWG3YrJGNCylhyzuEw4I3LcaZovYL1rLf9NgBk\\/tg8dufqYAdx\\npsaGOhUUuKSzkiLmPSWUBbo3XTSVmgKB1ZMpPCt149J3AYI7BD1\\/pz5WjTWnxo1N\\n6b92G\\/oAPC1SHumc5dvmJ7q0viYi9sbT6q0SgnyD2Kllvx2I5yDuj0v\\/rRl\\/RD7r\\nAAgnxVYzeJ28f3qJ7ORNmzsvskdIyLgB5W+DWPQh+sPU1HcZjNLwX0agDC69LO1\\/\\nS7jUlJeJDVE=\\n=WqeQ\\n-----END PGP MESSAGE-----\"
            }],
           "ContactEmails": [{
               "ID": "K_xk57_5KrR4Y78ZftadIEvVTQtma6HBSRJgRm8Xx11MlV0f0nUspnW_OBZzOC13jGukdWgNvim_5DIdDzj72Q==",
               "Name": "New Test",
               "Email": "test@test.com",
               "Type": [],
               "Defaults": 1,
               "Order": 1,
               "LastUsedTime": 0,
               "ContactID": "_9E6ypCp6i9m7sUDdX9sYi3WDmPGUkidbhpA-d3qszlhMaglnj-OvfJLk2zdUsTaNy3ZavFFW3JvFn_VE_2wdg==",
               "LabelIDs": []
           }],
           "LabelIDs": []
       }
"""

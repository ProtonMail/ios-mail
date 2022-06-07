//
//  LabelTestData.swift
//  Proton MailTests
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

let testLabelsData = """
    [{
        "ID": "dixQoKdS1OPVzHB0nZ5Yp7MDlZM4-nHhvspULoUSdWKFRKhHLOQEmU58ExrwFHJY2cejSP1TrDOyc7mvVcSa6Q==",
        "Name": "Test",
        "Path": "Test",
        "Type": 1,
        "Color": "#e6984c",
        "Order": 10000,
        "Notify": 0,
        "Exclusive": 0,
        "Display": 0
    }, {
        "ID": "Vg_DqN6s-xg488vZQBkiNGz0U-62GKN6jMYRnloXY-isM9s5ZR-rWCs_w8k9Dtcc-sVC-qnf8w301Q-1sA6dyw==",
        "Name": "TestFolder",
        "Path": "TestFolder",
        "Type": 1,
        "Color": "#e7d292",
        "Order": 40000,
        "Notify": 1,
        "Exclusive": 1,
        "Display": 0
    },
    {
        "ID": "0"
    },
    {
        "ID": "8"
    },
    {
        "ID": "1"
    },
    {
        "ID": "7"
    },
    {
        "ID": "2"
    },
    {
        "ID": "10"
    },
    {
        "ID": "6"
    },
    {
        "ID": "4"
    },
    {
        "ID": "3"
    },
    {
        "ID": "5"
    }]
"""

let testSingleLabelData = """
            {
                "ID": "fFECHlO7rfi9KXhmx_CAKS32uaGGZgOy4Wgdpme4yg95zA4vUomxViDJmUYvrYGH51Mk0-wSs1m_A7IJHEA5tA==",
                "Name": "new",
                "Path": "new",
                "Type": 1,
                "Color": "#c26cc7",
                "Order": 50000,
                "Notify": 0,
                "Exclusive": 0,
                "Display": 0
            }
"""

let testV4LabelData = """
[
    {
      "ID": "D_naocdWUywLeH9qH6cK4xVuH0YmJSRUoAsOxY2sahcSUaz-eRxUu1yWOt3AIvj0NHHrbdnasShH8rn8LAQBew==",
      "Name": "ggg",
      "Path": "ggg",
      "Type": 3,
      "Color": "#8989ac",
      "Order": 1,
      "Notify": 1,
      "Expanded": 0,
      "Sticky": 0
    },
    {
      "ID": "cQj3yw8Pr_FUEs-rvDZr5cMTUo4mGBN_pIoOORQCUKYq_XWErpzIEYODkr4QU7nYt2NQGVKX5db0Cn7DIlrk5w==",
      "Name": "saved",
      "Path": "saved",
      "Type": 3,
      "Color": "#69a9d1",
      "Order": 2,
      "Notify": 1,
      "Expanded": 0,
      "Sticky": 0
    },
    {
      "ID": "LHG1aEwOFMalNyYUoHcO56uaqt5rM8r8J590lnWzlAgw6dDPb87CCU38le2K7rYLDN422NSjDp9TiDC308nLKw==",
      "Name": "jira",
      "Path": "jira",
      "Type": 3,
      "Color": "#8989ac",
      "Order": 3,
      "Notify": 1,
      "Expanded": 0,
      "Sticky": 0
    },
    {
      "ID": "RUuFzNv2lR2lL44K6yofrtFdAZIzQqmUKOsAzTPm4UmKK5vdTw2EjnxHWUDT-nFhIoi20pQjO4QxF0uZU3FvQA==",
      "Name": "conference",
      "Path": "conference",
      "Type": 3,
      "Color": "#c6cd97",
      "Order": 4,
      "Notify": 1,
      "Expanded": 0,
      "Sticky": 0
    },
    {
      "ID": "OPnn1gxpLMJptqkQWS3Pvjwldwd__1HwSFiu9tcFIt-du7zs115KUQsWpKcVsTzdo6dCmSYOkwsTl-OLuqixhA==",
      "Name": "NewsLetters",
      "Path": "NewsLetters",
      "Type": 3,
      "Color": "#e6984c",
      "Order": 5,
      "Notify": 1,
      "Expanded": 0,
      "Sticky": 0
    },
    {
      "ID": "blWkPrbMeF7GjHDz5lBpkbC6vRgb3nNtsg9-s__UfXss3ax1y1wLfFYw7Blw2yqWjJAmBNZz29hPkJ-gh3zzcg==",
      "Name": "gitlab",
      "Path": "gitlab",
      "Type": 3,
      "Color": "#cf7e7e",
      "Order": 6,
      "Notify": 1,
      "Expanded": 0,
      "Sticky": 0
    },
    {
      "ID": "_ZkdaXw85lqp397VYrq1OUWXY0Ptq2aV5if0J5KPLnY9RuVSA0C0gEa5NlGHpYw9Qm7GU_yoNtkPasm2BL7AyQ==",
      "Name": "client-2451",
      "Path": "client-2451",
      "Type": 3,
      "Color": "#5ec7b7",
      "Order": 7,
      "Notify": 1,
      "Expanded": 0,
      "Sticky": 0
    },
    {
      "ID": "9fh7cH4dgk4JqFlSWf3rfcua9AkSwx5LizqH70MZG7fmNtgfR2Unrg9MayFrTzDU2ZS1M3NnFiB_oeq33oCN-Q==",
      "Name": "payment",
      "Path": "payment",
      "Type": 3,
      "Color": "#c26cc7",
      "Order": 8,
      "Notify": 1,
      "Expanded": 0,
      "Sticky": 0
    },
    {
      "ID": "McToVpfXly8nccAey391VY652WNF7rtZEeiq6M3E07UYfGu5Bq4pcxpI7jMJQl8zaCZV3T9H8SQ9rHnyOgFKKA==",
      "Name": "abjbn",
      "Path": "saved/abjbn",
      "Type": 3,
      "Color": "#5ec7b7",
      "Order": 1,
      "Notify": 1,
      "Expanded": 0,
      "Sticky": 0,
      "ParentID": "cQj3yw8Pr_FUEs-rvDZr5cMTUo4mGBN_pIoOORQCUKYq_XWErpzIEYODkr4QU7nYt2NQGVKX5db0Cn7DIlrk5w=="
    },
    {
      "ID": "Kp_0MF_KQBA6K_XIJ1gkfD_foEq3hmMDWT_uCjPqt4rcfXmSXA7Jd_3xW44uQuVGBc6csH9aKGIEZ56yzOW1_A==",
      "Name": "sub1",
      "Path": "saved/sub1",
      "Type": 3,
      "Color": "#9db99f",
      "Order": 2,
      "Notify": 0,
      "Expanded": 0,
      "Sticky": 0,
      "ParentID": "cQj3yw8Pr_FUEs-rvDZr5cMTUo4mGBN_pIoOORQCUKYq_XWErpzIEYODkr4QU7nYt2NQGVKX5db0Cn7DIlrk5w=="
    },
    {
      "ID": "9zsmHugutFSyK484yQ_2gY8-rPyfmLtV5V_1HZT9fKCCpUbekzRfiY9n0RQleC6f3rsmJ-o4Y1liLYCH-4o_ZA==",
      "Name": "sub2",
      "Path": "saved/sub2",
      "Type": 3,
      "Color": "#5ec7b7",
      "Order": 3,
      "Notify": 1,
      "Expanded": 0,
      "Sticky": 0,
      "ParentID": "cQj3yw8Pr_FUEs-rvDZr5cMTUo4mGBN_pIoOORQCUKYq_XWErpzIEYODkr4QU7nYt2NQGVKX5db0Cn7DIlrk5w=="
    },
    {
      "ID": "qOEDAmcFE4c9_sD-JV2h6BNPN8pRsWXngWFVA1v0baVCZ8unJvKtaPPE769uFUr85nNowKGVtD2o6zFGXBOHfA==",
      "Name": "sub_sub1",
      "Path": "saved/sub1/sub_sub1",
      "Type": 3,
      "Color": "#a8c4d5",
      "Order": 1,
      "Notify": 1,
      "Expanded": 0,
      "Sticky": 0,
      "ParentID": "Kp_0MF_KQBA6K_XIJ1gkfD_foEq3hmMDWT_uCjPqt4rcfXmSXA7Jd_3xW44uQuVGBc6csH9aKGIEZ56yzOW1_A=="
    },
    {
      "ID": "LHCR5QMCml_QNxWDB2S2KHjaHemQJPbQxxnSIrmbPMHMqZMmFWOIqbVRDtfwOH7a7bfWHqwfZQxamWLLE9w4PA==",
      "Name": "yooo",
      "Path": "ggg/yooo",
      "Type": 3,
      "Color": "#7272a7",
      "Order": 2,
      "Notify": 0,
      "Expanded": 1,
      "Sticky": 0,
      "ParentID": "D_naocdWUywLeH9qH6cK4xVuH0YmJSRUoAsOxY2sahcSUaz-eRxUu1yWOt3AIvj0NHHrbdnasShH8rn8LAQBew=="
    },
    {
      "ID": "JqdQKHN_APS8IqDOGTejUZkOCDjozscukwxJzmUvzCUSJ_Cyv9SRyDeGQviPrOz-SuG8ySCHqAUQU0WA_deodw==",
      "Name": "label 1",
      "Path": "label 1",
      "Type": 1,
      "Color": "#e6c04c",
      "Order": 1,
      "Notify": 0,
      "Expanded": 0,
      "Sticky": 0
    },
    {
      "ID": "PTUNFXIuL8FrnuYYn6M0sUQbVNFVE6rfUgVwYZX4trt1CxlNw5_wd72iepQ12dbH4Z7ymP-cAXsD7TOjBWBckQ==",
      "Name": "label 2",
      "Path": "label 2",
      "Type": 1,
      "Color": "#5ec7b7",
      "Order": 2,
      "Notify": 0,
      "Expanded": 0,
      "Sticky": 0
    },
    {
      "ID": "NhL8UEAqAZQu_hatluJhnqwdn8b17uaLuyPe0fa4emwov3hnAqGftchOyzdl_MmvxFWEN25lymobt4tIbVVjFA==",
      "Name": "label3",
      "Path": "label3",
      "Type": 1,
      "Color": "#8989ac",
      "Order": 3,
      "Notify": 0,
      "Expanded": 0,
      "Sticky": 0
    },
    {
      "ID": "KSxyEEPrbp0WZ_ZD1xMYcMbRmjqDQi-3FK1PbGt-_P01iiYHm5gyj7z3NMZCEPYxbIT-np3CeiuWSqfWkIKlHQ==",
      "Name": "label4",
      "Path": "label4",
      "Type": 1,
      "Color": "#cf5858",
      "Order": 4,
      "Notify": 0,
      "Expanded": 0,
      "Sticky": 0
    },
    {
      "ID": "l9AEEtxo_9udDul_OuSiFsRQeTkQKF9u9z3u9niQuGIdpd3SqEnnUz2urgPX_nHZZXR90ErW4K8F9DC5Yc6DpA==",
      "Name": "label5aaa",
      "Path": "label5aaa",
      "Type": 1,
      "Color": "#cf5858",
      "Order": 5,
      "Notify": 0,
      "Expanded": 0,
      "Sticky": 0
    },
    {
      "ID": "LT2IhkQH4KQ_YZPBNsXZL7mzqr3tyV2jgOVIyFWf5g0LzlwAYmsL-p12IO5dozZD08ObS5h2TRUJt4m1b0jbOg==",
      "Name": "rename label",
      "Path": "rename label",
      "Type": 1,
      "Color": "#c26cc7",
      "Order": 6,
      "Notify": 0,
      "Expanded": 0,
      "Sticky": 0
    }
  ]
"""

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
import ProtonCore_Crypto

struct KeyTestData {
    static let publicKey1 = """
    -----BEGIN PGP PUBLIC KEY BLOCK-----
    Version: Keybase OpenPGP v1.0.0
    Comment: https://keybase.io/crypto

    xm8EYYSwHxMFK4EEACIDAwQoeACeE8AGHxeEMVWMpbK0ALBeihEqPj5pjEUGKkKC
    jM3IbKMi7q9X7tL1Gl3cazN7BXC3sahIvMKRFg4x0kMXgVRTXmu/Ahz4vuJhTRKa
    gKD0tQYVMxZUqtn758US7vXNFXRlc3QgPHRlc3RAdGVzdC50ZXN0PsKPBBMTCgAX
    BQJhhLAfAhsvAwsJBwMVCggCHgECF4AACgkQZR/wBUgbnang0wF+MXhLMY1iyh5b
    uCov6/tHsbrQgfg09shGXW547CXvQ/t6+e9bVoSShOgL0ocdcDLbAX9RIevMHlfr
    88iUFWjXJ8KnO0MaqNQorR3iFYTme2uaFD3A35Ooh1KSAyGgybdDmjTOUgRhhLAf
    EwgqhkjOPQMBBwIDBOXwkvaqlwa7J1NJQzLqD4p34NnsW/nuT0CTObScTGRJldNh
    CjN7XthLXBYOagnZ4I+LqBhs8rViWi1PqBl3ePTCwCcEGBMKAA8FAmGEsB8FCQ8J
    nAACGy4AagkQZR/wBUgbnalfIAQZEwoABgUCYYSwHwAKCRAalaVKq0xbh9nuAQD8
    rWOHHbIUOvdal6NHX/lqsKLcSvmvHGviVQdo2FBbLQEA6Z8LrVBDZeN4cWhAUnJb
    xcBgLwXSeJJx0yxozL0injipdQF/d267AhKVY0kvtFlK/M4iZ8bAeDh9ZLhwqbKQ
    f3vt16Ww73R+E92djz4q5kMF6RJSAYDUXzUq5MoZ0kJAOOgZ4Xdk/2LAU5OMUXMn
    FwyrEih3zN8Y3Ek4FmjBwzQaR4oxMUHOUgRhhLAfEwgqhkjOPQMBBwIDBDhOcTaF
    XKCa/sAMnPweUuy/IyVenAM1+MtMSuVXPc3ZKl3j4WVXiR0DD+zjJTPuXM+mq6NM
    xsaDQe3pz0BF/5PCwCcEGBMKAA8FAmGEsB8FCQ8JnAACGy4AagkQZR/wBUgbnalf
    IAQZEwoABgUCYYSwHwAKCRCtdIkjffiPYmKHAP4nVAblnliaS7mYHIPyb+H2EPrp
    8rGmZPAJHebh1HTK+wD/fc9lquxBiNZP8DtGv9fyykhBAQt1YFmnQ9kijrmopZkD
    IwF/Zd9gv96GBwIafSo1z7KFIS98LUNz/akHCWPkAJHpl2xBYjrdRrlIBrngkQ5Z
    gnK1AX9g7qAfyMBfRrdIEJCP2GGANqWn5UAWmK2Eq4vFrDFp3vMELsXtN+LDb+G4
    VZfaJu8=
    =3SpF
    -----END PGP PUBLIC KEY BLOCK-----
    """
    static let  privateKey1 = """
    -----BEGIN PGP PRIVATE KEY BLOCK-----
    Version: Keybase OpenPGP v1.0.0
    Comment: https://keybase.io/crypto

    xcASBGGEsB8TBSuBBAAiAwMEKHgAnhPABh8XhDFVjKWytACwXooRKj4+aYxFBipC
    gozNyGyjIu6vV+7S9Rpd3GszewVwt7GoSLzCkRYOMdJDF4FUU15rvwIc+L7iYU0S
    moCg9LUGFTMWVKrZ++fFEu71/gkDCI6PT1kSeO28YJuyf0XylbPEJJRLQGl/LG4W
    qvUbmOEoc3hbHLTRypfM43ykXzG5o1GjaWoChoi5fizVa42O6GzEsUNk6eQ5evpr
    DiHY4Za5toUZVk7Kt/GroA1TR13czRV0ZXN0IDx0ZXN0QHRlc3QudGVzdD7CjwQT
    EwoAFwUCYYSwHwIbLwMLCQcDFQoIAh4BAheAAAoJEGUf8AVIG52p4NMBfjF4SzGN
    YsoeW7gqL+v7R7G60IH4NPbIRl1ueOwl70P7evnvW1aEkoToC9KHHXAy2wF/USHr
    zB5X6/PIlBVo1yfCpztDGqjUKK0d4hWE5ntrmhQ9wN+TqIdSkgMhoMm3Q5o0x6UE
    YYSwHxMIKoZIzj0DAQcCAwTl8JL2qpcGuydTSUMy6g+Kd+DZ7Fv57k9Akzm0nExk
    SZXTYQoze17YS1wWDmoJ2eCPi6gYbPK1YlotT6gZd3j0/gkDCLxawleJHzYvYK4m
    HnRqWp6d/cQwWRBgqqbPbWMbIZFwXLQBGkzlsQoP1ISbgQqXUZl9KtSiPPb1svll
    3DHyfP9ab1CMPXOvSDxAR/lRetnCwCcEGBMKAA8FAmGEsB8FCQ8JnAACGy4AagkQ
    ZR/wBUgbnalfIAQZEwoABgUCYYSwHwAKCRAalaVKq0xbh9nuAQD8rWOHHbIUOvda
    l6NHX/lqsKLcSvmvHGviVQdo2FBbLQEA6Z8LrVBDZeN4cWhAUnJbxcBgLwXSeJJx
    0yxozL0injipdQF/d267AhKVY0kvtFlK/M4iZ8bAeDh9ZLhwqbKQf3vt16Ww73R+
    E92djz4q5kMF6RJSAYDUXzUq5MoZ0kJAOOgZ4Xdk/2LAU5OMUXMnFwyrEih3zN8Y
    3Ek4FmjBwzQaR4oxMUHHpQRhhLAfEwgqhkjOPQMBBwIDBDhOcTaFXKCa/sAMnPwe
    Uuy/IyVenAM1+MtMSuVXPc3ZKl3j4WVXiR0DD+zjJTPuXM+mq6NMxsaDQe3pz0BF
    /5P+CQMIcP6udPwovBlg5Hq4DwS92AbadZt/oiZt9E2v/qSRZepRKNgxLPI1WSFs
    b7qwqnznMKddX9Q3iqNg7XTRnCUBqx6dGgqfUtaE+mpbs6RajMLAJwQYEwoADwUC
    YYSwHwUJDwmcAAIbLgBqCRBlH/AFSBudqV8gBBkTCgAGBQJhhLAfAAoJEK10iSN9
    +I9iYocA/idUBuWeWJpLuZgcg/Jv4fYQ+unysaZk8Akd5uHUdMr7AP99z2Wq7EGI
    1k/wO0a/1/LKSEEBC3VgWadD2SKOuailmQMjAX9l32C/3oYHAhp9KjXPsoUhL3wt
    Q3P9qQcJY+QAkemXbEFiOt1GuUgGueCRDlmCcrUBf2DuoB/IwF9Gt0gQkI/YYYA2
    paflQBaYrYSri8WsMWne8wQuxe034sNv4bhVl9om7w==
    =+Uml
    -----END PGP PRIVATE KEY BLOCK-----
    """
    static let  passphrash1 = Passphrase(value: "12345")
    static let  publicKey2 = """
    -----BEGIN PGP PUBLIC KEY BLOCK-----
    Version: Keybase OpenPGP v1.0.0
    Comment: https://keybase.io/crypto

    xm8EYYSwfhMFK4EEACIDAwTa1tC6OSnHMMJXOcYXKqshuXa4hKrAoGiE2+JvJGRg
    fOfUYVo9HaYLmwyNBE/CTY53jDr1bcqtgBHLS9B0LUJc1tuBRz8PiG4Ov/9f6d+f
    pqrmwrMeHw3XvMXI5j+xDJbNFnRlc3QyIDx0ZXN0QHRlc3QudGVzdD7CjwQTEwoA
    FwUCYYSwfgIbLwMLCQcDFQoIAh4BAheAAAoJEFSf8LN9v0wpBwgBgO4+3FKtmScB
    bNJr0SlpnMSx+MXwRmHycd307MU9qLfEu1NgFsvK95pSQQlNF5o37QGAxaztFZt+
    yfjS+Ifj/l90+V224WfLPV5bsnIdLeTqHrvRr5E1Fc5jEkvKEDeWKJG7zlIEYYSw
    fhMIKoZIzj0DAQcCAwQZeFcWsNHQE4OeKAjZrToC98yvGCJ24Anpv+yNrSGQZ+x9
    FxlNlnk/YKHrmUBURCfjA+HrEKxxekeRNH912ronwsAnBBgTCgAPBQJhhLB+BQkP
    CZwAAhsuAGoJEFSf8LN9v0wpXyAEGRMKAAYFAmGEsH4ACgkQMpjwftKqaecNjAEA
    i3IfImuP0eMwUNeJAmzzz0rs+1sSlZGh3IytNByg/HgA/RvYCJzDnqXNpnlIb+Gm
    +JmCsC8DzttfyIojnpY8a7gliRoBgK0IU32mv5cYgBjJpNCopRNzQf6QJKK3LedL
    gCVj6cmc3n8XtFh2WQnj6pmSYmzMGwGAtFnDcXAlaf67HVNMHCziUXDISJmSn9+Z
    sLThU5ZvGSlVDAHrnljrxQSDy5gcJ3pSzlIEYYSwfhMIKoZIzj0DAQcCAwSsGgH9
    3exVg8OhyX/MG8sVe3ENMWa6LFsTNCEkLIaEjsuuM5GmIfriW5dY624xKAS7Pov1
    8A0+YCE7kjbRgf+NwsAnBBgTCgAPBQJhhLB+BQkPCZwAAhsuAGoJEFSf8LN9v0wp
    XyAEGRMKAAYFAmGEsH4ACgkQMMDnRHlADusLBQEAp/+z8pZuqYEZQlgPrmdiXxA8
    kbTdGrEi/wa2nfK6XBUA/03UCqLnrhYUOOqy4fwMy/TWY2kI/EKIgg12lkAbr9nm
    MJABf1iU4DX06wXUZCNfxKlh+r1Qja6n7q10ChVCEokGjaCgyY41c6/9odQzgk+F
    YfNe4gGApoAcv0FhCfM3wc5r9IRMFs6Tir3Uaro7cunWycYjEgdBimZ/cVa0qihh
    OXyn7A5A
    =ssIw
    -----END PGP PUBLIC KEY BLOCK-----
    """
    static let  privateKey2 = """
    -----BEGIN PGP PRIVATE KEY BLOCK-----
    Version: Keybase OpenPGP v1.0.0
    Comment: https://keybase.io/crypto

    xcASBGGEsH4TBSuBBAAiAwME2tbQujkpxzDCVznGFyqrIbl2uISqwKBohNvibyRk
    YHzn1GFaPR2mC5sMjQRPwk2Od4w69W3KrYARy0vQdC1CXNbbgUc/D4huDr//X+nf
    n6aq5sKzHh8N17zFyOY/sQyW/gkDCHb9k2mLHRX+YPKpA1nBE3kwFdyihqi/bh59
    LBPBGS5cQwC27a4FGTutCo2LE0xmKR3ne6BoSF/IMuzJcd4XQzA1C2Btrqf/E5Pm
    gy7SHCjMr/Sv6wpf3UHIf7nH+BHnzRZ0ZXN0MiA8dGVzdEB0ZXN0LnRlc3Q+wo8E
    ExMKABcFAmGEsH4CGy8DCwkHAxUKCAIeAQIXgAAKCRBUn/Czfb9MKQcIAYDuPtxS
    rZknAWzSa9EpaZzEsfjF8EZh8nHd9OzFPai3xLtTYBbLyveaUkEJTReaN+0BgMWs
    7RWbfsn40viH4/5fdPldtuFnyz1eW7JyHS3k6h670a+RNRXOYxJLyhA3liiRu8el
    BGGEsH4TCCqGSM49AwEHAgMEGXhXFrDR0BODnigI2a06AvfMrxgiduAJ6b/sja0h
    kGfsfRcZTZZ5P2Ch65lAVEQn4wPh6xCscXpHkTR/ddq6J/4JAwjtPDJjKmNqjWCl
    e5s4MqduJD8/LaOnlupqXnjGK+350ZNnX5aSvkb06QslxQKDf/dzkxzPY31UwGb+
    U1nzaK1tMBwDQfsqPPzyy4S23F9zwsAnBBgTCgAPBQJhhLB+BQkPCZwAAhsuAGoJ
    EFSf8LN9v0wpXyAEGRMKAAYFAmGEsH4ACgkQMpjwftKqaecNjAEAi3IfImuP0eMw
    UNeJAmzzz0rs+1sSlZGh3IytNByg/HgA/RvYCJzDnqXNpnlIb+Gm+JmCsC8Dzttf
    yIojnpY8a7gliRoBgK0IU32mv5cYgBjJpNCopRNzQf6QJKK3LedLgCVj6cmc3n8X
    tFh2WQnj6pmSYmzMGwGAtFnDcXAlaf67HVNMHCziUXDISJmSn9+ZsLThU5ZvGSlV
    DAHrnljrxQSDy5gcJ3pSx6UEYYSwfhMIKoZIzj0DAQcCAwSsGgH93exVg8OhyX/M
    G8sVe3ENMWa6LFsTNCEkLIaEjsuuM5GmIfriW5dY624xKAS7Pov18A0+YCE7kjbR
    gf+N/gkDCDRWw8yE4pr0YDsSxbdPoSyLY8XH5MKDm626FeufmpRAzlB4zVhja7co
    Rw6fSymWPr8aNVp6FNQm0mtp7bbtGVouebBu8Lox2gCNf0+wrWPCwCcEGBMKAA8F
    AmGEsH4FCQ8JnAACGy4AagkQVJ/ws32/TClfIAQZEwoABgUCYYSwfgAKCRAwwOdE
    eUAO6wsFAQCn/7Pylm6pgRlCWA+uZ2JfEDyRtN0asSL/Brad8rpcFQD/TdQKoueu
    FhQ46rLh/AzL9NZjaQj8QoiCDXaWQBuv2eYwkAF/WJTgNfTrBdRkI1/EqWH6vVCN
    rqfurXQKFUISiQaNoKDJjjVzr/2h1DOCT4Vh817iAYCmgBy/QWEJ8zfBzmv0hEwW
    zpOKvdRqujty6dbJxiMSB0GKZn9xVrSqKGE5fKfsDkA=
    =5fxc
    -----END PGP PRIVATE KEY BLOCK-----
    """
    static let  passphrash2 = "54321"
    static let  publicKey11 = """
    -----BEGIN PGP PUBLIC KEY BLOCK-----
    Version: Keybase OpenPGP v2.1.15
    Comment: https://keybase.io/crypto

    xm8EYYTbPRMFK4EEACIDAwRXmR31PdEH3wstFHeHiVFJ+fqtd4KSV4LDMZCH5OBh
    NlEft2PfRIHl/bVMAsFsxcL17Awxn8AByjx9utwRi7/R5+pIGknK3kULEoKHL/DQ
    BSAt/ifXwAWIJGk8x4OoaJPNAMKWBBMTCgAeBQJhhNs9AhsvAwsJBwMVCggCHgEC
    F4ADFgIBAhkBAAoJED0Ds+fgvPfcWtoBgKNb4V0oiz2UpsdZ9gLefUb53v9IbaTO
    pwZsecqI2ZTmRs/1OtMkHNfxDVsXpl6YIwGAiG1qrZKqj5CeSMV7jVvtzMOeTSmH
    G5UQYxsW4n0sZxtyPF/jSW7SZwU4DnmcmWnFzlIEYYTbPRMIKoZIzj0DAQcCAwSH
    tyFUv/xzTqbU7vsL02XA0kk+BZWjy9/wY0l5+iaqyzRAa+voxZM0Qu8tuX3tSKl6
    ubQrC+yuWVlEu1oYV6t8wsAnBBgTCgAPBQJhhNs9BQkPCZwAAhsuAGoJED0Ds+fg
    vPfcXyAEGRMKAAYFAmGE2z0ACgkQMxPcFzFx5PcnDgEAzYpi7ZmmHBXO51uCYpXg
    859Z+15WSH83NIVKRKyHHO8BAIDEkXNNm7xTM0ACzsD0UYTCXcXrd73rOv9Ovnim
    eMB9BXQBf13CsOItJYS32LVHeQVjpYH5iBv1HmkxzXwKvsqeqBmyccDYwBh0K16+
    CYfLzNZs8AF/dAwmqs/6xRwIjAziQla3F4SMjXS48bDQWHOPJ2Qm+2dS95KEfP8p
    LwWtkPmFybfezlIEYYTbPRMIKoZIzj0DAQcCAwT+FVvtRcQfRjFe3bizAiw2yT+n
    Zlxs0sJ2ZRegwH1OXd5JvhoSP2fo8hh/eSd7tzSzygpT2jTlAchu6nPIAAtiwsAn
    BBgTCgAPBQJhhNs9BQkDwmcAAhsuAGoJED0Ds+fgvPfcXyAEGRMKAAYFAmGE2z0A
    CgkQTl9U5jWK6yywHgD/WXQ0gyZsrywqBWjlbdSAb5kYVNlcxQEfEb5sEyc5xVIA
    /3Nh9hyyhS85L6RetgU9/vLh8PbZmK1LM2dswVOwA44wXKcBfAw5erweif9Q5luQ
    xe4IyWY2RKGqF/e9aMNKYIlP6oCpYY3vSA/RL/mDPuNop1bamgF/YNoIjnxni0PO
    4mDbpX6ptiey77cZxPaejmwh2kLeGmsB71qIEpLifT5aiTl7tgoa
    =yFi+
    -----END PGP PUBLIC KEY BLOCK-----
    """
    // same passphrase as privateKey1
    static let  privateKey11 = """
    -----BEGIN PGP PRIVATE KEY BLOCK-----
    Version: Keybase OpenPGP v2.1.15
    Comment: https://keybase.io/crypto

    xcASBGGE2z0TBSuBBAAiAwMEV5kd9T3RB98LLRR3h4lRSfn6rXeCkleCwzGQh+Tg
    YTZRH7dj30SB5f21TALBbMXC9ewMMZ/AAco8fbrcEYu/0efqSBpJyt5FCxKChy/w
    0AUgLf4n18AFiCRpPMeDqGiT/gkDCAtk/GaFewqnYKy8ZSQ09cowJrKkHn+Kc2kZ
    DU+w91ihPnZFomNzxsLNvxuInTnRNPCVQ1Lpr6fkJapeIxjDSbrbeqfvQfpq4P/T
    376DhvDuY452+7rmx3aVVuN4UzbhzQDClgQTEwoAHgUCYYTbPQIbLwMLCQcDFQoI
    Ah4BAheAAxYCAQIZAQAKCRA9A7Pn4Lz33FraAYCjW+FdKIs9lKbHWfYC3n1G+d7/
    SG2kzqcGbHnKiNmU5kbP9TrTJBzX8Q1bF6ZemCMBgIhtaq2Sqo+QnkjFe41b7czD
    nk0phxuVEGMbFuJ9LGcbcjxf40lu0mcFOA55nJlpxcelBGGE2z0TCCqGSM49AwEH
    AgMEh7chVL/8c06m1O77C9NlwNJJPgWVo8vf8GNJefomqss0QGvr6MWTNELvLbl9
    7Uiperm0KwvsrllZRLtaGFerfP4JAwgw9Cnyxz8RJGAjC93IA1H9tUxJa13VcCy8
    vYpxoBSoDKaoyU1VS1QBFO56igXjTyVg2LGM103NDTBMZsHwYbSwnqDFJySUKubk
    Xmyh/kw7wsAnBBgTCgAPBQJhhNs9BQkPCZwAAhsuAGoJED0Ds+fgvPfcXyAEGRMK
    AAYFAmGE2z0ACgkQMxPcFzFx5PcnDgEAzYpi7ZmmHBXO51uCYpXg859Z+15WSH83
    NIVKRKyHHO8BAIDEkXNNm7xTM0ACzsD0UYTCXcXrd73rOv9OvnimeMB9BXQBf13C
    sOItJYS32LVHeQVjpYH5iBv1HmkxzXwKvsqeqBmyccDYwBh0K16+CYfLzNZs8AF/
    dAwmqs/6xRwIjAziQla3F4SMjXS48bDQWHOPJ2Qm+2dS95KEfP8pLwWtkPmFybfe
    x6UEYYTbPRMIKoZIzj0DAQcCAwT+FVvtRcQfRjFe3bizAiw2yT+nZlxs0sJ2ZReg
    wH1OXd5JvhoSP2fo8hh/eSd7tzSzygpT2jTlAchu6nPIAAti/gkDCD+p6K4fgX22
    YMk5hN+Nfgc1yiNtI+rG2SPzSMp9ezAtIEOOSYSIQmIUrc4t5r/+IzpIVL0Dk0gG
    I1eesklmdzgpj3LBM/pSuQpXIfq6AvXCwCcEGBMKAA8FAmGE2z0FCQPCZwACGy4A
    agkQPQOz5+C899xfIAQZEwoABgUCYYTbPQAKCRBOX1TmNYrrLLAeAP9ZdDSDJmyv
    LCoFaOVt1IBvmRhU2VzFAR8RvmwTJznFUgD/c2H2HLKFLzkvpF62BT3+8uHw9tmY
    rUszZ2zBU7ADjjBcpwF8DDl6vB6J/1DmW5DF7gjJZjZEoaoX971ow0pgiU/qgKlh
    je9ID9Ev+YM+42inVtqaAX9g2giOfGeLQ87iYNulfqm2J7LvtxnE9p6ObCHaQt4a
    awHvWogSkuJ9PlqJOXu2Cho=
    =n53n
    -----END PGP PRIVATE KEY BLOCK-----
    """
}

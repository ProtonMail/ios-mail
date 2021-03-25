//
//  JKBCrypt.swift
//  JKBCrypt
//
//  Created by Joe Kramer on 6/19/2015.
//  Copyright (c) 2015 Joe Kramer. All rights reserved.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//
// ----------------------------------------------------------------------
//
// This Swift port is based on the Objective-C port by Jay Fuerstenberg.
// https://github.com/jayfuerstenberg/JFCommon
//
// ----------------------------------------------------------------------
//
// The Objective-C port is based on the original Java implementation by Damien Miller
// found here: http://www.mindrot.org/projects/jBCrypt/
// In accordance with the Damien Miller's request, his original copyright covering
// his Java implementation is included here:
//
// Copyright (c) 2006 Damien Miller <djm@mindrot.org>
//
// Permission to use, copy, modify, and distribute this software for any
// purpose with or without fee is hereby granted, provided that the above
// copyright notice and this permission notice appear in all copies.
//
// THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
// WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
// MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
// ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
// WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
// ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
// OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
//

import Foundation

// MARK: - Class Extensions
extension Character {
    func utf16Value() -> UInt16 {
        for s in String(self).utf16 {
            return s
        }
        return 0
    }
}

// BCrypt parameters
let GENSALT_DEFAULT_LOG2_ROUNDS : Int = 10
let BCRYPT_SALT_LEN             : Int = 16

// Blowfish parameters
let BLOWFISH_NUM_ROUNDS : Int = 16

// Initial contents of key schedule
let P_orig : [Int32] = [
    Int32(bitPattern: 0x243f6a88), Int32(bitPattern: 0x85a308d3), Int32(bitPattern: 0x13198a2e), Int32(bitPattern: 0x03707344),
    Int32(bitPattern: 0xa4093822), Int32(bitPattern: 0x299f31d0), Int32(bitPattern: 0x082efa98), Int32(bitPattern: 0xec4e6c89),
    Int32(bitPattern: 0x452821e6), Int32(bitPattern: 0x38d01377), Int32(bitPattern: 0xbe5466cf), Int32(bitPattern: 0x34e90c6c),
    Int32(bitPattern: 0xc0ac29b7), Int32(bitPattern: 0xc97c50dd), Int32(bitPattern: 0x3f84d5b5), Int32(bitPattern: 0xb5470917),
    Int32(bitPattern: 0x9216d5d9), Int32(bitPattern: 0x8979fb1b)
]

let S_orig : [Int32] = [
    Int32(bitPattern: 0xd1310ba6), Int32(bitPattern: 0x98dfb5ac), Int32(bitPattern: 0x2ffd72db), Int32(bitPattern: 0xd01adfb7),
    Int32(bitPattern: 0xb8e1afed), Int32(bitPattern: 0x6a267e96), Int32(bitPattern: 0xba7c9045), Int32(bitPattern: 0xf12c7f99),
    Int32(bitPattern: 0x24a19947), Int32(bitPattern: 0xb3916cf7), Int32(bitPattern: 0x0801f2e2), Int32(bitPattern: 0x858efc16),
    Int32(bitPattern: 0x636920d8), Int32(bitPattern: 0x71574e69), Int32(bitPattern: 0xa458fea3), Int32(bitPattern: 0xf4933d7e),
    Int32(bitPattern: 0x0d95748f), Int32(bitPattern: 0x728eb658), Int32(bitPattern: 0x718bcd58), Int32(bitPattern: 0x82154aee),
    Int32(bitPattern: 0x7b54a41d), Int32(bitPattern: 0xc25a59b5), Int32(bitPattern: 0x9c30d539), Int32(bitPattern: 0x2af26013),
    Int32(bitPattern: 0xc5d1b023), Int32(bitPattern: 0x286085f0), Int32(bitPattern: 0xca417918), Int32(bitPattern: 0xb8db38ef),
    Int32(bitPattern: 0x8e79dcb0), Int32(bitPattern: 0x603a180e), Int32(bitPattern: 0x6c9e0e8b), Int32(bitPattern: 0xb01e8a3e),
    Int32(bitPattern: 0xd71577c1), Int32(bitPattern: 0xbd314b27), Int32(bitPattern: 0x78af2fda), Int32(bitPattern: 0x55605c60),
    Int32(bitPattern: 0xe65525f3), Int32(bitPattern: 0xaa55ab94), Int32(bitPattern: 0x57489862), Int32(bitPattern: 0x63e81440),
    Int32(bitPattern: 0x55ca396a), Int32(bitPattern: 0x2aab10b6), Int32(bitPattern: 0xb4cc5c34), Int32(bitPattern: 0x1141e8ce),
    Int32(bitPattern: 0xa15486af), Int32(bitPattern: 0x7c72e993), Int32(bitPattern: 0xb3ee1411), Int32(bitPattern: 0x636fbc2a),
    Int32(bitPattern: 0x2ba9c55d), Int32(bitPattern: 0x741831f6), Int32(bitPattern: 0xce5c3e16), Int32(bitPattern: 0x9b87931e),
    Int32(bitPattern: 0xafd6ba33), Int32(bitPattern: 0x6c24cf5c), Int32(bitPattern: 0x7a325381), Int32(bitPattern: 0x28958677),
    Int32(bitPattern: 0x3b8f4898), Int32(bitPattern: 0x6b4bb9af), Int32(bitPattern: 0xc4bfe81b), Int32(bitPattern: 0x66282193),
    Int32(bitPattern: 0x61d809cc), Int32(bitPattern: 0xfb21a991), Int32(bitPattern: 0x487cac60), Int32(bitPattern: 0x5dec8032),
    Int32(bitPattern: 0xef845d5d), Int32(bitPattern: 0xe98575b1), Int32(bitPattern: 0xdc262302), Int32(bitPattern: 0xeb651b88),
    Int32(bitPattern: 0x23893e81), Int32(bitPattern: 0xd396acc5), Int32(bitPattern: 0x0f6d6ff3), Int32(bitPattern: 0x83f44239),
    Int32(bitPattern: 0x2e0b4482), Int32(bitPattern: 0xa4842004), Int32(bitPattern: 0x69c8f04a), Int32(bitPattern: 0x9e1f9b5e),
    Int32(bitPattern: 0x21c66842), Int32(bitPattern: 0xf6e96c9a), Int32(bitPattern: 0x670c9c61), Int32(bitPattern: 0xabd388f0),
    Int32(bitPattern: 0x6a51a0d2), Int32(bitPattern: 0xd8542f68), Int32(bitPattern: 0x960fa728), Int32(bitPattern: 0xab5133a3),
    Int32(bitPattern: 0x6eef0b6c), Int32(bitPattern: 0x137a3be4), Int32(bitPattern: 0xba3bf050), Int32(bitPattern: 0x7efb2a98),
    Int32(bitPattern: 0xa1f1651d), Int32(bitPattern: 0x39af0176), Int32(bitPattern: 0x66ca593e), Int32(bitPattern: 0x82430e88),
    Int32(bitPattern: 0x8cee8619), Int32(bitPattern: 0x456f9fb4), Int32(bitPattern: 0x7d84a5c3), Int32(bitPattern: 0x3b8b5ebe),
    Int32(bitPattern: 0xe06f75d8), Int32(bitPattern: 0x85c12073), Int32(bitPattern: 0x401a449f), Int32(bitPattern: 0x56c16aa6),
    Int32(bitPattern: 0x4ed3aa62), Int32(bitPattern: 0x363f7706), Int32(bitPattern: 0x1bfedf72), Int32(bitPattern: 0x429b023d),
    Int32(bitPattern: 0x37d0d724), Int32(bitPattern: 0xd00a1248), Int32(bitPattern: 0xdb0fead3), Int32(bitPattern: 0x49f1c09b),
    Int32(bitPattern: 0x075372c9), Int32(bitPattern: 0x80991b7b), Int32(bitPattern: 0x25d479d8), Int32(bitPattern: 0xf6e8def7),
    Int32(bitPattern: 0xe3fe501a), Int32(bitPattern: 0xb6794c3b), Int32(bitPattern: 0x976ce0bd), Int32(bitPattern: 0x04c006ba),
    Int32(bitPattern: 0xc1a94fb6), Int32(bitPattern: 0x409f60c4), Int32(bitPattern: 0x5e5c9ec2), Int32(bitPattern: 0x196a2463),
    Int32(bitPattern: 0x68fb6faf), Int32(bitPattern: 0x3e6c53b5), Int32(bitPattern: 0x1339b2eb), Int32(bitPattern: 0x3b52ec6f),
    Int32(bitPattern: 0x6dfc511f), Int32(bitPattern: 0x9b30952c), Int32(bitPattern: 0xcc814544), Int32(bitPattern: 0xaf5ebd09),
    Int32(bitPattern: 0xbee3d004), Int32(bitPattern: 0xde334afd), Int32(bitPattern: 0x660f2807), Int32(bitPattern: 0x192e4bb3),
    Int32(bitPattern: 0xc0cba857), Int32(bitPattern: 0x45c8740f), Int32(bitPattern: 0xd20b5f39), Int32(bitPattern: 0xb9d3fbdb),
    Int32(bitPattern: 0x5579c0bd), Int32(bitPattern: 0x1a60320a), Int32(bitPattern: 0xd6a100c6), Int32(bitPattern: 0x402c7279),
    Int32(bitPattern: 0x679f25fe), Int32(bitPattern: 0xfb1fa3cc), Int32(bitPattern: 0x8ea5e9f8), Int32(bitPattern: 0xdb3222f8),
    Int32(bitPattern: 0x3c7516df), Int32(bitPattern: 0xfd616b15), Int32(bitPattern: 0x2f501ec8), Int32(bitPattern: 0xad0552ab),
    Int32(bitPattern: 0x323db5fa), Int32(bitPattern: 0xfd238760), Int32(bitPattern: 0x53317b48), Int32(bitPattern: 0x3e00df82),
    Int32(bitPattern: 0x9e5c57bb), Int32(bitPattern: 0xca6f8ca0), Int32(bitPattern: 0x1a87562e), Int32(bitPattern: 0xdf1769db),
    Int32(bitPattern: 0xd542a8f6), Int32(bitPattern: 0x287effc3), Int32(bitPattern: 0xac6732c6), Int32(bitPattern: 0x8c4f5573),
    Int32(bitPattern: 0x695b27b0), Int32(bitPattern: 0xbbca58c8), Int32(bitPattern: 0xe1ffa35d), Int32(bitPattern: 0xb8f011a0),
    Int32(bitPattern: 0x10fa3d98), Int32(bitPattern: 0xfd2183b8), Int32(bitPattern: 0x4afcb56c), Int32(bitPattern: 0x2dd1d35b),
    Int32(bitPattern: 0x9a53e479), Int32(bitPattern: 0xb6f84565), Int32(bitPattern: 0xd28e49bc), Int32(bitPattern: 0x4bfb9790),
    Int32(bitPattern: 0xe1ddf2da), Int32(bitPattern: 0xa4cb7e33), Int32(bitPattern: 0x62fb1341), Int32(bitPattern: 0xcee4c6e8),
    Int32(bitPattern: 0xef20cada), Int32(bitPattern: 0x36774c01), Int32(bitPattern: 0xd07e9efe), Int32(bitPattern: 0x2bf11fb4),
    Int32(bitPattern: 0x95dbda4d), Int32(bitPattern: 0xae909198), Int32(bitPattern: 0xeaad8e71), Int32(bitPattern: 0x6b93d5a0),
    Int32(bitPattern: 0xd08ed1d0), Int32(bitPattern: 0xafc725e0), Int32(bitPattern: 0x8e3c5b2f), Int32(bitPattern: 0x8e7594b7),
    Int32(bitPattern: 0x8ff6e2fb), Int32(bitPattern: 0xf2122b64), Int32(bitPattern: 0x8888b812), Int32(bitPattern: 0x900df01c),
    Int32(bitPattern: 0x4fad5ea0), Int32(bitPattern: 0x688fc31c), Int32(bitPattern: 0xd1cff191), Int32(bitPattern: 0xb3a8c1ad),
    Int32(bitPattern: 0x2f2f2218), Int32(bitPattern: 0xbe0e1777), Int32(bitPattern: 0xea752dfe), Int32(bitPattern: 0x8b021fa1),
    Int32(bitPattern: 0xe5a0cc0f), Int32(bitPattern: 0xb56f74e8), Int32(bitPattern: 0x18acf3d6), Int32(bitPattern: 0xce89e299),
    Int32(bitPattern: 0xb4a84fe0), Int32(bitPattern: 0xfd13e0b7), Int32(bitPattern: 0x7cc43b81), Int32(bitPattern: 0xd2ada8d9),
    Int32(bitPattern: 0x165fa266), Int32(bitPattern: 0x80957705), Int32(bitPattern: 0x93cc7314), Int32(bitPattern: 0x211a1477),
    Int32(bitPattern: 0xe6ad2065), Int32(bitPattern: 0x77b5fa86), Int32(bitPattern: 0xc75442f5), Int32(bitPattern: 0xfb9d35cf),
    Int32(bitPattern: 0xebcdaf0c), Int32(bitPattern: 0x7b3e89a0), Int32(bitPattern: 0xd6411bd3), Int32(bitPattern: 0xae1e7e49),
    Int32(bitPattern: 0x00250e2d), Int32(bitPattern: 0x2071b35e), Int32(bitPattern: 0x226800bb), Int32(bitPattern: 0x57b8e0af),
    Int32(bitPattern: 0x2464369b), Int32(bitPattern: 0xf009b91e), Int32(bitPattern: 0x5563911d), Int32(bitPattern: 0x59dfa6aa),
    Int32(bitPattern: 0x78c14389), Int32(bitPattern: 0xd95a537f), Int32(bitPattern: 0x207d5ba2), Int32(bitPattern: 0x02e5b9c5),
    Int32(bitPattern: 0x83260376), Int32(bitPattern: 0x6295cfa9), Int32(bitPattern: 0x11c81968), Int32(bitPattern: 0x4e734a41),
    Int32(bitPattern: 0xb3472dca), Int32(bitPattern: 0x7b14a94a), Int32(bitPattern: 0x1b510052), Int32(bitPattern: 0x9a532915),
    Int32(bitPattern: 0xd60f573f), Int32(bitPattern: 0xbc9bc6e4), Int32(bitPattern: 0x2b60a476), Int32(bitPattern: 0x81e67400),
    Int32(bitPattern: 0x08ba6fb5), Int32(bitPattern: 0x571be91f), Int32(bitPattern: 0xf296ec6b), Int32(bitPattern: 0x2a0dd915),
    Int32(bitPattern: 0xb6636521), Int32(bitPattern: 0xe7b9f9b6), Int32(bitPattern: 0xff34052e), Int32(bitPattern: 0xc5855664),
    Int32(bitPattern: 0x53b02d5d), Int32(bitPattern: 0xa99f8fa1), Int32(bitPattern: 0x08ba4799), Int32(bitPattern: 0x6e85076a),
    Int32(bitPattern: 0x4b7a70e9), Int32(bitPattern: 0xb5b32944), Int32(bitPattern: 0xdb75092e), Int32(bitPattern: 0xc4192623),
    Int32(bitPattern: 0xad6ea6b0), Int32(bitPattern: 0x49a7df7d), Int32(bitPattern: 0x9cee60b8), Int32(bitPattern: 0x8fedb266),
    Int32(bitPattern: 0xecaa8c71), Int32(bitPattern: 0x699a17ff), Int32(bitPattern: 0x5664526c), Int32(bitPattern: 0xc2b19ee1),
    Int32(bitPattern: 0x193602a5), Int32(bitPattern: 0x75094c29), Int32(bitPattern: 0xa0591340), Int32(bitPattern: 0xe4183a3e),
    Int32(bitPattern: 0x3f54989a), Int32(bitPattern: 0x5b429d65), Int32(bitPattern: 0x6b8fe4d6), Int32(bitPattern: 0x99f73fd6),
    Int32(bitPattern: 0xa1d29c07), Int32(bitPattern: 0xefe830f5), Int32(bitPattern: 0x4d2d38e6), Int32(bitPattern: 0xf0255dc1),
    Int32(bitPattern: 0x4cdd2086), Int32(bitPattern: 0x8470eb26), Int32(bitPattern: 0x6382e9c6), Int32(bitPattern: 0x021ecc5e),
    Int32(bitPattern: 0x09686b3f), Int32(bitPattern: 0x3ebaefc9), Int32(bitPattern: 0x3c971814), Int32(bitPattern: 0x6b6a70a1),
    Int32(bitPattern: 0x687f3584), Int32(bitPattern: 0x52a0e286), Int32(bitPattern: 0xb79c5305), Int32(bitPattern: 0xaa500737),
    Int32(bitPattern: 0x3e07841c), Int32(bitPattern: 0x7fdeae5c), Int32(bitPattern: 0x8e7d44ec), Int32(bitPattern: 0x5716f2b8),
    Int32(bitPattern: 0xb03ada37), Int32(bitPattern: 0xf0500c0d), Int32(bitPattern: 0xf01c1f04), Int32(bitPattern: 0x0200b3ff),
    Int32(bitPattern: 0xae0cf51a), Int32(bitPattern: 0x3cb574b2), Int32(bitPattern: 0x25837a58), Int32(bitPattern: 0xdc0921bd),
    Int32(bitPattern: 0xd19113f9), Int32(bitPattern: 0x7ca92ff6), Int32(bitPattern: 0x94324773), Int32(bitPattern: 0x22f54701),
    Int32(bitPattern: 0x3ae5e581), Int32(bitPattern: 0x37c2dadc), Int32(bitPattern: 0xc8b57634), Int32(bitPattern: 0x9af3dda7),
    Int32(bitPattern: 0xa9446146), Int32(bitPattern: 0x0fd0030e), Int32(bitPattern: 0xecc8c73e), Int32(bitPattern: 0xa4751e41),
    Int32(bitPattern: 0xe238cd99), Int32(bitPattern: 0x3bea0e2f), Int32(bitPattern: 0x3280bba1), Int32(bitPattern: 0x183eb331),
    Int32(bitPattern: 0x4e548b38), Int32(bitPattern: 0x4f6db908), Int32(bitPattern: 0x6f420d03), Int32(bitPattern: 0xf60a04bf),
    Int32(bitPattern: 0x2cb81290), Int32(bitPattern: 0x24977c79), Int32(bitPattern: 0x5679b072), Int32(bitPattern: 0xbcaf89af),
    Int32(bitPattern: 0xde9a771f), Int32(bitPattern: 0xd9930810), Int32(bitPattern: 0xb38bae12), Int32(bitPattern: 0xdccf3f2e),
    Int32(bitPattern: 0x5512721f), Int32(bitPattern: 0x2e6b7124), Int32(bitPattern: 0x501adde6), Int32(bitPattern: 0x9f84cd87),
    Int32(bitPattern: 0x7a584718), Int32(bitPattern: 0x7408da17), Int32(bitPattern: 0xbc9f9abc), Int32(bitPattern: 0xe94b7d8c),
    Int32(bitPattern: 0xec7aec3a), Int32(bitPattern: 0xdb851dfa), Int32(bitPattern: 0x63094366), Int32(bitPattern: 0xc464c3d2),
    Int32(bitPattern: 0xef1c1847), Int32(bitPattern: 0x3215d908), Int32(bitPattern: 0xdd433b37), Int32(bitPattern: 0x24c2ba16),
    Int32(bitPattern: 0x12a14d43), Int32(bitPattern: 0x2a65c451), Int32(bitPattern: 0x50940002), Int32(bitPattern: 0x133ae4dd),
    Int32(bitPattern: 0x71dff89e), Int32(bitPattern: 0x10314e55), Int32(bitPattern: 0x81ac77d6), Int32(bitPattern: 0x5f11199b),
    Int32(bitPattern: 0x043556f1), Int32(bitPattern: 0xd7a3c76b), Int32(bitPattern: 0x3c11183b), Int32(bitPattern: 0x5924a509),
    Int32(bitPattern: 0xf28fe6ed), Int32(bitPattern: 0x97f1fbfa), Int32(bitPattern: 0x9ebabf2c), Int32(bitPattern: 0x1e153c6e),
    Int32(bitPattern: 0x86e34570), Int32(bitPattern: 0xeae96fb1), Int32(bitPattern: 0x860e5e0a), Int32(bitPattern: 0x5a3e2ab3),
    Int32(bitPattern: 0x771fe71c), Int32(bitPattern: 0x4e3d06fa), Int32(bitPattern: 0x2965dcb9), Int32(bitPattern: 0x99e71d0f),
    Int32(bitPattern: 0x803e89d6), Int32(bitPattern: 0x5266c825), Int32(bitPattern: 0x2e4cc978), Int32(bitPattern: 0x9c10b36a),
    Int32(bitPattern: 0xc6150eba), Int32(bitPattern: 0x94e2ea78), Int32(bitPattern: 0xa5fc3c53), Int32(bitPattern: 0x1e0a2df4),
    Int32(bitPattern: 0xf2f74ea7), Int32(bitPattern: 0x361d2b3d), Int32(bitPattern: 0x1939260f), Int32(bitPattern: 0x19c27960),
    Int32(bitPattern: 0x5223a708), Int32(bitPattern: 0xf71312b6), Int32(bitPattern: 0xebadfe6e), Int32(bitPattern: 0xeac31f66),
    Int32(bitPattern: 0xe3bc4595), Int32(bitPattern: 0xa67bc883), Int32(bitPattern: 0xb17f37d1), Int32(bitPattern: 0x018cff28),
    Int32(bitPattern: 0xc332ddef), Int32(bitPattern: 0xbe6c5aa5), Int32(bitPattern: 0x65582185), Int32(bitPattern: 0x68ab9802),
    Int32(bitPattern: 0xeecea50f), Int32(bitPattern: 0xdb2f953b), Int32(bitPattern: 0x2aef7dad), Int32(bitPattern: 0x5b6e2f84),
    Int32(bitPattern: 0x1521b628), Int32(bitPattern: 0x29076170), Int32(bitPattern: 0xecdd4775), Int32(bitPattern: 0x619f1510),
    Int32(bitPattern: 0x13cca830), Int32(bitPattern: 0xeb61bd96), Int32(bitPattern: 0x0334fe1e), Int32(bitPattern: 0xaa0363cf),
    Int32(bitPattern: 0xb5735c90), Int32(bitPattern: 0x4c70a239), Int32(bitPattern: 0xd59e9e0b), Int32(bitPattern: 0xcbaade14),
    Int32(bitPattern: 0xeecc86bc), Int32(bitPattern: 0x60622ca7), Int32(bitPattern: 0x9cab5cab), Int32(bitPattern: 0xb2f3846e),
    Int32(bitPattern: 0x648b1eaf), Int32(bitPattern: 0x19bdf0ca), Int32(bitPattern: 0xa02369b9), Int32(bitPattern: 0x655abb50),
    Int32(bitPattern: 0x40685a32), Int32(bitPattern: 0x3c2ab4b3), Int32(bitPattern: 0x319ee9d5), Int32(bitPattern: 0xc021b8f7),
    Int32(bitPattern: 0x9b540b19), Int32(bitPattern: 0x875fa099), Int32(bitPattern: 0x95f7997e), Int32(bitPattern: 0x623d7da8),
    Int32(bitPattern: 0xf837889a), Int32(bitPattern: 0x97e32d77), Int32(bitPattern: 0x11ed935f), Int32(bitPattern: 0x16681281),
    Int32(bitPattern: 0x0e358829), Int32(bitPattern: 0xc7e61fd6), Int32(bitPattern: 0x96dedfa1), Int32(bitPattern: 0x7858ba99),
    Int32(bitPattern: 0x57f584a5), Int32(bitPattern: 0x1b227263), Int32(bitPattern: 0x9b83c3ff), Int32(bitPattern: 0x1ac24696),
    Int32(bitPattern: 0xcdb30aeb), Int32(bitPattern: 0x532e3054), Int32(bitPattern: 0x8fd948e4), Int32(bitPattern: 0x6dbc3128),
    Int32(bitPattern: 0x58ebf2ef), Int32(bitPattern: 0x34c6ffea), Int32(bitPattern: 0xfe28ed61), Int32(bitPattern: 0xee7c3c73),
    Int32(bitPattern: 0x5d4a14d9), Int32(bitPattern: 0xe864b7e3), Int32(bitPattern: 0x42105d14), Int32(bitPattern: 0x203e13e0),
    Int32(bitPattern: 0x45eee2b6), Int32(bitPattern: 0xa3aaabea), Int32(bitPattern: 0xdb6c4f15), Int32(bitPattern: 0xfacb4fd0),
    Int32(bitPattern: 0xc742f442), Int32(bitPattern: 0xef6abbb5), Int32(bitPattern: 0x654f3b1d), Int32(bitPattern: 0x41cd2105),
    Int32(bitPattern: 0xd81e799e), Int32(bitPattern: 0x86854dc7), Int32(bitPattern: 0xe44b476a), Int32(bitPattern: 0x3d816250),
    Int32(bitPattern: 0xcf62a1f2), Int32(bitPattern: 0x5b8d2646), Int32(bitPattern: 0xfc8883a0), Int32(bitPattern: 0xc1c7b6a3),
    Int32(bitPattern: 0x7f1524c3), Int32(bitPattern: 0x69cb7492), Int32(bitPattern: 0x47848a0b), Int32(bitPattern: 0x5692b285),
    Int32(bitPattern: 0x095bbf00), Int32(bitPattern: 0xad19489d), Int32(bitPattern: 0x1462b174), Int32(bitPattern: 0x23820e00),
    Int32(bitPattern: 0x58428d2a), Int32(bitPattern: 0x0c55f5ea), Int32(bitPattern: 0x1dadf43e), Int32(bitPattern: 0x233f7061),
    Int32(bitPattern: 0x3372f092), Int32(bitPattern: 0x8d937e41), Int32(bitPattern: 0xd65fecf1), Int32(bitPattern: 0x6c223bdb),
    Int32(bitPattern: 0x7cde3759), Int32(bitPattern: 0xcbee7460), Int32(bitPattern: 0x4085f2a7), Int32(bitPattern: 0xce77326e),
    Int32(bitPattern: 0xa6078084), Int32(bitPattern: 0x19f8509e), Int32(bitPattern: 0xe8efd855), Int32(bitPattern: 0x61d99735),
    Int32(bitPattern: 0xa969a7aa), Int32(bitPattern: 0xc50c06c2), Int32(bitPattern: 0x5a04abfc), Int32(bitPattern: 0x800bcadc),
    Int32(bitPattern: 0x9e447a2e), Int32(bitPattern: 0xc3453484), Int32(bitPattern: 0xfdd56705), Int32(bitPattern: 0x0e1e9ec9),
    Int32(bitPattern: 0xdb73dbd3), Int32(bitPattern: 0x105588cd), Int32(bitPattern: 0x675fda79), Int32(bitPattern: 0xe3674340),
    Int32(bitPattern: 0xc5c43465), Int32(bitPattern: 0x713e38d8), Int32(bitPattern: 0x3d28f89e), Int32(bitPattern: 0xf16dff20),
    Int32(bitPattern: 0x153e21e7), Int32(bitPattern: 0x8fb03d4a), Int32(bitPattern: 0xe6e39f2b), Int32(bitPattern: 0xdb83adf7),
    Int32(bitPattern: 0xe93d5a68), Int32(bitPattern: 0x948140f7), Int32(bitPattern: 0xf64c261c), Int32(bitPattern: 0x94692934),
    Int32(bitPattern: 0x411520f7), Int32(bitPattern: 0x7602d4f7), Int32(bitPattern: 0xbcf46b2e), Int32(bitPattern: 0xd4a20068),
    Int32(bitPattern: 0xd4082471), Int32(bitPattern: 0x3320f46a), Int32(bitPattern: 0x43b7d4b7), Int32(bitPattern: 0x500061af),
    Int32(bitPattern: 0x1e39f62e), Int32(bitPattern: 0x97244546), Int32(bitPattern: 0x14214f74), Int32(bitPattern: 0xbf8b8840),
    Int32(bitPattern: 0x4d95fc1d), Int32(bitPattern: 0x96b591af), Int32(bitPattern: 0x70f4ddd3), Int32(bitPattern: 0x66a02f45),
    Int32(bitPattern: 0xbfbc09ec), Int32(bitPattern: 0x03bd9785), Int32(bitPattern: 0x7fac6dd0), Int32(bitPattern: 0x31cb8504),
    Int32(bitPattern: 0x96eb27b3), Int32(bitPattern: 0x55fd3941), Int32(bitPattern: 0xda2547e6), Int32(bitPattern: 0xabca0a9a),
    Int32(bitPattern: 0x28507825), Int32(bitPattern: 0x530429f4), Int32(bitPattern: 0x0a2c86da), Int32(bitPattern: 0xe9b66dfb),
    Int32(bitPattern: 0x68dc1462), Int32(bitPattern: 0xd7486900), Int32(bitPattern: 0x680ec0a4), Int32(bitPattern: 0x27a18dee),
    Int32(bitPattern: 0x4f3ffea2), Int32(bitPattern: 0xe887ad8c), Int32(bitPattern: 0xb58ce006), Int32(bitPattern: 0x7af4d6b6),
    Int32(bitPattern: 0xaace1e7c), Int32(bitPattern: 0xd3375fec), Int32(bitPattern: 0xce78a399), Int32(bitPattern: 0x406b2a42),
    Int32(bitPattern: 0x20fe9e35), Int32(bitPattern: 0xd9f385b9), Int32(bitPattern: 0xee39d7ab), Int32(bitPattern: 0x3b124e8b),
    Int32(bitPattern: 0x1dc9faf7), Int32(bitPattern: 0x4b6d1856), Int32(bitPattern: 0x26a36631), Int32(bitPattern: 0xeae397b2),
    Int32(bitPattern: 0x3a6efa74), Int32(bitPattern: 0xdd5b4332), Int32(bitPattern: 0x6841e7f7), Int32(bitPattern: 0xca7820fb),
    Int32(bitPattern: 0xfb0af54e), Int32(bitPattern: 0xd8feb397), Int32(bitPattern: 0x454056ac), Int32(bitPattern: 0xba489527),
    Int32(bitPattern: 0x55533a3a), Int32(bitPattern: 0x20838d87), Int32(bitPattern: 0xfe6ba9b7), Int32(bitPattern: 0xd096954b),
    Int32(bitPattern: 0x55a867bc), Int32(bitPattern: 0xa1159a58), Int32(bitPattern: 0xcca92963), Int32(bitPattern: 0x99e1db33),
    Int32(bitPattern: 0xa62a4a56), Int32(bitPattern: 0x3f3125f9), Int32(bitPattern: 0x5ef47e1c), Int32(bitPattern: 0x9029317c),
    Int32(bitPattern: 0xfdf8e802), Int32(bitPattern: 0x04272f70), Int32(bitPattern: 0x80bb155c), Int32(bitPattern: 0x05282ce3),
    Int32(bitPattern: 0x95c11548), Int32(bitPattern: 0xe4c66d22), Int32(bitPattern: 0x48c1133f), Int32(bitPattern: 0xc70f86dc),
    Int32(bitPattern: 0x07f9c9ee), Int32(bitPattern: 0x41041f0f), Int32(bitPattern: 0x404779a4), Int32(bitPattern: 0x5d886e17),
    Int32(bitPattern: 0x325f51eb), Int32(bitPattern: 0xd59bc0d1), Int32(bitPattern: 0xf2bcc18f), Int32(bitPattern: 0x41113564),
    Int32(bitPattern: 0x257b7834), Int32(bitPattern: 0x602a9c60), Int32(bitPattern: 0xdff8e8a3), Int32(bitPattern: 0x1f636c1b),
    Int32(bitPattern: 0x0e12b4c2), Int32(bitPattern: 0x02e1329e), Int32(bitPattern: 0xaf664fd1), Int32(bitPattern: 0xcad18115),
    Int32(bitPattern: 0x6b2395e0), Int32(bitPattern: 0x333e92e1), Int32(bitPattern: 0x3b240b62), Int32(bitPattern: 0xeebeb922),
    Int32(bitPattern: 0x85b2a20e), Int32(bitPattern: 0xe6ba0d99), Int32(bitPattern: 0xde720c8c), Int32(bitPattern: 0x2da2f728),
    Int32(bitPattern: 0xd0127845), Int32(bitPattern: 0x95b794fd), Int32(bitPattern: 0x647d0862), Int32(bitPattern: 0xe7ccf5f0),
    Int32(bitPattern: 0x5449a36f), Int32(bitPattern: 0x877d48fa), Int32(bitPattern: 0xc39dfd27), Int32(bitPattern: 0xf33e8d1e),
    Int32(bitPattern: 0x0a476341), Int32(bitPattern: 0x992eff74), Int32(bitPattern: 0x3a6f6eab), Int32(bitPattern: 0xf4f8fd37),
    Int32(bitPattern: 0xa812dc60), Int32(bitPattern: 0xa1ebddf8), Int32(bitPattern: 0x991be14c), Int32(bitPattern: 0xdb6e6b0d),
    Int32(bitPattern: 0xc67b5510), Int32(bitPattern: 0x6d672c37), Int32(bitPattern: 0x2765d43b), Int32(bitPattern: 0xdcd0e804),
    Int32(bitPattern: 0xf1290dc7), Int32(bitPattern: 0xcc00ffa3), Int32(bitPattern: 0xb5390f92), Int32(bitPattern: 0x690fed0b),
    Int32(bitPattern: 0x667b9ffb), Int32(bitPattern: 0xcedb7d9c), Int32(bitPattern: 0xa091cf0b), Int32(bitPattern: 0xd9155ea3),
    Int32(bitPattern: 0xbb132f88), Int32(bitPattern: 0x515bad24), Int32(bitPattern: 0x7b9479bf), Int32(bitPattern: 0x763bd6eb),
    Int32(bitPattern: 0x37392eb3), Int32(bitPattern: 0xcc115979), Int32(bitPattern: 0x8026e297), Int32(bitPattern: 0xf42e312d),
    Int32(bitPattern: 0x6842ada7), Int32(bitPattern: 0xc66a2b3b), Int32(bitPattern: 0x12754ccc), Int32(bitPattern: 0x782ef11c),
    Int32(bitPattern: 0x6a124237), Int32(bitPattern: 0xb79251e7), Int32(bitPattern: 0x06a1bbe6), Int32(bitPattern: 0x4bfb6350),
    Int32(bitPattern: 0x1a6b1018), Int32(bitPattern: 0x11caedfa), Int32(bitPattern: 0x3d25bdd8), Int32(bitPattern: 0xe2e1c3c9),
    Int32(bitPattern: 0x44421659), Int32(bitPattern: 0x0a121386), Int32(bitPattern: 0xd90cec6e), Int32(bitPattern: 0xd5abea2a),
    Int32(bitPattern: 0x64af674e), Int32(bitPattern: 0xda86a85f), Int32(bitPattern: 0xbebfe988), Int32(bitPattern: 0x64e4c3fe),
    Int32(bitPattern: 0x9dbc8057), Int32(bitPattern: 0xf0f7c086), Int32(bitPattern: 0x60787bf8), Int32(bitPattern: 0x6003604d),
    Int32(bitPattern: 0xd1fd8346), Int32(bitPattern: 0xf6381fb0), Int32(bitPattern: 0x7745ae04), Int32(bitPattern: 0xd736fccc),
    Int32(bitPattern: 0x83426b33), Int32(bitPattern: 0xf01eab71), Int32(bitPattern: 0xb0804187), Int32(bitPattern: 0x3c005e5f),
    Int32(bitPattern: 0x77a057be), Int32(bitPattern: 0xbde8ae24), Int32(bitPattern: 0x55464299), Int32(bitPattern: 0xbf582e61),
    Int32(bitPattern: 0x4e58f48f), Int32(bitPattern: 0xf2ddfda2), Int32(bitPattern: 0xf474ef38), Int32(bitPattern: 0x8789bdc2),
    Int32(bitPattern: 0x5366f9c3), Int32(bitPattern: 0xc8b38e74), Int32(bitPattern: 0xb475f255), Int32(bitPattern: 0x46fcd9b9),
    Int32(bitPattern: 0x7aeb2661), Int32(bitPattern: 0x8b1ddf84), Int32(bitPattern: 0x846a0e79), Int32(bitPattern: 0x915f95e2),
    Int32(bitPattern: 0x466e598e), Int32(bitPattern: 0x20b45770), Int32(bitPattern: 0x8cd55591), Int32(bitPattern: 0xc902de4c),
    Int32(bitPattern: 0xb90bace1), Int32(bitPattern: 0xbb8205d0), Int32(bitPattern: 0x11a86248), Int32(bitPattern: 0x7574a99e),
    Int32(bitPattern: 0xb77f19b6), Int32(bitPattern: 0xe0a9dc09), Int32(bitPattern: 0x662d09a1), Int32(bitPattern: 0xc4324633),
    Int32(bitPattern: 0xe85a1f02), Int32(bitPattern: 0x09f0be8c), Int32(bitPattern: 0x4a99a025), Int32(bitPattern: 0x1d6efe10),
    Int32(bitPattern: 0x1ab93d1d), Int32(bitPattern: 0x0ba5a4df), Int32(bitPattern: 0xa186f20f), Int32(bitPattern: 0x2868f169),
    Int32(bitPattern: 0xdcb7da83), Int32(bitPattern: 0x573906fe), Int32(bitPattern: 0xa1e2ce9b), Int32(bitPattern: 0x4fcd7f52),
    Int32(bitPattern: 0x50115e01), Int32(bitPattern: 0xa70683fa), Int32(bitPattern: 0xa002b5c4), Int32(bitPattern: 0x0de6d027),
    Int32(bitPattern: 0x9af88c27), Int32(bitPattern: 0x773f8641), Int32(bitPattern: 0xc3604c06), Int32(bitPattern: 0x61a806b5),
    Int32(bitPattern: 0xf0177a28), Int32(bitPattern: 0xc0f586e0), Int32(bitPattern: 0x006058aa), Int32(bitPattern: 0x30dc7d62),
    Int32(bitPattern: 0x11e69ed7), Int32(bitPattern: 0x2338ea63), Int32(bitPattern: 0x53c2dd94), Int32(bitPattern: 0xc2c21634),
    Int32(bitPattern: 0xbbcbee56), Int32(bitPattern: 0x90bcb6de), Int32(bitPattern: 0xebfc7da1), Int32(bitPattern: 0xce591d76),
    Int32(bitPattern: 0x6f05e409), Int32(bitPattern: 0x4b7c0188), Int32(bitPattern: 0x39720a3d), Int32(bitPattern: 0x7c927c24),
    Int32(bitPattern: 0x86e3725f), Int32(bitPattern: 0x724d9db9), Int32(bitPattern: 0x1ac15bb4), Int32(bitPattern: 0xd39eb8fc),
    Int32(bitPattern: 0xed545578), Int32(bitPattern: 0x08fca5b5), Int32(bitPattern: 0xd83d7cd3), Int32(bitPattern: 0x4dad0fc4),
    Int32(bitPattern: 0x1e50ef5e), Int32(bitPattern: 0xb161e6f8), Int32(bitPattern: 0xa28514d9), Int32(bitPattern: 0x6c51133c),
    Int32(bitPattern: 0x6fd5c7e7), Int32(bitPattern: 0x56e14ec4), Int32(bitPattern: 0x362abfce), Int32(bitPattern: 0xddc6c837),
    Int32(bitPattern: 0xd79a3234), Int32(bitPattern: 0x92638212), Int32(bitPattern: 0x670efa8e), Int32(bitPattern: 0x406000e0),
    Int32(bitPattern: 0x3a39ce37), Int32(bitPattern: 0xd3faf5cf), Int32(bitPattern: 0xabc27737), Int32(bitPattern: 0x5ac52d1b),
    Int32(bitPattern: 0x5cb0679e), Int32(bitPattern: 0x4fa33742), Int32(bitPattern: 0xd3822740), Int32(bitPattern: 0x99bc9bbe),
    Int32(bitPattern: 0xd5118e9d), Int32(bitPattern: 0xbf0f7315), Int32(bitPattern: 0xd62d1c7e), Int32(bitPattern: 0xc700c47b),
    Int32(bitPattern: 0xb78c1b6b), Int32(bitPattern: 0x21a19045), Int32(bitPattern: 0xb26eb1be), Int32(bitPattern: 0x6a366eb4),
    Int32(bitPattern: 0x5748ab2f), Int32(bitPattern: 0xbc946e79), Int32(bitPattern: 0xc6a376d2), Int32(bitPattern: 0x6549c2c8),
    Int32(bitPattern: 0x530ff8ee), Int32(bitPattern: 0x468dde7d), Int32(bitPattern: 0xd5730a1d), Int32(bitPattern: 0x4cd04dc6),
    Int32(bitPattern: 0x2939bbdb), Int32(bitPattern: 0xa9ba4650), Int32(bitPattern: 0xac9526e8), Int32(bitPattern: 0xbe5ee304),
    Int32(bitPattern: 0xa1fad5f0), Int32(bitPattern: 0x6a2d519a), Int32(bitPattern: 0x63ef8ce2), Int32(bitPattern: 0x9a86ee22),
    Int32(bitPattern: 0xc089c2b8), Int32(bitPattern: 0x43242ef6), Int32(bitPattern: 0xa51e03aa), Int32(bitPattern: 0x9cf2d0a4),
    Int32(bitPattern: 0x83c061ba), Int32(bitPattern: 0x9be96a4d), Int32(bitPattern: 0x8fe51550), Int32(bitPattern: 0xba645bd6),
    Int32(bitPattern: 0x2826a2f9), Int32(bitPattern: 0xa73a3ae1), Int32(bitPattern: 0x4ba99586), Int32(bitPattern: 0xef5562e9),
    Int32(bitPattern: 0xc72fefd3), Int32(bitPattern: 0xf752f7da), Int32(bitPattern: 0x3f046f69), Int32(bitPattern: 0x77fa0a59),
    Int32(bitPattern: 0x80e4a915), Int32(bitPattern: 0x87b08601), Int32(bitPattern: 0x9b09e6ad), Int32(bitPattern: 0x3b3ee593),
    Int32(bitPattern: 0xe990fd5a), Int32(bitPattern: 0x9e34d797), Int32(bitPattern: 0x2cf0b7d9), Int32(bitPattern: 0x022b8b51),
    Int32(bitPattern: 0x96d5ac3a), Int32(bitPattern: 0x017da67d), Int32(bitPattern: 0xd1cf3ed6), Int32(bitPattern: 0x7c7d2d28),
    Int32(bitPattern: 0x1f9f25cf), Int32(bitPattern: 0xadf2b89b), Int32(bitPattern: 0x5ad6b472), Int32(bitPattern: 0x5a88f54c),
    Int32(bitPattern: 0xe029ac71), Int32(bitPattern: 0xe019a5e6), Int32(bitPattern: 0x47b0acfd), Int32(bitPattern: 0xed93fa9b),
    Int32(bitPattern: 0xe8d3c48d), Int32(bitPattern: 0x283b57cc), Int32(bitPattern: 0xf8d56629), Int32(bitPattern: 0x79132e28),
    Int32(bitPattern: 0x785f0191), Int32(bitPattern: 0xed756055), Int32(bitPattern: 0xf7960e44), Int32(bitPattern: 0xe3d35e8c),
    Int32(bitPattern: 0x15056dd4), Int32(bitPattern: 0x88f46dba), Int32(bitPattern: 0x03a16125), Int32(bitPattern: 0x0564f0bd),
    Int32(bitPattern: 0xc3eb9e15), Int32(bitPattern: 0x3c9057a2), Int32(bitPattern: 0x97271aec), Int32(bitPattern: 0xa93a072a),
    Int32(bitPattern: 0x1b3f6d9b), Int32(bitPattern: 0x1e6321f5), Int32(bitPattern: 0xf59c66fb), Int32(bitPattern: 0x26dcf319),
    Int32(bitPattern: 0x7533d928), Int32(bitPattern: 0xb155fdf5), Int32(bitPattern: 0x03563482), Int32(bitPattern: 0x8aba3cbb),
    Int32(bitPattern: 0x28517711), Int32(bitPattern: 0xc20ad9f8), Int32(bitPattern: 0xabcc5167), Int32(bitPattern: 0xccad925f),
    Int32(bitPattern: 0x4de81751), Int32(bitPattern: 0x3830dc8e), Int32(bitPattern: 0x379d5862), Int32(bitPattern: 0x9320f991),
    Int32(bitPattern: 0xea7a90c2), Int32(bitPattern: 0xfb3e7bce), Int32(bitPattern: 0x5121ce64), Int32(bitPattern: 0x774fbe32),
    Int32(bitPattern: 0xa8b6e37e), Int32(bitPattern: 0xc3293d46), Int32(bitPattern: 0x48de5369), Int32(bitPattern: 0x6413e680),
    Int32(bitPattern: 0xa2ae0810), Int32(bitPattern: 0xdd6db224), Int32(bitPattern: 0x69852dfd), Int32(bitPattern: 0x09072166),
    Int32(bitPattern: 0xb39a460a), Int32(bitPattern: 0x6445c0dd), Int32(bitPattern: 0x586cdecf), Int32(bitPattern: 0x1c20c8ae),
    Int32(bitPattern: 0x5bbef7dd), Int32(bitPattern: 0x1b588d40), Int32(bitPattern: 0xccd2017f), Int32(bitPattern: 0x6bb4e3bb),
    Int32(bitPattern: 0xdda26a7e), Int32(bitPattern: 0x3a59ff45), Int32(bitPattern: 0x3e350a44), Int32(bitPattern: 0xbcb4cdd5),
    Int32(bitPattern: 0x72eacea8), Int32(bitPattern: 0xfa6484bb), Int32(bitPattern: 0x8d6612ae), Int32(bitPattern: 0xbf3c6f47),
    Int32(bitPattern: 0xd29be463), Int32(bitPattern: 0x542f5d9e), Int32(bitPattern: 0xaec2771b), Int32(bitPattern: 0xf64e6370),
    Int32(bitPattern: 0x740e0d8d), Int32(bitPattern: 0xe75b1357), Int32(bitPattern: 0xf8721671), Int32(bitPattern: 0xaf537d5d),
    Int32(bitPattern: 0x4040cb08), Int32(bitPattern: 0x4eb4e2cc), Int32(bitPattern: 0x34d2466a), Int32(bitPattern: 0x0115af84),
    Int32(bitPattern: 0xe1b00428), Int32(bitPattern: 0x95983a1d), Int32(bitPattern: 0x06b89fb4), Int32(bitPattern: 0xce6ea048),
    Int32(bitPattern: 0x6f3f3b82), Int32(bitPattern: 0x3520ab82), Int32(bitPattern: 0x011a1d4b), Int32(bitPattern: 0x277227f8),
    Int32(bitPattern: 0x611560b1), Int32(bitPattern: 0xe7933fdc), Int32(bitPattern: 0xbb3a792b), Int32(bitPattern: 0x344525bd),
    Int32(bitPattern: 0xa08839e1), Int32(bitPattern: 0x51ce794b), Int32(bitPattern: 0x2f32c9b7), Int32(bitPattern: 0xa01fbac9),
    Int32(bitPattern: 0xe01cc87e), Int32(bitPattern: 0xbcc7d1f6), Int32(bitPattern: 0xcf0111c3), Int32(bitPattern: 0xa1e8aac7),
    Int32(bitPattern: 0x1a908749), Int32(bitPattern: 0xd44fbd9a), Int32(bitPattern: 0xd0dadecb), Int32(bitPattern: 0xd50ada38),
    Int32(bitPattern: 0x0339c32a), Int32(bitPattern: 0xc6913667), Int32(bitPattern: 0x8df9317c), Int32(bitPattern: 0xe0b12b4f),
    Int32(bitPattern: 0xf79e59b7), Int32(bitPattern: 0x43f5bb3a), Int32(bitPattern: 0xf2d519ff), Int32(bitPattern: 0x27d9459c),
    Int32(bitPattern: 0xbf97222c), Int32(bitPattern: 0x15e6fc2a), Int32(bitPattern: 0x0f91fc71), Int32(bitPattern: 0x9b941525),
    Int32(bitPattern: 0xfae59361), Int32(bitPattern: 0xceb69ceb), Int32(bitPattern: 0xc2a86459), Int32(bitPattern: 0x12baa8d1),
    Int32(bitPattern: 0xb6c1075e), Int32(bitPattern: 0xe3056a0c), Int32(bitPattern: 0x10d25065), Int32(bitPattern: 0xcb03a442),
    Int32(bitPattern: 0xe0ec6e0e), Int32(bitPattern: 0x1698db3b), Int32(bitPattern: 0x4c98a0be), Int32(bitPattern: 0x3278e964),
    Int32(bitPattern: 0x9f1f9532), Int32(bitPattern: 0xe0d392df), Int32(bitPattern: 0xd3a0342b), Int32(bitPattern: 0x8971f21e),
    Int32(bitPattern: 0x1b0a7441), Int32(bitPattern: 0x4ba3348c), Int32(bitPattern: 0xc5be7120), Int32(bitPattern: 0xc37632d8),
    Int32(bitPattern: 0xdf359f8d), Int32(bitPattern: 0x9b992f2e), Int32(bitPattern: 0xe60b6f47), Int32(bitPattern: 0x0fe3f11d),
    Int32(bitPattern: 0xe54cda54), Int32(bitPattern: 0x1edad891), Int32(bitPattern: 0xce6279cf), Int32(bitPattern: 0xcd3e7e6f),
    Int32(bitPattern: 0x1618b166), Int32(bitPattern: 0xfd2c1d05), Int32(bitPattern: 0x848fd2c5), Int32(bitPattern: 0xf6fb2299),
    Int32(bitPattern: 0xf523f357), Int32(bitPattern: 0xa6327623), Int32(bitPattern: 0x93a83531), Int32(bitPattern: 0x56cccd02),
    Int32(bitPattern: 0xacf08162), Int32(bitPattern: 0x5a75ebb5), Int32(bitPattern: 0x6e163697), Int32(bitPattern: 0x88d273cc),
    Int32(bitPattern: 0xde966292), Int32(bitPattern: 0x81b949d0), Int32(bitPattern: 0x4c50901b), Int32(bitPattern: 0x71c65614),
    Int32(bitPattern: 0xe6c6c7bd), Int32(bitPattern: 0x327a140a), Int32(bitPattern: 0x45e1d006), Int32(bitPattern: 0xc3f27b9a),
    Int32(bitPattern: 0xc9aa53fd), Int32(bitPattern: 0x62a80f00), Int32(bitPattern: 0xbb25bfe2), Int32(bitPattern: 0x35bdd2f6),
    Int32(bitPattern: 0x71126905), Int32(bitPattern: 0xb2040222), Int32(bitPattern: 0xb6cbcf7c), Int32(bitPattern: 0xcd769c2b),
    Int32(bitPattern: 0x53113ec0), Int32(bitPattern: 0x1640e3d3), Int32(bitPattern: 0x38abbd60), Int32(bitPattern: 0x2547adf0),
    Int32(bitPattern: 0xba38209c), Int32(bitPattern: 0xf746ce76), Int32(bitPattern: 0x77afa1c5), Int32(bitPattern: 0x20756060),
    Int32(bitPattern: 0x85cbfe4e), Int32(bitPattern: 0x8ae88dd8), Int32(bitPattern: 0x7aaaf9b0), Int32(bitPattern: 0x4cf9aa7e),
    Int32(bitPattern: 0x1948c25c), Int32(bitPattern: 0x02fb8a8c), Int32(bitPattern: 0x01c36ae4), Int32(bitPattern: 0xd6ebe1f9),
    Int32(bitPattern: 0x90d4f869), Int32(bitPattern: 0xa65cdea0), Int32(bitPattern: 0x3f09252d), Int32(bitPattern: 0xc208e69f),
    Int32(bitPattern: 0xb74e6132), Int32(bitPattern: 0xce77e25b), Int32(bitPattern: 0x578fdfe3), Int32(bitPattern: 0x3ac372e6)
]

// bcrypt IV: "OrpheanBeholderScryDoubt"
let bf_crypt_ciphertext : [Int32] = [
    0x4f727068, 0x65616e42, 0x65686f6c, 0x64657253, 0x63727944, 0x6f756274
]

// Table for Base64 encoding
let base64_code : [Character] = [
    ".", "/", "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K",
    "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X",
    "Y", "Z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k",
    "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x",
    "y", "z", "0", "1", "2", "3", "4", "5", "6", "7", "8", "9"
]

// Table for Base64 decoding
let index_64 : [Int8]  = [
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1, -1, -1, -1, -1,
    -1, -1, -1, -1, -1, -1,  0,  1, 54, 55,
    56, 57, 58, 59, 60, 61, 62, 63, -1, -1,
    -1, -1, -1, -1, -1,  2,  3,  4,  5,  6,
    7,  8,  9, 10, 11, 12, 13, 14, 15, 16,
    17, 18, 19, 20, 21, 22, 23, 24, 25, 26,
    27, -1, -1, -1, -1, -1, -1, 28, 29, 30,
    31, 32, 33, 34, 35, 36, 37, 38, 39, 40,
    41, 42, 43, 44, 45, 46, 47, 48, 49, 50,
    51, 52, 53, -1, -1, -1, -1, -1
]

// MARK: -

@available(*, deprecated, message: "remove me after gmp")
class JKBCrypt: NSObject {

    // MARK: Property List

    fileprivate var p : UnsafeMutablePointer<Int32> // [Int32]
    fileprivate var s : UnsafeMutablePointer<Int32> // [Int32]

    // MARK: - Override Methods

    override init() {
        self.p = UnsafeMutablePointer<Int32>.allocate(capacity: P_orig.count)
        self.s = UnsafeMutablePointer<Int32>.allocate(capacity: S_orig.count)
    }

    // MARK: - Public Class Methods

    /**
     Generates a salt with the provided number of rounds.

     :param: numberOfRounds  The number of rounds to apply.

     The work factor increases exponentially as the `numberOfRounds` increases.

     :returns: String    The generated salt
     */
    class func generateSaltWithNumberOfRounds(_ rounds: UInt) -> String {
        let randomData : Data = JKBCryptRandom.generateRandomSignedDataOfLength(BCRYPT_SALT_LEN)

        var salt : String
        salt =  "$2a$" + ((rounds < 10) ? "0" : "") + "\(rounds)" + "$"
        salt += JKBCrypt.encodeData(randomData, ofLength: UInt(randomData.count))

        return salt
    }

    class func based64DotSlash(_ data: Data) -> String {
        return encodeData(data, ofLength: UInt(data.count))
    }


    /**
     Generates a salt with a defaulted set of 10 rounds.

     :returns: String    The generated salt.
     */
    class func generateSalt() -> String {
        return JKBCrypt.generateSaltWithNumberOfRounds(10)
    }

    /**
     Hashes the provided password with the provided salt.

     :param: password    The password to hash.
     :param: salt        The salt to use in the hash.

     The `salt` must be 16 characters in length. Also, the `salt` must be properly formatted
     with accepted version, revision, and salt rounds. If any of this is not true, nil is
     returned.

     :returns: String?  The hashed password.
     */

    @available(*, deprecated, message: "remove me after gmp")
    class func hashPassword(_ password: String, withSalt salt: String) -> String? {
        var bCrypt         : JKBCrypt
        var realSalt       : String
        //var hashedData     : NSData
        var minor          : Character = "\000"[0]
        var off            : Int = 0

        // If the salt length is too short, it is invalid
        if salt.count < BCRYPT_SALT_LEN {
            return nil
        }

        // If the salt does not start with "$2", it is an invalid version
        if salt[0] != "$" || salt[1] != "2" {
            return nil
        }

        if salt[2] == "$" {
            off = 3
        }
        else {
            off = 4
            minor = salt[2]
            if minor != "a" || salt[3] != "$" {
                // Invalid salt revision.
                return nil
            }
        }

        // Extract number of rounds
        if salt[(Int)(off+2)] > "$" {
            // Missing salt rounds
            return nil
        }

        let saltStart = salt.startIndex
        var range = salt.index(saltStart, offsetBy: off) ..< salt.index(saltStart, offsetBy: off+2)
        let extactedRounds = Int(salt[range])
        if extactedRounds == nil {
            // Invalid number of rounds
            return nil
        }
        let rounds : Int = extactedRounds!
        range = salt.index(saltStart, offsetBy: off+3) ..< salt.index(saltStart, offsetBy: off+25)
        realSalt = String(salt[range])

        var passwordPreEncoding : String = password
        if minor >= "a" {
            passwordPreEncoding += "\0"
        }

        let passwordData : Data? = passwordPreEncoding.data(using: .utf8)
        let saltData : Data? = JKBCrypt.decode_base64(realSalt, ofMaxLength: BCRYPT_SALT_LEN)

        if passwordData != nil && saltData != nil {
            bCrypt = JKBCrypt()
            if let hashedData = bCrypt.hashPassword(passwordData!, withSalt: saltData!, numberOfRounds: rounds) {
                var hashedPassword : String = "$2" + ((minor >= "a") ? String(minor) : "") + "$"

                hashedPassword += ((rounds < 10) ? "0" : "") + "\(rounds)" + "$"

                let saltString = JKBCrypt.encodeData(saltData!, ofLength: UInt(saltData!.count))
                let hashedString = JKBCrypt.encodeData(hashedData, ofLength: 23)

                return hashedPassword + saltString + hashedString
            }
        }

        return nil
    }

    /**
     Hashes the provided password with the provided hash and compares if the two hashes are equal.

     :param: password    The password to hash.
     :param: hash        The hash to use in generating and comparing the password.

     The `hash` must be properly formatted with accepted version, revision, and salt rounds. If
     any of this is not true, nil is returned.

     :returns: Bool?     TRUE if the password hash matches the given hash; FALSE if the two do not
     match; nil if hash is improperly formatted.
     */
    class func verifyPassword(_ password: String, matchesHash hash: String) -> Bool? {
        if let hashedPassword = JKBCrypt.hashPassword(password, withSalt: hash) {
            return hashedPassword == hash
        }
        else {
            return nil
        }
    }

    // MARK: - Private Class Methods

    /**
     Encodes an NSData composed of signed chararacters and returns slightly modified
     Base64 encoded string.

     :param: data    The data to be encoded. Passing nil will result in nil being returned.
     :param: length  The length. Must be greater than 0 and no longer than the length of data.

     :returns: String  A Base64 encoded string.
     */
    class fileprivate func encodeData(_ data: Data, ofLength length: UInt) -> String {

        if data.count == 0 || length == 0 {
            // Invalid data so return nil.
            return String()
        }

        var len : Int = Int(length)
        if len > data.count {
            len = data.count
        }

        var offset : Int = 0
        var c1 : UInt8
        var c2 : UInt8
        var result : String = String()

        var dataArray : [UInt8] = [UInt8](data)

        while offset < len {
            c1 = dataArray[offset] & 0xff
            offset += 1

            result.append(base64_code[Int((c1 >> 2) & 0x3f)])
            c1 = (c1 & 0x03) << 4
            if offset >= len {
                result.append(base64_code[Int(c1 & 0x3f)])
                break
            }

            c2 = dataArray[offset] & 0xff
            offset += 1

            c1 |= (c2 >> 4) & 0x0f
            result.append(base64_code[Int(c1 & 0x3f)])
            c1 = (c2 & 0x0f) << 2
            if offset >= len {
                result.append(base64_code[Int(c1 & 0x3f)])
                break
            }

            c2 = dataArray[offset] & 0xff
            offset += 1

            c1 |= (c2 >> 6) & 0x03
            result.append(base64_code[Int(c1 & 0x3f)])
            result.append(base64_code[Int(c2 & 0x3f)])
        }

        return result
    }

    /**
     Returns the Base64 encoded signed character of the provided unicode character.

     :param: x   The 16-bit unicode character whose Base64 counterpart, if any, will be returned.

     :returns: Int8  The Base64 encoded signed character or -1 if none exists.
     */
    class fileprivate func char64of(_ x: Character) -> Int8 {
        let xAsInt : Int32 = Int32(x.utf16Value())

        if xAsInt < 0 || xAsInt > 128 - 1 {
            // The character would go out of bounds of the pre-calculated array so return -1.
            return -1
        }

        // Return the matching Base64 encoded character.
        return index_64[Int(xAsInt)]
    }

    /**
     Decodes the provided Base64 encoded string to an NSData composed of signed characters.

     :param: s       The Base64 encoded string. If this is nil, nil will be returned.
     :param: maxolen The maximum number of characters to decode. If this is not greater than 0 nil will be returned.

     :returns: NSData?   An NSData or nil if the arguments are invalid.
     */
    class fileprivate func decode_base64(_ s: String, ofMaxLength maxolen: Int) -> Data? {
        var off : Int = 0
        let slen : Int = s.count
        var olen : Int = 0
        var result : [Int8] = [Int8](repeating: 0, count: maxolen)

        var c1 : Int8
        var c2 : Int8
        var c3 : Int8
        var c4 : Int8
        var o : Int8

        if maxolen <= 0 {
            // Invalid number of characters.
            return nil
        }

        //var v1 : UInt8
        //var v2 : UnicodeScalar

        while off < slen - 1 && olen < maxolen {
            c1 = JKBCrypt.char64of(s[off])
            off += 1
            c2 = JKBCrypt.char64of(s[off])
            off += 1
            if c1 == -1 || c2 == -1 {
                break
            }

            o = c1 << 2
            o |= (c2 & 0x30) >> 4
            result[olen] = o
            olen += 1
            if olen >= maxolen || off >= slen {
                break
            }

            c3 = JKBCrypt.char64of(s[Int(off)])
            off += 1
            if c3 == -1 {
                break
            }

            o = (c2 & 0x0f) << 4
            o |= (c3 & 0x3c) >> 2
            result[olen] = o
            olen += 1
            if olen >= maxolen || off >= slen {
                break
            }

            c4 = JKBCrypt.char64of(s[off])
            off += 1
            o = (c3 & 0x03) << 6
            o |= c4
            result[olen] = o
            olen += 1
            //++olen
        }

        return Data(buffer: UnsafeBufferPointer(start: &result, count: result.count)) // NSData(bytes: result, length: olen)
    }

    /**
     Cyclically extracts a word of key material from the provided NSData.

     :param: d       The NSData from which the word will be extracted.
     :param: offp    The "pointer" (as a one-entry array) to the current offset into data.

     :returns: UInt32 The next word of material from the data.
     */
    // class private func streamToWord(data: NSData, inout off offp: Int32) -> Int32 {
    class fileprivate func streamToWordWithData(_ data: UnsafeMutablePointer<Int8>, ofLength length: Int, off offp: inout Int32) -> Int32 {
        var word : Int32 = 0
        var off  : Int32 = offp
        for _ in 0..<4 {
            word = (word << 8) | (Int32(data[Int(off)]) & 0xff)
            off = (off + 1) % Int32(length)
        }
        //for i = 0; i < 4; i++
        offp = off
        return word
    }

    // MARK: - Private Instance Methods

    /**
     Hashes the provided password with the salt for the number of rounds.

     :param: password        The password to hash.
     :param: salt            The salt to use in the hash.
     :param: numberOfRounds  The number of rounds to apply.

     The salt must be 16 characters in length. The `numberOfRounds` must be between 4
     and 31 inclusively. If any of this is not true, nil is returned.

     :returns: NSData?  The hashed password.
     */
    fileprivate func hashPassword(_ password: Data, withSalt salt: Data, numberOfRounds: Int) -> Data? {
        var rounds : Int
        //var i      : Int
        var j      : Int
        let clen   : Int = 6
        var cdata  : [Int32] = bf_crypt_ciphertext

        if numberOfRounds < 4 || numberOfRounds > 31 {
            // Invalid number of rounds
            return nil
        }

        rounds = 1 << numberOfRounds
        if salt.count != BCRYPT_SALT_LEN {
            // Invalid salt length
            return nil
        }

        self.initKey()
        self.enhanceKeyScheduleWithData(salt, key: password)

        for _ in 0 ..< rounds {
            self.key(password)
            self.key(salt)
        }

        for _ in 0 ..< 64 {
            for j in 0 ..< (clen >> 1) {
                self.encipher(&cdata, off: j << 1)
            }
        }

        var result : [Int8] = [Int8](repeating: 0, count:clen * 4)

        j = 0
        for i in 0 ..< clen {
            result[j] = Int8(truncatingIfNeeded: (cdata[i] >> 24) & 0xff)
            j += 1
            result[j] = Int8(truncatingIfNeeded: (cdata[i] >> 16) & 0xff)
            j += 1
            result[j] = Int8(truncatingIfNeeded: (cdata[i] >> 8) & 0xff)
            j += 1
            result[j] = Int8(truncatingIfNeeded: cdata[i] & 0xff)
            j += 1
        }

        deinitKey()
        return Data(buffer: UnsafeBufferPointer(start: &result, count: result.count))
    }

    /**
     Enciphers the provided array using the Blowfish algorithm.

     :param: lr  The left-right array containing two 32-bit half blocks.
     :param: off The offset into the array.

     :returns: <void>
     */
    // private func encipher(inout lr: [Int32], off: Int) {
    fileprivate func encipher(/*inout*/ _ lr: UnsafeMutablePointer<Int32>, off: Int) {
        if off < 0 {
            // Invalid offset.
            return
        }

        var n : Int32
        var l : Int32 = lr[off]
        var r : Int32 = lr[off + 1]

        l ^= p[0]
        var i : Int = 0
        while i <= BLOWFISH_NUM_ROUNDS - 2 {
            // Feistel substitution on left word
            n = s.advanced(by: Int((l >> 24) & 0xff)).pointee
            n = n &+ s.advanced(by: Int(0x100 | ((l >> 16) & 0xff))).pointee
            n ^= s.advanced(by: Int(0x200 | ((l >> 8) & 0xff))).pointee
            n = n &+ s.advanced(by: Int(0x300 | (l & 0xff))).pointee
            i += 1
            r ^= n ^ p.advanced(by: i).pointee

            // Feistel substitution on right word
            n = s.advanced(by: Int((r >> 24) & 0xff)).pointee
            n = n &+ s.advanced(by: Int(0x100 | ((r >> 16) & 0xff))).pointee
            n ^= s.advanced(by: Int(0x200 | ((r >> 8) & 0xff))).pointee
            n = n &+ s.advanced(by: Int(0x300 | (r & 0xff))).pointee
            i += 1
            l ^= n ^ p.advanced(by: i).pointee
        }

        lr[off] = r ^ p.advanced(by: BLOWFISH_NUM_ROUNDS + 1).pointee
        lr[off + 1] = l
    }

    /**
     Initializes the blowfish key schedule.

     :returns: <void>
     */
    fileprivate func initKey() {
        // p = P_orig
        p = UnsafeMutablePointer<Int32>.allocate(capacity: P_orig.count)
        p.initialize(from: UnsafeMutablePointer<Int32>(mutating: P_orig), count: P_orig.count)

        // s = S_orig
        s = UnsafeMutablePointer<Int32>.allocate(capacity: S_orig.count)
        s.initialize(from: UnsafeMutablePointer<Int32>(mutating: S_orig), count: S_orig.count)
    }

    fileprivate func deinitKey() {
        p.deinitialize(count: P_orig.count) //.deinitialize()
        p.deallocate() //p.deallocate(capacity: P_orig.count)

        s.deinitialize(count: S_orig.count) //.deinitialize()
        s.deallocate() //s.deallocate(capacity: S_orig.count)
    }

    /**
     Keys the receiver's blowfish cipher using the provided key.

     :param: key The array containing the key.

     :returns: <void>
     */
    // private func key(key: NSData) {
    fileprivate func key(_ key: Data) {
        var i : Int
        var koffp : Int32 = 0
        var lr    : [Int32] = [0, 0]

        let plen  : Int = 18
        let slen  : Int = 1024
        let keyPointer : UnsafeMutablePointer<Int8> = UnsafeMutablePointer<Int8>(mutating: (key as NSData).bytes.bindMemory(to: Int8.self, capacity: key.count))
        //var keyPointer : UnsafeMutablePointer<Int8> = UnsafeMutablePointer<Int8>(key.bytes)// key.bytes.assumingMemoryBound(to: Int8.self)// UnsafeMutablePointer<Int8>(key.bytes)
        let keyLength : Int = key.count

        for i in 0 ..< plen {
            p[i] = p[i] ^ JKBCrypt.streamToWordWithData(keyPointer, ofLength: keyLength, off: &koffp)
        }
        i = 0
        while i < plen {
            self.encipher(&lr, off: 0)
            p[i] = lr[0]
            p[i + 1] = lr[1]
            i += 2
        }
        i = 0
        while i < slen {
            self.encipher(&lr, off: 0)
            s[i] = lr[0]
            s[i + 1] = lr[1]
            i += 2
        }
    }

    /**
     Performs the "enhanced key schedule" step described by Provos and Mazieres
     in "A Future-Adaptable Password Scheme"
     http://www.openbsd.org/papers/bcrypt-paper.ps

     :param: data    The salt data.
     :param: key     The password data.

     :returns: <void>
     */
    fileprivate func enhanceKeyScheduleWithData(_ data: Data, key: Data) {
        var i : Int
        var koffp : Int32 = 0
        var doffp : Int32 = 0
        var lr    : [Int32] = [0, 0]
        let plen  : Int = 18
        let slen  : Int = 1024

        let keyPointer : UnsafeMutablePointer<Int8> = UnsafeMutablePointer<Int8>(mutating: (key as NSData).bytes.bindMemory(to: Int8.self, capacity: key.count))
        let keyLength : Int = key.count
        let dataPointer : UnsafeMutablePointer<Int8> = UnsafeMutablePointer<Int8>(mutating: (data as NSData).bytes.bindMemory(to: Int8.self, capacity: data.count))
        let dataLength : Int = data.count

        for i in 0 ..< plen {
            p[i] = p[i] ^ JKBCrypt.streamToWordWithData(keyPointer, ofLength: keyLength, off:&koffp)
        }

        i = 0
        while i < plen {
            lr[0] ^= JKBCrypt.streamToWordWithData(dataPointer, ofLength: dataLength, off: &doffp)
            lr[1] ^= JKBCrypt.streamToWordWithData(dataPointer, ofLength: dataLength, off: &doffp)
            self.encipher(&lr, off: 0)
            p[i] = lr[0]
            p[i + 1] = lr[1]

            i += 2
        }

        i = 0
        while i < slen {
            lr[0] ^= JKBCrypt.streamToWordWithData(dataPointer, ofLength: dataLength, off: &doffp)
            lr[1] ^= JKBCrypt.streamToWordWithData(dataPointer, ofLength: dataLength, off: &doffp)
            self.encipher(&lr, off: 0)
            s[i] = lr[0]
            s[i + 1] = lr[1]
            i += 2
        }
    }
}

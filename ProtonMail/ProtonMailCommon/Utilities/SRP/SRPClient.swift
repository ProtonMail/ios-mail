//
//  SRPClient.swift
//  ProtonMail - Created on 10/6/16.
//
//
//  The MIT License
//
//  Copyright (c) 2018 Proton Technologies AG
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.


import Foundation


class Proofs {
    var clientEphemeral : Data
    var clientProof : Data
    var expectedServerProof : Data

    init (ephemeral : Data, proof : Data, serverProof :Data ) {
        self.clientEphemeral = ephemeral
        self.clientProof = proof
        self.expectedServerProof = serverProof
    }
}


//public static Proofs generateProofs(final int bitLength, final byte[] modulusRepr, final byte[] serverEphemeralRepr, final byte[] hashedPasswordRepr) throws NoSuchAlgorithmException {
//    if (modulusRepr.length * 8 != bitLength || serverEphemeralRepr.length * 8 != bitLength || hashedPasswordRepr.length * 8 != bitLength) {
//        // FIXME: better error message?
//        return null;
//    }
//    
//    final BigInteger modulus = toBI(modulusRepr);
//    final BigInteger serverEphemeral = toBI(serverEphemeralRepr);
//    final BigInteger hashedPassword = toBI(hashedPasswordRepr);
//    
//    if (modulus.bitLength() != bitLength) {
//        return null;
//    }
//    
//    final BigInteger generator = BigInteger.valueOf(2);
//    
//    final BigInteger multiplier = toBI(PasswordUtils.expandHash(ArrayUtils.addAll(fromBI(bitLength, generator), modulusRepr))).mod(modulus);
//    final BigInteger modulusMinusOne = modulus.clearBit(0);
//    
//    if (multiplier.compareTo(BigInteger.ONE) <= 0 || multiplier.compareTo(modulusMinusOne) >= 0) {
//        return null;
//    }
//    
//    if (serverEphemeral.compareTo(BigInteger.ONE) <= 0 || serverEphemeral.compareTo(modulusMinusOne) >= 0) {
//        return null;
//    }
//    
//    if (!modulus.isProbablePrime(10) || !modulus.shiftRight(1).isProbablePrime(10)) {
//        return null;
//    }
//    
//    final SecureRandom random = new SecureRandom();
//    BigInteger clientSecret;
//    BigInteger clientEphemeral;
//    BigInteger scramblingParam;
//    do {
//        do {
//            clientSecret = new BigInteger(bitLength, random);
//        }
//            while (clientSecret.compareTo(modulusMinusOne) >= 0 || clientSecret.compareTo(BigInteger.valueOf(bitLength * 2)) <= 0);
//        clientEphemeral = generator.modPow(clientSecret, modulus);
//        scramblingParam = toBI(PasswordUtils.expandHash(ArrayUtils.addAll(fromBI(bitLength, clientEphemeral), serverEphemeralRepr)));
//    } while (scramblingParam.equals(BigInteger.ZERO)); // Very unlikely
//    
//    BigInteger subtracted = serverEphemeral.subtract(generator.modPow(hashedPassword, modulus).multiply(multiplier).mod(modulus));
//    if (subtracted.compareTo(BigInteger.ZERO) < 0) {
//        subtracted = subtracted.add(modulus);
//    }
//    final BigInteger exponent = scramblingParam.multiply(hashedPassword).add(clientSecret).mod(modulusMinusOne);
//    final BigInteger sharedSession = subtracted.modPow(exponent, modulus);
//    
//    final byte[] clientEphemeralRepr = fromBI(bitLength, clientEphemeral);
//    final byte[] clientProof = PasswordUtils.expandHash(ArrayUtils.addAll(ArrayUtils.addAll(clientEphemeralRepr, serverEphemeralRepr), fromBI(bitLength, sharedSession)));
//    final byte[] serverProof = PasswordUtils.expandHash(ArrayUtils.addAll(ArrayUtils.addAll(clientEphemeralRepr, clientProof), fromBI(bitLength, sharedSession)));
//    
//    return new Proofs(clientEphemeralRepr, clientProof, serverProof);
//}

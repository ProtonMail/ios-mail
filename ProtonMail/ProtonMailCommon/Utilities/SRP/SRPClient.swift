//
//  SRPClient.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 10/6/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

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

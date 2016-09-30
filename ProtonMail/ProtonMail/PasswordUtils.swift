//
//  PasswordUtils.swift
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/28/16.
//  Copyright © 2016 ProtonMail. All rights reserved.
//

import Foundation

enum PasswordError: ErrorType {
    case HashEmpty
    case HashSizeWrong
    
}
class PasswordUtils {
    
    static func CleanUserName(username : String) -> String {
        return username.preg_replace("_|\\.|-", replaceto: "").lowercaseString
    }
    
    private static func bcrypt(password :String, salt :String) throws -> String {
        if let out = JKBCrypt.hashPassword(password, withSalt: "$2a$10$" + salt) where !out.isEmpty {
            let size = out.characters.count
            if size > 4 {
                let index = out.startIndex.advancedBy(4)
                return "$2y$" + out.substringFromIndex(index)
            } else {
                throw PasswordError.HashSizeWrong
            }
        }
        throw PasswordError.HashEmpty
    }
}


//    public static byte[] expandHash(final byte[] input) throws NoSuchAlgorithmException {
//    final byte[] output = new byte[2048 / 8];
//    final MessageDigest digest = MessageDigest.getInstance("SHA-512");
//    
//    digest.update(input);
//    digest.update((byte)0);
//    System.arraycopy(digest.digest(), 0, output, 0, 512 / 8);
//    digest.reset();
//    
//    digest.update(input);
//    digest.update((byte)1);
//    System.arraycopy(digest.digest(), 0, output, 512 / 8, 512 / 8);
//    digest.reset();
//    
//    digest.update(input);
//    digest.update((byte)2);
//    System.arraycopy(digest.digest(), 0, output, 1024 / 8, 512 / 8);
//    digest.reset();
//    
//    digest.update(input);
//    digest.update((byte)3);
//    System.arraycopy(digest.digest(), 0, output, 1536 / 8, 512 / 8);
//    digest.reset();
//    
//    return output;
//    }
//    

//    public static byte[] hashPasswordVersion4(final String password, final byte[] salt, final byte[] modulus) {
//    return hashPasswordVersion3(password, salt, modulus);
//    }
//    
//    public static byte[] hashPasswordVersion3(final String password, final byte[] salt, final byte[] modulus) {
//    try {
//    final String encodedSalt = ConstantTime.encodeBase64DotSlash(ArrayUtils.addAll(salt, "proton".getBytes("UTF8")), false);
//    return expandHash(ArrayUtils.addAll(bcrypt(password, encodedSalt).getBytes("UTF8"), modulus));
//    } catch (NoSuchAlgorithmException | UnsupportedEncodingException e) {
//    Logger.doLogException(e);
//    return null;
//    }
//    }
//    
//    public static byte[] hashPasswordVersion2(final String password, final String username, final byte[] modulus) {
//    return hashPasswordVersion1(password, cleanUserName(username), modulus);
//    }
//    
//    public static byte[] hashPasswordVersion1(final String password, final String username, final byte[] modulus) {
//    try {
//    final String salt = new String(Hex.encodeHex(MessageDigest.getInstance("MD5").digest(username.toLowerCase().getBytes("UTF8"))));
//    return expandHash(ArrayUtils.addAll(bcrypt(password, salt).getBytes("UTF8"), modulus));
//    } catch (NoSuchAlgorithmException | UnsupportedEncodingException e) {
//    Logger.doLogException(e);
//    return null;
//    }
//    }
//    
//    public static byte[] hashPasswordVersion0(final String password, final String username, final byte[] modulus) {
//    try {
//    final byte[] prehashed = MessageDigest.getInstance("SHA-512").digest(password.getBytes("UTF8"));
//    return hashPasswordVersion1(ConstantTime.encodeBase64(prehashed, true), username, modulus);
//    } catch (NoSuchAlgorithmException | UnsupportedEncodingException e) {
//    Logger.doLogException(e);
//    return null;
//    }
//    }
//}

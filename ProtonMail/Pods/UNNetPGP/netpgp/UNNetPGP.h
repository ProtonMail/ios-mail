//
//  UNNetPGP.h
//  netpgp
//
//  Created by Marcin Krzyzanowski on 01.10.2013.
//  Copyright (c) 2013 Marcin Krzyżanowski
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//


#import <Foundation/Foundation.h>

typedef NS_OPTIONS(NSUInteger, UNEncryptOption)
{
    UNEncryptOptionNone                 = 0,
    UNEncryptDontUseSubkey              = 1 << 0 // Not recomended, by default subkey is used to encrypt data. Use only if required.
};

@interface UNNetPGP : NSObject

/** user identifier. Required for most actions. */
@property (strong, atomic) NSString *userId;

/** home dir for keyrings */
@property (strong, atomic) NSString *homeDirectory;

/** path to public key ring file */
@property (strong, atomic) NSString *publicKeyRingPath;

/** path to secure key ring file */
@property (strong, atomic) NSString *secretKeyRingPath;

/** keys in a keyring */
@property (strong, atomic) NSArray *availableKeys;

/** password for key **/
@property (copy, atomic) NSString *password;

/** armored */
@property (assign) BOOL armored;

/** Maximum memory allocation. Default 4 MiB. Incrase for large files.*/
@property (assign) NSUInteger maximumMemoryAllocationSize;

/** Initialize with user identifier */
- (instancetype) initWithUserId:(NSString *)userId;

/** Encrypt file at path and save result to out file */
- (BOOL) encryptFileAtPath:(NSString *)inFilePath toFileAtPath:(NSString *)outFilePath options:(UNEncryptOption)options;
/** Decrypt file at path and save result to out file */
- (BOOL) decryptFileAtPath:(NSString *)inFilePath toFileAtPath:(NSString *)outFilePath;

/** Sign file and write signature to separate file */
- (BOOL) signFileAtPath:(NSString *)inFilePath writeSignatureToPath:(NSString *)signatureFilePath;

/** Sign file and write signed to output file */
- (BOOL) signFileAtPath:(NSString *)inFilePath writeSignedFileToPath:(NSString *)signedFilePath;

/** 
 Sign file and write signature to separate file or attach signature to signed file.
 signatureFilePath have extension ".asc" or ".sig"
 */
- (BOOL) signFileAtPath:(NSString *)inFilePath writeToFile:(NSString *)signatureFilePath detached:(BOOL)detached;

/** 
 Verifies the signatures in a signed file.
 @param inFilePath have to be one of ".sig" or ".asc" file. Method expect companion signed filed.
 */
- (BOOL) verifyFileAtPath:(NSString *)inFilePath;

- (NSData *) encryptData:(NSData *)inData options:(UNEncryptOption)options;
- (NSData *) decryptData:(NSData *)inData;

- (NSData *) signData:(NSData *)data;
- (BOOL) verifyData:(NSData *)inData;

/**
 *  Import public key from given keyring file
 *
 *  @param inFilePath pubring.gpg file to import
 *
 *  @return YES for success.
 */
- (BOOL) importPublicKeyFromFileAtPath:(NSString *)inFilePath;
//- (BOOL) importSecureKeyFromFileAtPath:(NSString *)inFilePath;
- (NSString *)exportKeyNamed:(NSString *)keyName;

/** Generate pair of keys and store in keyring */
- (BOOL) generateKey:(int)numberOfBits;
/** Generate pair of keys and store in specified by path */
- (BOOL) generateKey:(int)numberOfBits named:(NSString *)keyName toDirectory:(NSString *)path;

@end

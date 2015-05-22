//
//  OpenPGP.h
//  OpenPGP
//
//  Created by Yanfeng Zhang on 1/29/15.
//  Copyright (c) 2015 Yanfeng Zhang. All rights reserved.
//

#import <Foundation/Foundation.h>



@interface OpenPGP : NSObject

//issues:
// The NSError doesn't work on swift
//


// self keys setup up for login user
- (BOOL) SetupKeys:(NSString *)priv_key pubKey:(NSString *)pub_key pass:(NSString*) passphrase error:(NSError* *) err;

//Encrypt for user self
- (NSString *) encrypt_message:(NSString*) unencrypt_message error:(NSError**) err;

//Encrypt message use public key(other people's key)
- (NSString *) encrypt_message:(NSString*) unencrypt_message pub_key:(NSString *)pub_key error:(NSError**) err;
//Decrypt message user Private key
- (NSString *) decrypt_message:(NSString*) encrypted_message error:(NSError**) err;

//Encrypt message use aes with pwd
- (NSString *) encrypt_message_aes:(NSString*) unencrypt_message pwd:(NSString *)password error:(NSError**) err;
//Decrypt message use aes with pwd
- (NSString *) decrypt_message_aes:(NSString*) encrypted_message pwd:(NSString *)password error:(NSError**) err;

//Update Private Key password
- (NSString *) update_key_password:(NSString*)old_passphrase new_pwd:(NSString*) new_passphrase error:(NSError**) err;

//Generate new key pair
- (NSMutableDictionary*) generate_key:(NSString*)passphrase username:(NSString*)user_name error:(NSError**) err;




// print debug logs
- (void)EnableDebug:(BOOL) isDebug;


- (void)Test_Privatekey:(NSString *)priv_key pass:(NSString*) passphrase;

- (NSString* ) TestEncryptPwd:(NSString *)plain pass:(NSString*) slat;
- (NSString* ) TestDecryptPwd:(NSString *)plain pass:(NSString*) slat;







@end


//
//  UNNetPGP.m
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

#import "UNNetPGP.h"
#import "netpgp.h"
#import "fmemopen.h"

static dispatch_queue_t lock_queue;

@implementation UNNetPGP

@synthesize availableKeys = _availableKeys;
@synthesize publicKeyRingPath = _publicKeyRingPath;
@synthesize secretKeyRingPath = _secretKeyRingPath;

+ (void)initialize
{
    lock_queue = dispatch_queue_create("UUNetPGP lock queue", DISPATCH_QUEUE_SERIAL);
}

- (instancetype) init
{
    if (self = [super init]) {
        // by default search keys in Documents
      
        // NOTE: saving the keyring in this location means that it could get backed up to iCloud,
        // leaving private keys vulernable to whoever can get access to Apple's servers.
      
        NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
        NSString *documentDirectoryPath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
      
#if TARGET_IPHONE_SIMULATOR
        // Sometimes the simulator doesn't have the normal directories.
        if (![[NSFileManager defaultManager] fileExistsAtPath:documentDirectoryPath]) {
          [[NSFileManager defaultManager] createDirectoryAtPath:documentDirectoryPath withIntermediateDirectories:YES attributes:nil error:nil];
        }
#endif
        _homeDirectory = documentDirectoryPath;
    }
    return self;
}

- (instancetype) initWithUserId:(NSString *)userId
{
    if (self = [self init]) {
        self.userId = userId;
    }
    return self;
}

- (void)setPublicKeyRingPath:(NSString *)publicKeyRingPath
{
    dispatch_sync(lock_queue, ^{
        self->_publicKeyRingPath = publicKeyRingPath;
    });
}

- (NSString *)publicKeyRingPath
{
    @synchronized(self) {
        NSString *ret = nil;
        if (_publicKeyRingPath) {
            ret = _publicKeyRingPath;
        } else if (self.homeDirectory) {
            ret = [self.homeDirectory stringByAppendingPathComponent:@"pubring.gpg"];
        }
        return ret;
    }
}

- (void)setSecretKeyRingPath:(NSString *)secretKeyRingPath
{
    dispatch_sync(lock_queue, ^{
        self->_secretKeyRingPath = secretKeyRingPath;
    });

}

- (NSString *)secretKeyRingPath
{
    @synchronized(self) {
        NSString *ret = nil;
        if (_secretKeyRingPath) {
            ret = _secretKeyRingPath;
        } else if (self.homeDirectory) {
            ret = [self.homeDirectory stringByAppendingPathComponent:@"secring.gpg"];
        }
        return ret;
    }
}

#pragma mark - Data

- (NSData *) encryptData:(NSData *)inData options:(UNEncryptOption)options
{
    __block NSData *result = nil;
    
    dispatch_sync(lock_queue, ^{
        netpgp_t *netpgp = [self buildnetpgp];
        if (netpgp) {
            
            if (options & UNEncryptDontUseSubkey) {
                netpgp_setvar(netpgp, "dont use subkey to encrypt", "1");
            }

            void *inbuf = calloc(inData.length, sizeof(Byte));
            memcpy(inbuf, inData.bytes, inData.length);
            
            NSInteger maxsize = (unsigned)atoi(netpgp_getvar(netpgp, "max mem alloc"));
            void *outbuf = calloc(sizeof(Byte), maxsize);
            int outsize = netpgp_encrypt_memory(netpgp, self.userId.UTF8String, inbuf, inData.length, outbuf, maxsize, self.armored ? 1 : 0);
            
            if (outsize > 0) {
                result = [NSData dataWithBytesNoCopy:outbuf length:outsize freeWhenDone:YES];
            }
            
            [self finishnetpgp:netpgp];
            
            if (inbuf)
                free(inbuf);
        }
    });
    
    return result;
}

- (NSData *) decryptData:(NSData *)inData
{
    __block NSData *result = nil;
    
    dispatch_sync(lock_queue, ^{
        netpgp_t *netpgp = [self buildnetpgp];
        if (netpgp) {
            NSInteger maxsize = (unsigned)atoi(netpgp_getvar(netpgp, "max mem alloc"));
            void *outbuf = calloc(sizeof(Byte), maxsize);
            int outsize = netpgp_decrypt_memory(netpgp, inData.bytes, inData.length, outbuf, maxsize, self.armored ? 1 : 0);
            
            if (outsize > 0) {
                result = [NSData dataWithBytesNoCopy:outbuf length:outsize freeWhenDone:YES];
            }
            
            [self finishnetpgp:netpgp];
        }
    });
    
    return result;
}

- (NSData *) signData:(NSData *)inData
{
    __block NSData *result = nil;
    
    dispatch_sync(lock_queue, ^{
        netpgp_t *netpgp = [self buildnetpgp];
        if (netpgp) {
            void *inbuf = calloc(inData.length, sizeof(Byte));
            memcpy(inbuf, inData.bytes, inData.length);
            
            NSInteger maxsize = (unsigned)atoi(netpgp_getvar(netpgp, "max mem alloc"));
            void *outbuf = calloc(sizeof(Byte), maxsize);
            int outsize = netpgp_sign_memory(netpgp, self.userId.UTF8String, inbuf, inData.length, outbuf, maxsize, self.armored ? 1 : 0, 0 /* !cleartext */);
            
            if (outsize > 0) {
                result = [NSData dataWithBytesNoCopy:outbuf length:outsize freeWhenDone:YES];
            }
            
            [self finishnetpgp:netpgp];
            
            if (inbuf)
                free(inbuf);
        }
    });
    
    return result;
}

- (BOOL) verifyData:(NSData *)inData
{
    __block BOOL result = NO;
    
    dispatch_sync(lock_queue, ^{
        netpgp_t *netpgp = [self buildnetpgp];
        if (netpgp) {
            result = netpgp_verify_memory(netpgp, inData.bytes, inData.length, NULL, 0, self.armored ? 1 : 0);
            [self finishnetpgp:netpgp];
        }
    });
    
    return result;
}


#pragma mark - Files

/**
 Encrypt file.
 
 @param inFilePath File to encrypt
 @param outFilePath Optional. If `nil` then encrypted name is created at the same path as original file with addedd suffix `.gpg`.
 @param options UNEncryptOption
 @return `YES` if operation success.
 
 Encrypted file is created at outFilePath, file is overwritten if already exists.
 */
- (BOOL) encryptFileAtPath:(NSString *)inFilePath toFileAtPath:(NSString *)outFilePath options:(UNEncryptOption)options
{
    __block BOOL result = NO;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:inFilePath])
        return NO;
    
    dispatch_sync(lock_queue, ^{
        netpgp_t *netpgp = [self buildnetpgp];
        
        if (netpgp) {
            
            if (options & UNEncryptDontUseSubkey) {
                netpgp_setvar(netpgp, "dont use subkey to encrypt", "1");
            }
            
            if (self.maximumMemoryAllocationSize <= 4096) {
                NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:inFilePath error: NULL];
                unsigned long long fileSize = [attrs fileSize];
                float newMax = ceilf(fileSize / (float)self.maximumMemoryAllocationSize) * (float)self.maximumMemoryAllocationSize;
                netpgp_setvar(netpgp, "max mem alloc", [[NSString stringWithFormat:@"%d",(int32_t)newMax] UTF8String]);
            }
            
            char infilepath[inFilePath.length];
            strcpy(infilepath, inFilePath.UTF8String);

            char *outfilepath = NULL;
            if (outFilePath) {
                outfilepath = calloc(outFilePath.length, sizeof(char));
                strcpy(outfilepath, outFilePath.UTF8String);
            }

            result = netpgp_encrypt_file(netpgp, self.userId.UTF8String, infilepath, outfilepath, self.armored ? 1 : 0);

            [self finishnetpgp:netpgp];

            if (outfilepath)
                free(outfilepath);
        }
    });

    return result;
}

/**
 Decrypt file.
 
 @param inFilePath File to encrypt
 @param outFilePath Optional. If `nil` then encrypted name is created at the same path as original file with addedd suffix `.gpg`.
 @return `YES` if operation success.
 
 Descrypted file is created at outFilePath, file is overwritten if already exists.
 */
- (BOOL) decryptFileAtPath:(NSString *)inFilePath toFileAtPath:(NSString *)outFilePath
{
    __block BOOL result = NO;
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:inFilePath])
        return NO;
    
    dispatch_sync(lock_queue, ^{
        netpgp_t *netpgp = [self buildnetpgp];
        if (netpgp) {
            char infilepath[inFilePath.length];
            strcpy(infilepath, inFilePath.UTF8String);
            
            char *outfilepath = NULL;
            if (outFilePath) {
                outfilepath = calloc(outFilePath.length, sizeof(char));
                strcpy(outfilepath, outFilePath.UTF8String);
            }
            
            result = netpgp_decrypt_file(netpgp, infilepath, outfilepath, self.armored ? 1 : 0);
            
            [self finishnetpgp:netpgp];

            if (outfilepath)
                free(outfilepath);
        }
    });

    return result;
}

- (BOOL) signFileAtPath:(NSString *)inFilePath writeSignatureToPath:(NSString *)signatureFilePath
{
    return [self signFileAtPath:inFilePath writeToFile:signatureFilePath detached:YES];
}

- (BOOL) signFileAtPath:(NSString *)inFilePath writeSignedFileToPath:(NSString *)signedFilePath
{
    return [self signFileAtPath:inFilePath writeToFile:signedFilePath detached:NO];
}

- (BOOL) signFileAtPath:(NSString *)inFilePath writeToFile:(NSString *)signatureFilePath detached:(BOOL)detached
{
    __block BOOL result = NO;
  
    // HACK: Don't crash
    if (inFilePath == nil || signatureFilePath == nil) return NO;

    dispatch_sync(lock_queue, ^{
        netpgp_t *netpgp = [self buildnetpgp];
        if (netpgp) {
            char infilepath[inFilePath.length];
            memset(infilepath, 0x0, sizeof(infilepath));
            strcpy(infilepath, inFilePath.UTF8String);
            
            char *outfilepath = NULL;
            if (signatureFilePath) {
                outfilepath = calloc(signatureFilePath.length, sizeof(char));
                strcpy(outfilepath, signatureFilePath.UTF8String);
            }
            
            //TODO: cleartext is not working right, need to investigate and fix
            result = netpgp_sign_file(netpgp, self.userId.UTF8String, infilepath, outfilepath /* sigfile name */, self.armored ? 1 : 0, 0 /* !cleartext */, detached ? 1 : 0 /* detached */);
            
            [self finishnetpgp:netpgp];
            
            if (outfilepath) {
                free(outfilepath);
            }
        }
    });
    
    return result;
}

- (BOOL) verifyFileAtPath:(NSString *)inFilePath
{
    __block BOOL result = NO;
    
    dispatch_sync(lock_queue, ^{
        netpgp_t *netpgp = [self buildnetpgp];
        if (netpgp) {
            char infilepath[inFilePath.length];
            strcpy(infilepath, inFilePath.UTF8String);
            
            result = netpgp_verify_file(netpgp, infilepath, NULL, self.armored ? 1 : 0);
            
            [self finishnetpgp:netpgp];
        }
    });
    
    return result;
}

#pragma mark - Keys

- (NSArray *)availableKeys
{
    __block NSArray *keysDict = nil;
    
    dispatch_sync(lock_queue, ^{
        netpgp_t *netpgp = [self buildnetpgp];
        if (netpgp) {
            
            char *jsonCString = NULL;
            if (netpgp_list_keys_json(netpgp, &jsonCString, 0) && (jsonCString != NULL)) {
                NSError *error = nil;
                keysDict = [NSJSONSerialization JSONObjectWithData:[NSData dataWithBytes:jsonCString length:strlen(jsonCString)] options:0 error:&error];
            }
            free(jsonCString);
            
            [self finishnetpgp:netpgp];
        }
    });
    return keysDict;
}

- (void)setAvailableKeys:(NSArray *)keys
{
    dispatch_sync(lock_queue, ^{
        _availableKeys = keys;
    });
}

- (NSString *)exportKeyNamed:(NSString *)keyName
{
    __block NSString *keyData;
    
    dispatch_sync(lock_queue, ^{
        netpgp_t *netpgp = [self buildnetpgp];
        if (netpgp) {            
            char keyname[keyName.length];
            strcpy(keyname, keyName.UTF8String);
            
            char *keydata = netpgp_export_key(netpgp, keyname);
            if (keydata) {
                keyData = [NSString stringWithCString:keydata encoding:NSASCIIStringEncoding];
                free(keydata);
            }
            
            [self finishnetpgp:netpgp];
        }
    });
    return keyData;
}

/** import a key into keyring */
- (BOOL) importPublicKeyFromFileAtPath:(NSString *)inFilePath
{
    if (!inFilePath)
        return NO;
    
    __block BOOL result = NO;
    dispatch_sync(lock_queue, ^{
        netpgp_t *netpgp = [self buildnetpgp];
        if (netpgp) {
            
            char infilepath[inFilePath.length];
            strcpy(infilepath, inFilePath.UTF8String);
            
            result = netpgp_import_public_key(netpgp, infilepath);
            
            [self finishnetpgp:netpgp];
        }
    });
    
    return result;
}
//
///** import a key into keyring */
//- (BOOL) importSecureKeyFromFileAtPath:(NSString *)inFilePath
//{
//    if (!inFilePath)
//        return NO;
//    
//    __block BOOL result = NO;
//    dispatch_sync(lock_queue, ^{
//        netpgp_t *netpgp = [self buildnetpgp];
//        if (netpgp) {
//            
//            char infilepath[inFilePath.length];
//            strcpy(infilepath, inFilePath.UTF8String);
//            //TODO: save in keyring
//            result = netpgp_import_secure_key(netpgp, infilepath);
//            
//            [self finishnetpgp:netpgp];
//        }
//    });
//    
//    return result;
//}

/** 
 Generate key and save to keyring.
 
 @param numberOfBits
 @param keyName
 @param path
 @param defaultKeyring
 @see userId
 */
- (BOOL) generateKey:(int)numberOfBits named:(NSString *)keyName toDirectory:(NSString *)path saveToDefaultKeyring:(BOOL)defaultKeyring
{
    __block BOOL result = NO;
    dispatch_sync(lock_queue, ^{
        netpgp_t *netpgp = [self buildnetpgp];
        if (netpgp) {
            NSString *keyIdString = keyName ?: self.userId;
            if (keyIdString == nil) {
              keyIdString = @"";
            }
            netpgp_setvar(netpgp, "userid checks", "skip");
            
            char key_id[keyIdString.length];
            strcpy(key_id, keyIdString.UTF8String);
            
            char *directory_path = NULL;
            if (path) {
                directory_path = calloc(path.length, sizeof(char));
                strcpy(directory_path, path.UTF8String);

                if (![[NSFileManager defaultManager] fileExistsAtPath:path]) {
                    [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:@{NSFilePosixPermissions: [NSNumber numberWithShort:0700]} error:nil];
                }
            }

            result = netpgp_generate_key_rich(netpgp, key_id, numberOfBits, directory_path, defaultKeyring ? 1 : 0);
            [self finishnetpgp:netpgp];
            
            if (directory_path) {
                free(directory_path);
            }
        }
    });

    return result;
}

/**
 Generate key and save to keyring.
 
 @param numberOfBits
 @see userId
 */
- (BOOL) generateKey:(int)numberOfBits
{
    return [self generateKey:numberOfBits named:nil toDirectory:nil saveToDefaultKeyring:YES];
}

/**
 Generate key and save to defined path
 
 @param numberOfBits
 @param keyName
 @param path
 @see userId
 */

- (BOOL) generateKey:(int)numberOfBits named:(NSString *)keyName toDirectory:(NSString *)path
{
    return [self generateKey:numberOfBits named:keyName toDirectory:path saveToDefaultKeyring:NO];
}

#pragma mark - private

- (netpgp_t *) buildnetpgp;
{
    // Love http://jverkoey.github.io/fmemopen/

    netpgp_t *netpgp = calloc(0x1, sizeof(netpgp_t));
    
    if (self.userId)
        netpgp_setvar(netpgp, "userid", self.userId.UTF8String);
    
    if (self.homeDirectory) {
        char *directory_path = calloc(self.homeDirectory.length, sizeof(char));
        strcpy(directory_path, self.homeDirectory.UTF8String);
        
        netpgp_set_homedir(netpgp, directory_path, NULL, 0);
        
        free(directory_path);
    }
    
    if (self.secretKeyRingPath) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.secretKeyRingPath]) {
            [[NSFileManager defaultManager] createFileAtPath:self.secretKeyRingPath contents:nil attributes:@{NSFilePosixPermissions: [NSNumber numberWithShort:0600]}];
        }
        netpgp_setvar(netpgp, "secring", self.secretKeyRingPath.UTF8String);
    }
    
    if (self.publicKeyRingPath) {
        if (![[NSFileManager defaultManager] fileExistsAtPath:self.publicKeyRingPath]) {
            [[NSFileManager defaultManager] createFileAtPath:self.publicKeyRingPath contents:nil attributes:@{NSFilePosixPermissions: [NSNumber numberWithShort:0600]}];
        }
        netpgp_setvar(netpgp, "pubring", self.publicKeyRingPath.UTF8String);
    }
    
    if (self.password) {
        const char* cstr = [self.password stringByAppendingString:@"\n"].UTF8String;
        netpgp->passfp = fmemopen((void *)cstr, sizeof(char) * (self.password.length + 1), "r");
    }

    /* 4 MiB for a memory file */
    netpgp_setvar(netpgp, "max mem alloc", "4194304");
    if (self.maximumMemoryAllocationSize) {
        netpgp_setvar(netpgp, "max mem alloc", [[NSString stringWithFormat:@"%i",self.maximumMemoryAllocationSize] UTF8String]);
    }
    
    //FIXME: use sha1 because sha256 crashing, don't know why yet
    netpgp_setvar(netpgp, "hash", "sha1");
    
    // Custom variable
    //netpgp_setvar(netpgp, "dont use subkey to encrypt", "1");

#if DEBUG
    netpgp_incvar(netpgp, "verbose", 1);
    netpgp_set_debug(NULL);
#endif
    
    if (!netpgp_init(netpgp)) {
        NSLog(@"Can't initialize netpgp stack");
        free(netpgp);
        return nil;
    }
    
    return netpgp;
}

- (void) finishnetpgp:(netpgp_t *)netpgp
{
    if (!netpgp) {
        return;
    }
    
    netpgp_end(netpgp);
    free(netpgp);
}


@end

//
//  FileClientDelegate.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/14/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TypeBlocks.h"

@protocol FileClientDelegate <NSObject>

@required
    - (void) createDefaultDirectoriesAsyncWithCompletionBlock: (void (^)(BOOL succeed, NSError* error))completed;
    - (void) createDefaultFilesAsync;
    - (BOOL) save: (NSString*)fileName andContents: (NSString*)contents andFailureBlock: (void (^)(NSError* error))failureBlock;
    - (NSString*) read: (NSString*)fileName;
    - (void) saveAsync: (NSString*)fileName contents: (NSString*)contents andCompletionBlock: (void (^)(BOOL succeed, NSError* error))completed;
    - (void) readAsync: (NSString*)fileName andCompletionBlock: (void (^)(NSString* contents))completed;
    - (void) readLoggedExceptionsWithCompletionBlock: (void (^)(NSArray* fileNames))completed;
    - (BOOL) deleteFile: (NSString*)fileName andFailureBlock: (void (^)(NSError* error))failureBlock;
    - (void) deleteFileAsync: (NSString*)fileName completionBlock: (void (^)(BOOL succeed, NSError* error))completed;
    - (BOOL) updateCrashOnLastRunErrorId: (NSNumber*)errorId;
    - (RemoteSettingsData*) loadRemoteSettings;
    - (BOOL) saveRemoteSettings:(RemoteSettingsData*)remoteSettingsData;
    - (NSArray*) readLoggedStartedTransactions;
    - (NSArray*) readLoggedStoppedTransactions;
    - (BOOL)isFileSizeLimitExceeded:(NSString*)filePath;

@end

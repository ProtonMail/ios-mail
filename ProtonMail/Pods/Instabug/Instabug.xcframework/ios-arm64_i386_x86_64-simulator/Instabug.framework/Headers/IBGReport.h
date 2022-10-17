//
//  IBGReport.h
//  InstabugCore
//
//  Created by khaled mohamed el morabea on 1/21/18.
//  Copyright © 2018 Instabug. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface IBGReport : NSObject

@property (nonatomic, copy, readonly) NSArray<NSString *> *tags;
@property (nonatomic, copy, readonly) NSArray<NSDictionary *> *instabugLogs;
@property (nonatomic, copy, readonly) NSArray<NSDictionary *> *consoleLogs;
@property (nonatomic, copy, readonly) NSDictionary<NSString *, NSString *> *userAttributes;
@property (nonatomic, copy, readonly) NSArray<NSString *> *fileLocations;
@property (nonatomic, copy) NSString *userData;

- (void)appendTag:(NSString *)tag;
- (void)logVerbose:(NSString *)log;
- (void)logDebug:(NSString *)log;
- (void)logInfo:(NSString *)log;
- (void)logWarn:(NSString *)log;
- (void)logError:(NSString *)log;
- (void)appendToConsoleLogs:(NSString *)log;
- (void)setUserAttribute:(NSString *)userAttribute withKey:(NSString *)key;
- (void)addFileAttachmentWithURL:(NSURL *)url;
- (void)addFileAttachmentWithData:(NSData *)data;
- (void)addFileAttachmentWithData:(NSData *)data andName:(NSString *)name;

@end

NS_ASSUME_NONNULL_END

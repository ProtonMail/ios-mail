//
//  RequestWorkerFacadeDelegate.h
//  Splunk-iOS
//
//  Created by G.Tas on 1/24/14.
//  Copyright (c) 2014 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TypeBlocks.h"
#import "MintLogResult.h"
#import "MintResponseResult.h"
#import "LimitedExtraDataList.h"
#import "MintEnums.h"
#import "DeviceInfoDelegate.h"
#import "FileClientDelegate.h"
#import "ServiceClientDelegate.h"
#import "RequestJsonSerializerDelegate.h"
#import "ContentTypeDelegate.h"
#import "RequestWorkerDelegate.h"
#import "ExceptionDataFixture.h"

@protocol RequestWorkerFacadeDelegate <NSObject>

@required
    @property (nonatomic, strong) id<RequestWorkerDelegate> workerDelegate;
    @property (nonatomic, strong) id<DeviceInfoDelegate> deviceInfo;
    @property (nonatomic, strong) id<RequestJsonSerializerDelegate> jsonSerializer;
    - (id) initWithDeviceInfo: (id<DeviceInfoDelegate>)deviceUtil fileClient: (id<FileClientDelegate>)fileRepo serviceClient: (id<ServiceClientDelegate>)serviceRepo contentTypeWorker: (id<ContentTypeDelegate>)aContentTypeWorker andJsonSerializer: (id<RequestJsonSerializerDelegate>)jsonWorker;
    - (void) sendUnhandledRequestAsync: (MintExceptionRequest*)exceptionRequest andResultBlock: (ResponseResultBlock)resultBlock;
    - (NSString*) getErrorHashFromJson: (NSString*)jsonRequest;
    - (void) flushAsyncWithBlock: (ResponseResultBlock)resultBlock;
    - (void) transactionStartWithName: (NSString*)transactionName andResultBlock: (TransactionStartResultBlock)resultBlock;
    - (void) transactionStopWithName: (NSString*)transactionName andResultBlock: (TransactionStopResultBlock)resultBlock;
    - (void) transactionCancelWithName: (NSString*)transactionName reason: (NSString*)reason andResultBlock: (TransactionStopResultBlock)resultBlock;
    - (void) stopAllTransactions: (NSString*)errorHash;
    - (void) startWorker;
    - (void) sendEventAsync: (DataType)eventType completionBlock: (ResponseResultBlock)completed;
    - (void) logEventAsync: (DataType)eventType completionBlock: (LogResultBlock)completed;
    - (MintLogResult*) logEvent: (DataType)eventType;
    - (void) processPreviousLoggedRequestsAsyncWithBlock: (ResponseResultBlock)resultBlock;
    - (void) getLastCrashIdWithBlock: (void (^)(NSNumber* lastCrashId))success failure: (FailureBlock)failure;
    - (void) getTotalCrashesNumWithBlock: (void (^)(NSNumber* totalCrashes))success failure: (FailureBlock)failure;
    - (void) clearTotalCrashesNumWithBlock:(void (^)(BOOL succeeded))success failure:(FailureBlock)failure;
    - (void) sendEventAsyncWithTag: (NSString*)tag completionBlock: (ResponseResultBlock)completed;
    - (void) logEventAsyncWithTag: (NSString*)tag completionBlock: (LogResultBlock)completed;
    - (MintLogResult*) closeSession;
    - (void) startSessionAsyncWithCompletionBlock: (ResponseResultBlock)completed;
    - (void) closeSessionAsyncWithCompletionBlock: (LogResultBlock)completed;
    - (void) sendExceptionAsync: (NSException*)exception extraDataKey: (NSString*)key extraDataValue: (NSString*)value completionBlock: (ResponseResultBlock)completed;
    - (void) sendExceptionAsync: (NSException*)exception limitedExtraDataList: (LimitedExtraDataList*)extraDataList completionBlock: (ResponseResultBlock)completed;
    - (void) logExceptionAsync: (NSException*)exception extraDataKey: (NSString*)key extraDataValue: (NSString*)value completionBlock: (LogResultBlock)completed;
    - (void) logExceptionAsync: (NSException*)exception limitedExtraDataList: (LimitedExtraDataList*)extraDataList completionBlock: (LogResultBlock)completed;
    - (void) xamarinLogExceptionAsync:(NSException*)exception andCompletionBlock:(LogResultBlock)completed;
    - (MintLogResult*) xamarinLogException:(NSException*)exception;
    - (ExceptionDataFixture*) exceptionFixtureFrom:(NSException*)exception;
    - (void) logEventAsyncWithName:(NSString *)name logLevel:(MintLogLevel)logLevel andCompletionBlock:(LogResultBlock)completed;
    - (void) logSplunkMintLogWithMessage:(NSString *)message logLevel:(MintLogLevel)logLevel andCompletionBlock: (LogResultBlock)completionBlock;

@end

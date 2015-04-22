//
//  RequestWorkerFacadeDelegate.h
//  Splunk-iOS
//
//  Created by G.Tas on 1/24/14.
//  Copyright (c) 2014 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
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
    - (void) logExceptionAsync: (id)exception limitedExtraDataList: (LimitedExtraDataList*)extraDataList completionBlock: (LogResultBlock)completed;
    - (void) xamarinLogExceptionAsync:(NSException*)exception andCompletionBlock:(LogResultBlock)completed;
    - (MintLogResult*) xamarinLogException:(NSException*)exception;
    - (ExceptionDataFixture*) exceptionFixtureFrom:(NSException*)exception;
    - (void) logEventAsyncWithName:(NSString *)name logLevel:(MintLogLevel)logLevel andCompletionBlock:(LogResultBlock)completed;
    - (void) logSplunkMintLogWithMessage:(NSString *)message logLevel:(MintLogLevel)logLevel andCompletionBlock: (LogResultBlock)completionBlock;

    - (void) logEventAsyncWithName:(NSString *)name logLevel:(MintLogLevel)logLevel extraDataKey: (NSString*)key extraDataValue: (NSString*)value andCompletionBlock:(LogResultBlock)completed;
    - (void) logEventAsyncWithName:(NSString*)name logLevel:(MintLogLevel)logLevel limitedExtraDataList: (LimitedExtraDataList*)extraDataList andCompletionBlock:(LogResultBlock)completed;

    - (void) transactionStop:(NSString*)transactionName andResultBlock:(TransactionStopResultBlock)resultBlock;
    - (void) transactionStop:(NSString*)transactionName extraDataKey: (NSString*)key extraDataValue: (NSString*)value andResultBlock:(TransactionStopResultBlock)resultBlock;
    - (void) transactionStop:(NSString*)transactionName limitedExtraDataList: (LimitedExtraDataList*)extraDataList andResultBlock:(TransactionStopResultBlock)resultBlock;

    - (void) transactionStart:(NSString*)transactionName andResultBlock:(TransactionStartResultBlock)resultBlock;
    - (void) transactionStart:(NSString*)transactionName extraDataKey: (NSString*)key extraDataValue: (NSString*)value andResultBlock:(TransactionStartResultBlock)resultBlock;
    - (void) transactionStart:(NSString*)transactionName limitedExtraDataList: (LimitedExtraDataList*)extraDataList andResultBlock:(TransactionStartResultBlock)resultBlock;

    - (void) logEventAsyncWithTag: (NSString*)tag extraDataKey: (NSString*)key extraDataValue: (NSString*)value completionBlock: (LogResultBlock)completed;
    - (void) logEventAsyncWithTag: (NSString*)tag limitedExtraDataList: (LimitedExtraDataList*)extraDataList completionBlock: (LogResultBlock)completed;


    - (void) transactionCancelWithName: (NSString*)transactionName extraDataKey: (NSString*)key extraDataValue: (NSString*)value reason: (NSString*)reason andResultBlock: (TransactionStopResultBlock)resultBlock;

    - (void) transactionCancelWithName: (NSString*)transactionName limitedExtraDataList: (LimitedExtraDataList*)extraDataList reason: (NSString*)reason andResultBlock: (TransactionStopResultBlock)resultBlock;

    - (NSString*)getMintUUID;

    - (NSString*)getSessionID;

- (void)logViewWithCurrentViewName:(NSString*)currentViewName limitedExtraDataList:(LimitedExtraDataList*)extraDataList;
@end

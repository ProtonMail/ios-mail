//
//  TrStop.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/23/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPLTransaction.h"
#import "MintAppEnvironment.h"
#import "LimitedExtraDataList.h"

@interface TrStop : SPLTransaction

+ (BOOL) isJSONTrStop:(NSString*)json;

/**
 *  The duration of the transaction, in milliseconds.
 */
@property (nonatomic, strong) NSNumber* duration;

/**
 *  The status of the transaction.
 */
@property (nonatomic, strong) NSString* status;

/**
 *  The reason the transaction stopped, was cancelled, or failed.
 */
@property (nonatomic, strong) NSString<SPLOptional>* reason;

//@property (nonatomic, assign) BOOL slow;

/**
 *  Creates a new TrStop instance.
 *
 *  @param transactionId    The transaction ID of the TrStart instance, auto-generated when the TrStart instance is created.
 *  @param transactionName  The unique transaction name of the TrStart instance.
 *  @param anAppEnvironment A MintAppEnvironment instance.
 *  @param aDuration        The duration of the transaction, in seconds.
 *  @param aReason          The reason the transaction stopped, was cancelled, or failed.
 *  @param aCompletedStatus The completion status of the transaction.
 *
 *  @return A TrStop instance reference.
 */
+ (TrStop*) getInstanceWithTransactionId:(NSString*)transactionId transactionName:(NSString*)transactionName appEnvironment:(MintAppEnvironment*)anAppEnvironment duration:(NSNumber*)aDuration reason:(NSString*)aReason andCompletedStatus:(NSString*)aCompletedStatus;

+ (TrStop*) getInstanceWithTransactionId:(NSString*)transactionId transactionName:(NSString*)transactionName limittedExtraData:(LimitedExtraDataList*)extraList appEnvironment:(MintAppEnvironment*)anAppEnvironment duration:(NSNumber*)aDuration reason:(NSString*)aReason andCompletedStatus:(NSString*)aCompletedStatus;
@end

//
//  TransactionStopResult.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/25/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import "TransactionResult.h"
#import "TrStop.h"

/**
 *  The TransactionStopResult class stops a transaction.
 */
@interface TransactionStopResult : TransactionResult

/**
 *  The reason the transaction stopped, was cancelled, or failed.
 */
@property (nonatomic, strong) NSString* reason;

/**
 *  The transaction stop model.
 */
@property (nonatomic, strong) TrStop* transactionStop;

@end

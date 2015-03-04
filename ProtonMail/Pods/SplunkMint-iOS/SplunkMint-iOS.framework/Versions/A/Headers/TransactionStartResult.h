//
//  TransactionStartResult.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/25/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import "TransactionResult.h"
#import "TrStart.h"

/**
 *  The TransactionStartResult class provides information when a transaction starts.
 */
@interface TransactionStartResult : TransactionResult

/**
 *  The unique name of the transaction.
 */
@property (nonatomic, strong) NSString* transactionName;

/**
 *  The transaction model that started.
 */
@property (nonatomic, strong) TrStart* transactionStart;

@end

//
//  TransactionResult.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/25/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import "SPLJSONModel.h"
#import "MintEnums.h"

/**
 *  The TransactionResult base transaction model class contains information about creating, stopping, and cancelling a transaction.
 */
@interface TransactionResult : SPLJSONModel

/**
 *  The status of the transaction request.
 */
@property (nonatomic, assign) TransactionStatus transactionStatus;

/**
 *  Additional information about the transaction.
 */
@property (nonatomic, strong) NSString* descriptionResult;

@end

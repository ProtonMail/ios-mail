//
//  Transaction.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/23/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataFixture.h"

/**
 *  The Transaction base model class is used for a transaction requests.
 */
@interface SPLTransaction : DataFixture

/**
 *  A string that contains the name of the transaction.
 */
@property (nonatomic, strong) NSString* name;

/**
 *  An auto-generated string that contains the ID of the transaction.
 */
@property (nonatomic, strong) NSString* transactionId;

@end

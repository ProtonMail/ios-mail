//
//  TypeBlocks.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/13/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import "MintResponseResult.h"
#import "MintLogResult.h"
#import "TransactionStartResult.h"
#import "TransactionStopResult.h"
#import "RemoteSettingsData.h"

typedef void (^ResponseResultBlock)(MintResponseResult* mintResponseResult);
typedef void (^LogResultBlock)(MintLogResult* mintLogResult);
typedef void (^FailureBlock)(NSError* error);
typedef void (^TransactionStartResultBlock)(TransactionStartResult* transactionStartResult);
typedef void (^TransactionStopResultBlock)(TransactionStopResult* transactionStopResult);
typedef void (^RemoteSettingsBlock)(BOOL succeed, NSError* error, RemoteSettingsData* remoteSettings);
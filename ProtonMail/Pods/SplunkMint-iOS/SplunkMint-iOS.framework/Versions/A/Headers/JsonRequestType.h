//
//  JsonRequestType.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/22/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface JsonRequestType : NSObject

extern NSString* const SplunkMintError;
extern NSString* const SplunkMintEvent;
extern NSString* const SplunkMintPing;
extern NSString* const SplunkMintGnip;
extern NSString* const SplunkMintLog;
extern NSString* const SplunkMintTransactionStart;
extern NSString* const SplunkMintTransactionStop;
extern NSString* const SplunkMintNetwork;
extern NSString* const SplunkMintPerformance;
extern NSString* const SplunkMintScreen;

@end

//
//  SplunkMintLog.h
//  Splunk-iOS
//
//  Created by George Taskos on 7/24/14.
//  Copyright (c) 2014 SLK. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MintEnums.h"
#import "RequestWorkerFacadeDelegate.h"

@interface MintLogger : NSObject

+ (void) setRequestWorker:(id<RequestWorkerFacadeDelegate>)worker;

void MintLog(MintLogLevel logLevel, NSString* message, ...) NS_FORMAT_FUNCTION(2,3);

@end
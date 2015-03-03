//
//  SplunkLogResult.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/2/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import "MintResult.h"
#import "MintEnums.h"

/**
 *  The MintLogResult class provides information about the logged request.
 */
@interface MintLogResult : MintResult

/**
 *  The log type of the request.
 */
@property (nonatomic, assign) MintLogType logType;

@end

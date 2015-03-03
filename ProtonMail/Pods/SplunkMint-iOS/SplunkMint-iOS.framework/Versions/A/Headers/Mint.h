//
//  Splunk.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/2/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MintBase.h"

/**
 *  MintLogException is a helper function that calls the [[Mint sharedInstance] logExceptionAsync:limitedExtraDataList:completionBlock:]. 
 *  This function logs a handled exception with any optional data.
 *
 *  @param exception The handled exception instance.
 *  @param extradata The extra data to include in the request.
 *
 *  @return void. Nothing to return.
 */
#define MintLogException(exception, extradata) [[Mint sharedInstance] logExceptionAsync:exception limitedExtraDataList:extradata completionBlock:nil];

/**
 *  The Mint class is the main class for all appropriate requests.
 */
@interface Mint : MintBase

/**
 *  Returns the singleton Mint reference to use in your application. You should not initialize the Mint class yourself because unexpected results may occur. 
 *
 *  @return The Mint singleton instance reference.
 */
+ (Mint*) sharedInstance;

@end

//
//  SplunkMessageException.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/6/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 *  The MintMessageException class is derived from NSException.
 */
@interface MintMessageException : NSException

/**
 *  Initializes an instance of MintMessageException.
 *
 *  @param aName     The name of the exception.
 *  @param aReason   The reason for the exception.
 *  @param aUserInfo A dictionary with additional data, if applicable.
 *
 *  @return The MintMessageException instance.
 */
- (id) initWithName: (NSString*)aName reason: (NSString*)aReason userInfo: (NSDictionary*)aUserInfo;

@end

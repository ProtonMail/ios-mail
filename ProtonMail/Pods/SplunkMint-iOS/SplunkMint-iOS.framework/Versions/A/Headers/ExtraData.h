//
//  ExtraData.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/2/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPLJSONModel.h"

/**
 *  The ExtraData class contains extra data as a key-value pair to attach to error requests.
 */
@interface ExtraData : SPLJSONModel

/**
 *  A string that contains the key.
 */
@property (nonatomic, strong) NSString* key;

/**
 *  A string that contains the value.
 */
@property (nonatomic, strong) NSString* value;

/**
 *  Returns the allowed length of the value.
 */
@property (nonatomic, assign) NSNumber<SPLIgnore>* maxValueLength;

/**
 *  Initializes an ExtraData instance with a key-value pair.
 *
 *  @param key   The key.
 *  @param value The value.
 *
 *  @return The ExtraData instance.
 */
- (id) initWithKey: (NSString*)key andValue: (NSString*)value;

/**
 *  Determines whether two ExtraData instances are equal according to internal IDs.
 *
 *  @param aExtraData The ExtraData instance to test equality.
 *
 *  @return A Boolean that indicates whether the instances are equal.
 */
- (BOOL) isEqualToExtraData: (ExtraData*)extraData;

@end

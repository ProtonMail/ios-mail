//
//  LimitedExtraDataList.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/2/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "ExtraData.h"
#import "DataFixture.h"

/**
 *  The LimitedExtraDataList class contains a list of extra crash data 
 *  (from ExtraData instances) to attach to error requests.
 */
@interface LimitedExtraDataList : SPLJSONModel

/**
 *  The maximum number of ExtraData instances that can be included in the 
 *  list of extra crash data. 
 */
@property (nonatomic, assign) NSUInteger maxCount;

/**
 *  Returns the count of ExtraData instances in the list.
 */
@property (nonatomic, assign) NSUInteger count;

/**
 *  A modifiable array that contains the ExtraData instances.
 */
@property (nonatomic, strong) NSMutableArray* extraDataArray;


+ (void) addExtraDataToDataFixture:(DataFixture*)dataFixture;

/**
 *  A singleton instance for the global extra data attached to the crash.
 *
 *  @return A reference to the LimitedExtraDataList singleton instance.
 */
+ (LimitedExtraDataList*) sharedInstance;

/**
 *  Adds an ExtraData instance to the list.
 *
 *  @param extraData The ExtraData instance.
 */
- (void) add:(ExtraData*)extraData;

/**
 *  Removes an ExtraData instance from the list.
 *
 *  @param extraData The ExtraData instance.
 */
- (void) remove:(ExtraData*)extraData;

/**
 *  Adds an ExtraData instance to the list as a key-value pair.
 *
 *  @param key   The key.
 *  @param value The value.
 */
- (void) addWithKey:(NSString*)key andValue:(NSString*)value;

/**
 *  Removes an ExtraData instance from the list.
 *
 *  @param key The key of the ExtraData instance.
 */
- (void) removeWithKey:(NSString*)key;

/**
 *  Gets the index of an ExtraData instance in the list.
 *
 *  @param extraData An ExtraData instance.
 *
 *  @return The index of the ExtraData in the list.
 */
- (NSInteger) indexOf:(ExtraData*)extraData;

/**
 *  Inserts an ExtraData instance at a specific index in the list.
 *
 *  @param index          The index.
 *  @param extraData      An ExtraData instance.
 */
- (void) insertAtIndex:(NSUInteger)index extraData:(ExtraData*)extraData;

/**
 *  Removes an ExtraData instance from a specific index in the list.
 *
 *  @param index The index.
 */
- (void) removeAtIndex:(NSUInteger)index;

/**
 *  Clears the internal ExtraData list.
 */
- (void) clear;

/**
 *  Determines whether an ExtraData instance is in the list.
 *
 *  @param extraData An ExtraData instance.
 *
 *  @return A Boolean that indicates whether the ExtraData instance exists.
 */
- (BOOL) contains:(ExtraData*)extraData;

@end

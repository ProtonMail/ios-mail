//
//  SplunkEventFactory.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/2/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MintEnums.h"

@interface BugSenseEventFactory : NSObject

- (NSString*) createEventWithEventType: (DataType)eventType;
- (NSString*) createEventWithTag: (NSString*)tag;

@end

//
//  NSDate+DateExtensions.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/22/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSDate (DateExtensions)

- (NSString*) dateComponentWith: (NSDate*)fromDate and: (NSDate*)toDate;

@end

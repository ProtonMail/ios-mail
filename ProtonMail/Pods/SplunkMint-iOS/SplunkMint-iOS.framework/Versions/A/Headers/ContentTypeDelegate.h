//
//  ContentTypeDelegate.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/15/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ContentTypeDelegate <NSObject>

@required
    - (NSString*) eventContentType;
    - (NSString*) errorContentType;

@end

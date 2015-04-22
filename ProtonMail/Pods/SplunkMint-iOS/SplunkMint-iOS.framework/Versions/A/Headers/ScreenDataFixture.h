//
//  ScreenDataFixture.h
//  Splunk-iOS
//
//  Created by G.Tas on 2/21/14.
//  Copyright (c) 2014 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "DataFixture.h"

@interface ScreenDataFixture : DataFixture

@property (nonatomic, strong) NSString *current;
@property (nonatomic, strong) NSString *previous;
@property (nonatomic, strong) NSString *domainLookupTime;
@property (nonatomic, strong) NSString *domProcessingTime;
@property (nonatomic, strong) NSString *serverTime;
@property (nonatomic, strong) NSString *host;
@property (nonatomic, strong) NSString *elapsedTime;
@property (nonatomic, strong) NSString *loadTime;

@end

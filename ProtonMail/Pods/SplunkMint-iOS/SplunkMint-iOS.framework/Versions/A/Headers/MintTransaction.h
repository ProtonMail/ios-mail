//
//  SplunkTransaction.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/25/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TrStart.h"
#import "TrStop.h"

@interface MintTransaction : NSObject

@property (nonatomic, strong) NSNumber* elapsed;
@property (nonatomic, strong) TrStart* transactionStart;
@property (nonatomic, strong) TrStop* transactionStop;
@property (nonatomic, strong) NSDate* transactionStartedAt;

@end

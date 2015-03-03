//
//  LoggedRequestEventArgs.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/16/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MintResponseResult.h"

@interface LoggedRequestEventArgs : NSObject

@property (nonatomic, strong) MintResponseResult* responseResult;

@end

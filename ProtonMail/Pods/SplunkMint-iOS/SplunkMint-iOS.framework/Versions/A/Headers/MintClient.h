//
//  SplunkClient.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/7/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPLJSONModel.h"

@interface MintClient : SPLJSONModel

- (BOOL) isEqualToSplunkClient: (MintClient*)aSplunkClient;

@property (nonatomic, strong) NSString* version;
@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSString* flavor;

@end

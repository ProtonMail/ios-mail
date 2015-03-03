//
//  ScreenDataFixture.h
//  Splunk-iOS
//
//  Created by G.Tas on 2/21/14.
//  Copyright (c) 2014 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPLJSONModel.h"

@interface ScreenDataFixture : SPLJSONModel

@property (nonatomic, strong) NSString* name;
@property (nonatomic, strong) NSMutableDictionary<SPLOptional>* ExtraData;

@end

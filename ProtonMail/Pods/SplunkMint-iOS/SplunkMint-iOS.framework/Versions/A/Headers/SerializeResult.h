//
//  SerializeResult.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/22/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SerializeResult : NSObject

@property(nonatomic,strong) NSString* encodedJson;
@property(nonatomic,strong) NSString* decodedJson;

@end

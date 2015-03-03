//
//  ScreenProperties.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/3/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SPLJSONModel.h"

@interface ScreenProperties : SPLJSONModel

@property (nonatomic, assign) float width;
@property (nonatomic, assign) float height;
@property (nonatomic, assign) float xdpi;
@property (nonatomic, assign) float ydpi;

@end

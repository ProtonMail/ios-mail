//
//  MultipartResponseParser.h
//  MultipartResponseParser
//
//  Created by Alexander Vorobjov on 17/07/14.
//  Copyright (c) 2014 Alexander Vorobjov. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MultipartResponseParser : NSObject

+ (NSArray *)parseData:(NSData *)data;

@end

extern NSString *const kMultipartHeadersKey;
extern NSString *const kMultipartBodyKey;

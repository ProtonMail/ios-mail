//
//  NSData+MultipartResponses.h
//  ProtonMail
//
//  Created by Yanfeng Zhang on 9/22/15.
//  Copyright (c) 2015 ArcTouch. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSData (MultipartResponses)

- (NSArray *)multipartArray;
- (NSDictionary *)multipartDictionary;

@end
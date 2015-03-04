//
//  LimitedBreadcrumbList.h
//  Splunk-iOS
//
//  Created by G.Tas on 11/2/13.
//  Copyright (c) 2013 Splunk. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LimitedBreadcrumbList : NSObject

@property (nonatomic, assign) NSUInteger maxCount;
@property (nonatomic, assign) NSUInteger count;
@property (nonatomic, strong) NSMutableArray* breadcrumbsArray;

+ (LimitedBreadcrumbList*) sharedInstance;

- (void) add: (NSString*)breadcrumb;
- (void) remove: (NSString*)breadcrumb;
- (NSInteger) indexOf: (NSString*)breadcrumb;
- (void) insertAtIndex: (NSUInteger)index breadcrumb: (NSString*)aBreadcrumb;
- (void) removeAtIndex: (NSUInteger)index;
- (void) clear;
- (BOOL) contains: (NSString*)breadcrumb;
- (NSArray*) descriptionArray;

@end

/*
 File:       Instabug/IBGSurvey.h
 
 Contains:   API for using Instabug's SDK.
 
 Copyright:  (c) 2013-2020 by Instabug, Inc., all rights reserved.

 Version:    11.3.0
 */

#import <Foundation/Foundation.h>

@interface IBGSurvey : NSObject

@property (nonatomic, readonly) NSString *title;

- (void)show;

@end

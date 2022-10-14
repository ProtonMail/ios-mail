/*
 File:       Instabug/UIView+Instabug.h
 
 Contains:   API for using Instabug's SDK.
 
 Copyright:  (c) 2013-2019 by Instabug, Inc., all rights reserved.
 
 Version:    0.0.0
 */

#import <UIKit/UIKit.h>

@interface UIView (Instabug)

/**
 @brief Set this to true on any UIView to mark it as private.
 Doing this will exclude it from all screenshots, view hierarchy captures and screen recordings.
 */
@property (nonatomic, assign) BOOL instabug_privateView;

@end

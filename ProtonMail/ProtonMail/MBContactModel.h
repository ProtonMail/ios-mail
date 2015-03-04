//
//  MBContactModel.h
//  MBContactPicker
//
//  Created by Matt Bowman on 12/13/13.
//  Copyright (c) 2013 Citrrus, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@protocol MBContactPickerModelProtocol <NSObject>

@required

@property (readonly, nonatomic, copy) NSString *contactTitle;

@optional

@property (readonly, nonatomic, copy) NSString *contactSubtitle;
@property (readonly, nonatomic) UIImage *contactImage;

@end

@interface MBContactModel : NSObject <MBContactPickerModelProtocol>

@property (nonatomic, copy) NSString *contactTitle;
@property (nonatomic, copy) NSString *contactSubtitle;
@property (nonatomic) UIImage *contactImage;

@end

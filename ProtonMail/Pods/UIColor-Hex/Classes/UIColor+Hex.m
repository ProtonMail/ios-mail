//
//  UIColor+Hex.m
//
//  Created by nakajijapan
//

#import "UIColor+Hex.h"

@implementation UIColor (Hex)

+ (UIColor *)colorWithHex:(NSInteger)hex
{
    return [self colorWithHex:hex alpha:1.0];
}

+ (UIColor *)colorWithHex:(NSInteger)hex alpha:(CGFloat)alpha
{
    CGFloat red   = (CGFloat)((0xff0000 & hex) >> 16) / 255.0;
    CGFloat green = (CGFloat)((0xff00   & hex) >> 8)  / 255.0;
    CGFloat blue  = (CGFloat)(0xff      & hex)        / 255.0;
    return [UIColor colorWithRed: red green: green blue: blue alpha: alpha];
}

@end

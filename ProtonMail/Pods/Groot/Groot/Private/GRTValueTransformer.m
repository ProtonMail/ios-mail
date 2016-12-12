// GRTValueTransformer.m
// 
// Copyright (c) 2014-2016 Guillermo Gonzalez
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.

#import "GRTValueTransformer.h"

NS_ASSUME_NONNULL_BEGIN

#pragma mark - GRTValueTransformer

@interface GRTValueTransformer ()

@property (copy, nonatomic) __nullable id (^transformBlock)(id);

@end

@implementation GRTValueTransformer

- (instancetype)initWithBlock:(__nullable id (^)(id value))block {
    self = [super init];
    if (self) {
        self.transformBlock = block;
    }
    return self;
}

#pragma mark - NSValueTransformer

+ (BOOL)allowsReverseTransformation {
    return NO;
}

+ (Class)transformedValueClass {
    return NSObject.class;
}

- (nullable id)transformedValue:(nullable id)value {
    if (value != nil) {
        return self.transformBlock(value);
    }
    return nil;
}

@end

#pragma mark - GRTReversibleValueTransformer

@interface GRTReversibleValueTransformer ()

@property (copy, nonatomic) __nullable id (^reverseTransformBlock)(id);

@end

@implementation GRTReversibleValueTransformer

- (instancetype)initWithForwardBlock:(__nullable id (^)(id value))forwardBlock
                        reverseBlock:(__nullable id (^)(id value))reverseBlock
{
    self = [super initWithBlock:forwardBlock];
    if (self) {
        self.reverseTransformBlock = reverseBlock;
    }
    return self;
}

#pragma mark - NSValueTransformer

+ (BOOL)allowsReverseTransformation {
    return YES;
}

- (nullable id)reverseTransformedValue:(nullable id)value {
    if (value != nil) {
        return self.reverseTransformBlock(value);
    }
    return nil;
}

@end

NS_ASSUME_NONNULL_END

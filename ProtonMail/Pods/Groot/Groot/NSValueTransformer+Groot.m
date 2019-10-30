// NSValueTransformer+Groot.h
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

#import "NSValueTransformer+Groot.h"
#import "GRTValueTransformer.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSValueTransformer (Groot)

+ (void)grt_setValueTransformerWithName:(NSString *)name
                         transformBlock:(__nullable id (^)(id value))transformBlock
{
    GRTValueTransformer *valueTransformer = [[GRTValueTransformer alloc] initWithBlock:transformBlock];
    [self setValueTransformer:valueTransformer forName:name];
}

+ (void)grt_setValueTransformerWithName:(NSString *)name
                         transformBlock:(__nullable id (^)(id value))transformBlock
                  reverseTransformBlock:(__nullable id (^)(id value))reverseTransformBlock
{
    GRTReversibleValueTransformer *valueTransformer = [[GRTReversibleValueTransformer alloc] initWithForwardBlock:transformBlock reverseBlock:reverseTransformBlock];
    [self setValueTransformer:valueTransformer forName:name];
}

+ (void)grt_setDictionaryTransformerWithName:(NSString *)name
                              transformBlock:(NSDictionary * __nullable (^)(NSDictionary *value))transformBlock
{
    return [self grt_setValueTransformerWithName:name transformBlock:transformBlock];
}

+ (void)grt_setEntityMapperWithName:(NSString *)name
                           mapBlock:(NSString * __nullable (^)(NSDictionary *JSONDictionary))mapBlock
{
    return [self grt_setValueTransformerWithName:name transformBlock:mapBlock];
}

@end

NS_ASSUME_NONNULL_END

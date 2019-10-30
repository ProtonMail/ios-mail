// NSAttributeDescription+Groot.m
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

#import "NSAttributeDescription+Groot.h"
#import "NSPropertyDescription+Groot.h"

@implementation NSAttributeDescription (Groot)

- (nullable NSValueTransformer *)grt_JSONTransformer {
    NSString *name = self.userInfo[@"JSONTransformerName"];
    return name != nil ? [NSValueTransformer valueTransformerForName:name] : nil;
}

- (nullable id)grt_valueForJSONValue:(id __nonnull)JSONValue {
    id value = nil;

    if ([JSONValue isKindOfClass:[NSDictionary class]]) {
        value = [self grt_rawValueInJSONDictionary:JSONValue];
    } else if ([JSONValue isKindOfClass:[NSNumber class]] || [JSONValue isKindOfClass:[NSString class]]) {
        value = JSONValue;
    }
    
    if (value != nil) {
        if (value == [NSNull null]) {
            return nil;
        }
        
        NSValueTransformer *transformer = [self grt_JSONTransformer];
        
        if (transformer != nil) {
            return [transformer transformedValue:value];
        }
        
        return value;
    }
    
    return nil;
}

- (NSArray * __nonnull)grt_valuesInJSONArray:(NSArray * __nonnull)array {
    NSMutableArray *values = [NSMutableArray arrayWithCapacity:array.count];
    
    for (id object in array) {
        id value = [self grt_valueForJSONValue:object];
        
        if (value != nil) {
            [values addObject:value];
        }
    }
    
    return values;
}

@end

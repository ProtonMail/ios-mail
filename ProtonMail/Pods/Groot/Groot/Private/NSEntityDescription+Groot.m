// NSEntityDescription+Groot.m
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

#import "NSEntityDescription+Groot.h"
#import "NSPropertyDescription+Groot.h"
#import "NSAttributeDescription+Groot.h"
#import "NSManagedObject+Groot.h"
#import "NSArray+DictionaryTransformer.h"

#import "GRTError.h"

NS_ASSUME_NONNULL_BEGIN

@implementation NSEntityDescription (Groot)

+ (nullable NSEntityDescription *)grt_entityForName:(NSString *)entityName
                                          inContext:(NSManagedObjectContext *)context
                                              error:(NSError *__autoreleasing  __nullable * __nullable)error
{
    NSEntityDescription *entity = [self entityForName:entityName inManagedObjectContext:context];
    
    if (entity == nil && error != nil) {
        *error = [NSError errorWithDomain:GRTErrorDomain code:GRTErrorEntityNotFound userInfo:nil];
    }
    
    return entity;
}

- (NSSet *)grt_identityAttributes {
    NSSet *keys = [self grt_keysForUniquing];
    NSMutableSet *attributes = [NSMutableSet setWithCapacity:keys.count];
    
    if (keys.count > 0) {
        for (NSString *key in keys) {
            NSAttributeDescription *attribute = self.attributesByName[key];
            NSAssert(attribute != nil, @"Could not find attribute '%@.%@'.", self.name, key);
            
            [attributes addObject:attribute];
        }
    }
    
    return attributes;
}

- (nullable NSValueTransformer *)grt_dictionaryTransformer {
    NSString *name = self.userInfo[@"JSONDictionaryTransformerName"];
    
    if (name == nil) {
        return nil;
    }
    
    return [NSValueTransformer valueTransformerForName:name];
}

- (NSString *)grt_subentityNameForJSONValue:(id)value {
    NSString *name = nil;
    
    if ([value isKindOfClass:[NSDictionary class]]) {
        name = [[self grt_entityMapper] transformedValue:value];
    }
    
    return name ? : self.name;
}

#pragma mark - Private

- (nullable NSValueTransformer *)grt_entityMapper {
    NSString *name = self.userInfo[@"entityMapperName"];
    
    if (name == nil) {
        return nil;
    }
    
    return [NSValueTransformer valueTransformerForName:name];
}

- (NSSet *)grt_keysForUniquing {
    NSMutableSet *keys = [NSMutableSet set];
    NSEntityDescription *entity = self;
    
    while (entity != nil) {
        NSString *value = entity.userInfo[@"identityAttributes"];
        
        if (value == nil) {
            // For backwards compatibility
            value = entity.userInfo[@"identityAttribute"];
        }
        
        if (value != nil) {
            NSCharacterSet *characterSet = [NSCharacterSet characterSetWithCharactersInString:@" ,"];
            NSArray *names = [value componentsSeparatedByCharactersInSet:characterSet];
            
            for (NSString *name in names) {
                if (name.length > 0) {
                    [keys addObject:name];
                }
            }
        }
        
        entity = [entity superentity];
    }
    
    return keys;
}

@end

NS_ASSUME_NONNULL_END

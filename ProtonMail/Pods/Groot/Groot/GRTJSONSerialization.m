// GRTJSONSerialization.m
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

#import "GRTJSONSerialization.h"
#import "GRTManagedObjectSerializer.h"

#import "NSEntityDescription+Groot.h"
#import "NSManagedObject+Groot.h"

NS_ASSUME_NONNULL_BEGIN

@implementation GRTJSONSerialization

+ (nullable NSArray<__kindof NSManagedObject *> *)objectsWithEntityName:(NSString *)entityName
                                                           fromJSONData:(NSData *)data
                                                              inContext:(NSManagedObjectContext *)context
                                                                  error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    NSError *error = nil;
    id parsedJSON = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    
    if (error != nil) {
        if (outError != nil) *outError = error;
        return nil;
    }
    
    NSArray *array = nil;
    if ([parsedJSON isKindOfClass:[NSDictionary class]]) {
        array = @[parsedJSON];
    } else if ([parsedJSON isKindOfClass:[NSArray class]]) {
        array = parsedJSON;
    }
    
    NSAssert(array != nil, @"Invalid JSON. The top level object must be an NSArray or an NSDictionary");
    
    return [self objectsWithEntityName:entityName fromJSONArray:array inContext:context error:outError];
}

+ (nullable __kindof NSManagedObject *)objectWithEntityName:(NSString *)entityName
                                         fromJSONDictionary:(NSDictionary *)JSONDictionary
                                                  inContext:(NSManagedObjectContext *)context
                                                      error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    NSError *error = nil;
    NSEntityDescription *entity = [NSEntityDescription grt_entityForName:entityName inContext:context error:&error];
    
    if (error != nil) {
        if (outError != nil) *outError = error;
        return nil;
    }
    
    GRTManagedObjectSerializer *serializer = [[GRTManagedObjectSerializer alloc] initWithEntity:entity];
    
    return [serializer serializeJSONArray:@[JSONDictionary]
                                inContext:context
                                    error:outError].firstObject;
}

+ (nullable NSArray<__kindof NSManagedObject *> *)objectsWithEntityName:(NSString *)entityName
                                                          fromJSONArray:(NSArray *)JSONArray
                                                              inContext:(NSManagedObjectContext *)context
                                                                  error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    NSError *error = nil;
    NSEntityDescription *entity = [NSEntityDescription grt_entityForName:entityName inContext:context error:&error];
    
    if (error != nil) {
        if (outError != nil) *outError = error;
        return nil;
    }
    
    GRTManagedObjectSerializer *serializer = [[GRTManagedObjectSerializer alloc] initWithEntity:entity];
    
    return [serializer serializeJSONArray:JSONArray
                                inContext:context
                                    error:outError];
}

+ (NSDictionary *)JSONDictionaryFromObject:(NSManagedObject *)object {
    // Keeping track of in process relationships avoids infinite recursion when serializing inverse relationships
    NSMutableSet *relationships = [NSMutableSet set];
    return [object grt_JSONDictionarySerializingRelationships:relationships];
}

+ (NSArray *)JSONArrayFromObjects:(NSArray *)objects {
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:objects.count];
    
    for (NSManagedObject *object in objects) {
        NSDictionary *dictionary = [self JSONDictionaryFromObject:object];
        [array addObject:dictionary];
    }
    
    return array;
}

@end

NS_ASSUME_NONNULL_END

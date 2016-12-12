// GRTManagedObjectSerializer.m
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

#import "GRTManagedObjectSerializer.h"
#import "GRTSerializationStrategy.h"

#import "NSEntityDescription+Groot.h"
#import "NSArray+DictionaryTransformer.h"

NS_ASSUME_NONNULL_BEGIN

@interface GRTManagedObjectSerializer ()

@property (strong, nonatomic) id<GRTSerializationStrategy> strategy;

@end

@implementation GRTManagedObjectSerializer

- (instancetype)initWithEntity:(NSEntityDescription *)entity
{
    self = [super init];
    if (self) {
        _strategy = GRTSerializationStrategyForEntity(entity);
    }
    return self;
}

- (nullable NSArray *)serializeJSONArray:(NSArray *)array
                               inContext:(NSManagedObjectContext *)context
                                   error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    if (array.count == 0) {
        return @[];
    }
    
    // Transform the JSON array if our entity has a dictionary transformer
    
    NSArray *transformedArray = array;
    NSValueTransformer *dictionaryTransformer = [self.strategy.entity grt_dictionaryTransformer];
    
    if (dictionaryTransformer != nil) {
        transformedArray = [array grt_arrayByApplyingDictionaryTransformer:dictionaryTransformer];
    }
    
    // Delegate serialization to our strategy object
    
    NSError *error = nil;
    NSArray *managedObjects = [self.strategy serializeJSONArray:transformedArray
                                                      inContext:context
                                                          error:&error];
    
    // Rollback any changes if an error ocurred
    
    if (error != nil) {
        // Delete any objects we have created when there's an error
        if (managedObjects.count > 0) {
            [context performBlockAndWait:^{
                for (NSManagedObject *object in managedObjects) {
                    [context deleteObject:object];
                }
            }];
        }
        
        if (outError != nil) {
            *outError = error;
        }
        
        managedObjects = nil;
    }
    
    return managedObjects;
}

@end

NS_ASSUME_NONNULL_END

// GRTCompositeUniquingSerializationStrategy.m
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

#import "GRTCompositeUniquingSerializationStrategy.h"
#import "GRTError.h"

#import "NSEntityDescription+Groot.h"
#import "NSAttributeDescription+Groot.h"
#import "NSManagedObject+Groot.h"

NS_ASSUME_NONNULL_BEGIN

@interface GRTCompositeUniquingSerializationStrategy ()

@property (strong, nonatomic, readonly) NSSet *uniqueAttributes;

@end

@implementation GRTCompositeUniquingSerializationStrategy

@synthesize entity = _entity;

- (instancetype)initWithEntity:(NSEntityDescription *)entity uniqueAttributes:(NSSet *)uniqueAttributes {
    self = [super init];
    if (self) {
        _entity = entity;
        _uniqueAttributes = uniqueAttributes;
    }
    return self;
}

- (NSArray *)serializeJSONArray:(NSArray *)array
                      inContext:(NSManagedObjectContext *)context
                          error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    NSMutableArray * __block managedObjects = [NSMutableArray array];
    NSError * __block error = nil;
    
    [context performBlockAndWait:^{
        for (id obj in array) {
            if (obj == [NSNull null]) {
                continue;
            }
            
            if (![obj isKindOfClass:[NSDictionary class]]) {
                // This strategy can only serialize JSON dictionaries
                NSString *format = NSLocalizedString(@"Cannot serialize '%@' into entity '%@'.", @"Groot");
                NSString *message = [NSString stringWithFormat:format, obj, self.entity.name];
                error = [NSError errorWithDomain:GRTErrorDomain
                                            code:GRTErrorInvalidJSONObject
                                        userInfo:@{ NSLocalizedDescriptionKey: message }];
                
                break;
            }
            
            NSManagedObject *managedObject = [self serializeJSONDictionary:obj
                                                                 inContext:context
                                                                     error:&error];
            
            if (error != nil) {
                break;
            }
            
            [managedObjects addObject:managedObject];
        }
    }];
    
    if (error != nil) {
        if (outError != nil) {
            *outError = error;
        }
    }
    
    return managedObjects;
}

#pragma mark - Private

- (NSManagedObject *)serializeJSONDictionary:(NSDictionary *)dictionary
                                   inContext:(NSManagedObjectContext *)context
                                       error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    NSError *error = nil;
    NSManagedObject *managedObject = [self existingObjectWithJSONDictionary:dictionary inContext:context error:&error];
    
    if (error != nil) {
        if (outError != nil) {
            *outError = error;
        }
        return nil;
    }
    
    if (managedObject == nil) {
        NSString *entityName = [self.entity grt_subentityNameForJSONValue:dictionary];
        managedObject = [NSEntityDescription insertNewObjectForEntityForName:entityName
                                                      inManagedObjectContext:context];
    }
    
    [managedObject grt_serializeJSONDictionary:dictionary mergeChanges:YES error:&error];
    
    if (error != nil) {
        [context deleteObject:managedObject];
        
        if (outError != nil) {
            *outError = error;
        }
        
        return nil;
    }
    
    return managedObject;
}

- (nullable NSManagedObject *)existingObjectWithJSONDictionary:(NSDictionary *)dictionary
                                                     inContext:(NSManagedObjectContext *)context
                                                         error:(NSError *__autoreleasing  __nullable * __nullable)outError
{
    NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
    fetchRequest.entity = self.entity;
    fetchRequest.predicate = [self predicateForJSONDictionary:dictionary];
    
    return [context executeFetchRequest:fetchRequest error:outError].firstObject;
}

- (NSPredicate *)predicateForJSONDictionary:(NSDictionary *)dictionary {
    NSMutableArray *subpredicates = [NSMutableArray arrayWithCapacity:self.uniqueAttributes.count];
    
    for (NSAttributeDescription *attribute in self.uniqueAttributes) {
        id value = [attribute grt_valueForJSONValue:dictionary];
        
        NSExpression *leftExpression = [NSExpression expressionForKeyPath:attribute.name];
        NSExpression *rightExpression = [NSExpression expressionForConstantValue:value];
        
        NSComparisonPredicate *subpredicate = [NSComparisonPredicate predicateWithLeftExpression:leftExpression
                                                                                 rightExpression:rightExpression
                                                                                        modifier:NSDirectPredicateModifier
                                                                                            type:NSEqualToPredicateOperatorType
                                                                                         options:0];
        [subpredicates addObject:subpredicate];
    }
    
    return [NSCompoundPredicate andPredicateWithSubpredicates:subpredicates];
}

@end

NS_ASSUME_NONNULL_END

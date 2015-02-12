// GRTJSONSerialization.h
//
// Copyright (c) 2014 Guillermo Gonzalez
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

#import <CoreData/CoreData.h>

extern NSString * const GRTJSONSerializationErrorDomain;
extern const NSInteger GRTJSONSerializationErrorInvalidJSONObject;

/**
 Converts JSON dictionaries and JSON arrays to and from Managed Objects.
 
 The serialization process can be customized by adding certain information to the user dictionary
 available in Core Data entities, attributes and relationships:
 
 You can specify how an attribute or a relationship is mapped to JSON with the `JSONKeyPath` key. If
 this key is not present, the attribute name will be used. If `JSONKeyPath` is associated with `@"null"`
 or `NSNull` then the attribute or relationship will not participate in JSON serialization.
 
 Use `JSONTransformerName` to specify the name of the value transformer that will be used to convert
 the JSON value for an attribute. If the specified transformer is reversible, it will also be used
 to convert the attribute value back to JSON.
 
 The **merge** methods `mergeObjectForEntityName:fromJSONDictionary:inManagedObjectContext:error:` and
 `mergeObjectsForEntityName:fromJSONArray:inManagedObjectContext:error:` need to know when a managed
 object already exist when converting from JSON. You can specify which attribute makes an object unique
 by using the `identityAttribute` option. Note that this option must be added to the **Entity** user
 dictionary.
 
 Note that the user dictionary can be manipulated directly in the Core Data Model Editor.
 */
@interface GRTJSONSerialization : NSObject

/**
 Creates a managed object from a JSON dictionary.
 
 This method converts the specified JSON dictionary into a managed object of a given entity.
 
 @param entityName The name of an entity.
 @param JSONDictionary A dictionary representing JSON data. This should match the format returned
                       by `NSJSONSerialization`.
 @param context The context into which to insert the created managed object.
 @param error If an error occurs, upon return contains an NSError object that describes the problem.
 
 @return A managed object, or `nil` if an error occurs.
 */
+ (id)insertObjectForEntityName:(NSString *)entityName fromJSONDictionary:(NSDictionary *)JSONDictionary inManagedObjectContext:(NSManagedObjectContext *)context error:(NSError **)error;

/**
 Creates set of managed objects from a JSON array.
 
 This method converts the specified JSON array into a set of managed objects of a given entity.
 
 @param entityName The name of an entity.
 @param JSONArray An array of dictionaries representing JSON data. This should match the format
                  returned by `NSJSONSerialization`.
 @param context The context into which to insert the created managed object.
 @param error If an error occurs, upon return contains an NSError object that describes the problem.
 
 @return An array of managed objects, or `nil` if an error occurs.
 */
+ (NSArray *)insertObjectsForEntityName:(NSString *)entityName fromJSONArray:(NSArray *)JSONArray inManagedObjectContext:(NSManagedObjectContext *)context error:(NSError **)error;

/**
 Creates or updates a managed object from a JSON dictionary.
 
 This method will perform a fetch request for an object matching the given JSON dictionary, using
 the identity attribute specified in the entity's user info. If a match is found, then it will be
 updated with the given JSON dictionary, otherwise a new object will be created.
 
 Note that this method will throw an exception if the given entity has no identity attribute defined.
 
 @param entityName The name of an entity.
 @param JSONDictionary A dictionary representing JSON data. This should match the format returned
 by `NSJSONSerialization`.
 @param context The context into which to fetch or insert the managed object.
 @param error If an error occurs, upon return contains an NSError object that describes the problem.
 
 @return A managed object, or `nil` if an error occurs.
 */
+ (id)mergeObjectForEntityName:(NSString *)entityName fromJSONDictionary:(NSDictionary *)JSONDictionary inManagedObjectContext:(NSManagedObjectContext *)context error:(NSError **)error;

/**
 Creates or updates a set of managed objects from a JSON array.
 
 This method will perform a **single** fetch request for objects matching the given JSON array,
 using the identity attribute specified in the entity's user info. Matching objects will be updated,
 and the rest will be created.
 
 Note that this method will throw an exception if the given entity has no identity attribute defined.
 
 @param entityName The name of an entity.
 @param JSONArray An array representing JSON data. This should match the format returned by
                  `NSJSONSerialization`.
 @param context The context into which to fetch or insert the managed objects.
 @param error If an error occurs, upon return contains an NSError object that describes the problem.
 
 @return An array of managed objects, or `nil` if an error occurs.
 */
+ (NSArray *)mergeObjectsForEntityName:(NSString *)entityName fromJSONArray:(NSArray *)JSONArray inManagedObjectContext:(NSManagedObjectContext *)context error:(NSError **)error;

/**
 Converts a managed object into a JSON representation.
 
 @param managedObject The managed object to use for JSON serialization.
 
 @return A JSON dictionary.
 */
+ (NSDictionary *)JSONDictionaryFromManagedObject:(NSManagedObject *)managedObject;

/**
 Converts an array of managed objects into a JSON representation.
 
 @param managedObjects The array of managed objects to use for JSON serialization.
 
 @return A JSON array.
 */
+ (NSArray *)JSONArrayFromManagedObjects:(NSArray *)managedObjects;

@end

// Groot.swift
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

import CoreData

extension NSManagedObjectContext {

    internal var managedObjectModel: NSManagedObjectModel? {
        if let persistentStoreCoordinator = persistentStoreCoordinator {
            return persistentStoreCoordinator.managedObjectModel
        }

        if let parent = parent {
            return parent.managedObjectModel
        }

        return nil
    }
}

extension NSManagedObject {

    internal static func entity(inManagedObjectContext context: NSManagedObjectContext) -> NSEntityDescription {

        guard let model = context.managedObjectModel else {
            fatalError("Could not find managed object model for the provided context.")
        }

        let className = String(reflecting: self)

        for entity in model.entities {
            if entity.managedObjectClassName == className {
                return entity
            }
        }

        fatalError("Could not locate the entity for \(className).")
    }
}

/// Creates or updates a set of managed objects from JSON data.
///
/// - parameter name:    The name of an entity.
/// - parameter data:    A data object containing JSON data.
/// - parameter context: The context into which to fetch or insert the managed objects.
///
/// - returns: An array of managed objects
public func objects(withEntityName name: String, fromJSONData data: Data, inContext context: NSManagedObjectContext) throws -> [NSManagedObject] {
    return try GRTJSONSerialization.objects(withEntityName: name, fromJSONData: data, in: context)
}

/// Creates or updates a set of managed objects from JSON data.
///
/// - parameter data:    A data object containing JSON data.
/// - parameter context: The context into which to fetch or insert the managed objects.
///
/// - returns: An array of managed objects.
public func objects<T: NSManagedObject>(fromJSONData data: Data, inContext context: NSManagedObjectContext) throws -> [T] {
    let entity = T.entity(inManagedObjectContext: context)
    let managedObjects = try objects(withEntityName: entity.name!, fromJSONData: data, inContext: context)
    
    return managedObjects as! [T]
}

public typealias JSONDictionary = [String: Any]

/// Creates or updates a managed object from a JSON dictionary.
///
/// This method converts the specified JSON dictionary into a managed object of a given entity.
///
/// - parameter name:       The name of an entity.
/// - parameter dictionary: A dictionary representing JSON data.
/// - parameter context:    The context into which to fetch or insert the managed objects.
///
/// - returns: A managed object.
public func object(withEntityName name: String, fromJSONDictionary dictionary: JSONDictionary, inContext context: NSManagedObjectContext) throws -> NSManagedObject {
    return try GRTJSONSerialization.object(withEntityName: name, fromJSONDictionary: dictionary, in: context)
}

/// Creates or updates a managed object from a JSON dictionary.
///
/// This method converts the specified JSON dictionary into a managed object.
///
/// - parameter dictionary: A dictionary representing JSON data.
/// - parameter context:    The context into which to fetch or insert the managed objects.
///
/// - returns: A managed object.
public func object<T: NSManagedObject>(fromJSONDictionary dictionary: JSONDictionary, inContext context: NSManagedObjectContext) throws -> T {
    let entity = T.entity(inManagedObjectContext: context)
    let managedObject = try object(withEntityName: entity.name!, fromJSONDictionary: dictionary, inContext: context)
    
    return managedObject as! T
}

public typealias JSONArray = [Any]

/// Creates or updates a set of managed objects from a JSON array.
///
/// - parameter name:    The name of an entity.
/// - parameter array:   An array representing JSON data.
/// - parameter context: The context into which to fetch or insert the managed objects.
///
/// - returns: An array of managed objects.
public func objects(withEntityName name: String, fromJSONArray array: JSONArray, inContext context: NSManagedObjectContext) throws -> [NSManagedObject] {
    return try GRTJSONSerialization.objects(withEntityName: name, fromJSONArray: array, in: context)
}

/// Creates or updates a set of managed objects from a JSON array.
///
/// - parameter array:   An array representing JSON data.
/// - parameter context: The context into which to fetch or insert the managed objects.
///
/// - returns: An array of managed objects.
public func objects<T: NSManagedObject>(fromJSONArray array: JSONArray, inContext context: NSManagedObjectContext) throws -> [T] {
    let entity = T.entity(inManagedObjectContext: context)
    let managedObjects = try objects(withEntityName: entity.name!, fromJSONArray: array, inContext: context)
    
    return managedObjects as! [T]
}

/// Converts a managed object into a JSON representation.
///
/// - parameter object: The managed object to use for JSON serialization.
///
/// - returns: A JSON dictionary.
public func json(fromObject object: NSManagedObject) -> JSONDictionary {
    return GRTJSONSerialization.jsonDictionary(from: object) as! JSONDictionary;
}

/// Converts an array of managed objects into a JSON representation.
///
/// - parameter objects: The array of managed objects to use for JSON serialization.
///
/// - returns: A JSON array.
public func json(fromObjects objects: [NSManagedObject]) -> JSONArray {
    return GRTJSONSerialization.jsonArray(from: objects)
}

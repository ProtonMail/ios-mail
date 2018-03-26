# Groot
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)

Groot provides a simple way of serializing Core Data object graphs from or into JSON.

It uses [annotations](Documentation/Annotations.md) in the Core Data model to perform the serialization and provides the following features:

1. Attribute and relationship mapping to JSON key paths.
2. Value transformation using named `NSValueTransformer` objects.
3. Object graph preservation.
4. Support for entity inheritance

## Installing Groot

##### Using CocoaPods

Add the following to your `Podfile`:

``` ruby
use_frameworks!
pod 'Groot'
```

Or, if you need to support iOS 6 / OS X 10.8:

``` ruby
pod 'Groot/ObjC'
```

Then run `$ pod install`.

If you don’t have CocoaPods installed or integrated into your project, you can learn how to do so [here](http://cocoapods.org).

##### Using Carthage

Add the following to your `Cartfile`:

```
github "gonzalezreal/Groot"
```

Then run `$ carthage update`.

Follow the instructions in [Carthage’s README](https://github.com/Carthage/Carthage#adding-frameworks-to-an-application]) to add the framework to your project.

You may need to set **Embedded Content Contains Swift Code** to **YES** in the build settings for targets that only contain Objective-C code.

## Getting started

Consider the following JSON describing a well-known comic book character:

```json
{
    "id": "1699",
    "name": "Batman",
    "real_name": "Bruce Wayne",
    "powers": [
        {
            "id": "4",
            "name": "Agility"
        },
        {
            "id": "9",
            "name": "Insanely Rich"
        }
    ],
    "publisher": {
        "id": "10",
        "name": "DC Comics"
    }
}
```

We could translate this into a Core Data model using three entities: `Character`, `Power` and `Publisher`.

<img src="https://cloud.githubusercontent.com/assets/373190/6988401/5346423a-da51-11e4-8bf1-a41da3a7372f.png" alt="Model" width=600 height=334/>


### Mapping attributes and relationships

Groot relies on the presence of certain key-value pairs in the user info dictionary associated with entities, attributes and relationships to serialize managed objects from or into JSON. These key-value pairs are often referred in the documentation as [annotations](Documentation/Annotations.md).

In our example, we should add a `JSONKeyPath` in the user info dictionary of each attribute and relationship specifying the corresponding key path in the JSON:

* `id` for the `identifier` attribute,
* `name` for the `name` attribute,
* `real_name` for the `realName` attribute,
* `powers` for the `powers` relationship,
* `publisher` for the `publisher` relationship,
* etc.

Attributes and relationships that don't have a `JSONKeyPath` entry are **not considered** for JSON serialization or deserialization.

### Value transformers

When we created the model we decided to use `Integer 64` for our `identifier` attributes. The problem is that, for compatibility reasons, the JSON uses strings for `id` values.

We can add a `JSONTransformerName` entry to each `identifier` attribute's user info dictionary specifying the name of a value transformer that converts strings to numbers.

Groot provides a simple way for creating and registering named value transformers:

```swift
// Swift

func toString(_ value: Int) -> String? {
    return String(value)
}

func toInt(_ value: String) -> Int? {
    return Int(value)
}

ValueTransformer.setValueTransformer(withName: "StringToInteger", transform: toString, reverseTransform: toInt)
```

```objc
// Objective-C

[NSValueTransformer grt_setValueTransformerWithName:@"StringToInteger" transformBlock:^id(NSString *value) {
    return @([value integerValue]);
} reverseTransformBlock:^id(NSNumber *value) {
    return [value stringValue];
}];
```

### Object graph preservation

To preserve the object graph and avoid duplicating information when serializing managed objects from JSON, Groot needs to know how to uniquely identify your model objects.

In our example, we should add an `identityAttributes` entry to the `Character`, `Power` and `Publisher` entities user dictionaries with the value `identifier`.

Adding the `identityAttributes` annotation to your entities can affect performance when serializing from JSON. For more information see [Object Uniquing Performance](#object-uniquing-performance).

For more information about annotating your model have a look at [Annotations](Documentation/Annotations.md).

### Serializing from JSON

Now that we have our Core Data model ready we can start adding some data.

```swift
// Swift

let batmanJSON: JSONDictionary = [
    "name": "Batman",
    "id": "1699",
    "powers": [
        [
            "id": "4",
            "name": "Agility"
        ],
        [
            "id": "9",
            "name": "Insanely Rich"
        ]
    ],
    "publisher": [
        "id": "10",
        "name": "DC Comics"
    ]
]

do {
    let batman: Character = try object(fromJSONDictionary: batmanJSON, inContext: context)
} catch let error as NSError {
    // handle error
}
```

```objc
// Objective-C

Character *batman = [GRTJSONSerialization objectWithEntityName:@"Character"
                                            fromJSONDictionary:batmanJSON
                                                     inContext:self.context
                                                         error:&error];
```

If we want to update the object we just created, Groot can merge the changes for us:

```swift
// Swift

let updateJSON: JSONDictionary = [
    "id": "1699",
    "real_name": "Bruce Wayne",
]

do {
    // This will return the previously created managed object
    let batman: Character = try object(fromJSONDictionary: updateJSON, inContext: context)
} catch let error as NSError {
    // handle error
}
```

#### Serializing relationships from identifiers

Suppose that our API does not return full objects for the relationships but only the identifiers.

We don't need to change our model to support this situation:

```swift
// Swift

let batmanJSON: JSONDictionary = [
    "name": "Batman",
    "real_name": "Bruce Wayne",
    "id": "1699",
    "powers": ["4", "9"],
    "publisher": "10"
]

do {
    let batman: Character = try object(fromJSONDictionary: batmanJSON, inContext: context)
} catch let error as NSError {
    // handle error
}
```

The above code creates a full `Character` object and the corresponding relationships pointing to `Power` and `Publisher` objects that just have the identifier attribute populated.

We can import powers and publisher from different JSON objects and Groot will merge them nicely:

```swift
// Swift

let powersJSON: JSONArray = [
    [
        "id": "4",
        "name": "Agility"
    ],
    [
        "id": "9",
        "name": "Insanely Rich"
    ]
]

let publisherJSON: JSONDictionary = [
    "id": "10",
    "name": "DC Comics"
]

do {
    let _: [Power] = try objects(fromJSONArray: powersJSON, inContext: context)
    let _: Publisher = try object(fromJSONDictionary: publisherJSON, inContext: context)
} catch let error as NSError {
    // handle error
}
```

Note that serializing relationships from identifiers only works with entities specifying **only one attribute** as the value of `identityAttributes` annotation.

For more serialization alternatives check [Groot.swift](Groot/Groot.swift) and [GRTJSONSerialization.h](Groot/GRTJSONSerialization.h).

### Entity inheritance

Groot supports entity inheritance via the [entityMapperName](Documentation/Annotations.md#entitymappername) annotation.

If you are using SQLite as your persistent store, Core Data implements entity inheritance by creating one table for the parent entity and all child entities, with a superset of all their attributes. This can obviously have unintended performance consequences if you have a lot of data in the entities, so use this feature wisely.

### Object Uniquing Performance

**Object uniquing** can affect performance when serialising from JSON, as it requires fetching data from the database before inserting.

If you take a look on how **Groot** is implemented, there are three serialization strategies:

* Insert
* Uniquing
* Composite Uniquing

As you may guess, the first one is the most performant as it does not fetch from the database. If you know that there is no duplicate data in your data set, **DO NOT** set `identityAttributes` in your entity. This will make Groot use the *Insert* strategy.

Groot will pick the *Uniquing* strategy if the `identityAttributes` annotation has a single attribute, otherwise it will pick the *Composite Uniquing* strategy.

The *Uniquing* strategy requires one fetch for every array of JSON objects, whereas the *Composite Uniquing* strategy requires one fetch for every single JSON object (it is potentially the slowest of the three strategies).

### Serializing to JSON

Groot provides methods to serialize managed objects back to JSON:

```swift
// Swift

let result = json(fromObject: batman)
```

```objc
// Objective-C

NSDictionary *JSONDictionary = [GRTJSONSerialization JSONDictionaryFromObject:batman];
```

For more serialization alternatives check [Groot.swift](Groot/Groot.swift) and [GRTJSONSerialization.h](Groot/GRTJSONSerialization.h).

## Contact

[Guillermo Gonzalez](http://github.com/gonzalezreal)  
[@gonzalezreal](https://twitter.com/gonzalezreal)

## License

Groot is available under the [MIT license](LICENSE.md).

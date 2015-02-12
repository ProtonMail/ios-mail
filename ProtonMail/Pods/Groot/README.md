# Groot
With Groot you can convert JSON dictionaries and arrays to and from Core Data managed objects.

## Requirements
Groot supports OS X 10.8+ and iOS 6.0+.

## Installation
Add the following to your `Podfile` and run `$ pod install`.

``` ruby
pod 'Groot'
```

If you don't have CocoaPods installed or integrated into your project, you can learn how to do so [here](http://cocoapods.org).

## Usage
Suppose we would like to convert the JSON returned by a Comic Database web service into our own model objects. The JSON could look something like this:

```json
[
    {
        "id": "1699",
        "name": "Batman",
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
        },
        "real_name": "Bruce Wayne"
    },
	...
]
```

We could model this in Core Data using 3 entities: Character, Power and Publisher.

![Model](https://raw.githubusercontent.com/gonzalezreal/Groot/master/Images/sample-model.jpg)

Note that we don't need to name our attributes as in the JSON. The serialization process can be customized by adding certain information to the user dictionary provided in Core Data *entities*, *attributes* and *relationships*.

For instance, we can specify that the `identifier` attribute will be mapped from the `id` JSON key path, and that its value will be transformed using an `NSValueTransformer` named *GRTTestTransfomer*.

![Property User Info](https://raw.githubusercontent.com/gonzalezreal/Groot/master/Images/property-userInfo.jpg)

Now we can easily convert JSON data and insert the corresponding managed objects with a simple method call:

```objc
NSDictionary *batmanJSON = @{
	@"id": @"1699",
	@"name": @"Batman",
	@"real_name": @"Bruce Wayne",
	@"powers": @[
	@{
		@"id": @"4",
		@"name": @"Agility"
	},
	@{
		@"id": @"9",
		@"name": @"Insanely Rich"
	}],
	@"publisher": @{
		@"id": @"10",
		@"name": @"DC Comics"
	}
};

NSError *error = nil;
NSManagedObject *batman = [GRTJSONSerialization insertObjectForEntityName:@"Character"
													   fromJSONDictionary:batmanJSON
												   inManagedObjectContext:context
														            error:&error];
```

### Merging data

When inserting data, Groot does not check if the serialized managed objects already exist and simply treats them as new.

If instead, you would like to merge (that is, create or update) the serialized managed objects, then you need to tell Groot how to uniquely identify your model objects. You can do that by associating the `identityAttribute` key with the name of an attribute in the *entity* user info dictionary.

![Entity User Info](https://raw.githubusercontent.com/gonzalezreal/Groot/master/Images/entity-userInfo.jpg)

In our sample, all of our models are identified by the `identifier` attribute.

Now we can update the Batman character we just inserted in the previous snippet:

```objc
NSDictionary *updateJSON = @{
	@"id": @"1699",
	@"real_name": @"Guille Gonzalez"
}

// This will return the previously created managed object
NSManagedObject *batman = [GRTJSONSerialization mergeObjectForEntityName:@"Character"
													  fromJSONDictionary:batmanJSON
												  inManagedObjectContext:context
														           error:NULL];
```

If you want to merge a JSON array, its better to call `mergeObjectsForEntityName:fromJSONArray:inManagedObjectContext:error:`. This method will perform a single fetch per entity regardless of the number of objects in the JSON array.

### Back to JSON

You can convert managed objects into their JSON representations by using `JSONDictionaryFromManagedObject:` or `JSONArrayFromManagedObjects:`.

```objc
NSDictionary *JSONDictionary = [GRTJSONSerialization JSONDictionaryFromManagedObject:someManagedObject];
```

## Contact
[Guillermo Gonzalez](http://github.com/gonzalezreal)  
[@gonzalezreal](https://twitter.com/gonzalezreal)

## License
Groot is available under the MIT license. See [LICENSE](https://github.com/gonzalezreal/Groot/blob/master/LICENSE).

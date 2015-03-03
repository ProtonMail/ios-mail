# UIColor-Hex

Convenience methods to convert UIColors to from hex/css value/strings.

## Usage

### Creating a colour from a hex value

Use the `colorWithHex:` class method:

```objc
UIColor *color = [UIColor colorWithHex:0xffcc00];
```

The hex value is in the format RRGGBB, as you would expect.
You can specify a 32-bit hex value if you want an alpha component:

```objc
UIColor *fadedColor = [UIColor colorWithHex:0x33ffcc00];
```

If you do not specify an alpha "prefix" value, the default will be fully opaque (alpha = 0xFF).

### Retrieving the hex value from a colour

```objc
uint hexValue = [color hex];
// hexValue is 0x33ffcc00
```

This will always return a 32bit value, including the alpha component.

You can also get a hex string:

```objc
NSString* hexString = [fadedColor hexString];
// hexString is @"0x33ffcc00"
```

This will return a string with the color described as a 32bit hex value, including the `0x` prefix.

### Creating a colour with a CSS string

This only support the standard RGB css strings, not the `argb()` format. If there's interest, I might add support for it.

```objc
UIColor *color = [UIColor colorWithCSS:@"ffcc00"];
UIColor *sameColor = [UIColor colorWithCSS:@"#ffcc00"];
```

You can include the hashmark before the colour, but it's not required.
This also supports 32bit colour strings, including the alpha component in front:

```objc
UIColor *fadedColor = [UIColor colorWithCSS:@"#33ffcc00"];
```

### Retrieving the CSS string from a colour

```objc
NSString* cssString = [color cssString];
// cssString is @"#ffcc00"
```

The resulting string will always include a hashmark. If the colour is fully opaque, the alpha component will not be included in the string. Otherwise, the alpha component will be prepended before the other colour components:

```objc
NSString* cssString = [color cssString];
NSString* fadedCssString = [fadedColor cssString];
// cssString is @"#ffcc00"
// fadedCssString is @"#33ffcc00"
```

## License

This code is published under the MIT license:

Copyright (C) 2011-2014, Tom Adriaenssen

*Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:*

*The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.*

*THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.*

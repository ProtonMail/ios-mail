//
//  UIColor+Hex
//

#import "UIColor+Hex.h"

@implementation NSString (LeftPadding)

// taken from http://stackoverflow.com/questions/964322/padding-string-to-left-with-objective-c

- (NSString *) stringByPaddingTheLeftToLength:(NSUInteger) newLength withString:(NSString *) padString startingAtIndex:(NSUInteger) padIndex
{
    if ([self length] <= newLength)
        return [[@"" stringByPaddingToLength:newLength - [self length] withString:padString startingAtIndex:padIndex] stringByAppendingString:self];
    else
        return [self copy];
}

@end


@implementation UIColor (Hex)

+ (UIColor*) colorWithCSS: (NSString*)css {
	if (css.length == 0)
		return [UIColor blackColor];

	if ([css characterAtIndex:0] == '#')
		css = [css substringFromIndex:1];

	NSString *a, *r, *g, *b;

	NSUInteger len = css.length;
	if (len == 6) {
	six:
		a = @"FF";
		r = [css substringWithRange:NSMakeRange(0, 2)];
		g = [css substringWithRange:NSMakeRange(2, 2)];
		b = [css substringWithRange:NSMakeRange(4, 2)];
	}
	else if (len == 8) {
	eight:
		a = [css substringWithRange:NSMakeRange(0, 2)];
		r = [css substringWithRange:NSMakeRange(2, 2)];
		g = [css substringWithRange:NSMakeRange(4, 2)];
		b = [css substringWithRange:NSMakeRange(6, 2)];
	}
	else if (len == 3) {
	three:
		a = @"FF";
		r = [css substringWithRange:NSMakeRange(0, 1)];
		r = [r stringByAppendingString:a];
		g = [css substringWithRange:NSMakeRange(1, 1)];
		g = [g stringByAppendingString:a];
		b = [css substringWithRange:NSMakeRange(2, 1)];
		b = [b stringByAppendingString:a];
	}
	else if (len == 4) {
		a = [css substringWithRange:NSMakeRange(0, 1)];
		a = [a stringByAppendingString:a];
		r = [css substringWithRange:NSMakeRange(1, 1)];
		r = [r stringByAppendingString:a];
		g = [css substringWithRange:NSMakeRange(2, 1)];
		g = [g stringByAppendingString:a];
		b = [css substringWithRange:NSMakeRange(3, 1)];
		b = [b stringByAppendingString:a];
	}
	else if (len == 5 || len == 7) {
		css = [@"0" stringByAppendingString:css];
		if (len == 5) goto six;
		goto eight;
	}
	else if (len < 3) {
		css = [css stringByPaddingTheLeftToLength:3 withString:@"0" startingAtIndex:0];
		goto three;
	}
	else if (len > 8) {
		css = [css substringFromIndex:len-8];
		goto eight;
	}
	else {
		a = @"FF";
		r = @"00";
		g = @"00";
		b = @"00";
	}

	// parse each component separately. This gives more accurate results than
	// throwing it all together in one string and use scanf on the global string.
	a = [@"0x" stringByAppendingString:a];
	r = [@"0x" stringByAppendingString:r];
	g = [@"0x" stringByAppendingString:g];
	b = [@"0x" stringByAppendingString:b];

	uint av, rv, gv, bv;
	sscanf([a cStringUsingEncoding:NSASCIIStringEncoding], "%x", &av);
	sscanf([r cStringUsingEncoding:NSASCIIStringEncoding], "%x", &rv);
	sscanf([g cStringUsingEncoding:NSASCIIStringEncoding], "%x", &gv);
	sscanf([b cStringUsingEncoding:NSASCIIStringEncoding], "%x", &bv);

	return [UIColor colorWithRed: rv / 255.f
						   green: gv / 255.f
							blue: bv / 255.f
						   alpha: av / 255.f];
}

+ (UIColor*) colorWithHex: (NSUInteger)hex {
	CGFloat red, green, blue, alpha;

	red = ((CGFloat)((hex >> 16) & 0xFF)) / ((CGFloat)0xFF);
	green = ((CGFloat)((hex >> 8) & 0xFF)) / ((CGFloat)0xFF);
	blue = ((CGFloat)((hex >> 0) & 0xFF)) / ((CGFloat)0xFF);
	alpha = hex > 0xFFFFFF ? ((CGFloat)((hex >> 24) & 0xFF)) / ((CGFloat)0xFF) : 1;

	return [UIColor colorWithRed: red green:green blue:blue alpha:alpha];
}

- (uint)hex {
    CGFloat red, green, blue, alpha;
    if (![self getRed:&red green:&green blue:&blue alpha:&alpha]) {
        [self getWhite:&red alpha:&alpha];
        green = red;
        blue = red;
    }

    red = roundf(red * 255.f);
    green = roundf(green * 255.f);
    blue = roundf(blue * 255.f);
    alpha = roundf(alpha * 255.f);

    return ((uint)alpha << 24) | ((uint)red << 16) | ((uint)green << 8) | ((uint)blue);
}

- (NSString*)hexString {
    return [NSString stringWithFormat:@"0x%08x", [self hex]];
}

- (NSString*)cssString {
    uint hex = [self hex];
    if ((hex & 0xFF000000) == 0xFF000000)
        return [NSString stringWithFormat:@"#%06x", hex & 0xFFFFFF];

    return [NSString stringWithFormat:@"#%08x", hex];
}


@end

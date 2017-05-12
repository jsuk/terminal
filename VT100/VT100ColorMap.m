// ColorMap.m
// MobileTerminal

#import "VT100ColorMap.h"
#import "VT100Terminal.h"

@interface VT100ColorMap () {
	UIColor *_table[COLOR_MAP_MAX_COLORS];
}

@end

@implementation VT100ColorMap

- (instancetype)init {
	self = [super init];
	
	if (self) {
		_background       = [[UIColor alloc] initWithWhite:0.f alpha:1.f];;
		_foreground	      = [[UIColor alloc] initWithWhite:0.95f alpha:1.f];
		_foregroundBold   = [[UIColor alloc] initWithWhite:1.f alpha:1.f];
		_foregroundCursor = [[UIColor alloc] initWithWhite:0.95f alpha:1.f];
		_backgroundCursor = [[UIColor alloc] initWithWhite:0.4f alpha:1.f];
		_isDark = YES;
		
		// System 7.5 colors, why not?
		_table[0]  = [[UIColor alloc] initWithRed:0.0f green:0.0f blue:0.0f alpha:1.f]; // black
		_table[1]  = [[UIColor alloc] initWithRed:0.6f green:0.0f blue:0.0f alpha:1.f]; // dark red
		_table[2]  = [[UIColor alloc] initWithRed:0.0f green:0.6f blue:0.0f alpha:1.f]; // dark green
		_table[3]  = [[UIColor alloc] initWithRed:0.6f green:0.4f blue:0.0f alpha:1.f]; // dark yellow
		_table[4]  = [[UIColor alloc] initWithRed:0.0f green:0.0f blue:0.6f alpha:1.f]; // dark blue
		_table[5]  = [[UIColor alloc] initWithRed:0.6f green:0.0f blue:0.6f alpha:1.f]; // dark magenta
		_table[6]  = [[UIColor alloc] initWithRed:0.0f green:0.6f blue:0.6f alpha:1.f]; // dark cyan
		_table[7]  = [[UIColor alloc] initWithRed:0.6f green:0.6f blue:0.6f alpha:1.f]; // dark white
		_table[8]  = [[UIColor alloc] initWithRed:0.0f green:0.0f blue:0.0f alpha:1.f]; // black
		_table[9]  = [[UIColor alloc] initWithRed:1.0f green:0.0f blue:0.0f alpha:1.f]; // red
		_table[10] = [[UIColor alloc] initWithRed:0.0f green:1.0f blue:0.0f alpha:1.f]; // green
		_table[11] = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:0.0f alpha:1.f]; // yellow
		_table[12] = [[UIColor alloc] initWithRed:0.0f green:0.0f blue:1.0f alpha:1.f]; // blue
		_table[13] = [[UIColor alloc] initWithRed:1.0f green:0.0f blue:1.0f alpha:1.f]; // magenta
		_table[14] = [[UIColor alloc] initWithRed:0.0f green:1.0f blue:1.0f alpha:1.f]; // light cyan
		_table[15] = [[UIColor alloc] initWithRed:1.0f green:1.0f blue:1.0f alpha:1.f]; // white
	}
	
	return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary {
	self = [self init];
	
	if (self) {
		if ([dictionary valueForKey:@"Background"]) {
			[_background release];
			_background = [[self _colorFromArray:[dictionary valueForKey:@"Background"]] retain];
		}
		
		if ([dictionary valueForKey:@"Text"]) {
			[_foreground release];
			_foreground = [[self _colorFromArray:[dictionary valueForKey:@"Text"]] retain];
		}
		
		if ([dictionary valueForKey:@"BoldText"]) {
			[_foregroundBold release];
			_foregroundBold = [[self _colorFromArray:[dictionary valueForKey:@"BoldText"]] retain];
		}
		
		if ([dictionary valueForKey:@"Cursor"]) {
			[_foregroundCursor release];
			_foregroundCursor = [[self _colorFromArray:[dictionary valueForKey:@"Cursor"]] retain];
			
			[_backgroundCursor release];
			_backgroundCursor = [[self _colorFromArray:[dictionary valueForKey:@"Cursor"]] retain];
		}
		
		if ([dictionary valueForKey:@"Dark"]) {
			_isDark = ((NSNumber *)[dictionary valueForKey:@"Dark"]).boolValue;
		}
	}
	
	return self;
}

- (UIColor *)_colorFromArray:(NSArray *)array {
	if (!array || array.count != 3) {
		return nil;
	}
	
	return [UIColor colorWithRed:((NSNumber *)[array objectAtIndex:0]).floatValue / 255.f green:((NSNumber *)[array objectAtIndex:1]).floatValue / 255.f blue:((NSNumber *)[array objectAtIndex:2]).floatValue / 255.f alpha:1.f];
}

- (void) dealloc {
	for (int i = 0; i < COLOR_MAP_MAX_COLORS; i++) {
		[_table[i] release];
	}
	
	[_background release];
	[_foreground release];
	[_foregroundBold release];
	[_foregroundCursor release];
	[_backgroundCursor release];
	[super dealloc];
}

- (UIColor *)colorAtIndex:(unsigned int)index {
	// TODO(allen): The logic here is pretty ad hoc and could use some
	// some helpful comments describing whats its doing.	It seems to work?	 
	if (index & COLOR_CODE_MASK) {
		switch (index) {
			case CURSOR_TEXT:
				return _foregroundCursor;
			case CURSOR_BG:
				return _backgroundCursor;
			case BG_COLOR_CODE:
				return _background;
			default:
				if (index & BOLD_MASK) {
					if (index - BOLD_MASK == BG_COLOR_CODE) {
						return _background;
					} else {
						return _foregroundBold;
					}
				} else {
					return _foreground;
				}
		}
	} else {
		index &= 0xff;
		if (index < 16) {
			return _table[index];
		} else if (index < 232) {
			index -= 16;
			float components[] = {
				(index / 36) ? ((index / 36) * 40 + 55) / 256.0 : 0,
				(index % 36) / 6 ? (((index % 36) / 6) * 40 + 55 ) / 256.0 : 0,
				(index % 6) ? ((index % 6) * 40 + 55) / 256.0 : 0,
				1.0
			};
			return [UIColor colorWithRed:components[0] green:components[1] blue:components[2] alpha:1.0f];
		} else {
			return _foreground;
		}
	}
}

@end

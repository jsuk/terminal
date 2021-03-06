// FontMetrics.m
// MobileTerminal

#import "FontMetrics.h"

@implementation FontMetrics

- (instancetype)initWithFont:(UIFont *)uiFont {
	self = [super init];
	
	if (self) {
		_font = [uiFont retain];
		
		CGFontRef ctFont = (__bridge CGFontRef)_font;
		NSAssert(ctFont != NULL, @"Error in CTFontCreateWithName");
		
		// This creates a CoreText line that isn't drawn, but used to get the
		// size of a single character. This will probably fail miserably if used
		// with a non-monospaced font.
		//CFStringRef string = CFSTR("A");
    NSMutableAttributedString *str = [[NSMutableAttributedString alloc] initWithString:@"A" attributes:nil];
		//CFMutableAttributedStringRef attrString = CFAttributedStringCreateMutable(kCFAllocatorDefault, 0);
		CFMutableAttributedStringRef attrString = (__bridge CFMutableAttributedStringRef)str;
		//CFAttributedStringReplaceString(attrString, CFRangeMake(0, 0), string);	 
		//CFAttributedStringSetAttribute(attrString, CFRangeMake(0, CFStringGetLength(string)), kCTFontAttributeName, ctFont);
		CTLineRef line = CTLineCreateWithAttributedString(attrString);
		NSLog(@"CRASH POINT %@", attrString);
		CGFloat width = CTLineGetTypographicBounds(line, &_ascent, &_descent, &_leading);
		
		CFRelease(line);
		CFRelease(attrString);
		CFRelease(ctFont);
		
		_boundingBox = CGSizeMake(width, _ascent + _descent + _leading);
		//NSLog(@"boundingBox %@", _boundingBox);
	}
	
	return self;
}

- (void) dealloc {
	[_font release];
	[super dealloc];
}

@end

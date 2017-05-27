// VT100RowView.m
// MobileTerminal

#import "VT100RowView.h"

#import "FontMetrics.h"
#import "VT100StringSupplier.h"
#import "VT100Types.h"

extern NSString *const kBackgroundColorAttributeName;
@implementation VT100RowView

@synthesize rowIndex;
@synthesize stringSupplier;
@synthesize fontMetrics;

- (CFAttributedStringRef)newAttributedString
{
  //UIFont *ctFont = [fontMetrics font];    
  CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
  CGFloat components[] = { 1.0, 1.0, 0.0, 0.8 };
  CGColorRef red = CGColorCreate(rgbColorSpace, components);
  NSString *string = [stringSupplier stringForLine:rowIndex];
  NSLog(@"line %d %@", string.length, string);
  // Make a new copy of the line of text with the correct font
  //int length = string.length; //(int)CFAttributedStringGetLength(string);
  //int length = string.length; //(int)CFAttributedStringGetLength(string);
  NSMutableAttributedString *stringWithFont = [[NSMutableAttributedString alloc] initWithString:string];

  //CFMutableAttributedStringRef stringWithFont =
  //    CFAttributedStringCreateMutable(kCFAllocatorDefault, length);
  //CFAttributedStringSetAttribute(stringWithFont, CFRangeMake(0, length),
  //                               kCTFontAttributeName, ctFont);
  //CFAttributedStringReplaceString((CFMutableAttributedStringRef)stringWithFont, CFRangeMake(0, 0), (__bridge CFStringRef)string);
  CFAttributedStringSetAttribute((CFMutableAttributedStringRef)stringWithFont, CFRangeMake(0, string.length), kCTForegroundColorAttributeName, red);
  CFRelease(string);
  return (CFAttributedStringRef)stringWithFont;
}

- (float)textOffset
{
  // The base line of the text from the top of the row plus some offset for the
  // glyph descent.  This assumes that the frame size for this cell is based on
  // the same font metrics
  //float glyphHeight = [fontMetrics boundingBox].height;
  //float glyphDescent = [fontMetrics descent];  
  return 20.f;//glyphHeight - glyphDescent;
}

// Convert a range of characters in a string to the rect where they are drawn
- (CGRect)rectFromRange:(CFRange)range
{
  CGSize characterBox = [fontMetrics boundingBox];
  return CGRectMake(characterBox.width * range.location, 0.0f,
                    characterBox.width * range.length, characterBox.height);
}


- (void)drawBackground:(CGContextRef)context
             forString:(CFAttributedStringRef)attributedString
{
  // Paints the background in as few steps as possible by finding common runs
  // of text with the same attributes.
  CFRange remaining =
      CFRangeMake(0, CFAttributedStringGetLength(attributedString));  
  while (remaining.length > 0) {
    CFRange effectiveRange;
    CGColorRef backgroundColor =
        (CGColorRef) CFAttributedStringGetAttribute(
            attributedString, remaining.location, (CFStringRef)kBackgroundColorAttributeName,
            &effectiveRange);
    CGContextSetFillColorWithColor(context, backgroundColor);
    CGContextFillRect(context, [self rectFromRange:effectiveRange]);
    
    remaining.length -= effectiveRange.length;
    remaining.location += effectiveRange.length;
  }
}

- (void)drawRect:(CGRect)rect
{
  //NSAssert(fontMetrics != nil, @"fontMetrics not initialized");
  //NSAssert(stringSupplier != nil, @"stringSupplier not initialized");
  CGContextRef context = UIGraphicsGetCurrentContext();
  //NSDictionary *attributesdict = [NSDictionary dictionaryWithObjectsAndKeys: 
  CFAttributedStringRef attributedString = [self newAttributedString];
  NSLog(@"attrStr %@", attributedString);
  //[self drawBackground:context forString:attributedString];
  //[self drawBackground:context forString:@"attributedString"];

  // By default, text is drawn upside down.  Apply a transformation to turn
  // orient the text correctly.
  CGAffineTransform xform = CGAffineTransformMake(1.0, 0.0, 0.0, -1.0, 0.0, 0.0);
  CGContextSetTextMatrix(context, xform);
  CGContextSetTextPosition(context, 0, [self textOffset]);
  CTLineRef line = CTLineCreateWithAttributedString(attributedString);
  CTLineDraw(line, context);
  CFRelease(line);
  CFRelease(attributedString);
}

@end

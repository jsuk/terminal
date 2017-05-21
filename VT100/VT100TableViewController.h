// VT100TableViewController.h
// MobileTerminal


#import <UIKit/UIKit.h>

@class VT100ColorMap;
@class FontMetrics;
@protocol AttributedStringSupplier;

@interface VT100TableViewController : UITableViewController {
@private
  VT100ColorMap* colorMap;
  FontMetrics* fontMetrics;
  id<AttributedStringSupplier> stringSupplier;
}

- (id)initWithColorMap:(VT100ColorMap*)colorMap;

@property (nonatomic, retain) FontMetrics* fontMetrics;
@property (nonatomic, retain) id<AttributedStringSupplier> stringSupplier;

- (void)refresh;

@end

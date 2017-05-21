// TerminalKeyboard.h
// MobileTerminal

#import <UIKit/UIKit.h>

// Protocol implemented by listener of keyboard events
@protocol TerminalInputProtocol
@required
- (void)receiveKeyboardInput:(NSData*)data;
@end

@protocol TerminalKeyboardProtocol <TerminalInputProtocol>
@required
- (void)fillDataWithSelection:(NSMutableData*)data;
@end


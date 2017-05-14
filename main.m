#import "TerminalAppDelegate.h"
#import "TerminalRootViewController.h"

int main(int argc, char *argv[]) {
  @autoreleasepool {
    return UIApplicationMain(argc, argv, @"Application", NSStringFromClass(TerminalAppDelegate.class));
  }
}

@interface Application : UIApplication
@end
@implementation Application

// Calculation of offsets for traversing GSEventRef:
// Count the size of types inside CGEventRecord struct
// https://github.com/kennytm/iphone-private-frameworks/blob/master/GraphicsServices/GSEvent.h

// typedef struct GSEventRecord {
//        GSEventType type; // 0x8 //2
//        GSEventSubType subtype;    // 0xC //3
//        CGPoint location;     // 0x10 //4
//        CGPoint windowLocation;    // 0x18 //6
//        int windowContextId;    // 0x20 //8
//        uint64_t timestamp;    // 0x24, from mach_absolute_time //9
//        GSWindowRef window;    // 0x2C //
//        GSEventFlags flags;    // 0x30 //12
//        unsigned senderPID;    // 0x34 //13
//        CFIndex infoSize; // 0x38 //14
// } GSEventRecord;

// typedef struct GSEventKey {
//        GSEvent _super;
//        UniChar keycode, characterIgnoringModifier, character;    // 0x38, 0x3A, 0x3C // 15 and start of 16
//        short characterSet;        // 0x3E // end of 16
//        Boolean isKeyRepeating;    // 0x40 // start of 17
// } GSEventKey;

#define GSEVENT_TYPE 2
//#define GSEVENT_SUBTYPE 3
//#define GSEVENT_LOCATION 4
//#define GSEVENT_WINLOCATION 6
//#define GSEVENT_WINCONTEXTID 8
//#define GSEVENT_TIMESTAMP 9
//#define GSEVENT_WINREF 11
#define GSEVENT_FLAGS 12
//#define GSEVENT_SENDERPID 13
//#define GSEVENT_INFOSIZE 14

#define GSEVENTKEY_KEYCODE_CHARIGNORINGMOD 15
//#define GSEVENTKEY_CHARSET_CHARSET 16
//#define GSEVENTKEY_ISKEYREPEATING 17 // ??

#define GSEVENT_TYPE_KEYDOWN 10
#define GSEVENT_TYPE_KEYUP 11

NSString *const UIEventGSEventKeyUpNotification = @"UIEventGSEventKeyUpNotification";
NSString *const UIEventGSEventKeyDownNotification = @"UIEventGSEventKeyDownNotification";

- (void)sendEvent:(UIEvent *)event
{
    [super sendEvent:event];

    if ([event respondsToSelector:@selector(_gsEvent)]) {
        // Hardware Key events are of kind UIInternalEvent which are a wrapper of GSEventRef which is wrapper of GSEventRecord
        int *eventMemory = (int *)[event performSelector:@selector(_gsEvent)];
        int eventType = eventMemory[GSEVENT_TYPE];
        int flags = eventMemory[GSEVENT_FLAGS];
        int tmp = eventMemory[15];
        char *keycode = (char *)&tmp; // Cast to silent warning
        char key = keycode[0];
        [self keyboardWithCode:key event:eventType flag:flags];
        TerminalAppDelegate *delegate = self.delegate;
        TerminalRootViewController *c = (TerminalRootViewController *)delegate.rootViewController.topViewController;
        if (eventMemory) {
            
            NSLog(@"#event type = %d", eventType);
            if (eventType == GSEVENT_TYPE_KEYDOWN) {
              [self keyDownWithCode:key flag:flags];  
            }
            else if (eventType == GSEVENT_TYPE_KEYUP) {
              [self keyUpWithCode:key flag:flags];
            } else if(1 == 0) {
                // Since the event type is key up we can assume is a GSEventKey struct
                // Get flags from GSEvent
                int eventFlags = eventMemory[GSEVENT_FLAGS];
                NSLog(@"event flags %d", eventFlags);
                if (eventFlags) { 
                    NSLog(@"flags %8X", eventFlags);
                    // Only post notifications when Shift, Ctrl, Cmd or Alt key were pressed.

                    // Get keycode from GSEventKey
                    int tmp = eventMemory[15];
                    UniChar *keycode = (UniChar *)&tmp; // Cast to silent warning
                    //tmp = (tmp & 0xFF00);
                    //tmp = tmp >> 16;
                    //UniChar keycode = tmp;
                    //tmp = eventMemory[16];
                    //tmp = (tmp & 0x00FF);
                    //tmp = tmp << 16;
                    //UniChar keycode = tmp;
                    NSLog(@"keycode %d", keycode[0]);
                    NSLog(@"Shift Ctrl Alt Ctrl %d %d %d %d\n ", (eventFlags&(1<<17))?1:0, (eventFlags&(1<<18))?1:0, (eventFlags&(1<<19))?1:0, (eventFlags&(1<<20))?1:0 );
                    
                    NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithShort:keycode[0]], @"keycode", [NSNumber numberWithInt:eventFlags], @"eventFlags", nil];
                    [[NSNotificationCenter defaultCenter] postNotificationName:UIEventGSEventKeyUpNotification object:nil userInfo:userInfo];

                    fflush(stderr);
                    /* 
                     Some Keycodes found
                     ===================

                     Alphabet
                     a = 4
                     b = 5
                     c = ...
                     z = 29
                     
                     Numbers
                     1 = 30
                     2 = 31
                     3 = ...
                     9 = 38
                     
                     Arrows
                     Right = 79
                     Left = 80
                     Down = 81
                     Up = 82
                     
                     Flags found (Differ from Kenny's header)
                     ========================================
                     
                     Cmd = 1 << 17
                     Shift = 1 << 18
                     Ctrl = 1 << 19
                     Alt = 1 << 20
                     
                     */
                  if (keycode[0] == 6 && flags > 0) {
                    char *control = "\x03";
                    NSLog(@"######## CTRL %d", control[0]);
                    [c.sub.fileHandle writeData:[NSData dataWithBytes:control length:strlen(control)]];
                  } else if ((keycode[0] >= 4 && keycode[0] <= 44) || keycode[0] == 40) {
                    const char *map = "    abcdefghijklmnopqrstuvwxyz1234567890\n \b\t ";
                    const char *cc = map + keycode[0];
                    NSData *data = [NSData dataWithBytes:cc length:1];
                    [c.sub.fileHandle writeData:data];
                  }
                } else {
                  /*
                  int tmp = eventMemory[15];
                  char *keycode = (char *)&tmp; // Cast to silent warning
                  // NSLog(@"no flag  keycode  %d", keycode[0]);
                  const char *map = "    abcdefghijklmnopqrstuvwxyz1234567890\n \b\t ";
                  if ((keycode[0] >= 4 && keycode[0] <= 44) || keycode[0] == 40) {
                    [c.sub.fileHandle writeData:[NSData dataWithBytes:map + keycode[0] length:1]];
                  }
                  */
                }
            }
        }
    }
}

- (void)keyboardWithCode:(unsigned long)code event:(unsigned long)event flag:(unsigned long)flag {
  NSLog(@"code %lu (%02lXh)", code, code);
  NSLog(@"event %ld", event);
  NSLog(@"flag %02lXh %lu", flag, flag);
}

- (void)keyDownWithCode:(unsigned long)key flag:(unsigned long)flags {
  NSDictionary *userInfo = [[NSDictionary alloc] initWithObjectsAndKeys:[NSNumber numberWithShort:key], @"keycode", [NSNumber numberWithInt:flags], @"eventFlags", nil];
  [[NSNotificationCenter defaultCenter] postNotificationName:UIEventGSEventKeyDownNotification object:nil userInfo:userInfo];

  TerminalAppDelegate *delegate = self.delegate;
  TerminalRootViewController *c = (TerminalRootViewController *)delegate.rootViewController.topViewController;
  if (key == 6 && flags > 0) {
    char *control = "\x03";
    NSLog(@"######## CTRL %d", control[0]);
    [c.sub.fileHandle writeData:[NSData dataWithBytes:control length:strlen(control)]];
  } else if ((key >= 4 && key <= 44) || key == 40) {
    const char *map = "    abcdefghijklmnopqrstuvwxyz1234567890\n \b\t ";
    const char *cc = map + key;
    NSData *data = [NSData dataWithBytes:cc length:1];
    [c.sub.fileHandle writeData:data];
  }
}

- (void)keyUpWithCode:(unsigned long)key flag:(unsigned long)flags {
  
}

@end


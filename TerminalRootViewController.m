#import "TerminalRootViewController.h"
#import "SubProcess/SubProcess.h"
#import "SubProcess/PTY.h"
#import "TerminalView.h"

extern NSString *const UIEventGSEventKeyUpNotification;
extern NSString *const UIEventGSEventKeyDownNotification;

@implementation TerminalRootViewController {
	NSMutableArray *_objects;
  SubProcess *_sub;
  TerminalView *terminal;
}

- (void)loadView {
	[super loadView];
  terminal = [[TerminalView alloc] init];
  NSLog(@"loadView frame width %f", self.view.frame.size.width);
  [self.view addSubview:terminal];
  terminal.backgroundColor = [UIColor redColor];
  self.view.backgroundColor = [UIColor greenColor];
	_objects = [[NSMutableArray alloc] init];

	self.title = @"Root View Controller";
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonTapped:)] autorelease];
  [terminal startSubProcess];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyPressedDown:) name:UIEventGSEventKeyDownNotification object:nil];
}

- (void)viewWillLayoutSubviews {
  [super viewWillLayoutSubviews];
  terminal.frame  = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
}

- (void)addButtonTapped:(id)sender {
	[_objects insertObject:[NSDate date] atIndex:0];
	//[self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ] withRowAnimation:UITableViewRowAnimationAutomatic];
  _sub = [[SubProcess alloc] init];
  [_sub start];
  [[PTY alloc] initWithFileHandle:_sub.fileHandle];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:NSFileHandleReadCompletionNotification object:[_sub fileHandle]];
  [[_sub fileHandle] readInBackgroundAndNotify];

}

- (void)keyPressedDown:(NSNotification *)aNotification {
  NSNumber *keycode = [[aNotification userInfo] objectForKey:@"keycode"];
  NSNumber *flag = [[aNotification userInfo] objectForKey:@"flags"];
  int key = [keycode integerValue];
  int flags = [flag integerValue];
  char *cc;
  if (key == 6 && flags > 0) {
    char *control = "\x03";
    NSLog(@"######## CTRL %d", control[0]);
    //[c.sub.fileHandle writeData:[NSData dataWithBytes:control length:strlen(control)]];
    cc = control;
  } else if ((key >= 4 && key <= 44) || key == 40) {
    char *map = "    abcdefghijklmnopqrstuvwxyz1234567890\n \b\t ";
    cc = map + key;
  } else {
    return;
  }

  NSData *data = [NSData dataWithBytes:cc length:1];
  NSLog(@"TerminalView keyPressedDown %@", data);
  [terminal receiveKeyboardInput:data];
}

static const char* kProcessExitedMessage = "Process completed!";
//static const char* kLS= "ls\n";
- (void)dataAvailable:(NSNotification *)aNotification {
  
  NSData *data = [[aNotification userInfo] objectForKey:NSFileHandleNotificationDataItem];
  if ([data length] == 0) {
    NSData *message = [NSData dataWithBytes:kProcessExitedMessage length:strlen(kProcessExitedMessage)];
    NSLog(@"%@", message);
    [_sub stop];
    return;
  }

  NSLog(@"dataAvailable %d", [data length]);
  NSLog(@"dataAvailable %@", [NSString stringWithUTF8String:[data bytes]]);
  //if ([data length] % 2 == 0) {
  //  [[_sub fileHandle] writeData:[NSData dataWithBytes:kLS length:strlen(kLS)]];
  //}
  [[_sub fileHandle] readInBackgroundAndNotify];
}

#pragma mark - Table View Data Source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return _objects.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"Cell";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];

	if (!cell) {
		cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	}

	NSDate *date = [_objects objectAtIndex:indexPath.row];
	cell.textLabel.text = date.description;
	return cell;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
	[_objects removeObjectAtIndex:indexPath.row];
	[tableView deleteRowsAtIndexPaths:@[ indexPath ] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
  return YES;
}

#pragma mark - Table View Delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

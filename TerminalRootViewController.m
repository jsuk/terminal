#import "TerminalRootViewController.h"
#import "SubProcess/SubProcess.h"
#import "SubProcess/PTY.h"

extern NSString *const UIEventGSEventKeyUpNotification;
extern NSString *const UIEventGSEventKeyDownNotification;

@implementation TerminalRootViewController {
	NSMutableArray *_objects;
//  SubProcess *_sub;
}

- (void)loadView {
	[super loadView];

	_objects = [[NSMutableArray alloc] init];

	self.title = @"Root View Controller";
	self.navigationItem.leftBarButtonItem = self.editButtonItem;
	self.navigationItem.rightBarButtonItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addButtonTapped:)] autorelease];
}

- (void)addButtonTapped:(id)sender {
	[_objects insertObject:[NSDate date] atIndex:0];
	[self.tableView insertRowsAtIndexPaths:@[ [NSIndexPath indexPathForRow:0 inSection:0] ] withRowAnimation:UITableViewRowAnimationAutomatic];
  _sub = [[SubProcess alloc] init];
  [_sub start];
  [[PTY alloc] initWithFileHandle:_sub.fileHandle];

  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(dataAvailable:) name:NSFileHandleReadCompletionNotification object:[_sub fileHandle]];
  [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyPressedDown:) name:UIEventGSEventKeyDownNotification object:nil];
  [[_sub fileHandle] readInBackgroundAndNotify];

}

- (void)keyPressedDown:(NSNotification *)aNotification {
  //NSData *data = [[aNotification userInfo] objectForKey:UIEventGSEventKeyDownNotification];
  NSLog(@"keyPressedDown %@", [aNotification userInfo]);
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

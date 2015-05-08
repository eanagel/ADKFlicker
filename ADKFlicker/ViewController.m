//
//  ViewController.m
//  ADKFlicker
//
//  Created by Ethan Nagel on 5/4/15.
//  Copyright (c) 2015 Ethan Nagel. All rights reserved.
//

#import <AsyncDisplayKit.h>

#import "ViewController.h"

#import "ViewController+TestData.h"

//#define SIMPLE_SCROLL_TO_END

static void *KVO_contentSize = &KVO_contentSize;


@interface ViewController () <ASTableViewDataSource, ASTableViewDelegate>

@property (weak, nonatomic) IBOutlet ASTableView *tableView;
@property (nonatomic) NSMutableArray *messages;
@property (nonatomic,readonly) NSArray *testData;

@end

@implementation ViewController {
  NSArray *_testData;
  BOOL _scrolling;
  BOOL _testRunning;
}

#pragma mark - UIViewController overrides

- (void)viewDidLoad {
  [super viewDidLoad];
  self.edgesForExtendedLayout = UIRectEdgeNone;
  self.automaticallyAdjustsScrollViewInsets = NO;

  self.title = @"ADK Cell Flicker Test";

  self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Start Test" style:UIBarButtonItemStylePlain target:self action:@selector(testAction)];

  self.messages = [[self testData] mutableCopy];

  [self.tableView addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(contentSize))
                      options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                      context:KVO_contentSize];

  self.tableView.asyncDelegate = self;
  self.tableView.asyncDataSource = self;

  self.messages = [[NSMutableArray alloc] init];
  [self.tableView reloadData];
}

- (void)dealloc
{
  if (self.isViewLoaded) {
    [self.tableView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) context:KVO_contentSize];
  }
}

#pragma mark - Test

- (void)testAction {
  _testRunning = !_testRunning;

  self.navigationItem.rightBarButtonItem.title = (_testRunning)  ? @"Stop Test" : @"Start Test";

  if ( _testRunning ) {
    [self doTest];
  }
}

-(void)doTest {
  if (!_testRunning) {
    return ;
  }

  const double MS = 0.50; // ms between each message add

  [self addMessage:[self randomMessage]];

  [self performSelector:@selector(doTest) withObject:nil afterDelay:MS];
}

#pragma mark - Data

- (NSArray *)testData {
  if (!_testData) {
    _testData = [self loadTestData];
  }

  return _testData;
}

- (NSString *)randomMessage {
  return self.testData[arc4random() % self.testData.count];
}

- (void)addMessage:(NSString *)message {
  [self.messages addObject:message];

  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:self.messages.count-1 inSection:0];

  // the following happens asynchronously, so we can't actually start scrolling to the new item here :(

  [self.tableView insertRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];

  // Suggestion: if we are going to continue making insert/delete etc async maybe we could add a completion handler
  // to endUpdates (at a minimum), so you can get a signal when the tableview is actually updated.
}

#pragma mark - KVO

// With ASTableView it's pretty difficult to figure out when new cells have actually been inserted into the TableView,
// so instead of the simpler [tableView insert...] followed by [tableView scrollToRowAtIndexPath:] approach we notice
// when the content size changes and scroll to the bottom of it. This approach seems to work  fine with a standard
// UITableView (see UITableView branch for an example)

- (void)handleContentSizeChangedFrom:(CGFloat)oldValue to:(CGFloat)newValue {
  NSLog(@"contentHeight changed from %f to %f, actual = %f", oldValue, newValue, self.tableView.contentSize.height);

  [self scrollToEnd];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
  if (object == self.tableView && context == KVO_contentSize) {
    CGFloat oldValue = [change[NSKeyValueChangeOldKey] CGSizeValue].height;
    CGFloat newValue = [change[NSKeyValueChangeNewKey] CGSizeValue].height;

    if (oldValue != newValue) {
      [self handleContentSizeChangedFrom:oldValue to:newValue];
    }
  } else {
    [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
  }
}

#pragma mark - Scroll to End

#ifdef SIMPLE_SCROLL_TO_END

// So, the simple approach just blindly scrolls to the end of the content when the contentSize changes (that's this version)
// The thing is, this can happen when we are alrreeady scrolling, which seems like it might cause a problem. (Ok it shouldn't
// but you know maybe.)
// So, I've added an alternate implementation (#else) that prevents calls to set the content offset while we are already
// scrolling. This DOES NOT fix our problem, but it seems like the descent thing to do. If you want a simple use case
// you can #define SIMPLE_SCROLL_TO_END

- (void)scrollToEnd {
  CGFloat newScrollPos = self.tableView.contentSize.height - self.tableView.bounds.size.height;

  if(newScrollPos != self.tableView.contentOffset.y && newScrollPos >= -self.tableView.contentInset.top) {
    NSLog(@"Scrolling to %f (simple)", newScrollPos);
    [self.tableView setContentOffset:CGPointMake(0, newScrollPos) animated:YES];
  }
}

#else

- (void)scrollToEnd {
  if (_scrolling) {
    NSLog(@"Ignoring concurrent scroll request");
    return ;
  }

  CGFloat newScrollPos = self.tableView.contentSize.height - self.tableView.bounds.size.height;

  if(newScrollPos != self.tableView.contentOffset.y && newScrollPos >= -self.tableView.contentInset.top) {
    _scrolling = YES;
    NSLog(@"Scrolling to %f", newScrollPos);

    // to be extra safe, delay scroll start to the next run loop
    dispatch_async(dispatch_get_main_queue(), ^{
      [self.tableView setContentOffset:CGPointMake(0, newScrollPos) animated:YES];
    });
  }
}

-(void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView {
  // Code here works with scrollToEnd to prevent concurrent calls to setContentOffset:animated:YES
  // While still scrolling to the end consistently.

  if ( _scrolling ) {
    _scrolling = NO;
    NSLog(@"Done scrolling");
    [self scrollToEnd]; // continue scrolling if more content was added while we were scrolling
  }
}

#endif

#pragma mark - ASTableViewDataSource/Delegate

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.messages.count;
}

-(ASCellNode *)tableView:(ASTableView *)tableView nodeForRowAtIndexPath:(NSIndexPath *)indexPath {
  ASTextCellNode *node = [[ASTextCellNode alloc] init];
  node.text = self.messages[indexPath.row];
  node.backgroundColor = (indexPath.row%2) ? [[UIColor redColor] colorWithAlphaComponent:0.25] : [[UIColor greenColor] colorWithAlphaComponent:0.25];

  return node;
}

@end

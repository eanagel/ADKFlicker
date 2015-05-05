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

static void *KVO_contentSize = &KVO_contentSize;


@interface ViewController () <ASTableViewDataSource, ASTableViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet ASTableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (nonatomic) NSMutableArray *messages;

@end

@implementation ViewController {
  BOOL _scrolling;
}

#pragma mark - UIViewController overrides

- (void)viewDidLoad {
  [super viewDidLoad];
  self.edgesForExtendedLayout = UIRectEdgeNone;
  self.automaticallyAdjustsScrollViewInsets = NO;

  self.title = @"ADK Cell Flicker Test";

  self.messages = [[self testData] mutableCopy];

  self.textField.delegate = self;
  self.tableView.asyncDelegate = self;
  self.tableView.asyncDataSource = self;

  [self.tableView addObserver:self
                   forKeyPath:NSStringFromSelector(@selector(contentSize))
                      options:NSKeyValueObservingOptionOld | NSKeyValueObservingOptionNew
                      context:KVO_contentSize];

    // Simulate async data fetch...

    __weak ViewController *weakSelf = self;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
      [weakSelf queryAvailable:[self testData]];
    });
}

- (void)dealloc
{
  if (self.isViewLoaded) {
    [self.tableView removeObserver:self forKeyPath:NSStringFromSelector(@selector(contentSize)) context:KVO_contentSize];
  }
}

#pragma mark - Data

- (void)queryAvailable:(NSArray *)messages {
  self.messages = [messages mutableCopy];
  [self.tableView reloadData];
}

- (void)addMessage:(NSString *)message {
  [self.messages addObject:message];

  [self.tableView insertRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:self.messages.count-1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Scroll to End

- (void)scrollToEnd {
  if (_scrolling) {
    NSLog(@"Ignoring concurrent scroll request");
    return ;
  }

  CGFloat newScrollPos = self.tableView.contentSize.height - self.tableView.bounds.size.height;

  if(newScrollPos != self.tableView.contentOffset.y && newScrollPos >= -self.tableView.contentInset.top) {
    _scrolling = YES;
    NSLog(@"Scrolling to %f", newScrollPos);

    [self.tableView setContentOffset:CGPointMake(0, newScrollPos) animated:YES];
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

#pragma mark - KVO

- (void)handleContentSizeChangedFrom:(CGFloat)oldValue to:(CGFloat)newValue {
  NSLog(@"contentHeight changed from %f to %f, actual = %f", oldValue, newValue, self.tableView.contentSize.height);

  // Whenever the size of the TV changes we want to scroll to the bottom (reveal newest message)
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

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self addMessage:textField.text];
  textField.text = @"";
  return YES;
}

@end

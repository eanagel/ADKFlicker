//
//  ViewController.m
//  ADKFlicker
//
//  Created by Ethan Nagel on 5/4/15.
//  Copyright (c) 2015 Ethan Nagel. All rights reserved.
//

//#import <AsyncDisplayKit.h>

#import "ViewController.h"

#import "ViewController+TestData.h"

#import "TableViewCell.h"

static void *KVO_contentSize = &KVO_contentSize;


@interface ViewController () <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate>

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *textField;
@property (nonatomic) NSMutableArray *messages;
@property (nonatomic,readonly) TableViewCell *sizingCell;

@end

@implementation ViewController {
  BOOL _scrolling;
  TableViewCell *_sizingCell;
}

#pragma mark - UIViewController overrides

- (void)viewDidLoad {
  [super viewDidLoad];
  self.edgesForExtendedLayout = UIRectEdgeNone;
  self.automaticallyAdjustsScrollViewInsets = NO;

  self.title = @"ADK Cell Flicker Test";

  self.messages = [[self testData] mutableCopy];

  self.textField.delegate = self;

  [self.tableView registerNib:[TableViewCell nib] forCellReuseIdentifier:[TableViewCell reuseIdentifier]];
  self.tableView.delegate = self;
  self.tableView.dataSource = self;

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

#pragma mark - UITableViewDataSource/Delegate


-(TableViewCell *)sizingCell {
  if (!_sizingCell) {
    _sizingCell = [TableViewCell tableViewCell];
  }

  return _sizingCell;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return self.messages.count;
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
  TableViewCell *sizingCell = self.sizingCell;

  sizingCell.bounds = CGRectMake(0, 0, CGRectGetWidth(tableView.bounds), CGRectGetHeight(sizingCell.bounds));

  [sizingCell configureWithMessage:self.messages[indexPath.row]];

  [sizingCell setNeedsUpdateConstraints];
  [sizingCell updateConstraintsIfNeeded];

  [sizingCell setNeedsLayout];
  [sizingCell layoutIfNeeded];

  CGFloat height = [sizingCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;

  return height + 1;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    TableViewCell *cell = (TableViewCell *)[self.tableView dequeueReusableCellWithIdentifier:[TableViewCell reuseIdentifier] forIndexPath:indexPath];

    [cell configureWithMessage:self.messages[indexPath.row]];

    cell.contentView.backgroundColor = (indexPath.row%2) ? [[UIColor redColor] colorWithAlphaComponent:0.25] : [[UIColor greenColor] colorWithAlphaComponent:0.25];
    
    return cell;
}

#pragma mark - UITextFieldDelegate

-(BOOL)textFieldShouldReturn:(UITextField *)textField {
  [self addMessage:textField.text];
  textField.text = @"";
  return YES;
}

@end

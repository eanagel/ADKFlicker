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


@interface ViewController () <ASTableViewDataSource, ASTableViewDelegate>

@property (weak, nonatomic) IBOutlet ASTableView *tableView;
@property (nonatomic) NSMutableArray *messages;
@property (nonatomic,readonly) NSArray *testData;

@end

@implementation ViewController {
  NSArray *_testData;
  BOOL _testRunning;
}

#pragma mark - UIViewController overrides

- (void)viewDidLoad {
  [super viewDidLoad];
  self.edgesForExtendedLayout = UIRectEdgeNone;
  self.automaticallyAdjustsScrollViewInsets = NO;

  self.title = @"ADK Cell Flicker Test 2.0";

  self.messages = [[self testData] mutableCopy];

  self.tableView.asyncDelegate = self;
  self.tableView.asyncDataSource = self;

  self.messages = [[NSMutableArray alloc] init];

  for (int x=0; x<25; x++) {
    [self.messages addObject:[self randomMessage]];
  }

  [self.tableView reloadData];
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

- (void)toggleLikeAtIndexPath:(NSIndexPath *)indexPath {
    NSString *likeMessage = @"\n----------\nYou Like This!";
    NSString *message = self.messages[indexPath.row];

    if ( [message hasSuffix:likeMessage] ) {
        message = [message substringToIndex:message.length - likeMessage.length];
    } else {
        message = [message stringByAppendingString:likeMessage];
    }

    self.messages[indexPath.row] = message;
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

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {

    [self.tableView beginUpdates];

    [self toggleLikeAtIndexPath:indexPath];
    [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    
    [self.tableView endUpdates];
}

@end

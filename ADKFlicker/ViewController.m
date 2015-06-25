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
@property (nonatomic) NSMutableArray *sections;
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

  [self loadData];

  self.tableView.asyncDelegate = self;
  self.tableView.asyncDataSource = self;

  [self.tableView reloadData];

  self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Test" style:UIBarButtonItemStylePlain target:self action:@selector(testAction:)];
}


- (void)testAction:(id)sender {

  BOOL (^isAfter)(NSIndexPath *, NSIndexPath *) = ^BOOL(NSIndexPath *indexPath, NSIndexPath *anchor) {
    if (!anchor || !indexPath) {
      return NO;
    }
    if (indexPath.section == anchor.section) {
      return (indexPath.row == anchor.row+1); // assumes that indexes are valid

    } else if (indexPath.section > anchor.section && indexPath.row == 0) {
      if (anchor.row != [self.tableView numberOfRowsInSection:anchor.section] -1) {
        return NO;  // anchor is not at the end of the section
      }

      NSInteger nextSection = anchor.section+1;
      while([self.tableView numberOfRowsInSection:nextSection] == 0) {
        ++nextSection;
      }

      return indexPath.section == nextSection;
    }

    return NO;
  };

  BOOL (^isBefore)(NSIndexPath *, NSIndexPath *) = ^BOOL(NSIndexPath *indexPath, NSIndexPath *anchor) {
    return isAfter(anchor, indexPath);
  };

  NSMutableArray *indexPaths = [NSMutableArray array];

  for(int sectionIndex=0; sectionIndex<[self.tableView numberOfSections]; sectionIndex++) {
    for(int rowIndex=0; rowIndex<[self.tableView numberOfRowsInSection:sectionIndex]; rowIndex++) {
      [indexPaths addObject:[NSIndexPath indexPathForRow:rowIndex inSection:sectionIndex]];
    }
  }

  for(int anchorIndex=0; anchorIndex<indexPaths.count; anchorIndex++) {
    for(int itemIndex=0; itemIndex<indexPaths.count; itemIndex++) {
      NSIndexPath *anchor = indexPaths[anchorIndex];
      NSIndexPath *item = indexPaths[itemIndex];

      BOOL expected, actual;

      expected = (anchorIndex + 1) == itemIndex;
      actual = isAfter(item, anchor);

      if (expected != actual) {
        NSLog(@"isAfter(%@, %@) Test Failed!", item, anchor);
        actual = isAfter(item, anchor);
      }

      expected = (anchorIndex - 1) == itemIndex;
      actual = isBefore(item, anchor);

      if (expected != actual) {
        NSLog(@"isBefore(%@, %@) Test Failed!", item, anchor);
        actual = isBefore(item, anchor);
      }
    }
  }

}

#pragma mark - Data

- (void)loadData {
  NSMutableArray *sections = [[NSMutableArray alloc] init];

  NSArray *rowCounts = @[@(3), @(5), @(1), @(2), @(0), @(5)];

  for (int sectionIndex=0; sectionIndex<rowCounts.count; sectionIndex++) {
    int numRows = [rowCounts[sectionIndex] intValue];

    NSMutableArray *rows = [NSMutableArray array];

    for(int rowIndex=0; rowIndex<numRows; rowIndex++) {
      [rows addObject:[self randomMessage]];
    }

    [sections addObject:@{@"title": [NSString stringWithFormat:@"Section %d", sectionIndex],
                               @"rows": rows}];
  }

  self.sections = sections;
}

- (NSArray *)testData {
  if (!_testData) {
    _testData = [self loadTestData];
  }

  return _testData;
}

- (NSString *)randomMessage {
  return self.testData[arc4random() % self.testData.count];
}


#pragma mark - ASTableViewDataSource/Delegate


-(NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
  return self.sections.count;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  NSMutableArray *rows =  [self.sections[section] valueForKey:@"rows"];
  return rows.count;
}

-(NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section {
  return [self.sections[section] valueForKey:@"title"];
}

-(ASCellNode *)tableView:(ASTableView *)tableView nodeForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSMutableArray *rows =  [self.sections[indexPath.section] valueForKey:@"rows"];
  NSString *message = rows[indexPath.row];

  ASTextCellNode *node = [[ASTextCellNode alloc] init];
  node.text = message;
  node.backgroundColor = (indexPath.row%2) ? [[UIColor redColor] colorWithAlphaComponent:0.25] : [[UIColor greenColor] colorWithAlphaComponent:0.25];

  return node;
}


@end

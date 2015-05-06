//
//  TableViewCell.m
//  ADKFlicker
//
//  Created by Ethan Nagel on 5/6/15.
//  Copyright (c) 2015 Ethan Nagel. All rights reserved.
//

#import "TableViewCell.h"

@interface TableViewCell ()

@property (weak, nonatomic) IBOutlet UILabel *myLabel;

@end

@implementation TableViewCell

+ (UINib *)nib {
  return [UINib nibWithNibName:@"TableViewCell" bundle:nil];
}

+ (NSString *)reuseIdentifier {
  return NSStringFromClass(self);
}

+(instancetype)tableViewCell {
  return [[[self nib] instantiateWithOwner:[[NSObject alloc] init] options:nil] firstObject];
}

- (NSString *)reuseIdentifier {
  return [self.class reuseIdentifier];
}

- (void)awakeFromNib {
  // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
  [super setSelected:selected animated:animated];

  // Configure the view for the selected state
}

- (void)configureWithMessage:(NSString *)message {
  self.myLabel.text = message;
  self.myLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.myLabel.bounds);
}




@end

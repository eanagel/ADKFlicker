//
//  TableViewCell.h
//  ADKFlicker
//
//  Created by Ethan Nagel on 5/6/15.
//  Copyright (c) 2015 Ethan Nagel. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TableViewCell : UITableViewCell

+(UINib *)nib;
+(NSString *)reuseIdentifier;

- (void)configureWithMessage:(NSString *)message;

@end

//
//  SELOrderListViewCell.h
//  menuapp
//
//  Created by dpcc on 2014/04/16.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SELOrderData.h"

@interface SELOrderListViewCell : UITableViewCell {
    // 円
    IBOutlet UILabel* _yen;
    // 個
    IBOutlet UILabel* _pieces;
    // キャンセルボタン
    IBOutlet UIButton* _cancelButton;
}

- (IBAction)deleteItem:(id)sender;

@property SELOrderData* orderData;
@property IBOutlet UILabel* name;
@property IBOutlet UILabel* price;
@property IBOutlet UIImageView* image;
@property IBOutlet UILabel* option;
@property IBOutlet UILabel* quantity;

@end

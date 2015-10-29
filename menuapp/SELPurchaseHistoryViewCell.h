//
//  SELPurchaseHistoryViewCell.h
//  menuapp
//
//  Created by dpcc on 2014/05/07.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SELPurchaseHistoryViewCell : UITableViewCell {
    IBOutlet UILabel* _priceLabel;
    IBOutlet UILabel* _priceYenLabel;
    IBOutlet UILabel* _totalLabel;
    IBOutlet UILabel* _totalYenLabel;
    IBOutlet UILabel* _quantityLabel;
    IBOutlet UILabel* _orderTimeLabel;
}

- (void)updateLocalizitaion;

@property IBOutlet UILabel* name;
@property IBOutlet UILabel* price;
@property IBOutlet UIImageView* image;

@property IBOutlet UILabel* quantity;
@property IBOutlet UILabel* total;
@property IBOutlet UILabel* leadtime;
@property IBOutlet UILabel* topping;
@property IBOutlet UILabel* customOrder;

@property IBOutlet UILabel* canceledLabel;

@end

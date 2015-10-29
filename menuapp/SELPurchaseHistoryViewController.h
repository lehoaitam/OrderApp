//
//  SELPurchaseHistoryViewController.h
//  menuapp
//
//  Created by dpcc on 2014/05/07.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SELOrderManager.h"

@interface SELPurchaseHistoryViewController : UIViewController<UITableViewDataSource, UITabBarDelegate, SELOrderManagerDelegate> {
    IBOutlet UITableView* _tableView;
    IBOutlet UILabel* _totalPriceLabel;
    IBOutlet UILabel* _numberOfPeopleLabel;
    IBOutlet UILabel* _splitCostLabel;
    NSInteger _totalPrice;
    NSInteger _numberOfPeople;
    
    IBOutlet UILabel* _totalAmountLabel;
    IBOutlet UILabel* _totalAmountYenLabel;
    IBOutlet UILabel* _dutchLabel;
    IBOutlet UILabel* _dutchYenLabel;
    
    IBOutlet UIButton* _closeButton;
    
    IBOutlet UIButton* _numberOfPeoplePlusButton;
    IBOutlet UIButton* _numberOfPeopleMinusButton;
}

- (IBAction)close:(id)sender;
- (IBAction)plus;
- (IBAction)minus;

@property NSArray* PurchaseHistory;

@end

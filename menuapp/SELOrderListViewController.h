//
//  SELOrderListViewController.h
//  menuapp
//
//  Created by dpcc on 2014/04/16.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SELOrderManager.h"

@interface SELOrderListViewController : UIViewController<UITableViewDataSource, UITableViewDelegate, SELOrderManagerDelegate> {
    IBOutlet UITableView* _orderListTable;
    IBOutlet UILabel* _totalLabel;
    NSInteger _sum;
    
    // 注文リスト
    IBOutlet UILabel* _orderListLabel;
    // 今回の注文合計
    IBOutlet UILabel* _totalOrderLabel;
    // 注文確定
    IBOutlet UIButton* _confirmOrderButton;
    // 注文確定(注意書き)
    IBOutlet UILabel* _confirmOrderNoteLabel;
    // 円
    IBOutlet UILabel* _yen;
}

- (IBAction)confirm:(id)sender;

@end

//
//  SELCustomOrderViewController.h
//  menuapp
//
//  Created by dpcc on 2014/04/15.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SELItemData.h"
#import "SELCustomOrderData.h"

@class SELCustomOrderViewController;
@protocol SELCustomOrderViewControllerDelegate <NSObject>

- (void)SelectedCustomOrder:(SELItemData*)selectedCustomOrder sender:(SELCustomOrderViewController*)sender;

@end

@interface SELCustomOrderViewController : UITableViewController

@property SELCustomOrderData* customOrderData;
@property id<SELCustomOrderViewControllerDelegate> delegate;

@end

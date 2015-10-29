//
//  SELToppingViewController.h
//  menuapp
//
//  Created by dpcc on 2014/05/26.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SELItemData.h"
#import "SELToppingGroupData.h"

@class SELToppingViewController;
@protocol SELToppingViewControllerDelegate <NSObject>

- (void)SelectedTopping:(NSMutableArray*)selectedToppingList sender:(SELToppingViewController*)sender;

@end

@interface SELToppingViewController : UITableViewController

@property SELToppingGroupData* toppingGroupData;
@property NSMutableArray* selectedToppingDataList;
@property id<SELToppingViewControllerDelegate> delegate;

@end

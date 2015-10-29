//
//  SELItemSelectPopoverViewController.h
//  selforder
//
//  Created by dpcc on 2014/06/02.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SELItemData.h"

@class SELItemSelectPopoverViewController;
@protocol SELItemSelectPopoverViewControllerDelegate <NSObject>
- (void)SelectedItem:(SELItemData*)selectedItem sender:(SELItemSelectPopoverViewController*)sender;
@end

@interface SELItemSelectPopoverViewController : UITableViewController
@property NSArray* ItemList;
@property id<SELItemSelectPopoverViewControllerDelegate> delegate;
@end

//
//  SELSettingViewController.h
//  menuapp
//
//  Created by dpcc on 2014/04/22.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "IASKAppSettingsViewController.h"
#import "SELMenuDataManager.h"

@interface SELSettingViewController : UITableViewController<IASKSettingsDelegate>

- (IBAction)dismiss:(id)sender;

@end

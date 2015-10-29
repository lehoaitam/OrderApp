//
//  SELRecommendViewController.h
//  selforder
//
//  Created by dpcc on 2015/06/15.
//  Copyright (c) 2015年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface RecommendItem : NSObject

@property NSString* itemCode;
@property NSNumber* sortKey;

@end

@interface SELRecommendViewController : UIViewController<UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UITableView *_tableView;
    IBOutlet UILabel* _titleLabel;
    NSArray* _recommendationItems;
    NSString* _selectedItemCode;    // work
}

- (IBAction)dismiss:(id)sender;

@end

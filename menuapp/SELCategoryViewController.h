//
//  SELCategoryViewController.h
//  selforder
//
//  Created by dpcc on 2014/06/05.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SELCategoryViewController : UICollectionViewController {
    // work
    NSString* _selectedItemCode;
}

- (IBAction)dismiss:(id)sender;

@property BOOL isItemList;
@property NSMutableDictionary* categoryDict;
@property NSArray* itemArray;

@end

//
//  SELItemCollectionViewCell.h
//  selforder
//
//  Created by dpcc on 2014/06/05.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SELItemData.h"

@interface SELItemCollectionViewCell : UICollectionViewCell {
    IBOutlet UIButton* _itemImage;
    IBOutlet UITextView* _itemDetailText;
}

- (void)setItemData:(SELItemData*)itemData;

@end

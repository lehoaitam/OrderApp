//
//  SELCategoryCollectionViewCell.h
//  selforder
//
//  Created by dpcc on 2014/06/05.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SELCategoryData.h"

@interface SELCategoryCollectionViewCell : UICollectionViewCell {
    IBOutlet UILabel* _label;
    IBOutlet UIImageView* _imageView;
}

- (void)setCategoryData:(SELCategoryData*)categoryData;

@end

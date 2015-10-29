//
//  SELItemCollectionViewCell.m
//  selforder
//
//  Created by dpcc on 2014/06/05.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELItemCollectionViewCell.h"

@implementation SELItemCollectionViewCell

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)setItemData:(SELItemData *)itemData
{
    [_itemDetailText setText:itemData.itemName];
    [_itemImage setBackgroundImage:[itemData getItemImage] forState:UIControlStateNormal];
}

@end

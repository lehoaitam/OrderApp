//
//  SELOrderListViewCell.m
//  menuapp
//
//  Created by dpcc on 2014/04/16.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELOrderListViewCell.h"
#import "SELOrderManager.h"

@implementation SELOrderListViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)updateLocalizitaion
{
    // 多言語対応
    [_yen setText:[SELLocalization localizedStringForKey:@"IB_YEN"]];
    [_pieces setText:[SELLocalization localizedStringForKey:@"IB_PIECES"]];
    [_cancelButton setTitle:[SELLocalization localizedStringForKey:@"IB_CANCEL"] forState:UIControlStateNormal];
}

- (void)awakeFromNib
{
    // Initialization code
    [self updateLocalizitaion];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)deleteItem:(id)sender
{
    SELOrderManager* orderListController = [SELOrderManager instance];
    [orderListController deleteOrder:self.orderData];
    
    // 削除されたことを通知
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:SELUpdateOrderListMessageNotification object:self];
}

@end

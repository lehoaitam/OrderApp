//
//  SELPurchaseHistoryViewCell.m
//  menuapp
//
//  Created by dpcc on 2014/05/07.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELPurchaseHistoryViewCell.h"

@implementation SELPurchaseHistoryViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    if (self) {
        // Initialization code
    }
    return self;
}

- (void)awakeFromNib
{
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)updateLocalizitaion
{
    // 多言語対応
    [_priceLabel setText:[SELLocalization localizedStringForKey:@"IB_PRICE"]];
    [_priceYenLabel setText:[SELLocalization localizedStringForKey:@"IB_YEN"]];
    [_totalLabel setText:[SELLocalization localizedStringForKey:@"IB_TOTAL"]];
    [_totalYenLabel setText:[SELLocalization localizedStringForKey:@"IB_YEN"]];
    [_quantityLabel setText:[SELLocalization localizedStringForKey:@"IB_QUANTITY"]];
    [_orderTimeLabel setText:[SELLocalization localizedStringForKey:@"IB_ORDERTIME"]];
}

@end

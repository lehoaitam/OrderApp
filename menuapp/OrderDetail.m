//
//  orderDetail.m
//  MobilePOS
//
//  Created by Ryutaro Minato on 11/07/02.
//  Copyright 2011 genephics design,Inc. All rights reserved.
//

#import "OrderDetail.h"
//#import "MobileOrderUtil.h"
#import "SmaregiUtil.h"

@implementation OrderDetail

@synthesize localOrderDetailId = _localOrderDetailId;
@synthesize localOrderHeaderId = _localOrderHeaderId;
@synthesize orderHeaderId = _orderHeaderId;
@synthesize orderDetailId = _orderDetailId;
@synthesize orderDetailNo = _orderDetailNo;
@synthesize orderDateTime = _orderDateTime;
@synthesize cateredDateTime = _cateredDateTime;
@synthesize itemId = _itemId;
@synthesize itemName = _itemName;
@synthesize itemDrillDownId = _itemDrillDownId;
@synthesize itemDrillDownName = _itemDrillDownName;
@synthesize itemDivision = _itemDivision;
@synthesize itemPlanId = _itemPlanId;
@synthesize categoryId = _categoryId;
@synthesize categoryName = _categoryName;
@synthesize quantity = _quantity;
@synthesize price = _price;
@synthesize salesPrice = _salesPrice;
@synthesize discountPrice = _discountPrice;
@synthesize discountRate = _discountRate;
@synthesize discountDivision = _discountDivision;
@synthesize staffId = _staffId;
@synthesize staffName = _staffName;
@synthesize memo = _memo;
@synthesize printerId = _printerId;
@synthesize synchronized = _synchronized;
@synthesize status = _status;

@synthesize priceLabel;
@synthesize salesPriceLabel;
@synthesize salesPriceLabelForCell;
@synthesize quantityLabel;
@synthesize discountLabel;
@synthesize discountPriceLabel;
@synthesize discountRateLabel;
@synthesize orderTimeLabel;
@synthesize statusLabel;
@synthesize discountedPriceLabel;
@synthesize discountPriceLabelForEdit;
@synthesize discountLabelForCell;
@synthesize discountPriceRateLabel;

@synthesize itemNameLabelForPrinter;
@synthesize itemDrillDownNameLabelForPrinter;
@synthesize memoLabelForPrinter;
@synthesize staffNameLabelForPrinter;
@synthesize orderDetailNoLabelForPrinter;

@synthesize isSynchronized;
@synthesize isCanceled;
@synthesize isCatered;
@synthesize isOrdered;
@synthesize isAdjustedPrice;
@synthesize isDiscounted;
@synthesize isDiscountPrice;
@synthesize isDiscountRate;
@synthesize isDiscountPriceCoupon;
@synthesize isDiscountRateCoupon;
@synthesize isDiscountFreeCoupon;
@synthesize hasItemDrillDownName;
@synthesize hasMemo;

@synthesize orderDetailTotal;

- (void) dealloc
{
    [_localOrderDetailId release];
    [_localOrderHeaderId release];
    [_orderHeaderId release];
    [_orderDetailId release];
    [_orderDetailNo release];
    [_orderDateTime release];
    [_cateredDateTime release];
    [_itemId release];
    [_itemName release];
    [_itemDrillDownId release];
    [_itemDrillDownName release];
    [_itemDivision release];
    [_itemPlanId release];
    [_categoryId release];
    [_categoryName release];
    [_price release];
    [_quantity release];
    [_discountPrice release];
    [_discountRate release];
    [_discountDivision release];
    [_salesPrice release];
    [_staffId release];
    [_staffName release];
    [_printerId release];
    [_memo release];
    [_synchronized release];
    [_status release];
    
    [super dealloc];
}

#pragma mark - data get methods

- (BOOL) isSynchronized{        return [SYNCHRONIZED_OK isEqualToString:_synchronized];}
- (BOOL) isCanceled{            return [ORDERDETAIL_STATUS_CANCELED isEqualToString:_status];}
- (BOOL) isCatered{             return [ORDERDETAIL_STATUS_CATERED isEqualToString:_status];}
- (BOOL) isOrdered{             return [ORDERDETAIL_STATUS_ORDERED isEqualToString:_status];}
- (BOOL) isAdjustedPrice{       return ![_price isEqualToNumber:_salesPrice];}
- (BOOL) isDiscounted{          return ![DISCOUNT_DIVISION_NONE isEqualToString:_discountDivision];}
- (BOOL) isDiscountPrice{       return [DISCOUNT_DIVISION_PRICE isEqualToString:_discountDivision];}
- (BOOL) isDiscountRate{        return [DISCOUNT_DIVISION_RATE isEqualToString:_discountDivision];}
- (BOOL) isDiscountPriceCoupon{ return [DISCOUNT_DIVISION_PRICE_COUPON isEqualToString:_discountDivision];}
- (BOOL) isDiscountRateCoupon{  return [DISCOUNT_DIVISION_RATE_COUPON isEqualToString:_discountDivision];}
- (BOOL) isDiscountFreeCoupon{  return [DISCOUNT_DIVISION_FREE_COUPON isEqualToString:_discountDivision];}
- (BOOL) hasItemDrillDownName{  return (_itemDrillDownName && [_itemDrillDownName length] > 0);}
- (BOOL) hasMemo{               return (_memo && [_memo length] > 0);}
- (BOOL) isPlan{                return [ITEM_DIVISION_PLAN isEqualToString:_itemDivision];}
- (BOOL) isPlanItem{            return [ITEM_DIVISION_PLAN_ITEM isEqualToString:_itemDivision];}
- (BOOL) hasToppingItem{        return (_toppingItems && [_toppingItems count] > 0);}

#pragma mark - initialize methods

- (id) init
{
    self = [super init];
    self.price = [NSNumber numberWithInt:0];
    self.quantity = [NSNumber numberWithInt:0];
    self.discountDivision = DISCOUNT_DIVISION_NONE;
    self.discountPrice = [NSNumber numberWithInt:0];
    self.discountRate = [NSNumber numberWithInt:0];
    self.salesPrice = [NSNumber numberWithInt:0];
    self.synchronized = SYNCHRONIZED_NO;
    self.status = ORDERDETAIL_STATUS_ORDERED;
    return self;
}

/*
- (id) initWithItem:(Item*)item
{
    self = [self init];
    [self setItem:item];
    return self;
}
*/

#pragma mark - data set methods

/*
- (void) setItem:(Item*)item
{
    self.itemId = item.itemId;
    self.itemName = item.itemName;
    self.price = item.price;
    self.salesPrice = item.price;
    self.categoryId = item.categoryId;
}
*/
 
- (void) setSalesPriceAndCalculate:(NSNumber*)price
{
    self.salesPrice = price;
    // 値引・割引後の数量変更や価格調整の対応
    if (self.isDiscountFreeCoupon)
    {
        self.discountPrice = _salesPrice;
    }
    else if (_discountRate && ![_discountRate isZero])
    {
        //self.discountPrice = [MobileOrderUtil calculateDiscountPrice:_salesPrice discountRate:_discountRate];
        self.discountPrice = self.discountPrice;
    }
    else if ([_discountPrice doubleValue] > [_salesPrice doubleValue])
    {
        self.discountPrice = _salesPrice;
    }
}

- (void) setDiscountPriceAndCalculate:(NSNumber*)price
{
    self.discountRate = [NSNumber numberWithInt:0];
    self.discountPrice = price;
}

- (void) setDiscountRateAndCalculate:(NSNumber*)rate
{
    self.discountRate = rate;
    //self.discountPrice = [MobileOrderUtil calculateDiscountPrice:_salesPrice discountRate:_discountRate];
}

- (void) setDiscountDivisionAndCalculate:(NSString*)division
{
    self.discountDivision = division;
    if (self.isDiscountPrice)
    {
        self.discountRate = [NSNumber numberWithInt:0];
    }
    else if (self.isDiscountRate)
    {
        [self setDiscountPriceAndCalculate:[NSNumber numberWithInt:0]];
    }
    else if (self.isDiscountPriceCoupon)
    {
        self.discountRate = [NSNumber numberWithInt:0];
    }
    else if (self.isDiscountRateCoupon)
    {
        [self setDiscountPriceAndCalculate:[NSNumber numberWithInt:0]];
    }
    else if (self.isDiscountFreeCoupon)
    {
        [self setDiscountPriceAndCalculate:_salesPrice];
    }
    else 
    {
        [self setDiscountPriceAndCalculate:[NSNumber numberWithInt:0]];
    }
}

#pragma mark - label methods

- (NSString*) salesPriceLabel{      return [FormatUtil currencyFormat:self.salesPrice];}
- (NSString*) priceLabel{           return [FormatUtil currencyFormat:self.price];}
- (NSString*) quantityLabel{        return [FormatUtil quantityFormat:self.quantity];}
- (NSString*) discountRateLabel{    return [FormatUtil percentFormat:self.discountRate];}
- (NSString*) discountPriceLabel{   return [FormatUtil currencyFormat:self.discountPrice];}
- (NSString*) orderTimeLabel{       return [FormatUtil stringDateToStringTime:self.orderDateTime];}

- (NSString*) statusLabel
{
    if (self.isOrdered) return NSLocalizedString(@"ORDER_DETAIL_STATUS_ORDERED", nil);
    else if (self.isCatered) return NSLocalizedString(@"ORDER_DETAIL_STATUS_CATERED", nil);
    else if (self.isCanceled) return NSLocalizedString(@"ORDER_DETAIL_STATUS_CANCELED", nil);
    else return @"";
}

- (NSString*) discountPriceLabelForEdit
{
    if (_discountRate == nil || [_discountRate isEqualToNumber:[NSNumber numberWithInt:0]])
    {
        return [FormatUtil currencyFormat:self.discountPrice];
    }
    else
    {
        return @"￥0";
    }
}

- (NSString*) discountedPriceLabel
{
    if (_discountPrice == nil || [_discountPrice isZero])
    {
        return self.salesPriceLabel;
    }
    else
    {
        double discountedPrice = [_salesPrice doubleValue] - [_discountPrice doubleValue];
        return [FormatUtil currencyFormat:[NSNumber numberWithDouble:discountedPrice]];
    }
}

- (NSString*) discountLabel
{
    if (!self.isDiscounted) return @"￥0";
    if (_discountRate == nil || [_discountRate isEqualToNumber:[NSNumber numberWithInt:0]])
    {
        return self.discountPriceLabel;
    }
    else if (_discountRate)
    {
        return self.discountRateLabel;
    }
    else
    {
        return @"￥0";
    }
}

- (NSString*) discountLabelForCell
{
    if (!self.isDiscounted) return @"￥0";
    if (_discountRate == nil || [_discountRate isZero])
    {
        return [NSString stringWithFormat:@"-%@", self.discountPriceLabel];
    }
    else if (_discountRate)
    {
        return [NSString stringWithFormat:@"%@OFF", self.discountRateLabel];
    }
    else
    {
        return @"￥0";
    }
}

- (NSString*) salesPriceLabelForCell
{
    if (!self.isDiscounted) return self.salesPriceLabel;
    return [NSString stringWithFormat:@"%@(%@)", self.salesPriceLabel, self.discountDivisionLabel];
}

- (NSString*) discountDivisionLabel
{
    if      (!self.isDiscounted)        return NSLocalizedString(@"LABEL_DISCOUNT_NONE", nil);
    else if (self.isDiscountPrice)      return NSLocalizedString(@"LABEL_DISCOUNT_PRICE", nil);
    else if (self.isDiscountRate)       return NSLocalizedString(@"LABEL_DISCOUNT_RATE", nil);
    else if (self.isDiscountPriceCoupon)return NSLocalizedString(@"LABEL_DISCOUNT_PRICE_COUPON", nil);
    else if (self.isDiscountRateCoupon) return NSLocalizedString(@"LABEL_DISCOUNT_RATE_COUPON", nil);
    else if (self.isDiscountFreeCoupon) return NSLocalizedString(@"LABEL_DISCOUNT_FREE_COUPON", nil);
    else return @"";
}

- (NSString*) discountDivisionLabelForPrinter
{
    if (self.isDiscountRate || self.isDiscountRateCoupon)
    {
        return [NSString stringWithFormat:@"%@(%@)", self.discountDivisionLabel, self.discountRateLabel];
    }
    else 
    {
        return self.discountDivisionLabel;
    }
}

- (NSString*) discountPriceRateLabel
{
    if      (!self.isDiscounted)        return @"";
    else if (self.isDiscountPrice)      return self.discountPriceLabel;
    else if (self.isDiscountRate)       return [NSString stringWithFormat:@"%@(%@)", self.discountRateLabel, self.discountPriceLabel];
    else if (self.isDiscountPriceCoupon)return self.discountPriceLabel;
    else if (self.isDiscountRateCoupon) return [NSString stringWithFormat:@"%@(%@)", self.discountRateLabel, self.discountPriceLabel];
    else if (self.isDiscountFreeCoupon) return @"free";
    else return @"";
}

- (NSString*) itemNameLabelForPrinter
{
    if (!self.itemName) return nil;
    return [NSString stringWithFormat:@"■%@", self.itemName];
}

- (NSString*) itemDrillDownNameLabelForPrinter
{
    if (!self.itemDrillDownName) return nil;
    return [NSString stringWithFormat:@" - %@", self.itemDrillDownName];
}

- (NSString*) itemToppingNameLabelForPrinter
{
    if (!self.itemName) return nil;
    return [NSString stringWithFormat:@" + %@", self.itemName];
}

- (NSString*) memoLabelForPrinter
{
    if (!self.memo) return nil;
    return [NSString stringWithFormat:@"(%@)", self.memo];
}

- (NSString*) staffNameLabelForPrinter
{
    return [NSString stringWithFormat:@"%@:%@", NSLocalizedString(@"LABEL_STAFF", nil), self.staffName ? self.staffName : @" -"];
}

- (NSString*) orderDetailNoLabelForPrinter
{
    return [NSString stringWithFormat:@"%@:%@", NSLocalizedString(@"LABEL_ORDER_DETAIL_NO", nil), self.orderDetailNo ? self.orderDetailNo : @" -"];
}

- (NSNumber*) orderDetailTotal
{
    return [NSNumber numberWithDouble:([_salesPrice doubleValue] - [_discountPrice doubleValue]) * [_quantity intValue]];
}

@end

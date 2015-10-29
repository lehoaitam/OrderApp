//
//  OrderHeader.m
//  MobileOrder
//
//  Created by Ryutaro Minato on 12/01/22.
//  Copyright (c) 2012 genephics design,Inc. All rights reserved.
//

#import "OrderHeader.h"
//#import "MobileOrderDefine.h"
//#import "MobileOrderUtil.h"
#import "SmaregiUtil.h"

@implementation OrderHeader

@synthesize localOrderHeaderId = _localOrderHeaderId;
@synthesize orderHeaderId = _orderHeaderId;
@synthesize tableNo = _tableNo;
@synthesize tableName = _tableName;
@synthesize applyPlans = _applyPlans;
@synthesize numbers = _numbers;
@synthesize enterDateTime = _enterDateTime;
@synthesize lastOrderDateTime = _lastOrderDateTime;
@synthesize checkoutDateTime = _checkoutDateTime;
@synthesize subtotal = _subtotal;
@synthesize amount = _amount;
@synthesize tax = _tax;
@synthesize taxRate = _taxRate;
@synthesize discountPrice = _discountPrice;
@synthesize discountRate = _discountRate;
@synthesize discountDivision =_discountDivision;
@synthesize tableChargePerPerson = _tableChargePerPerson;
@synthesize serviceChargeRate = _serviceChargeRate;
@synthesize total = _total;
@synthesize groupingId = _groupingId;
@synthesize groupingName = _groupingName;
@synthesize staffId = _staffId;
@synthesize staffName = _staffName;
@synthesize synchronized = _synchronized;
@synthesize status = _status;

@synthesize isSynchronized;
@synthesize isCheckouted;
@synthesize isCanceled;
@synthesize isDiscounted;
@synthesize isDiscountPrice;
@synthesize isDiscountRate;
@synthesize isDiscountPriceCoupon;
@synthesize isDiscountRateCoupon;
@synthesize isDiscountFreeCoupon;

@synthesize enterTime;
@synthesize checkoutTime;
@synthesize timeLabel;

- (void) dealloc
{
    [_localOrderHeaderId release];
    [_orderHeaderId release];
    [_tableNo release];
    [_tableName release];
    [_applyPlans release];
    [_numbers release];
    [_enterDateTime release];
    [_lastOrderDateTime release];
    [_checkoutDateTime release];
    [_subtotal release];
    [_discountDivision release];
    [_discountPrice release];
    [_discountRate release];
    [_amount release];
    [_tax release];
    [_taxRate release];
    [_serviceChargeRate release];
    [_tableChargePerPerson release];
    [_total release];
    [_groupingId release];
    [_groupingName release];
    [_staffId release];
    [_staffName release];
    [_synchronized release];
    [_status release];
    
    [super dealloc];
}

#pragma mark - data get methods

- (BOOL) isSynchronized{        return [SYNCHRONIZED_OK isEqualToString:self.synchronized];}
- (BOOL) isCheckouted{          return (_checkoutDateTime && [_checkoutDateTime length] > 0);}
- (BOOL) isCanceled{            return [ORDERHEADER_STATUS_CANCELED isEqualToString:_status];}
- (BOOL) isDiscounted{          return ![DISCOUNT_DIVISION_NONE isEqualToString:self.discountDivision];}
- (BOOL) isDiscountPrice{       return [DISCOUNT_DIVISION_PRICE isEqualToString:self.discountDivision];}
- (BOOL) isDiscountRate{        return [DISCOUNT_DIVISION_RATE isEqualToString:self.discountDivision];}
- (BOOL) isDiscountPriceCoupon{ return [DISCOUNT_DIVISION_PRICE_COUPON isEqualToString:self.discountDivision];}
- (BOOL) isDiscountRateCoupon{  return [DISCOUNT_DIVISION_RATE_COUPON isEqualToString:self.discountDivision];}
- (BOOL) isDiscountFreeCoupon{  return [DISCOUNT_DIVISION_FREE_COUPON isEqualToString:self.discountDivision];}

#pragma mark - initialize methods

- (id) init
{
    self = [super init];
    
    self.subtotal = [NSNumber numberWithInt:0];
    self.total = [NSNumber numberWithInt:0];
    self.discountDivision = DISCOUNT_DIVISION_NONE;
    self.discountPrice = [NSNumber numberWithInt:0];
    self.discountRate = [NSNumber numberWithInt:0];
    self.taxRate = [NSNumber numberWithInt:0];
    self.tableChargePerPerson = [NSNumber numberWithInt:0];
    self.serviceChargeRate = [NSNumber numberWithInt:0];
    self.numbers = [NSNumber numberWithInt:0];
    self.status = ORDERHEADER_STATUS_INPROCESS;
    self.synchronized = SYNCHRONIZED_NO;
    self.applyPlans = [NSNumber numberWithInt:0];
    return self;
}

/*
- (id) initWithStoreSetting:(Store*)store status:(NSString*)status
{
    self = [self initWithStatus:status];
    self.tableChargePerPerson = store.tableChargePerPerson;
    self.serviceChargeRate = store.serviceChargeRate;
    self.taxRate = store.taxRate;
    return self;
}

- (id) initWithStoreSetting:(Store*)store
{
    return [self initWithStoreSetting:store status:ORDERHEADER_STATUS_INPROCESS];
}
*/
 
- (id) initWithCharge:(NSNumber*)tableChargePerPerson serviceCharge:(NSNumber*)serviceChargeRate
{
    self = [self init];
    self.tableChargePerPerson = tableChargePerPerson;
    self.serviceChargeRate = serviceChargeRate;
    return self;
}

- (id) initWithTableCharge:(NSNumber*)tableCharge
{
    self = [self init];
    self.tableChargePerPerson = tableCharge;
    return self;
}

- (id) initWithStatus:(NSString*)status
{
    self = [self init];
    self.status = status;
    if ([ORDERHEADER_STATUS_VACANCY isEqualToString:status])
    {
        self.synchronized = SYNCHRONIZED_OK;
    }
    else
    {
        self.synchronized = SYNCHRONIZED_NO;
    }
    return self;
}

- (void) calculate
{
    // 値引・割引後の数量変更や価格調整の対応
    if (self.isDiscountFreeCoupon)
    {
        self.discountPrice = _subtotal;
    }
    else if (_discountRate && ![_discountRate isZero])
    {
        //self.discountPrice = [MobileOrderUtil calculateDiscountPrice:_subtotal discountRate:_discountRate];
        self.discountPrice = self.discountRate;
    }
    else if (![_subtotal isNegative] && [_discountPrice doubleValue] > [_subtotal doubleValue])
    {
        self.discountPrice = _subtotal;
    }
    
    // 合計
    double charge = [self.numbers doubleValue] * [self.tableChargePerPerson doubleValue];
    double sTotal = [self.subtotal doubleValue] + charge - [self.discountPrice doubleValue];
    sTotal = sTotal * ([self.serviceChargeRate doubleValue] + 100) / 100;
    self.total = [NSNumber numberWithDouble:floor(sTotal)];
    
    // 消費税（内税）
    self.tax = [NSNumber numberWithDouble:floor([_total doubleValue] / ([_taxRate floatValue] + 100) * [_taxRate floatValue])];
}

#pragma mark - data set methods

- (void) setNumbersAndCalculate:(NSNumber*)numbers
{
    self.numbers = numbers;
    [self calculate];
}

- (void) setSubtotalAndCalculate:(NSNumber*)subtotal
{
    self.subtotal = subtotal;
    [self calculate];
}

- (void) setTableChargePerPersonAndCalculate:(NSNumber*)tableChargePerPerson
{
    self.tableChargePerPerson = tableChargePerPerson;
    [self calculate];
}

- (void) setServiceChargeRateAndCalculate:(NSNumber*)serviceChargeRate
{
    self.serviceChargeRate = serviceChargeRate;
    [self calculate];
}

- (void) setDiscountPriceAndCalculate:(NSNumber*)price
{
    self.discountRate = [NSNumber numberWithInt:0];
    self.discountPrice = price;
    [self calculate];
}

- (void) setDiscountRateAndCalculate:(NSNumber*)rate
{
    self.discountRate = rate;
    //self.discountPrice = [MobileOrderUtil calculateDiscountPrice:_subtotal discountRate:_discountRate];;
    [self calculate];
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
        [self setDiscountPriceAndCalculate:_subtotal];
    }
    else 
    {
        [self setDiscountPriceAndCalculate:[NSNumber numberWithInt:0]];
    }
}

- (NSNumber*) serviceChargePrice
{
    double charge = [self.numbers doubleValue] * [self.tableChargePerPerson doubleValue];
    double sTotal = [self.subtotal doubleValue] + charge - [self.discountPrice doubleValue];
    return [NSNumber numberWithDouble:floor(sTotal * [self.serviceChargeRate doubleValue] / 100)];
}

#pragma mark - label methods

- (NSString*) numbersLabel{             return [FormatUtil peopleNumbersFormat:self.numbers];}
- (NSString*) enterTime{                return [FormatUtil stringDateToStringTime:self.enterDateTime];}
- (NSString*) checkoutTime{             return [FormatUtil stringDateToStringTime:self.checkoutDateTime];}
- (NSString*) amountLabel{              return [FormatUtil quantityFormat:self.amount];}
- (NSString*) subtotalLabel{            return [FormatUtil currencyFormat:self.subtotal];}
- (NSString*) discountLabel{            return [FormatUtil currencyFormat:self.discountPrice];}
- (NSString*) discountPriceLabel{       return [FormatUtil currencyFormat:self.discountPrice];}
- (NSString*) discountRateLabel{        return [FormatUtil percentFormat:self.discountRate];}
- (NSString*) taxLabel{                 return [FormatUtil currencyFormat:self.tax];}
- (NSString*) totalLabel{               return self.total ? [FormatUtil currencyFormat:self.total] : @"";}
- (NSString*) tableChargePerPersonLabel{return [FormatUtil currencyFormat:self.tableChargePerPerson];}
- (NSString*) serviceChargeRateLabel{   return [FormatUtil percentFormat:self.serviceChargeRate];}
- (NSString*) serviceChargePriceLabel{  return [FormatUtil currencyFormat:self.serviceChargePrice];}
- (NSString*) serviceChargeLabel{       return [NSString stringWithFormat:@"%@(%@)", self.serviceChargeRateLabel, self.serviceChargePriceLabel]; }
- (NSString*) billDivideLabel{          return [FormatUtil currencyFormat:[NSNumber numberWithDouble:([self.total doubleValue] / [self.numbers doubleValue])]];}
- (NSString*) tableNoLabel{             return [NSString stringWithFormat:@"%@ :%@", NSLocalizedString(@"LABEL_TABLE", nil), [self.tableNo stringValue]];}
- (NSString*) tableNameLabel{           return [NSString stringWithFormat:@"%@ :%@", NSLocalizedString(@"LABEL_TABLE", nil), self.tableName];}
- (NSString*) tableCategoryNameLabel{           return [NSString stringWithFormat:@"%@ :%@", self.tableCategory, self.tableName];}


- (NSString*) staffNameLabelForPrinter
{
    return [NSString stringWithFormat:@"%@:%@", NSLocalizedString(@"LABEL_STAFF", nil), self.staffName ? self.staffName : @" -"];
}

- (NSString*) timeLabel
{
    return [NSString stringWithFormat:@"%@ :%@ 〜 %@", 
                NSLocalizedString(@"LABEL_TABLE_TIME", nil), 
            self.enterTime ? self.enterTime : @"", 
            self.checkoutTime ? self.checkoutTime : @""];
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


- (NSString*) tableChargeLabel
{
    return [NSString stringWithFormat:@"%@ x %@ = %@", 
                [FormatUtil currencyFormat:self.tableChargePerPerson], 
                [FormatUtil peopleNumbersFormat:self.numbers],
                [FormatUtil currencyFormat:[NSNumber numberWithDouble:[self.tableChargePerPerson doubleValue] * [self.numbers doubleValue]]]];
}


@end

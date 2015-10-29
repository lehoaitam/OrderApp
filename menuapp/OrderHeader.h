//
//  OrderHeader.h
//  MobileOrder
//
//  Created by Ryutaro Minato on 12/01/22.
//  Copyright (c) 2012 genephics design,Inc. All rights reserved.
//

//#import "EntityBase.h"
//#import "Store.h"

@interface OrderHeader : NSObject

@property (nonatomic, copy) NSString* localOrderHeaderId;
@property (nonatomic, copy) NSString* orderHeaderId;
@property (nonatomic, copy) NSNumber* tableNo;
@property (nonatomic, copy) NSString* tableName;
@property (nonatomic, copy) NSNumber* applyPlans;
@property (nonatomic, copy) NSNumber* numbers;
@property (nonatomic, copy) NSString* enterDateTime;
@property (nonatomic, copy) NSString* lastOrderDateTime;
@property (nonatomic, copy) NSString* checkoutDateTime;
@property (nonatomic, copy) NSNumber* subtotal;
@property (nonatomic, copy) NSNumber* amount;
@property (nonatomic, copy) NSNumber* tax;
@property (nonatomic, copy) NSNumber* taxRate;
@property (nonatomic, copy) NSNumber* discountPrice;
@property (nonatomic, copy) NSNumber* discountRate;
@property (nonatomic, copy) NSString* discountDivision;
@property (nonatomic, copy) NSNumber* serviceChargeRate;
@property (nonatomic, copy) NSNumber* tableChargePerPerson;
@property (nonatomic, copy) NSNumber* total;
@property (nonatomic, copy) NSString* groupingId;
@property (nonatomic, copy) NSString* groupingName;
@property (nonatomic, copy) NSString* staffId;
@property (nonatomic, copy) NSString* staffName;
@property (nonatomic, copy) NSString* synchronized;
@property (nonatomic, copy) NSString* status;
@property (nonatomic, copy) NSString* tableCategory;
@property (nonatomic, copy) NSNumber* orderedtotal;

// add by n.sasaki 2013.04.15 プリンタ印刷対応. 小計のみ印字するフラグ
@property BOOL isPrintSubTotalOnly;


@property (nonatomic, readonly) NSNumber* serviceChargePrice;

@property (nonatomic, readonly) NSString* numbersLabel;
@property (nonatomic, readonly) NSString* amountLabel;
@property (nonatomic, readonly) NSString* subtotalLabel;
@property (nonatomic, readonly) NSString* discountDivisionLabel;
@property (nonatomic, readonly) NSString* discountDivisionLabelForPrinter;
@property (nonatomic, readonly) NSString* discountLabel;
@property (nonatomic, readonly) NSString* discountRateLabel;
@property (nonatomic, readonly) NSString* discountPriceLabel;
@property (nonatomic, readonly) NSString* discountPriceRateLabel;
@property (nonatomic, readonly) NSString* taxLabel;
@property (nonatomic, readonly) NSString* totalLabel;
@property (nonatomic, readonly) NSString* tableChargeLabel;
@property (nonatomic, readonly) NSString* tableChargePerPersonLabel;
@property (nonatomic, readonly) NSString* serviceChargeRateLabel;
@property (nonatomic, readonly) NSString* serviceChargePriceLabel;
@property (nonatomic, readonly) NSString* serviceChargeLabel;
@property (nonatomic, readonly) NSString* billDivideLabel;
@property (nonatomic, readonly) NSString* staffNameLabelForPrinter;
@property (nonatomic, readonly) NSString* tableNoLabel;
@property (nonatomic, readonly) NSString* tableNameLabel;
@property (nonatomic, readonly) NSString* tableCategoryNameLabel;
@property (nonatomic, readonly) NSString* enterTime;
@property (nonatomic, readonly) NSString* checkoutTime;
@property (nonatomic, readonly) NSString* timeLabel;

@property (nonatomic, readonly) BOOL isSynchronized;
@property (nonatomic, readonly) BOOL isCheckouted;
@property (nonatomic, readonly) BOOL isCanceled;

@property (nonatomic, readonly) BOOL isDiscounted;
@property (nonatomic, readonly) BOOL isDiscountPrice;
@property (nonatomic, readonly) BOOL isDiscountRate;
@property (nonatomic, readonly) BOOL isDiscountPriceCoupon;
@property (nonatomic, readonly) BOOL isDiscountRateCoupon;
@property (nonatomic, readonly) BOOL isDiscountFreeCoupon;

//- (id) initWithStoreSetting:(Store*)store status:(NSString*)status;
//- (id) initWithStoreSetting:(Store*)store;
- (id) initWithCharge:(NSNumber*)tableChargePerPerson serviceCharge:(NSNumber*)serviceChargeRate;
- (id) initWithTableCharge:(NSNumber*)tableCharge;
- (id) initWithStatus:(NSString*)status;

- (void) calculate;

- (void) setNumbersAndCalculate:(NSNumber*)numbers;
- (void) setSubtotalAndCalculate:(NSNumber*)subtotal;
- (void) setTableChargePerPersonAndCalculate:(NSNumber*)tableChargePerPerson;
- (void) setServiceChargeRateAndCalculate:(NSNumber*)serviceChargeRate;
- (void) setDiscountPriceAndCalculate:(NSNumber*)price;
- (void) setDiscountRateAndCalculate:(NSNumber*)rate;
- (void) setDiscountDivisionAndCalculate:(NSString*)division;

@end


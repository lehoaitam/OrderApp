//
//  OrderDetail.h
//  MobilePOS
//
//  Created by Ryutaro Minato on 11/07/02.
//  Copyright 2011 genephics design,Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "EntityBase.h"
//#import "Item.h"
//#import "Category.h"
//#import "FMResultSet.h"


@interface OrderDetail : NSObject

@property (nonatomic, copy) NSString* localOrderDetailId;
@property (nonatomic, copy) NSString* localOrderHeaderId;
@property (nonatomic, copy) NSString* orderDetailId;
@property (nonatomic, copy) NSString* orderHeaderId;
@property (nonatomic, copy) NSString* orderDetailNo;
@property (nonatomic, copy) NSString* orderDateTime;
@property (nonatomic, copy) NSString* cateredDateTime;
@property (nonatomic, copy) NSString* itemId;
@property (nonatomic, copy) NSString* itemName;
@property (nonatomic, copy) NSString* itemDrillDownId;
@property (nonatomic, copy) NSString* itemDrillDownName;
@property (nonatomic, copy) NSString* itemDivision;
@property (nonatomic, copy) NSNumber* itemPlanId;
@property (nonatomic, copy) NSString* categoryId;
@property (nonatomic, copy) NSString* categoryName;
@property (nonatomic, copy) NSNumber* quantity;
@property (nonatomic, copy) NSNumber* price;
@property (nonatomic, copy) NSNumber* salesPrice;
@property (nonatomic, copy) NSNumber* discountPrice;
@property (nonatomic, copy) NSNumber* discountRate;
@property (nonatomic, copy) NSString* discountDivision;
@property (nonatomic, copy) NSString* staffId;
@property (nonatomic, copy) NSString* staffName;
@property (nonatomic, copy) NSString* printerId;
@property (nonatomic, copy) NSString* memo;
@property (nonatomic, copy) NSString* synchronized;
@property (nonatomic, copy) NSString* status;

@property (nonatomic, readonly) NSString* priceLabel;
@property (nonatomic, readonly) NSString* salesPriceLabel;
@property (nonatomic, readonly) NSString* salesPriceLabelForCell;
@property (nonatomic, readonly) NSString* quantityLabel;
@property (nonatomic, readonly) NSString* discountDivisionLabel;
@property (nonatomic, readonly) NSString* discountDivisionLabelForPrinter;
@property (nonatomic, readonly) NSString* discountLabel;
@property (nonatomic, readonly) NSString* discountRateLabel;
@property (nonatomic, readonly) NSString* discountPriceLabel;
@property (nonatomic, readonly) NSString* orderTimeLabel;
@property (nonatomic, readonly) NSString* statusLabel;

@property (nonatomic, readonly) NSString* discountPriceLabelForEdit;
@property (nonatomic, readonly) NSString* discountedPriceLabel;
@property (nonatomic, readonly) NSString* discountLabelForCell;
@property (nonatomic, readonly) NSString* discountPriceRateLabel;

@property (nonatomic, readonly) NSString* itemNameLabelForPrinter;
@property (nonatomic, readonly) NSString* itemDrillDownNameLabelForPrinter;
@property (nonatomic, readonly) NSString* memoLabelForPrinter;
@property (nonatomic, readonly) NSString* staffNameLabelForPrinter;
@property (nonatomic, readonly) NSString* orderDetailNoLabelForPrinter;
@property (nonatomic, readonly) NSString* itemToppingNameLabelForPrinter;

@property (nonatomic, readonly) BOOL isSynchronized;
@property (nonatomic, readonly) BOOL isCanceled;
@property (nonatomic, readonly) BOOL isCatered;
@property (nonatomic, readonly) BOOL isOrdered;
@property (nonatomic, readonly) BOOL isAdjustedPrice;
@property (nonatomic, readonly) BOOL isDiscounted;
@property (nonatomic, readonly) BOOL isDiscountPrice;
@property (nonatomic, readonly) BOOL isDiscountRate;
@property (nonatomic, readonly) BOOL isDiscountPriceCoupon;
@property (nonatomic, readonly) BOOL isDiscountRateCoupon;
@property (nonatomic, readonly) BOOL isDiscountFreeCoupon;
@property (nonatomic, readonly) BOOL hasItemDrillDownName;
@property (nonatomic, readonly) BOOL hasMemo;
@property (nonatomic, readonly) BOOL isPlan;
@property (nonatomic, readonly) BOOL isPlanItem;
@property (nonatomic, readonly) BOOL hasToppingItem;

@property (nonatomic, readonly) NSNumber* orderDetailTotal;

// add by n.sasaki 2014.05.28
@property (nonatomic, retain) NSMutableArray* toppingItems;

//- (id) initWithItem:(Item*)item;
//- (void) setItem:(Item*)item;

- (void) setSalesPriceAndCalculate:(NSNumber*)price;
- (void) setDiscountPriceAndCalculate:(NSNumber*)price;
- (void) setDiscountRateAndCalculate:(NSNumber*)rate;
- (void) setDiscountDivisionAndCalculate:(NSString*)division;


@end

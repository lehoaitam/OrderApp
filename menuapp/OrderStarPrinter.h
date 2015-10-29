//
//  OrderStarPrinter.h
//  MobileOrder
//
//  Created by Ryutaro Minato on 12/04/26.
//  Copyright (c) 2012 genephics design,Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "StarPrinterUtil.h"
#import "OrderHeader.h"
#import "OrderDetail.h"
#import "Printer.h"
#import "PrintData.h"

@interface OrderStarPrinter : StarPrinterUtil<UIAlertViewDelegate>

@property (nonatomic, assign) id delegate;
@property (nonatomic) NSInteger tag;

@property (nonatomic, retain) OrderHeader* orderHeader;
@property (nonatomic, retain) NSMutableArray* orderDetailList;

@property (nonatomic, retain) NSMutableArray* printDataList;
@property (nonatomic, retain) PrintData* errorPrintData;

@property (nonatomic, readonly) BOOL enabledOrderPrint;
@property (nonatomic, readonly) BOOL enabledOrderSound;
@property (nonatomic, readonly) BOOL useOrderPrintFont2x;
@property (nonatomic, readonly) BOOL enabledOrderReceipt;
@property (nonatomic, readonly) BOOL enabledCheckoutReceipt;
@property (nonatomic, readonly) BOOL enabledCheckoutReceiptDetails;

@property (nonatomic, readonly) NSInteger doPrintCount;

- (id) initWithDelegate:(id)delegate;

- (BOOL) isFirstOrder:(OrderHeader*)orderHeader details:(NSArray*)orderDetailList;
- (NSMutableData*) dataOrderDetail:(OrderHeader*)orderHeader detail:(OrderDetail*)orderDetail isFirstOrder:(BOOL)isFirstOrder cutForPrevData:(BOOL)cut;

- (NSMutableData*) dataCheckoutReceipt:(OrderHeader *)orderHeader details:(NSArray *)orderDetailList;
- (NSMutableData*) dataCancelOrderDetail:(OrderHeader*)orderHeader detail:(OrderDetail*)orderDetail;
- (NSMutableData*) dataOrderReceipt:(OrderHeader *)orderHeader details:(NSArray *)orderDetailList isFirstOrder:(BOOL)isFirstOrder;
- (NSMutableData*) dataOrderCancelReceipt:(OrderHeader *)orderHeader orderDetail:(OrderDetail*)orderDetail;

- (void) printOrder:(OrderHeader*)orderHeader detail:(OrderDetail*)orderDetail;
- (void) printOrder:(OrderHeader*)orderHeader details:(NSArray*)orderDetailList;
- (void) printCheckout:(OrderHeader*)orderHeader details:(NSArray*)orderDetailList;
- (void) printCancelOrder:(OrderHeader*)orderHeader detail:(OrderDetail*)orderDetail;

// add by n.sasaki 2013.04.15 店員呼出
- (BOOL) printCallStuff:(OrderHeader*)orderHeader;

@end

@protocol OrderStarPrinterDelegate <NSObject>

- (void) orderStarPrinterPrintDone;
- (void) orderStarPrinterPrintError:(StarPrinterPrintStatus)status;

@end
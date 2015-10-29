//
//  SELOrderListController.h
//  menuapp
//
//  Created by dpcc on 2014/04/16.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SELConnectionBase.h"
#import "SELOrderData.h"

UIKIT_EXTERN NSString *const SELUpdateOrderListMessageNotification;

@protocol SELOrderManagerDelegate <NSObject>

@optional
- (void)didOrderConfirm:(BOOL)bSuccess info:(id)info;
- (void)didGetOrderedList:(BOOL)bSuccess orderedList:(NSArray*)orderedList totalPrice:(NSInteger)totalPrice info:(id)info;
- (void)didCallStaff:(BOOL)bSuccess info:(id)info;

@end

@interface SELOrderManager : NSObject<SELConnectionBaseDelegate> {
    NSMutableArray* _orderItemArray;
    NSTimer* _timerCartClear;  // cartclear用
}

+ (id)instance;

- (NSArray*)getOrderList;
- (void)addOrder:(SELOrderData*)orderData;
- (void)deleteOrder:(SELOrderData*)orderData;
- (void)clearOrderList;

- (NSInteger)cartCount;
- (NSDate*)lastAddCartTime;

- (void)timerOff;

// 注文確定
- (void)orderConfirm;
// 注文済みリスト取得
- (void)getOrderedList;
// 店員呼び出し
- (void)callStaff;

// 顧客情報取得
- (void)getCustomerInfo;

@property id<SELOrderManagerDelegate> delegate;

@end

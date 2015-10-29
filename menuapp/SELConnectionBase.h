//
//  SELConnectionBase.h
//  menuapp
//
//  Created by dpcc on 2014/05/01.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SELConnectionBaseDelegate <NSObject>

@optional
- (void)didOrderConfirm:(BOOL)bSuccess info:(id)info;
- (void)didGetOrderedList:(BOOL)bSuccess orderedList:(NSArray*)orderedList totalPrice:(NSInteger)totalPrice info:(id)info;
- (void)didCallStaff:(BOOL)bSuccess info:(id)info;

@end

@interface SELConnectionBase : NSObject

+ (id)instance;
- (void)terminate;

// 注文確定
- (void)orderConfirm:(NSArray*)orderList;
// 注文済みリスト取得
- (void)getOrderedList;
// 店員呼び出し
- (void)callStaff;

// 顧客情報取り込み(TEC連携のみ)
- (void)getCustomerInfo;

- (NSString*)createOrderDetailNo;

@property id<SELConnectionBaseDelegate> delegate;

@end

//
//  SELOrderListController.m
//  menuapp
//
//  Created by dpcc on 2014/04/16.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELOrderManager.h"

NSString *const SELUpdateOrderListMessageNotification = @"SELUpdateOrderListMessageNotification";

@implementation SELOrderManager

+ (id)instance
{
    static id _instance = nil;
    @synchronized(self) {
        if (!_instance) {
            _instance = [[self alloc] init];
        }
    }
    return _instance;
}

- (id)init
{
    self = [super init];
    
    if (self != nil) {
        _orderItemArray = [[NSMutableArray alloc]init];
    }
    return self;
}

- (NSArray*)getOrderList
{
    // 注文リストを取得
    return _orderItemArray;
}

- (void)addOrder:(SELOrderData*)orderData
{
    [self createTimer];
    
    // 注文リストに追加
    [_orderItemArray addObject:orderData];
}

- (void)deleteOrder:(SELOrderData*)orderData
{
    // 注文リストから削除
    [_orderItemArray removeObject:orderData];
    
    [self deleteTimer];
}

- (void)orderConfirm
{
    // 注文確定(連携システムによって処理先を返る)
    SELConnectionBase* connectionBase = [SELConnectionBase instance];
    connectionBase.delegate = self;
    [connectionBase orderConfirm:_orderItemArray];
}

- (void)getOrderedList
{
    // 注文済みリストを取得(連携システムによって処理先を返る)
    SELConnectionBase* connectionBase = [SELConnectionBase instance];
    connectionBase.delegate = self;
    [connectionBase getOrderedList];
}

- (void)callStaff
{
    // 店員呼出(連携システムによって処理先を返る)
    SELConnectionBase* connectionBase = [SELConnectionBase instance];
    connectionBase.delegate = self;
    [connectionBase callStaff];
}

- (NSInteger)cartCount
{
    return [_orderItemArray count];
}

- (NSDate *)lastAddCartTime
{
    SELOrderData* lastOrder = [_orderItemArray lastObject];
    if (!lastOrder) {
        return NULL;
    }
    return lastOrder.OrderDateTime;
}

- (void)clearOrderList
{
    [_orderItemArray removeAllObjects];
    [self deleteTimer];
}

- (void)getCustomerInfo
{
    // (連携システムによって処理先を返る)
    SELConnectionBase* connectionBase = [SELConnectionBase instance];
    connectionBase.delegate = self;
    [connectionBase getCustomerInfo];
}

#pragma mark- SELConnectionBase Delegate

- (void)didOrderConfirm:(BOOL)bSuccess info:(id)info
{
    if (bSuccess) {
        // 注文成功の場合、注文前リストを空にする
        [self clearOrderList];
    }
    [self.delegate didOrderConfirm:bSuccess info:info];
}

- (void)didGetOrderedList:(BOOL)bSuccess orderedList:(NSArray *)orderedList totalPrice:(NSInteger)totalPrice info:(id)info
{
    [self.delegate didGetOrderedList:bSuccess orderedList:orderedList totalPrice:totalPrice info:info];
}

- (void)didCallStaff:(BOOL)bSuccess info:(id)info
{
    [self.delegate didCallStaff:bSuccess info:info];
}

#pragma mark - カートクリア

- (void)createTimer
{
    NSString* sCartClearTime = [[NSUserDefaults standardUserDefaults] objectForKey:@"cartcleartime"];
    // 設定が空の場合は作成しない
    if (sCartClearTime == NULL) {
        return;
    }
    
    // 設定が0の場合は作成しない
    NSInteger cartClearTime = [sCartClearTime integerValue];
    if (cartClearTime <= 0) {
        return;
    }
    
    // 分なので60をかける
//    cartClearTime = 5;    //test
    cartClearTime = cartClearTime * 60;
    
    // Notificationを発行するTimerを起動する
    if (_timerCartClear) {
        // 現在のタイマーは無効
        [self timerOff];
    }
    _timerCartClear = [NSTimer scheduledTimerWithTimeInterval:cartClearTime target:self selector:@selector(timeToCartClear:) userInfo:nil repeats:NO];
}

- (void)deleteTimer
{
    // もし空であればTimerを削除
    if ([self cartCount] == 0) {
        if (_timerCartClear) {
            [_timerCartClear invalidate];
            _timerCartClear = NULL;
        }
    }
}

- (void)timeToCartClear:(NSTimer*)timer
{
    NSLog(@"timeToCartClear!!");
    
    // cartクリアする
    [self clearOrderList];

    // Notification通知(各画面を更新)
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter postNotificationName:SELUpdateOrderListMessageNotification object:self];
}

- (void)timerOff
{
    if (_timerCartClear) {
        // 現在のタイマーは無効
        [_timerCartClear invalidate];
        _timerCartClear = NULL;
    }
}

@end

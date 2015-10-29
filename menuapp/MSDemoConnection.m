//
//  MSDemoConnection.m
//  MenuApp
//
//  Created by dpcc on 12/11/07.
//
//

#import "MSDemoConnection.h"
#import "SELItemDataManager.h"
#import "SELItemData.h"
#import "SELOrderData.h"

@implementation MSDemoConnection

- (void)orderConfirm:(NSArray *)orderList
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        sleep(1);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate didOrderConfirm:TRUE info:NULL];
        });
    });
}

- (void)getOrderedList
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        
        sleep(0.5);
        SELItemDataManager* itemDataManager = [SELItemDataManager instance];
        
        NSMutableArray* orderDetailList = [[NSMutableArray alloc]init];
        
        NSInteger totalPrice = 0;
        
        // 10件分　商品情報からランダムに商品を作成する
        for (int i=0; i < 10; i++ ) {
            
            // dummyデータセット
            SELOrderData* orderData = [[SELOrderData alloc]init];
//            NSMutableDictionary* orderDetailView = [[NSMutableDictionary alloc]init];
            
            // 乱数を発生させる
            int n = random() % [itemDataManager.itemDict count];
            // dummyItemを取得する
            SELItemData* itemData = [itemDataManager getItemDataFromIndex:n];
            if (!itemData) {
                continue;
            }
            
            // 商品データ
            orderData.OrderItemData = itemData;
            
            // 品数(2固定)
            orderData.OrderQuantity = [NSNumber numberWithInteger:2];
            
            // 金額
            orderData.OrderTotalPrice = [NSNumber numberWithInteger:[itemData.price integerValue] * 2];
            
            // 合計金額
            totalPrice += [orderData.OrderTotalPrice integerValue];
            
            // 注文日時(現在時間)
            orderData.OrderDateTime = [NSDate date];
 
            // 取消フラグ
            orderData.OrderCancelFlag = [NSNumber numberWithBool:false];
            
            [orderDetailList addObject:orderData];
        }
        //    [result setValue:ar forKey:kOrderHistoryItemKey];
        
        // Header
        //    NSNumber* totalPriceNum = [[NSNumber alloc]initWithInt:totalPrice];
        //    [result setValue:totalPriceNum forKey:kOrderTotalPriceKey];        // 合計金額
        //    NSNumber* numbers = [[NSNumber alloc]initWithInt:4];      // 来店人数
        //    MSCustomerInfo * customerInfo = [MSCustomerInfo instance];
        //    customerInfo.headCount = [[NSString alloc]initWithFormat:@"%@", numbers];
        //    customerInfo.totalPrice = [[NSString alloc]initWithFormat:@"%@", totalPriceNum];
        
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate didGetOrderedList:TRUE orderedList:orderDetailList totalPrice:totalPrice info:NULL];
        });

    });

}

- (void)callStaff
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0),^{
        sleep(1);
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self.delegate didCallStaff:TRUE info:NULL];
        });
    });
    return;
}

@end

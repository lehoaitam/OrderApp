//
//  注文商品ひとつひとつを表すオブジェクト
//  SELOrderData.h
//  menuapp
//
//  Created by dpcc on 2014/05/26.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SELItemData.h"

@interface SELOrderData : NSObject

// 以下はRequest/Reponse時に使用する
@property SELItemData* OrderItemData;       // 注文商品
@property SELItemData* SelectedCustomOrder; // 選択されたカスタムオーダー
@property NSMutableArray* SelectedTopping;         // 選択されているトッピング
@property NSNumber* OrderQuantity;        // 注文数
@property NSDate* OrderDateTime;          // 注文時刻

// 以下はResponse受信時のみ使用する
@property NSString* OrderDetailNO;      // オーダー番号
@property NSNumber* OrderTotalPrice;    // 合計金額
@property NSNumber* OrderCancelFlag;    // キャンセルされている場合は1

@end

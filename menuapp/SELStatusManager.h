//
//  SELStatusManager.h
//  selforder
//
//  Created by dpcc on 2014/09/29.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol SELStatusManagerDelegate <NSObject>

@optional
- (void)didGetiPadList:(BOOL)bSuccess info:(id)info;

@end

@interface SELStatusManager : NSObject

+ (id)instance;

// 現在の端末状態を送信する, レスポンスで端末設定状態を取得する
- (void)sendCurrentStatus;

// 商品状態を取得する
- (void)updateItemStatus;

// iPadList取得
- (void)getIpadList;

@property id<SELStatusManagerDelegate> delegate;

@end

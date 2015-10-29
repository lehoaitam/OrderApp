//
//  SELMenuDataManager.h
//  menuapp
//
//  Created by dpcc on 2014/04/08.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <Foundation/Foundation.h>

UIKIT_EXTERN NSString *const SELMenuChangeNotification;
UIKIT_EXTERN NSString *const SELUISettingChangeNotification;
UIKIT_EXTERN NSString *const SELUpdateMenuSuccessNotification;
UIKIT_EXTERN NSString *const SELUpdateMenuErrorNotification;
UIKIT_EXTERN NSString *const SELUpdateMenuStatusNotification;

@interface SELMenuDataManager : NSObject {
}

+ (id)instance;

// デモデータを展開する
- (void)CreateDemoData;

// Menuのリストを返す
- (NSArray*)GetMenus;

// Menuの名称を返す
- (NSString*)GetMenuName:(NSInteger)menuNumber;

// Menuの言語を返す
- (NSString*)GetMenuLocalization:(NSInteger)menuNumber;

// 現在のMenuのTOPページを返す
- (NSURL*)GetTopMenu;

// データのアップデートを行う
- (void)Update;

// メニューデータの再読み込みを行う
- (void)UpdateMenuPages;

// Menu番号からMenuのPathを返す
- (NSString*)getCurrentMenuWorkPath;

@property NSMutableArray* MenuPages;

@end

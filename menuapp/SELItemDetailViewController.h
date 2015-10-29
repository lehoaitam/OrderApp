//
//  SELItemDetailViewController.h
//  menuapp
//
//  Created by dpcc on 2014/04/11.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SELItemData.h"
#import "SELCustomOrderData.h"
#import "SELCustomOrderViewController.h"
#import "SELOrderManager.h"
#import "SELBadgeView.h"
#import "SELToppingGroupData.h"
#import "SELToppingViewController.h"

@interface SELItemDetailViewController : UIViewController<SELCustomOrderViewControllerDelegate, SELOrderManagerDelegate, SELToppingViewControllerDelegate, UIPopoverControllerDelegate> {
    
    // 表示部品
    IBOutlet UILabel* _name;
    IBOutlet UILabel* _price;
    IBOutlet UIImageView* _image;
    IBOutlet UITextView* _description;
    
    IBOutlet UILabel* _suggestTitle;
    IBOutlet UIButton* _suggest1;
    IBOutlet UILabel* _suggest1label;
    IBOutlet UIButton* _suggest2;
    IBOutlet UILabel* _suggest2label;
    IBOutlet UIButton* _suggest3;
    IBOutlet UILabel* _suggest3label;
    
    // カスタムオーダー
    IBOutlet UILabel* _customOrderTitleLabel;
    IBOutlet UILabel* _customOrderValueLabel;
    IBOutlet UIButton* _customOrderButton;
    
    // トッピング
    IBOutlet UILabel* _toppingTitleLabel;
    IBOutlet UILabel* _toppingValueLabel;
    IBOutlet UIButton* _toppingButton;
    
    // 注文リストボタン
    IBOutlet UIButton* _orderListButton;
    IBOutlet SELBadgeView* _badgeView;
    
    // 商品にひもづくカスタムオーダー
    SELCustomOrderData* _customOrderData;
    
    // 選択されたカスタムオーダー
    SELItemData* _selectedCustomOrderData;
    
    // 商品にひもづくトッピング
    SELToppingGroupData* _toppingGroupData;
    
    // 選択されたトッピング
    NSMutableArray* _selectedToppingDataList;
    
    // ポップオーバー保持用
    UIPopoverController* _popover;
    
    // 注文ボタン
    IBOutlet UIButton* _addOrderButton;
    
    // アニメーションView用Queue
    NSMutableArray* _animationViewQueue;
//    UIImageView* _animationView;
    
    // 点滅用
    NSTimer* _blinkTimer;
    IBOutlet UILabel* _blinkLabel;
    
    // 個数変更用
    NSInteger _quantity;
    IBOutlet UILabel* _quantityLabel;
    IBOutlet UIButton* _quantityPlusButton;
    IBOutlet UIButton* _quantityMinusButton;
    
    // MENUへ戻る
    IBOutlet UILabel* _toMenuLabel;

    // 注文ボタン（注意書き）
    IBOutlet UILabel* _addOrderNote;
    
    // 円
    IBOutlet UILabel* _yen;
    
    // 個
    IBOutlet UILabel* _pieces;
}

- (IBAction)list:(id)sender;
- (IBAction)dismiss:(id)sender;

// 関連商品
- (IBAction)touchSuggest1:(id)sender;
- (IBAction)touchSuggest2:(id)sender;
- (IBAction)touchSuggest3:(id)sender;

// 注文する
- (IBAction)addOrder:(id)sender;

- (IBAction)touchCustomOrder:(id)sender;

- (IBAction)touchTopping:(id)sender;

- (IBAction)touchQuantityPlus:(id)sender;
- (IBAction)touchQuantityMinus:(id)sender;

// 商品データ(メニューから渡される)
@property SELItemData* ItemData;

@end

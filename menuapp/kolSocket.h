//
//  kolSocket.h
//  socketTab
//
//  Created by Kobe Digital Labo on 10/10/28.
//  Updated by Kobe Digital Labo on 10/11/29.
//
//  Copyright 2010 Kobe Digital Labo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import "kolSocketStruct.h"


@protocol KolSocketDelegate;					// 参照用


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface kolSocket : NSObject {
	
	NSNumber *operationFlag;					// 稼働中フラグ
	NSString *charge;							// 担当者
	NSString *headCount;						// 数量
	NSString *totalPrice;						// 合計金額
	unsigned int reqNo;							// リクエストNO(APLがリクエストする番号)
	
	id <KolSocketDelegate> delegate;
	
	AsyncSocket *asyncSocket;
    
    NSString* _errorString;
}


@property (nonatomic, assign) id <KolSocketDelegate> delegate;
@property (nonatomic, copy) NSString * hostAddr;	// STN　IPアドレス
@property (nonatomic, copy) NSString * portReq;		// STN　ポート番号（要求）
@property (nonatomic, copy) NSString * portAsk;		// STN　ポート番号（照会）
@property (nonatomic, copy) NSString * rtry;		// STN　リトライ回数

// 2012.01.23 n.sasaki memoryleak対応
@property (nonatomic, retain) AsyncSocket *asyncSocket;

////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark 画面とのI/Fメソッド定義	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
+ (id)instance;
- (NSNumber*)customerInfoFromTableID:(NSString *)tableID;
- (NSNumber*)orderingOfItems:(NSString*)tableID orderItems:(NSArray*)items;
- (NSNumber*)orderHistoryFromTableID:(NSString *)tableID;

@end


//----------------------------------
// プロトコル宣言
@protocol KolSocketDelegate

// 画面アプリにデータを返すdelegate method
- (void)kolSocket:(NSNumber *)reqNo didReadData:(id)data  error:(NSError*)error;


@end


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark 画面とのI/Fデータ
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

//// 画面とのI/Fデータ
//extern NSString *const kItemMenuCodeKey;		// メニューコード
//extern NSString *const kItemPriceKey;			// 価格
//extern NSString *const kItemQuantityKey;		// 注文数量
//extern NSString *const kItemSetItemkey;			// SCP情報　配列が返る。 nilが返ると単品
//extern NSString *const kItemKaisouCodekey;		// 階層コード
//extern NSString *const kItemSijiStatuskey;		// 指示ステータス
//extern NSString *const kItemSijiNOkey;			// 指示NO
//extern NSString *const kItemSt1key;             // ステータス１
//extern NSString *const kItemSt2key;             // ステータス２
//extern NSString *const kItemOrderDate;          // 注文時間時間
//// 0: メインメニュー、１：コメントメニュー、
//// ２：サブメニュー、３セットメニュー
//
//
//// 商品履歴データ
//extern NSString *const kOrderHistoryItemKey;
//extern NSString *const kOrderTotalPriceKey;

//商品CSV
static NSString *const kItemMenuCodeKey = @"menuCode";
static NSString *const kItemImageKey = @"image";
static NSString *const kItemNameKey = @"itemName";
static NSString *const kItemPriceKey = @"price";
static NSString *const kItemSubpriceKey = @"subprice";
static NSString *const kItemCategory1CodeKey = @"category1_code";
static NSString *const kItemCategory1NameKey = @"category1_name";
static NSString *const kItemCategory2CodeKey = @"category2_code";
static NSString *const kItemCategory2NameKey = @"category2_name";
static NSString *const kItemSuggest1Key = @"suggest1";
static NSString *const kItemSuggest2Key = @"suggest2";
static NSString *const kItemSuggest3Key = @"suggest3";
static NSString *const kItemAdLink = @"adLink";
static NSString *const kItemDescriptionKey = @"desc";
static NSString *const kItemOther1Key = @"other1";
static NSString *const kItemOther2Key = @"other2";
static NSString *const kItemSCP1Key = @"SCP1";
static NSString *const kItemSCP2Key = @"SCP2";
static NSString *const kItemSCP3Key = @"SCP3";
static NSString *const kItemSCP4Key = @"SCP4";
static NSString *const kItemSCP5Key = @"SCP5";
static NSString *const kItemSCP6Key = @"SCP6";
static NSString *const kItemSCP7Key = @"SCP7";
static NSString *const kItemSCP8Key = @"SCP8";
static NSString *const kItemSCP9Key = @"SCP9";
static NSString *const kItemSCP10Key = @"SCP10";
static NSString *const kItemSCP11Key = @"SCP11";
static NSString *const kItemSCP12Key = @"SCP12";
static NSString *const kItemSetItemkey = @"setItem";
static NSString *const kItemSetItemDatakey = @"setItemData";
static NSString *const kItemKaisouCodekey = @"kaisouCode";
static NSString *const kItemSijiStatuskey = @"sijiStatus";
static NSString *const kItemSijiNOkey = @"sijiNO";
static NSString *const kItemInItemCount = @"inItemCount";
static NSString *const kItemOrderDate = @"orderDate";
static NSString *const kItemArryaNumber = @"no";
static NSString *const kItemIsCommentKey = @"isComment";
static NSString *const kItemIsSubKey = @"isSub";
static NSString *const kItemIsSetKey = @"isSet";

// 2012.01.24 n.sasaki 取消情報対応
static NSString *const kItemSt2key = @"ST2";

// 2012.01.10 n.sasaki 時間帯対応
static NSString *const kItemStartTime = @"startTime";
static NSString *const kItemEndTime = @"endTime";

//内部データ
static NSString *const kItemQuantityKey = @"quantity";

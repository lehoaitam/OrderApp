//
//  PrinterController.h
//  MenuApp
//
//  Created by ipadso on 12/03/05.
//  Copyright (c) 2012年 Kobe Digital Labo.,Inc. All rights reserved.
//  レジ無版対応

#include <unistd.h>

#import <sys/time.h>
#import <Foundation/Foundation.h>
#import "StarIO/Port.h"
#import "OrderStarPrinter.h"

// 会計伝票種別
#define BIG_SLIP_MASTER 0   // 店舗会計用
#define BIG_SLIP_COPY 1     // ゲスト控え用

@interface PrinterController : NSObject<OrderStarPrinterDelegate>
{
    // システム共通パラメータ(setting.jsonの設定項目)
    unsigned int _printerOpenTimeOut;       // プリンターオープンタイムアウト=ミリ秒
    unsigned int _printerOpenRetryNum;      // プリンターオープン最大リトライ回数
    unsigned int _printerOpenRetryWait;     // プリンターオープンリトライ時の待ち時間ベース=マイクロ秒
    unsigned int _printerOpenRetryRand;     // プリンターオープンリトライ時の待ち時間乱数範囲
    unsigned int _printerCheckRetryNum;     // プリンタ状態チェック最大リトライ回数
    unsigned int _printerCheckRetryWait;    // プリンタ状態チェックリトライ時の待ち時間ベース=マイクロ秒
    unsigned int _printerCheckRetryRand;    // プリンタ状態チェックリトライ時の待ち時間乱数範囲
    unsigned int _printItemsPerPage;        // 会計伝票改ページ商品数の閾値
    BOOL _bigSlipPageBreak;                 // 会計伝票改ページ有無[0:改ページしない／1:改ページする]
    BOOL _charPrintSizeExpansion;           // 印字文字サイズ拡大有無[0:拡大しない／1:拡大する]
    
    // 伝票ヘッダ項目
    NSString * _orderDate;  // 注文日時
    NSString * _tableNo;    // テーブルNo.
    NSString * _slipNo;     // 伝票No.

    // 伝票No管理ファイル
    NSString * _slipNoFilePath; // 伝票No管理ファイルのパス
    NSString * _slipNoData;     // 伝票No管理ファイル設定値
    
    // 注文コマンド
    NSMutableData * _orderCommands;
    NSData * _oderItemEncoding;
    unsigned char * _orderItemBytesData;
    
    // エラー情報
    NSMutableArray * _errInfo;
}

// インスタンス取得
+ (id)instance;

// スタッフ呼出伝票印刷処理
//- (void)printCallStaff;

// 注文伝票印刷処理
- (NSMutableArray *)printOrder:(NSDictionary *)orderHeaderDict orderDetailList:(NSArray*)orderDetailList;

// 厨房伝票印刷処理
- (NSMutableArray *)printSmallSlip:(NSArray *)items;

// 会計伝票印刷処理
- (void)printBigSlip:(NSArray *)items slipKind:(int)slipkind;

// セット商品名取得
- (NSMutableArray *)getSetItemName:(NSDictionary *)orderDict;

// 会計伝票金額計算行印字フォーマット変換
- (NSMutableString *)convertFormatCalculationRow:(NSDictionary *)orderDict;

// 金額印字フォーマット変換
- (NSString *)convertFormatAmount:(int)amount;

// 伝票No取得処理
- (BOOL)getSlipNo;

// 伝票No更新処理
- (BOOL)updateSlipNo;

// 注文コマンド初期化
- (void)initOrderCommand;

// 注文コマンド解放
- (void)releaseOrderCommand;

// 注文コマンド作成処理
- (void)createOrderCommand:(NSMutableString *)orderItem;

// プリンター設定コマンド送信処理
- (BOOL)printSetting:(Port *)starPort;

// 厨房伝票印刷用プリンターポートオープン
- (Port *)openPrinterPortForSmallSlip:(NSDictionary *)orderDict;

// 会計伝票印刷用プリンターポートオープン
- (Port *)openPrinterPortForBigSlip;

// プリンターポートオープン
- (Port *)openPrinterPort:(NSString *)portName portSettings:(NSString *)portNo;

// プリンターポートクローズ
- (void)closePrinterPort:(Port *)starPort;

// プリンター出力処理
- (BOOL)writeCommandToPrinter:(Port *)starPort printCommands:(NSMutableData *)commands;

// プリンター状態チェック処理
- (BOOL)checkPrinterStatus:(Port *)starPort;

// エラー情報編集
- (NSString *)errInfoToString;

@end

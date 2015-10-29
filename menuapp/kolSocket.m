

//
//  kolSocket.m
//  socketTab
//
//  Created by Kobe Digital Labo on 10/10/28.
//  Updated by Kobe Digital Labo on 10/12/09.
//  Copyright 2010 Kobe Digital Labo. All rights reserved.
//

#import "kolSocket.h"
#import "kolSocketStruct.h"

#import "logger.h"  // add by n.sasaki 2012.03.06 志対応

static id _instance = nil;

NSString *const kOrderHistoryItemKey = @"orderHistory";
NSString *const kOrderTotalPriceKey = @"totalPrice";



/*----------- NSError 
 
NSError

[NSError errorWithDomain:NSCocoaErrorDomain
					code:NSFileReadCorruptFileError
				userInfo:nil];

 @interface NSError : NSObject <NSCopying, NSCoding> {
 @private
 void *_reserved;
 NSInteger _code;
 NSString *_domain;
 NSDictionary *_userInfo;
 }
 
 [NSError errorWithDomain:NSCocoaErrorDomain
 code:NSFileReadCorruptFileError
 userInfo:nil];
 
 
 NSDictionary *errDict = [NSDictionary dictionaryWithObjects:err forKeys:@"message"];
 nErr = [[[NSError alloc]initWithDomain:@"KOLSOCKETDOMAIN" code:-10 userInfo:nil] ;
 
 
 
 *error = [[[NSError alloc] initWithDomain:NSPOSIXErrorDomain code:errno
 userInfo:
 [NSDictionary dictionaryWithObjects:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%s", strerror(errno)], nil] forKeys:[NSArray arrayWithObjects:NSLocalizedDescriptionKey, nil]]] autorelease];
 
 

 遅延でメソッドを呼ぶ方法
 
 [self performSelector:@selector(kolSocket:didReadData:error:) afterDelay:0.5]
 
 --------------------------------------------*/




////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark 内部メソッド定義	
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
@interface kolSocket (Private)

//
// 初期処理系
- (id)init;
- (id)initWithDelegate:(id)adelegate;
- (void)dealloc;


//
// シングルトン
+ (id)instance;
+ (id)allocWithZone:(NSZone *)zone;
- (id)copyWithZone:(NSZone *)zone;
- (NSUInteger)retainCount;
- (void)release;
- (id)autorelease;

//
// ソケット操作
- (BOOL) kolSocketOpen:(NSString*)host_adr port:(NSString*)portNo retry:(NSString*)rTryTime;
- (BOOL) kolSocketClose;

//
// AsyncSocketDelegate
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port;
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag;
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err;
- (void)onSocketDidDisconnect:(AsyncSocket *)sock;

//
// 応答伝文生成
- (void)resCustomerData:(NSData*)data customerData:(NSMutableDictionary *)dict;
- (void)resOrderingData:(NSData*)data sinagireData:(NSMutableArray**)theArray;
- (void)resOrderDspData:(NSData*)data orderData:(NSMutableArray**)orderData;


//
// 内部処理
- (void) dateGet:(unsigned char*)ymdhms;
- (void) strToPack:(NSString*)nStr length:(int)length packStr:(unsigned char*)pStr fugou:(int)fugou;
- (void) packToStr:(unsigned char*)packStr  length:(int)length  zoneStr:(unsigned char*)zoneStr fugou:(int)fugou;
- (unsigned char) checkSum:(unsigned char*)data startAddr:(int)sptr  endAddr:(int)eptr;

//
// 伝文生成
- (NSInteger) makeDataCustomerRequest:(TableNo_ReqStruct*)data tableno:(NSString*) tableNo;
- (BOOL)makeDataOrdering:(NSArray*)items  buffer:(OrderItemStruct*)data error:(NSError **) error;
- (BOOL) makeDataOrderingHead:(NSString*)tableID data:(OrderRequestHeadStruct*)data error:(NSError **) error;
- (NSInteger) makeDataOrderDspRequest:(TableNo_ReqStruct*)data tableno:(NSString*) tableNo;

@end



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark -
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation kolSocket



@synthesize delegate;
@synthesize hostAddr;				// STN　IPアドレス	
@synthesize portReq;				// STN　ポート番号（要求）
@synthesize portAsk;				// STN　ポート番号（照会）
@synthesize rtry;					// STN　リトライ回数

// n.sasaki 2012.01.23 memoryleak対応
@synthesize asyncSocket;

// オーダーヘッダーデータの退避バッファ
//  顧客照会においてSTNより取得したデータを保持して
//  注文時に送信伝文に該当データを含めて送信する
OrderHeadStruct saveOrderHeadData;


//
//
- (id)init
{
	return [self initWithDelegate:nil];
}


//
//
- (id)initWithDelegate:(id)adelegate
{
		
	if( self = [super init] )
	{
	
		delegate = adelegate;
#ifdef _DEBUG_DETAIL_	
		NSLog(@" ====  initWithDelegate ======== reqNo(%d)",reqNo);
#endif		
		reqNo = 0;				// リクエストNO クリア
	}
	return self;
}


//
//
- (void)dealloc
{

	[super dealloc];
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark --
#pragma mark シングルトン
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*
 * 以下はシングルトンにする為に必須のオーバーライド
 */

//
// インスタンス取得（クラスメソッド）
+ (id)instance {
	@synchronized(self) {
		if(!_instance) {
			[[self alloc] init];
		}
	}
	return _instance;
}

//
// インスタンスのメモリ領域を確保する（クラスメソッド）
+ (id)allocWithZone:(NSZone *)zone {
	@synchronized(self) {
		if (!_instance) {
			_instance = [super allocWithZone:zone];
			return _instance;
		}
	}
	return nil;
}

//
//
- (id)copyWithZone:(NSZone *)zone {
	return self;	// シングルトン状態を保持するため何もせず self を返す
}

//
//
- (id)retain {
	return self;	// シングルトン状態を保持するため何もせず self を返す
}

//
//
- (NSUInteger)retainCount {
	return UINT_MAX;	// 拡散できないインスタンスを表すため unsigned int 値の最大値　UINT_MAXを返す
}

//
//
- (oneway void)release {
		// シングルトン状態を保持するため何もしない
}

//
//
- (id)autorelease {
	return self;	// シングルトン状態を保持するため何もせず self を返す
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark --
#pragma mark socket Method
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/********************************************************/
/*			ソケット操作共通処理								*/
/********************************************************/
/*----------------------------------------------*/
/*		ソケット接続								*/
/*		引数説明	:								*/
/*			(I)　ソケット接続ホストIP				*/
/*			(I)　接続ポート						*/
/*----------------------------------------------*/
- (BOOL) kolSocketOpen:(NSString*)host_adr port:(NSString*)portNo retry:(NSString*)rTryTime
{
	int		i_portNo;
	double	d_rtryTime;
	
#ifdef _DEBUG_DETAIL_
	NSLog(@"kolSocket--> kolSocketOpen () リクエストNO(%d) in ---------->>",reqNo);
	NSLog(@"  接続先IPアドレス:(%@) ポート番号:(%@) リトライタイム(%@)",host_adr,portNo,rTryTime);
#endif

	if (self = [super init]){
		
#ifdef _DEBUG_DETAIL_
		NSLog(@"       kolSocketOpen asyncSocket retainCount(%d)---------->>",[asyncSocket retainCount]);
#endif
        // 2012.01.23 n.sasaki memoryleak修正
		//asyncSocket = [[AsyncSocket alloc] initWithDelegate:self];
		self.asyncSocket = [[[AsyncSocket alloc] initWithDelegate:self] autorelease];
#ifdef _DEBUG_DETAIL_
		NSLog(@"       kolSocketOpen asyncSocket retainCount(%d)---------->>",[asyncSocket retainCount]);
#endif
		
	}
	
	NSError *err = nil;	
	
	// ポート番号を整数型に変換する
	i_portNo = [portNo integerValue];
	
	// リトライタイムををdouble型に変換する
	d_rtryTime = [rTryTime doubleValue];
	
#ifdef _DEBUG_DETAIL_
	NSLog(@"                   ポート番号:(%d) リトライタイム(%f)",i_portNo,d_rtryTime);
#endif
	
	NSTimeInterval ntime = d_rtryTime;

	// 接続
	if(![self.asyncSocket connectToHost:host_adr onPort:i_portNo withTimeout:ntime error:&err]) // 2012.01.23 n.sasaki memoryleak対応
	{
		NSLog(@"connectToHost Error: %@", err);
		return NO;
	}
	
	
#ifdef _DEBUG_DETAIL_
	NSLog(@"kolSocket--> kolSocketOpen () OUT <<------- ");
#endif
	
	return YES;
}



/*----------------------------------------------*/
/*		切断										*/
/*		引数説明	:								*/
/*			なし									*/
/*----------------------------------------------*/
- (BOOL) kolSocketClose
{
#ifdef _DEBUG_DETAIL_
	NSLog(@"kolSocket--> kolSocketClose () in ");
#endif
	
	[self.asyncSocket disconnect];
	
	return YES;
}


/*----------------------------------------------*/
/*		画面へのdelegate通知用						*/
/*		引数説明	:								*/
/*			なし									*/
/*----------------------------------------------*/
- (void)nopSocket {
	
	NSError *err = nil;
	NSNumber *numReqNo;
	
	numReqNo = [NSNumber numberWithInt:reqNo];
	
	err = [NSError errorWithDomain:NSCocoaErrorDomain
							  code:-1
						  userInfo:nil];
	
	[delegate kolSocket:numReqNo didReadData:(id)nil error:err];

	return;
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark --
#pragma mark from asyncSocket CallBack Method
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/********************************************************/
/*			コールバック処理								*/
/********************************************************/

/*----------------------------------------------*/
/*		ソケット接続完了時にCALLBACKされる			*/
/*		引数説明	:								*/
/*			(I) ソケット接続子						*/
/*			(I) ソケット接続ホストIP				*/
/*			(I) 接続ポート							*/
/*----------------------------------------------*/
- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
#ifdef _DEBUG_DETAIL_
	NSLog(@" ソケット接続完了 onSocket:%p didConnectToHost:%@ port:%hu", sock, host, port);
#endif
	
	//受信完了のCALLBACKを有効にする
	[sock readDataWithTimeout:-1 tag:0];
		
	return;
	
}

/*----------------------------------------------*/
/*		STNからの伝文エラーチェック					*/
/*		引数説明	:								*/
/*			(I) 受信データ							*/
/*----------------------------------------------*/
- (BOOL)dataErrChk:(NSData*)data
{
	unsigned char errorStatus = 0x00;
//	NSString	*string;
	int	sinagireFlg= 0;
	
	// LANヘッダー部　領域取得
	LanHeadStruct lanHead;
	[data getBytes:&lanHead length: sizeof( lanHead) ];
	
#ifdef _DEBUG_
	NSLog(@"  Ack NAK (%c) errorStatus(%c%c)", lanHead.d_an,lanHead.d_status[0],lanHead.d_status[1]);
	NSLog(@"  ADP     (%c) 電文種別(%c%c%c%c%c%c)", lanHead.d_adp,lanHead.d_knd[0],lanHead.d_knd[1],lanHead.d_knd[2]
		  ,lanHead.d_knd[3],lanHead.d_knd[4],lanHead.d_knd[5]);
#endif
	
	//
	// NAK 応答の判定
	if( lanHead.d_an == 'N' ){
		// NAK応答を受信しました。
#ifdef _DEBUG_
		NSLog(@"NAK応答を受信しました");
#endif
		
		// 顧客照会応答時に 該当伝票NOなし（追加）エラー (D7) の場合はエラーを表示しない
		if( memcmp( lanHead.d_knd ,"1K2HO0", 6) == 0 && memcmp( lanHead.d_status, "D7", 2 ) == 0 ){				
			errorStatus = 0x00;
		}else
			errorStatus = 0x01;
		
	}else if( lanHead.d_an != 'A' ){
		// ACK応答を以外の伝文を受信しました。
#ifdef _DEBUG_
		NSLog(@"NAK/ACK応答以外の伝文種別を受信しました");
#endif
		errorStatus = 0x01;		
	}
	
	// ADP種別チェック
	if( lanHead.d_adp != 'R' ){
		// レスポンスエラー
#ifdef _DEBUG_
		NSLog(@" ADP種別が　R（返信伝文）以外で返信された");
#endif
		errorStatus = 0x01;
	}
	
	if( errorStatus != 0x00 ){
		if( memcmp( lanHead.d_status, "C1", 2) == 0 ){
		
			_errorString = [NSString stringWithFormat:@"もう一度注文してください:(%c%c)",
									lanHead.d_status[0],lanHead.d_status[1]];
		
		}else if( memcmp(lanHead.d_status, "D7", 2) == 0 ){
			_errorString = [NSString stringWithFormat:@"伝票NOがありません:(%c%c)",
									lanHead.d_status[0],lanHead.d_status[1]];
		
		}else if( memcmp(lanHead.d_status, "D9", 2) == 0 ){
			_errorString = [NSString stringWithFormat:@"品切れの商品があります:(%c%c)",
									lanHead.d_status[0],lanHead.d_status[1]];
//			sinagireFlg = 1;
		
		}else{
			_errorString = [NSString stringWithFormat:@"エラーが発生しました:(STN-%c%c)",
									lanHead.d_status[0],lanHead.d_status[1]];
		}
		
		/*
		NSString *string = [NSString stringWithFormat:@"%s:(%c%c)",
							comment,lanHead.d_status[0],lanHead.d_status[1]];
		*/
		
//        //品切メッセージ無限ループ修正 kitada 2012.01.25
//		if ( !sinagireFlg ) {
//            //品切れ以外のエラーはアラート表示
//            UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"エラーが発生しました"
//													  message:string
//													 delegate:nil
//											cancelButtonTitle:@"はい"
//											otherButtonTitles:nil];
//            [av show];
//            [av release];
//        }
        
	
		if( sinagireFlg == 1 )
			return YES;
		else
			return NO;
	}
	
	return YES;
}



/*----------------------------------------------*/
/*	データ受信時にAsyncSocketよりdelegate通知される	*/
/*		引数説明	:								*/
/*			(I) ソケット接続子						*/
/*			(I) 受信データ							*/
/*			(I) タグ								*/
/*----------------------------------------------*/
- (void)onSocket:(AsyncSocket *)sock didReadData:(NSData*)data withTag:(long)tag
{
    // add by n.sasaki 2012.03.06 志対応
    [Logger WriteLog:data sendrecv:false];
    
	NSError *err = nil;
	NSNumber *numReqNo;
	BOOL ret;

	/*---- Start ----*/
	
	numReqNo = [NSNumber numberWithInt:reqNo];
	
#ifdef _DEBUG_
	NSLog(@"=================================================");	
	NSLog(@" STNより応答伝文を受信しました(%@)", data);	
	NSLog(@"=================================================");	
#endif
	
	// LANヘッダー部　領域取得
	LanHeadStruct lanHead;
	[data getBytes:&lanHead length: sizeof( lanHead) ];

#ifdef _DEBUG_
	NSLog(@"  Ack NAK (%c) errorStatus(%c%c)", lanHead.d_an,lanHead.d_status[0],lanHead.d_status[1]);
	NSLog(@"  ADP     (%c) 電文種別(%c%c%c%c%c%c)", lanHead.d_adp,lanHead.d_knd[0],lanHead.d_knd[1],lanHead.d_knd[2]
		  ,lanHead.d_knd[3],lanHead.d_knd[4],lanHead.d_knd[5]);
#endif

	// STNからの伝文チェック
	ret = [self dataErrChk:data];
	
	if( ret == NO ){
		// 画面に渡す
		if( [(NSObject *)delegate respondsToSelector:@selector(kolSocket:didReadData:error:)])
		{
//			err = [NSError errorWithDomain:NSCocoaErrorDomain
//									  code:-1
//								  userInfo:nil];
            
            err = [NSError errorWithDomain:_errorString code:-1 userInfo:nil];
			
			[delegate kolSocket:(NSNumber *)numReqNo didReadData:nil error:err];
			return;
		}
	}

	
	// 伝文種別チェック
	//		顧客照会			1K2HO0
	//		注文				2L0HO0
	//		注文照会			2L1HO0

	//
	// 顧客照会　応答
	if( memcmp( lanHead.d_knd ,"1K2HO0", 6)==0 ){
#ifdef _DEBUG_
		NSLog(@"　　>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");	
		NSLog(@"　　　　受信しました伝文は「顧客照会　応答伝文」です。");
		NSLog(@"　　>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");	
#endif	
		// 配列を作成する
		NSMutableDictionary *dict;
		dict = [NSMutableDictionary dictionary];
		[self resCustomerData:(NSData*)data customerData:(NSMutableDictionary*)dict];
	
		// 画面に渡す
		if( [(NSObject *)delegate respondsToSelector:@selector(kolSocket:didReadData:error:)])
		{
			
			[delegate kolSocket:(NSNumber *)numReqNo didReadData:(id)dict error:(NSError*)err];
		}
	}

	//
	// 注文　応答
	else if( memcmp( lanHead.d_knd ,"2L0HO0", 6)==0 ){
#ifdef _DEBUG_
		NSLog(@"　　>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");	
		NSLog(@"　　　　受信しました伝文は「注文　応答伝文」です。");
		NSLog(@"　　>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");	
#endif
		
		// 画面に渡す注文履歴情報エリア
		NSMutableArray *theArray = [NSMutableArray array];
		[self resOrderingData:data sinagireData:&theArray];

#ifdef _DEBUG_DETAIL_		
		NSLog(@"============================================");
		NSLog(@"  画面に返す注文応答伝文の情報です(%@)",theArray);
		NSLog(@"============================================");
#endif
		// 画面に渡す
		if( [(NSObject *)delegate respondsToSelector:@selector(kolSocket:didReadData:error:)])
		{
			[delegate kolSocket:(NSNumber *)numReqNo didReadData:(id)theArray error:(NSError*)err];
		}
		
	}

	//
	//　注文照会 応答
	else if( memcmp( lanHead.d_knd ,"2L1HO0", 6)==0 ){
#ifdef _DEBUG_
		NSLog(@"　　>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");	
		NSLog(@"　　　　受信しました伝文は「注文照会 応答」です。");
		NSLog(@"　　>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>>");	
#endif
		


		NSMutableDictionary *dict;
		dict = [NSMutableDictionary dictionary];

		// 画面に渡す注文履歴の情報を配列に作って辞書形式にセット
		NSMutableArray *theArray = [NSMutableArray array];		
		[self resOrderDspData:data orderData:&theArray];
		[dict setObject:theArray forKey:kOrderHistoryItemKey];
		
		//　合計金額はNSString型で　辞書形式にセット
		AckResponceStruct	ackResponceStruct;
		[data getBytes:(unsigned char*)&ackResponceStruct range:NSMakeRange(0,sizeof(ackResponceStruct)-1)];
		char str12[12];
		memset( (char*)str12, (char)0x00, sizeof(str12));
		[self packToStr:&ackResponceStruct.orderSubHeadStruct.d_goukei[0] length:9 zoneStr:(u_char*)str12 fugou:1];
		[dict setObject:[NSString stringWithCString:(char*)str12 encoding:NSUTF8StringEncoding] forKey:kOrderTotalPriceKey];

		
		// 画面に渡す
		if( [(NSObject *)delegate respondsToSelector:@selector(kolSocket:didReadData:error:)])
		{
			//[delegate kolSocket:(NSNumber *)numReqNo didReadData:(id)theArray error:(NSError*)err];
			[delegate kolSocket:(NSNumber *)numReqNo didReadData:(id)dict error:(NSError*)err];
		}
		
	}
	
	// 
	//　不定 応答
	else {
		NSLog(@"伝文種別エラー");
		return;
	}

	
	[sock readDataWithTimeout:-1 tag:0];

	
#ifdef _DEBUG_DETAIL_
	NSLog(@"kolSocket--> onSocket:didReadData   OUT  <<-------");
#endif	

	return;
	
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark --
#pragma mark responceData Method
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*----------------------------------------------*/
/*		顧客照会　応答データチェック処理				*/
/*		引数説明	:								*/
/*			(I) 受信データ							*/
/*----------------------------------------------*/
- (void)resCustomerData:(NSData*)data customerData:(NSMutableDictionary*)dict
{
	unsigned char str[8];
	unsigned char * zoneStr;	// ゾーン10進数変換後バッファ
	int length = 0;				// パック10進数桁数
	
	/*----- Start ------*/
#ifdef _DEBUG_DETAIL_
	NSLog(@"----- 顧客照会　応答データチェック処理(resCustomerData) IN  ------->>");
#endif	
	
	// LANヘッダー部　領域取得
	LanHeadStruct lanHead;
	[data getBytes:&lanHead length: sizeof( lanHead) ];
	
	//
	// NAK 応答の判定
	if( lanHead.d_an == 'N' ){
		// NAK応答を受信しました。
#ifdef _DEBUG_
		NSLog(@"NAK応答を受信しました");
#endif
		// 稼働中フラグ　OFF
		[dict setObject:[NSNumber numberWithInteger:0] forKey:@"operationFlag"];
		
	}else if( lanHead.d_an != 'A' ){
		// ACK応答を以外の伝文を受信しました。
		

#ifdef _DEBUG_
		NSLog(@"NAK/ACK応答以外の伝文種別を受信しました");
#endif
		// 稼働中フラグ　OFF
		[dict setObject:[NSNumber numberWithInteger:0] forKey:@"operationFlag"];
		
	}else {
		
#ifdef _DEBUG_
		NSLog(@"ACK応答を受信しました");
#endif
		// ACK応答時の処理
		AckResponceStruct ackData;
		[data getBytes:&ackData length: sizeof( ackData) ];
		
		
		// オーダーヘッダ部を退避する。
		memcpy( &saveOrderHeadData, &ackData.orderHeadStruct, sizeof(saveOrderHeadData) );
		
		// 稼働中フラグ　ON
		[dict setObject:[NSNumber numberWithInteger:1] forKey:@"operationFlag"];
		
#ifdef _DEBUG_DETAIL_
		NSLog(@" 担当者 charge(%s)",ackData.orderHeadStruct.d_tantou);
#endif
		// 担当者NO
		memset( (char*)str, (char)0x00, (int)8);
		memcpy( str, ackData.orderHeadStruct.d_tantou, 5 );
		[dict setObject:[NSString stringWithCString:(char*)str encoding:NSUTF8StringEncoding] forKey:@"charge"];
#ifdef _DEBUG_DETAIL_
		NSLog(@" 担当者 charge(%s)",str);
#endif
		// 人数
		memset( (char*)str, (char)0x00, 8);
		memcpy( str, ackData.orderHeadStruct.d_ninzuu, 5 );
		[dict setObject:[NSString stringWithCString:(char*)str encoding:NSUTF8StringEncoding] forKey:@"headCount"];
#ifdef _DEBUG_DETAIL_
		NSLog(@" 人数 headCount(%s)",str);
#endif		

		//		パック桁数設定
		length = 9;

		// 合計金額
		//		ゾーン変換後バッファ領域確保
		zoneStr = malloc(length+1);
		zoneStr[length] = 0x00;
		
		
		[self packToStr:ackData.orderSubHeadStruct.d_goukei length:length zoneStr:zoneStr fugou:1 ];
		[dict setObject:[NSString stringWithCString:(char*)zoneStr encoding:NSUTF8StringEncoding] forKey:@"totalPrice"];
		
		
#ifdef _DEBUG_DETAIL_
		printf(" 合計金額(%02x%02x%02x%02x)\n",ackData.orderSubHeadStruct.d_goukei[0],ackData.orderSubHeadStruct.d_goukei[1],
               ackData.orderSubHeadStruct.d_goukei[2],ackData.orderSubHeadStruct.d_goukei[3],ackData.orderSubHeadStruct.d_goukei[4]);
		NSLog(@" 合計金額 totalPrice(%s)",zoneStr);
		NSLog(@"dict(%@)",dict);	
#endif
		free(zoneStr);
		
	}
	
#ifdef _DEBUG_DETAIL_
	NSLog(@"----- 顧客照会　応答データチェック処理(resCustomerData) OUT  <<-------");
#endif
	
	return;
	
}


/*----------------------------------------------*/
/*		注文　応答データチェック処理					*/
/*		引数説明	:								*/
/*			(I) 受信データ							*/
/*----------------------------------------------*/
- (void)resOrderingData:(NSData*)data sinagireData:(NSMutableArray**)theArray
{

	int i,cnt;
	NSNumber *num;
	
	/*----- Start ------*/
#ifdef _DEBUG_DETAIL_
	NSLog(@"----- 注文　応答データチェック処理(resOrderingData) IN  data length(%d) ------->>",[data length]);
#endif
	
	// LANヘッダー部　領域取得
	OrderResStruct  orderRes;
	[data getBytes:&orderRes length: sizeof(orderRes)];
	
	
#ifdef _DEBUG_DETAIL_
	NSLog(@"  メニュー品切れフラグの情報かをICコードより判定する　0x(%02x) OUT -------<<",orderRes.d_ic_s);
#endif	
	
	// メニュー品切れフラグの情報かをICコードより判定する
	if( orderRes.d_ic_s != 0xBA )
		return;
	
	// メニュー品切れフラグが　セット(1)されている配列番号を返す
	for (i=0,cnt=0; i<1200; i++) {
		if( orderRes.d_sinagire_flg[i] == 1 ){
			num = [NSNumber numberWithInt:i];
			[*theArray addObject:num];
			cnt++;
		}
	}

#ifdef _DEBUG_DETAIL_
	NSLog(@"----- 注文　応答データチェック処理(resOrderingData)  品切れ番号(%@)  OUT -------<<", [*theArray description]);
#endif	

	return;
}

/*----------------------------------------------*/
/*		注文照会　応答データチェック処理				*/
/*		引数説明	:								*/
/*			(I) 受信データ							*/
/*----------------------------------------------*/
- (void)resOrderDspData:(NSData*)data orderData:(NSMutableArray**)theArray
{

	unsigned char	str[8];
	unsigned char*	ptr_org;

	
	/*----- Start ------*/
#ifdef _DEBUG_DETAIL_
	NSLog(@"-----注文照会　応答データチェック処理(resOrderDspData) IN  data length(%d) ------->>",[data length]);
#endif	
	
	// LANヘッダー部　領域取得
	LanHeadStruct lanHead;
	[data getBytes:&lanHead length: sizeof( lanHead) ];
	
	
	//
	// NAK 応答の判定
	if( lanHead.d_an == 'N' ){
		// NAK応答を受信しました。
#ifdef _DEBUG_
		NSLog(@"NAK応答を受信しました");
#endif
		return;
		
	}else if( lanHead.d_an != 'A' ){
		// ACK応答を以外の伝文を受信しました。
#ifdef _DEBUG_
		NSLog(@"NAK/ACK応答以外の伝文種別を受信しました");
#endif
		return;
		
	}
		
#ifdef _DEBUG_
		NSLog(@"ACK応答を受信しました");
#endif
	
	//
	// 以下　ACK応答時の処理
	
	AckResponceStruct ackData;
	[data getBytes:&ackData length: sizeof( ackData) ];
	
#ifdef _DEBUG_DETAIL_
	NSLog(@" オーダーサブヘッダ　RC メニューアイテムの個数は 0x(%02x)です",ackData.orderSubHeadStruct.d_rc);
#endif
		
	// NSData のlengthを取得して　calloc して領域をとる
	// for Loop して情報を取得する
	if( ackData.orderSubHeadStruct.d_rc > 160 ){

		// エラー処理
		NSLog(@"商品照会データが１６０個を超えました");
		return;
	}
	
//	theArray = [NSMutableArray arrayWithCapacity:(int)ackData.orderSubHeadStruct.d_rc];
	
	
	// 注文品情報　データ読込み領域確保 ( オーダーアイテム個数　× １注文アイテム情報 )
	OrderItemTimeStruct orderItem;
	int sizeItem = (int)ackData.orderSubHeadStruct.d_rc * sizeof(orderItem);
	OrderItemTimeStruct *p = malloc( (int)ackData.orderSubHeadStruct.d_rc  * sizeof(orderItem) );
	
	// 領域解放時のために先頭アドレスを退避する
	ptr_org = (unsigned char*)p ;
	
	// 注文品情報 部だけの切り出し
	[data getBytes:(unsigned char*)p range:NSMakeRange((NSUInteger)sizeof(ackData),(NSUInteger)sizeItem)];

	//----------------------------
	// 注文品情報 個数分 LOOP 処理
	for( int i=0; i < (int)ackData.orderSubHeadStruct.d_rc; i++, p++ ){

#ifdef _DEBUG_MENU_
		NSLog(@"商品アイテム配列作成Loop(%d)",i);
#endif
		
		/* １注文データを辞書オブジェクトに生成する */
		NSMutableDictionary *dict;
		dict = [NSMutableDictionary dictionary];

		// メニューコード
		memset( (char*)str, (char)0x00, 8);
		[self packToStr:p->d_menucode length:4 zoneStr:str fugou:0];
		[dict setObject:[NSString stringWithCString:(char*)str encoding:NSUTF8StringEncoding] forKey:kItemMenuCodeKey];
#ifdef _DEBUG_MENU_
		printf("     メニューコード(%02x%02x)\n",   p->d_menucode[0],p->d_menucode[1]);
		printf("     str(%s)\n",str);
#endif
		/*----　注文照会画面では階層コード、指示NO STの情報は不要なので削除
		// 階層・指示ステータス
		memset( (char*)str, (char)0x00, 8);
		
		// packToStrは1Byteに対応していない！！
		//[self packToStr:p->d_kaisou length:1 zoneStr:str fugou:0];
		[dict setObject:[NSString stringWithCString:(char*)str encoding:NSUTF8StringEncoding] forKey:kItemKaisouCodekey];
#ifdef _DEBUG_MENU_
		printf("     階層(%02x)  指示NO(%02x)\n",   p->d_kaisou,p->d_siji);
		printf("     str(%s)\n",str);
#endif
		 
		// 指示NO
		memset( (char*)str, (char)0x00, 8);

		// packToStrは1Byteに対応していない！！
		//[self packToStr:p->d_siji length:1 zoneStr:str fugou:0];
		[dict setObject:[NSString stringWithCString:(char*)str encoding:NSUTF8StringEncoding] forKey:kItemSijiNOkey];
#ifdef _DEBUG_MENU_
		printf("     str(%s)\n",str);
#endif
         -----------------------------*/
        
		// ST1 - ST7
		memset( (char*)str, (char)0x00, 8);
		[self packToStr:p->d_st length:7 zoneStr:str fugou:0];
		//[dict setObject:[NSString stringWithCString:(char*)str encoding:NSUTF8StringEncoding] forKey:@"st"];
        
        // 2012.01.23 n.sasaki 取消情報を取り出し、配列に格納
        [dict setObject:[NSString stringWithFormat:@"%x", str[1]] forKey:kItemSt2key];
        
#ifdef _DEBUG_MENU_
		printf("     ST1~7(%s)\n",str);
		printf("     ST1(%01x)\n",str[0]);
		printf("     ST2(%01x)\n",str[1]);
		printf("     ST3(%01x)\n",str[2]);
		printf("     ST4(%01x)\n",str[3]);
		printf("     ST5(%01x)\n",str[4]);
		printf("     ST6(%01x)\n",str[5]);
		printf("     ST7(%01x)\n",str[6]);
		printf("     ST8(%01x)\n",str[7]);
#endif
		
		// 数量
		memset( (char*)str, (char)0x00, 8);
		[self packToStr:p->d_suuryou length:3 zoneStr:str fugou:1];
		[dict setObject:[NSString stringWithCString:(char*)str encoding:NSUTF8StringEncoding] forKey:kItemQuantityKey];
#ifdef _DEBUG_MENU_
		printf("     数量(%02x%02x)\n",   p->d_suuryou[0],p->d_suuryou[1]);
		printf("     str(%s)\n",str);
#endif
		
		
		// 単価
		memset( (char*)str, (char)0x00, 8);
		[self packToStr:p->d_tanka length:7 zoneStr:str fugou:1];
		[dict setObject:[NSString stringWithCString:(char*)str encoding:NSUTF8StringEncoding] forKey:kItemPriceKey];
#ifdef _DEBUG_MENU_
		printf("     単価(%02x%02x%02x%02x)\n",   p->d_tanka[0],p->d_tanka[1],p->d_tanka[2],p->d_tanka[3]);
		printf("     str(%s)\n",str);
#endif
		
		
		// オーダー時刻
		memset( (char*)str, (char)0x00, 8);
		[self packToStr:p->d_ordertime length:4 zoneStr:str fugou:0];
		[dict setObject:[NSString stringWithCString:(char*)str encoding:NSUTF8StringEncoding] forKey:kItemOrderDate];
#ifdef _DEBUG_MENU_
		printf("     オーダー時刻(%02x%02x)\n",   p->d_ordertime[0],p->d_ordertime[1]);
		printf("     str(%s)\n",str);
#endif
		
#ifdef _DEBUG_MENU_
		NSLog(@" dic (%@)",dict);
#endif
		
		// 配列内に辞書形式で設定する
		[*theArray addObject:dict];
	}
	
	// 注文品情報　データ読込み領域の解放
	free(ptr_org);
	
#ifdef _DEBUG_DETAIL_
	NSLog(@" array count(%d) theArray(%@)",[*theArray count], *theArray);
	NSLog(@"-----注文照会　応答データチェック処理(resOrderDspData)    OUT  <<-------");
#endif
	
	return;
	
}


/*----------------------------------------------*/
/*		エラー発生時にCALLBACK その１				*/
/*		引数説明	:								*/
/*			(I) ソケット接続子						*/
/*			(O) エラー							*/
/*----------------------------------------------*/
- (void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	NSNumber *numReqNo;
	
	/*---- Start ----*/
	
	numReqNo = [NSNumber numberWithInt:reqNo];
	NSInteger code = [err code];
	
#ifdef _DEBUG_
	NSLog(@" STNとの接続ステータス:(%@)", err);
	NSLog(@" NSError code:(%x)", code);
#endif
	
	if( code != 0 ){
		
#ifndef kokorozashi
        // 2012.01.17 n.sasaki エラーメッセージの表示を抑制
		NSString *string = [NSString stringWithFormat:@"エラーコード:(SKT-%x) エラーメッセージ:(%@0" ,code, err];
		UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"エラーが発生しました"
													  message:string
													 delegate:nil
											cancelButtonTitle:@"はい"
											otherButtonTitles:nil];
		[av show];
		[av release];
#endif
	}
    
    // Add Start 2012-03-11 kitada
    // 通信制御不具合改修(志様・01CAFE障害対応)
    // ソケットをクローズ
	[self kolSocketClose];
    // Add End 2012-03-11 kitada
	
    // Del Start 2012-03-11 kitada
    // 画面に返すのは　onSocketDidDisconnect: だけに変更する
	//[NSThread sleepForTimeInterval:0.5];
	//[delegate kolSocket:numReqNo didReadData:(id)nil error:err];	
    // Del End 2012-03-11 kitada
    
	return;

}


/*----------------------------------------------*/
/*		エラー発生時にCALLBACK その２				*/
/*		引数説明	:								*/
/*			(I) ソケット接続子						*/
/*----------------------------------------------*/
- (void)onSocketDidDisconnect:(AsyncSocket *)sock
{
    
    NSNumber *numReqNo;
	
	/*---- Start ----*/
#ifdef _DEBUG_DETAIL_
	NSLog(@"kolSocket--> onSocketDidDisconnect:%p", sock);
#endif	

	
	numReqNo = [NSNumber numberWithInt:reqNo];    
    
	//NSString *str = [[[NSString alloc] initWithData:buffer encoding:NSUTF8StringEncoding] autorelease];


    // Add Start 2012-03-11 kitada
    // 通信制御不具合改修(志様・01CAFE障害対応)
    // ソケットをクローズ
	[self kolSocketClose];
    
	// 画面に返すのにDelayしている
	[NSThread sleepForTimeInterval:0.5];
	[delegate kolSocket:numReqNo didReadData:(id)nil error:nil];	
    // Add End 2012-03-11 kitada

	return;
	
}


////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark --
#pragma mark Inside Method
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/********************************************************/
/*			内部処理										*/
/********************************************************/

/*----------------------------------------------*/
/*		現在日時(NSString) ->　パック１０進生成処理	*/
/*		引数説明	:								*/
/*			(O) 日時（パックデータ） 		*/
/*----------------------------------------------*/

- (void) dateGet:(unsigned char*)ymdhms
{
	unsigned int ind;
	unsigned int cnt;
	unichar z;
	unichar x;
	
	
#ifdef _DEBUG_DETAIL_
	NSLog(@"dateGet IN ----->> ");
#endif
	
	// 現在日時を取得する
	NSDate *date = [NSDate date];
	
	
	/*---------------------------------*/
	// カスタムフォーマット文字列を作成する
	NSString *formatStr;
	formatStr = @"yyMMddHHmmss";
	
	// フォーマッターを取得して設定する
	NSDateFormatter *formatter;
	
	formatter = [[[NSDateFormatter alloc] init] autorelease];
	[formatter setDateFormat:formatStr];
	
	// 日時を文字列化する
	NSString *str = [formatter stringFromDate:date];
	
	// 日時をパックデータに変換する
	for ( ind=0,cnt=0; ind < [str length]; ind++ ){
		
		// 文字列から1Byteを切り出す
		unichar c = [str characterAtIndex:ind];
		
		// 文字列を整数に変換
		z = c & 0x0F;
		
		if( (ind % 2) == 0 ){
			// 上位4Bitを生成
			x = z <<  4;
		}
		else {
			// 下位4Bitを生成して上位4Bitと合わせる
			x = x | z;
			// 伝文変数に設定
			ymdhms[cnt] = x;
			cnt ++;				// 配列カウンタをアップ
			x=0x00;				// 変換バッファをクリア
			z=0x00;				// 変換バッファをクリア
		}

	}
	
#ifdef _DEBUG_DETAIL_
	NSLog(@"dateGet OUT <<-----  date(0x%x%x%x%x%x%x)------->> ",
			ymdhms[0],ymdhms[1],ymdhms[2],ymdhms[3],ymdhms[4],ymdhms[5]);
#endif
	
	return ;

}



/*----------------------------------------------*/
/*		10進型文字列 -> パック10進型文字列に変換		*/
/*		引数説明	:								*/
/*			(I)  C文字列10進データ 先頭ポインタ		*/
/*			(I)  パック10進データ桁数				*/
/*			(I/O)パック10進データ 先頭ポインタ		*/
/*			(I)  符号チェックする、しないフラグ		*/
/*				1: チェックする 0: しない			*/
/*												*/
/*			例） 0x12345D  -> 5桁					*/
/*				最終4Bitは符号 C：正　D：負			*/
/*----------------------------------------------*/
- (void) strToPack:(NSString*)nStr length:(int)length packStr:(unsigned char*)pStr fugou:(int)fugou
{
	int ind;
	int nCnt;
	int pCnt;
	unichar c;
	unichar z;
	unichar x;
	
	
#ifdef _DEBUG_PACK_
	NSLog(@"strToPack IN ----->>  nStr(%@) length(%d)",nStr,[nStr length]);
#endif


	x=0x00;				// 変換バッファをクリア
	z=0x00;				// 変換バッファをクリア
	pCnt= length/2 -1 ;		// パック形式データ領域カウンター

	// 最終桁からLOOPさせる
	// Packデータ桁数分Loop
	for (ind=0, nCnt=[nStr length]; ind < length; ind++ ) {

		if( ind == 0 && fugou == 1 ){
			c = 0x0C;
			
#ifdef _DEBUG_PACK_
			NSLog(@" Loop(%d) 符号をつける c(%02x) nCnt(%d)",ind,c,nCnt);
#endif
			
		}else {
			
			// NSStringの桁数分は実データを取り出し、桁数を超える場合は0x00をセットする
			if( nCnt > 0 ){
				// 文字列から1Byteを切り出す
				// hatena
				c = [nStr characterAtIndex:nCnt-1];
			}else {
				c = 0x00;
			}
#ifdef _DEBUG_PACK_
			NSLog(@" Loop(%d) 文字列から1Byteを切り出す c(%02x) nCnt(%d)",ind,c,nCnt);
#endif
			
			nCnt--;
		}

		
		// 文字列を整数に変換
		z = c & 0x0F;
		
#ifdef _DEBUG_PACK_
		NSLog(@" 文字列を整数に変換 z(%02x)",z);
#endif

		
		if( (ind % 2) == 1 ){
			// 上位4Bitを生成
			z = z <<  4;
			
			x = x | z;
			// 伝文変数に設定
			pStr[pCnt] = x;
#ifdef _DEBUG_PACK_
			NSLog(@"  上位4Bitを生成 pStr[%d](%02x)",pCnt,pStr[pCnt]);
#endif
			pCnt --;			// 配列カウンタをアップ
			x=0x00;				// 変換バッファをクリア
			z=0x00;				// 変換バッファをクリア
			
		}
		else {
			// 下位4Bitを生成して上位4Bitと合わせる
			x = z & 0x0F;
			
#ifdef _DEBUG_PACK_
			NSLog(@" 下位4Bitを生成");
#endif
		}
		
#ifdef _DEBUG_PACK_
		NSLog(@"            x(%02x)",x);
#endif
		
	}
	
	
#ifdef _DEBUG_PACK_
	NSLog(@"strToPack OUT  pStr(%s)-----<< ",pStr);
#endif
	

}



/*----------------------------------------------*/
/*		パック10進型文字列　→　ゾーン10進型文字列に変換	*/
/*		引数説明	:								*/
/*			(I)  パック10進データ 先頭ポインタ		*/
/*			(I)  パック10進データの桁数				*/
/*			(I/O)ゾーン10進データ 先頭ポインタ		*/
/*			(I)  符号チェックする、しないフラグ		*/
/*				1: チェックする 0: しない			*/
/*												*/
/*			例） 0x12345D  -> 5桁					*/
/*				最終4Bitは符号 C：正　D：負			*/
/*----------------------------------------------*/
- (void) packToStr:(unsigned char*)packStr  length:(int)length  zoneStr:(unsigned char*)zoneStr fugou:(int)fugou
{
	unsigned int	ind;
	unsigned int	cnt;
	unsigned char	*str;
	unichar z;
	unichar x;
	int dec=0;

	
#ifdef _DEBUG_PACK_
	NSLog(@"packToStr IN ----->> ");
#endif
	
	// 文字列バッファの取得
	str = malloc(length+1);
	str[length] = 0x00;

	// パックデータを変換する
	for ( ind=0,cnt=0; ind < length; ind++ ){
		
		cnt = ind / 2 ;
		
		// 文字列から1Byteを切り出す
		 z = packStr[cnt] ;
				
#ifdef _DEBUG_PACK_
		NSLog(@" packStr(%02x) cnt(%d) ind(%d)",z,cnt,ind);
#endif
		if( (ind % 2) == 0 ){
			// 上位4Bitを生成
			x = z >>  4;
		}
		else {
			// 下位4Bitを生成			
			x = z & 0x0F;
		}
		// 前４BITに0x3をつけてASCII文字列にする
		x = x | 0x30;
		
		// 文字列変数に設定
		str[ind] = x;
#ifdef _DEBUG_PACK_
		NSLog(@" str[%d](%02x)",ind,x);
#endif
	}
	
#ifdef _DEBUG_PACK_
	printf(" str(%s)",str);
#endif	
	// 文字列から数値に変換　sscanf	
	sscanf( (char*)str, "%d", &dec);
	
#ifdef _DEBUG_PACK_
	printf("   dec(%d)\n",dec);
#endif	
	
	// 符号チェック
	if( fugou == 1 ){
		// 符号をつける最終４BITが　Cならば正　Dならば負となる
		z = packStr[length/2];
		x = z & 0x0F;
		if( x == 0x0C )
			dec = dec * 1;
		else if( x == 0x0D )
			dec = dec * -1;
		else
			NSLog(@"符号 不正 ERROR");
	}
	
#ifdef _DEBUG_PACK_
	printf("   dec(%d)\n",dec);
#endif
		
	sprintf( (char*)str, "%d", dec);
	memcpy ( zoneStr, str, length );
	
	free(str);	
	
#ifdef _DEBUG_PACK_
	NSLog(@"packToStr OUT <<-----  zoneStr(%s)------->> ",zoneStr);
#endif
	
	return;
	
}

/*----------------------------------------------*/
/*		チェックサム計算処理							*/
/*		引数説明	:								*/
/*			(I) 計算データ 先頭ポインタ				*/
/*			(I) 計算開始バイト位置					*/
/*			(I) 計算終了バイト位置					*/
/*		戻り値	:								*/
/*			チェックサム計算結果(unsigned char)		*/
/*----------------------------------------------*/
- (unsigned char) checkSum:(unsigned char*)data startAddr:(int)sptr  endAddr:(int)eptr
{
	int cnt=0;
	unsigned char crc = 0x00;
	
#ifdef _DEBUG_DETAIL_
	NSLog(@"チェックサム計算処理(checkSum) IN -------->> sptr(%d) eptr(%d)",sptr,eptr);
#endif
	
	// sptr = 0 始まりなので eptr は　length - 1 とする 　
	for (cnt=sptr; cnt<=eptr; cnt++) {

		
		// 28 Byte目はチェックサムを設定する領域の為スルーする
		if( cnt != 28 )
			crc = crc ^ *(data+cnt);	
	}

#ifdef _DEBUG_DETAIL_
	NSLog(@"チェックサム計算処理(checkSum) OUT <<-------- crc(0x%02x) ",crc);
#endif
	
	return crc;
}


/*----------------------------------------------*/
/*		リクエスト番号カウントアップ					*/
/*----------------------------------------------*/
- (void)countUP {
	++reqNo;
#ifdef _DEBUG_DETAIL_
	NSLog(@"=====================================================================");
	NSLog(@"         リクエスト番号カウントアップしました(%d)-------<<",reqNo);
	NSLog(@"=====================================================================");
#endif
	
}





////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark --
#pragma mark sendDataMake Method
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/*----------------------------------------------*/
/*		顧客照会伝文 生成処理						*/
/*		引数説明	:								*/
/*			(I) 伝文　先頭ポインタ					*/
/*			(I) 照会テーブルNO						*/
/*----------------------------------------------*/
- (NSInteger) makeDataCustomerRequest:(TableNo_ReqStruct*)data tableno:(NSString*) tableNo
{
	//const char *a;				// 文字列変換バッファ

	
#ifdef _DEBUG_DETAIL_
	NSLog(@"---- 顧客照会伝文 生成処理(makeDataCustomerRequest) IN  data(%s)------->> ", data);
#endif
	
	//-------------------------------
	// LAN ヘッダー部設定
	data->lanHeadStruct.d_head = 'T';
	data->lanHeadStruct.d_llr = ' ';
	data->lanHeadStruct.d_adp = 'C';

	// 伝文種別
	data->lanHeadStruct.d_knd[0] =  '1';		// 種別
	data->lanHeadStruct.d_knd[1] =  'K';		// 区分1（上位）
	data->lanHeadStruct.d_knd[2] =  '2';		// 区分1（下位）
	data->lanHeadStruct.d_knd[3] =  'H';		// 区分2
	data->lanHeadStruct.d_knd[4] =  'J';		// 区分3
	data->lanHeadStruct.d_knd[5] =  '0';		// タイプ

	// 通番
	data->lanHeadStruct.d_seq_no[0] = '0';
	data->lanHeadStruct.d_seq_no[1] = '0';
	data->lanHeadStruct.d_seq_no[2] = '0';
	data->lanHeadStruct.d_seq_no[3] = '1';

	// 日時設定
	[self dateGet:&data->lanHeadStruct.d_ymdhms[0]];

	// MD
	data->lanHeadStruct.d_md = 'O';				// ゼロ でなくて　オー　
	// 機種ID
	data->lanHeadStruct.d_kisyu_no[0] = 'O';
	data->lanHeadStruct.d_kisyu_no[1] = 'E';
	data->lanHeadStruct.d_kisyu_no[2] = 'S';
	data->lanHeadStruct.d_kisyu_no[3] = '9';
	data->lanHeadStruct.d_kisyu_no[4] = '0';
	// リザーブ
	data->lanHeadStruct.d_an = ' ';
	data->lanHeadStruct.d_status[0] = ' ';
	data->lanHeadStruct.d_status[1] = ' ';
	
	// チェックサムは全てのデータ設定後に計算する
	
	// PR指示子
	data->lanHeadStruct.d_pr = ' ';
	// データ長
	data->lanHeadStruct.d_datalen[0] = 0x00;
	data->lanHeadStruct.d_datalen[1] = 0x09;	// テーブルNO要求

	//-------------------------------
	// OES ヘッダー部設定
	data->oesHeadStruct.d_oes = 0x00;
	data->oesHeadStruct.d_sn = 0x00;
		
	// APLID の設定	
	// 常に 201(C9h)を設定する　テック様よりの指定　(2010-11-15)
	data->oesHeadStruct.d_aplid = 0xc9;
	
	//-------------------------------
	// データ部設定
	//   IC 設定　0x07 固定
	data->tableNoStruct.d_ic = 0x07;

	// テーブルNOの設定
	//  NSString -> unsigned char への変換
	char p[8];
	const char *ptr;
	ptr = &p[0];
	ptr = [tableNo UTF8String];
	char cbuf[8];
	memset( cbuf, (char)0x00, sizeof(cbuf) );
	sprintf( cbuf, "%5s",ptr);
	memcpy( (char*)&data->tableNoStruct.d_table_no[0], cbuf, 5 );

	
	//-------------------------------
	// チェックサム計算
	data->lanHeadStruct.d_chksum = [self checkSum: (unsigned char*) data startAddr:0  endAddr:40];
	
#ifdef _DEBUG_DETAIL_	
	NSLog(@"     checkSum  (0x%02x)  ",data->lanHeadStruct.d_chksum);
	NSLog(@"SendData 固定値: (%c)", data->lanHeadStruct.d_head);
	NSLog(@"SendData LLR: (%c)", data->lanHeadStruct.d_llr);
	NSLog(@"SendData ADP: (%c)", data->lanHeadStruct.d_adp);
	NSLog(@"SendData 伝文種別　種別: (%c)", data->lanHeadStruct.d_knd[0]);
	NSLog(@"SendData 伝文種別　区分１: (%c%c)", data->lanHeadStruct.d_knd[1],data->lanHeadStruct.d_knd[2]);
	NSLog(@"SendData 伝文種別　区分２: (%c)", data->lanHeadStruct.d_knd[3]);
	NSLog(@"SendData 伝文種別　区分３: (%c)", data->lanHeadStruct.d_knd[4]);
	NSLog(@"SendData 伝文種別　タイプ: (%c)", data->lanHeadStruct.d_knd[5]);
	NSLog(@"SendData 通番: (%c%c%c%c)", data->lanHeadStruct.d_seq_no[0],data->lanHeadStruct.d_seq_no[1],
												data->lanHeadStruct.d_seq_no[2],data->lanHeadStruct.d_seq_no[3]);
	NSLog(@"SendData 日付: 0x(%02x%02x%02x)", data->lanHeadStruct.d_ymdhms[0],data->lanHeadStruct.d_ymdhms[1],data->lanHeadStruct.d_ymdhms[2]);
	NSLog(@"SendData 時刻: 0x(%02x%02x%02x)", data->lanHeadStruct.d_ymdhms[3],data->lanHeadStruct.d_ymdhms[4],data->lanHeadStruct.d_ymdhms[5]);
	NSLog(@"SendData MD: (%02x)", data->lanHeadStruct.d_md);
	NSLog(@"SendData 機種ID: (%c%c%c%c%c)", data->lanHeadStruct.d_kisyu_no[0],data->lanHeadStruct.d_kisyu_no[1],data->lanHeadStruct.d_kisyu_no[2],data->lanHeadStruct.d_kisyu_no[3],data->lanHeadStruct.d_kisyu_no[4]);
	NSLog(@"SendData リザーブ an: (%x)", data->lanHeadStruct.d_an);
	NSLog(@"SendData リザーブ  status: (%02x%02x)", data->lanHeadStruct.d_status[0],data->lanHeadStruct.d_status[1]);
	NSLog(@"SendData チェックサム: (%02x)", data->lanHeadStruct.d_chksum);
	NSLog(@"SendData PR指示: (%02x)", data->lanHeadStruct.d_pr);
	NSLog(@"SendData　データ長: (%02x%02x)", data->lanHeadStruct.d_datalen[0],data->lanHeadStruct.d_datalen[1]);
	
	NSLog(@"SendData OES HEADER OES区分: (%02x)", data->oesHeadStruct.d_oes);
	NSLog(@"SendData OES HEADER SN: (%02x)", data->oesHeadStruct.d_sn);
	NSLog(@"SendData OES HEADER APLID: (%02x)", data->oesHeadStruct.d_aplid);
	
	NSLog(@"SendData TableNO IC: (%02x)", data->tableNoStruct.d_ic);
	NSLog(@"SendData TableNO IC: (%02x%02x%02x%02x%02x)", data->tableNoStruct.d_table_no[0],data->tableNoStruct.d_table_no[1],
		  data->tableNoStruct.d_table_no[2],data->tableNoStruct.d_table_no[3],data->tableNoStruct.d_table_no[4]);
	
	
	NSLog(@"---- 顧客照会伝文 生成処理(makeDataCustomerRequest) OUT -------<< ");
#endif
	
	return 0;
	
}

/*--------------------------------------------------*/
/*		アイテム部設定処理								*/
/*		引数説明	:									*/
/*			(I) 注文データ-配列						*/
/*			(I) メニューアイテム部伝文データ 先頭ポインタ	*/
/*--------------------------------------------------*/
-(void)setItemData:(id)item  buffer:(OrderItemStruct*)data
{
	NSString *theObject;
	int length;
	int ibuf;

	theObject = [item objectForKey:kItemMenuCodeKey];		// メニューコード
	[self strToPack:theObject length:4 packStr:data->d_menucode fugou:0];
	
	theObject = [item objectForKey:kItemQuantityKey];		// 数量
	[self strToPack:theObject length:4 packStr:data->d_suuryou fugou:1];
		
	theObject = [item objectForKey:kItemPriceKey];			// 単価
	[self strToPack:theObject length:8 packStr:data->d_tanka fugou:1];
	
	theObject = [item objectForKey:kItemKaisouCodekey];		// 階層コード
	if( theObject == nil )
		ibuf = 0x00;
	else
		ibuf = [theObject integerValue];	
	data->d_kaisou = ibuf << 4 ;
	
	theObject = [item objectForKey:kItemSijiStatuskey];		// 指示ステータス
	if( theObject == nil )
		ibuf = 0x00;
	else
		ibuf = [theObject integerValue];
	data->d_kaisou = data->d_kaisou | ibuf ;	
	
	theObject = [item objectForKey:kItemSijiNOkey];			// 指示NO
	if( theObject == nil )
		ibuf = 0;
	else{
		length = [theObject length];
		ibuf = [theObject integerValue];
	}	
	data->d_siji = ibuf ;

	// ST２ メニュー属性の設定（メイン、コメント、サブ、セット）
	if( data->d_kaisou == 0x00 )
		data->d_st[1] = 0x00;					// メインメニュー
	else {
		if ( 0 <= ibuf && ibuf <= 50 )
			data->d_st[1] = 0x01;				// コメント
		else if ( 51 <= ibuf && ibuf <= 100 )
			data->d_st[1] = 0x02;				// サブメニュー
		else if ( 101 <= ibuf && ibuf <= 150 )
			data->d_st[1] = 0x03;				// セットメニュー
		else
			data->d_st[1] = 0x00;				// それ以外はメインメニューを設定
	}

	data->d_st[0] = 0x01;			// ST 1 税区分
	data->d_st[2] = 0x00;			// ST 3(今回未使用)
	data->d_st[3] = 0x00;			// ST 4(今回未使用)
	data->d_st[4] = 0x00;			// ST 5(今回未使用)
	data->d_st[5] = 0x00;			// ST 6(今回未使用)
	data->d_st[6] = 0x00;			// ST 7(今回未使用)
	data->d_commentno[0] = 0x00;	// コメントNO(今回未使用)		
	data->d_commentno[1] = 0x00;	

	return;
}	



/*--------------------------------------------------*/
/*		注文データ-メニューアイテム部　生成処理				*/
/*		引数説明	:									*/
/*			(I) 注文データ-配列						*/
/*			(I) メニューアイテム部伝文データ 先頭ポインタ	*/
/*			(O) エラー								*/
/*--------------------------------------------------*/
-(BOOL)makeDataOrdering:(NSArray*)items  buffer:(OrderItemStruct*)data error:(NSError **) error
{
	NSString *theObject;

	/*----- Start ------*/
#ifdef _DEBUG_DETAIL_
	NSLog(@"------ 注文データ-メニューアイテム部　生成処理(makeDataOrdering) IN ------->> ");
	NSLog(@"    items(%@)------->> ",items);
#endif

	// メニューアイテム数分データを生成する
	//	A-D
	//   -A-D
	//     -A-D
	//       -D  hatena

	for (id temp in items) {
#ifdef _DEBUG_DETAIL_
		NSLog(@"--- 0 階層目データ ---- (%@)",temp);
#endif
		// メインメニュー( 0階層 )データ設定
		[self setItemData:temp buffer:data];
		data++;
		
		theObject = [temp objectForKey:kItemSetItemkey];
		if ([theObject isKindOfClass:[NSArray class]]) {
#ifdef _DEBUG_DETAIL_
			NSLog(@"---セットアイテムありますので１階層目のデータ設定を行います");
#endif
			NSArray * aArray = (NSArray *)theObject;
			
			for (id aTemp in aArray) {
#ifdef _DEBUG_DETAIL_
				NSLog(@"--- 1 階層目データ ---- (%@)",aTemp);
#endif				
								
				if ([aTemp isKindOfClass:[NSArray class]]) {
#ifdef _DEBUG_DETAIL_
					NSLog(@"---セットアイテムありますので2階層目のデータ設定を行います");
#endif
					NSArray * aaArray = (NSArray *)aTemp;
					
					for (id aaTemp in aaArray) {
#ifdef _DEBUG_DETAIL_
						NSLog(@"--- 2階層目データ ---- (%@)",aaTemp);
#endif
						if( [aaTemp isKindOfClass:[NSArray class]] ){
							NSLog(@"  配列です。");
							NSArray * aaaArray = (NSArray *)aaTemp;
							
							for (id aaaTemp in aaaArray) {
#ifdef _DEBUG_DETAIL_
								NSLog(@"--- 3階層目データ ---- (%@)",aaaTemp);
#endif
								//　セットメニュー等( 2階層 )データ設定
								[self setItemData:aaaTemp buffer:data];
								data++;
								
							}
						}else{
						   //　セットメニュー等( 2階層 )データ設定
						   [self setItemData:aaTemp buffer:data];
						   data++;
						}
						
					}
				}else {
					// セットメニュー等( 1階層 )データ設定
					[self setItemData:aTemp buffer:data];
					data++;
				}

			}
		}
	}
	
#ifdef _DEBUG_DETAIL_
	NSLog(@"------ 注文データ-メニューアイテム部　生成処理(makeDataOrdering)(%s) OUT -------<< ",data);
#endif

	return YES;
}


/*----------------------------------------------*/
/*		注文データヘッダ部生成処理					*/
/*		引数説明	:								*/
/*			(I) 伝文データ 先頭ポインタ				*/
/*			(I) テーブルNO						*/
/*----------------------------------------------*/
- (BOOL) makeDataOrderingHead:(NSString*)tableID data:(OrderRequestHeadStruct*)data error:(NSError **) error
{
	
#ifdef _DEBUG_DETAIL_
	NSLog(@"------- 注文データヘッダ部生成処理 IN ------->> ");
#endif

	//-------------------------------
	// LAN ヘッダー部設定
	data->lanHeadStruct.d_head = 'T';
	data->lanHeadStruct.d_llr = ' ';
	data->lanHeadStruct.d_adp = 'C';
	
	// 伝文種別の設定
	data->lanHeadStruct.d_knd[0] =  '2';		// 種別
	data->lanHeadStruct.d_knd[1] =  'L';		// 区分1(上位)
	data->lanHeadStruct.d_knd[2] =  '0';		// 区分1(下位)
	data->lanHeadStruct.d_knd[3] =  'H';		// 区分2
	data->lanHeadStruct.d_knd[4] =  'J';		// 区分3
	data->lanHeadStruct.d_knd[5] =  '0';		// タイプ
	
	// シーケンス番号の設定 (仕様上１固定)
	data->lanHeadStruct.d_seq_no[0] = '0';
	data->lanHeadStruct.d_seq_no[1] = '0';
	data->lanHeadStruct.d_seq_no[2] = '0';
	data->lanHeadStruct.d_seq_no[3] = '1';
	
	
	// 日時設定
	[self dateGet:&data->lanHeadStruct.d_ymdhms[0]];
	
	// MD
	data->lanHeadStruct.d_md = 'O';
	// 機種ID
	data->lanHeadStruct.d_kisyu_no[0] = 'O';
	data->lanHeadStruct.d_kisyu_no[1] = 'E';
	data->lanHeadStruct.d_kisyu_no[2] = 'S';
	data->lanHeadStruct.d_kisyu_no[3] = '9';
	data->lanHeadStruct.d_kisyu_no[4] = '0';
	// リザーブ
	data->lanHeadStruct.d_an = ' ';
	data->lanHeadStruct.d_status[0] = ' ';
	data->lanHeadStruct.d_status[1] = ' ';
	
	// チェックサムは全データ設定後に計算する
	
	// PR指示子
	data->lanHeadStruct.d_pr = ' ';
	
	// データ長の設定はメニューアイテム部（可変）を計算後にする
	
	//-------------------------
	// OES ヘッダー部設定
	
	// OES区分
	data->oesHeadStruct.d_oes = 0x00;
	// SN(オーダー通番) 仕様上常に１を設定
	data->oesHeadStruct.d_sn = 0x01;
	
	
	// APLID の設定	
	// 常に 201(C9h)を設定する　テック様よりの指定　(2010-11-15)
	data->oesHeadStruct.d_aplid = 0xc9;
	
	// Dummy テスト中は　0x0b で行う (2010-11-20)
	//data->oesHeadStruct.d_aplid = 0x0b;
	
	
	// 設定バージョン(YYMMDDHHMM)
	data->ackResHeadStruct.d_set_version[0] = 0x00;
	data->ackResHeadStruct.d_set_version[1] = 0x00;
	data->ackResHeadStruct.d_set_version[2] = 0x00;
	data->ackResHeadStruct.d_set_version[3] = 0x00;
	data->ackResHeadStruct.d_set_version[4] = 0x00;
	
	// HTL STATUS 部設定
	data->ackResHeadStruct.d_htl_status[0] = 0x01; // 常に追加オーダーを設定
	data->ackResHeadStruct.d_htl_status[1] = 0x00;
	data->ackResHeadStruct.d_htl_status[2] = 0x00;
	data->ackResHeadStruct.d_htl_status[3] = 0x00;
	
		
	// テーブル番号不一致チェック	
	char p[8];
	const char *ptr;
	ptr = &p[0];
	ptr = [tableID UTF8String];
	char cbuf[8];
    
	memset( cbuf, (char)0x00, sizeof(cbuf) );    
    sprintf( cbuf, "%5s",ptr);
    memcpy( (char*)&data->orderHeadStruct.d_table_no[0], cbuf, 5 );	
	
	// 顧客情報取得したテーブル番号と要求されたテーブル番号の整合性チェック	
	if( memcmp(cbuf, saveOrderHeadData.d_table_no, 5) != 0 ){

		// テーブル番号不整合のメッセージを出力する
		NSString *string = [NSString stringWithFormat:@"伝票NOがありません。"];
							
							/*
							data->orderHeadStruct.d_table_no[0],
							data->orderHeadStruct.d_table_no[1],
							data->orderHeadStruct.d_table_no[2],
							data->orderHeadStruct.d_table_no[3],
							data->orderHeadStruct.d_table_no[4]];
							 */
		
		UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"エラーが発生しました"
													  message:string
													 delegate:nil
											cancelButtonTitle:@"はい"
											otherButtonTitles:nil];
		[av show];
		[av release];
		return NO;
	}
	
	
	//--------------------------
	// オーダーヘッダ部設定
	// 顧客照会処理で　オーダーヘッダ部を保存しておく
	// そしてここに代入する。	
	memcpy( &data->orderHeadStruct, &saveOrderHeadData, sizeof(saveOrderHeadData) );

	
#ifdef _DEBUG_DETAIL_	
	NSLog(@"     checkSum  (0x%02x)  ",data->lanHeadStruct.d_chksum);
	NSLog(@"SendData 固定値: (%c)", data->lanHeadStruct.d_head);
	NSLog(@"SendData LLR: (%c)", data->lanHeadStruct.d_llr);
	NSLog(@"SendData ADP: (%c)", data->lanHeadStruct.d_adp);
	NSLog(@"SendData 伝文種別　種別: (%c)", data->lanHeadStruct.d_knd[0]);
	NSLog(@"SendData 伝文種別　区分１: (%c%c)", data->lanHeadStruct.d_knd[1],data->lanHeadStruct.d_knd[2]);
	NSLog(@"SendData 伝文種別　区分２: (%c)", data->lanHeadStruct.d_knd[3]);
	NSLog(@"SendData 伝文種別　区分３: (%c)", data->lanHeadStruct.d_knd[4]);
	NSLog(@"SendData 伝文種別　タイプ: (%c)", data->lanHeadStruct.d_knd[5]);
	NSLog(@"SendData 通番: (%c%c%c%c)", data->lanHeadStruct.d_seq_no[0],data->lanHeadStruct.d_seq_no[1],
		  data->lanHeadStruct.d_seq_no[2],data->lanHeadStruct.d_seq_no[3]);
	NSLog(@"SendData 日付: 0x(%02x%02x%02x)", data->lanHeadStruct.d_ymdhms[0],data->lanHeadStruct.d_ymdhms[1],data->lanHeadStruct.d_ymdhms[2]);
	NSLog(@"SendData 時刻: 0x(%02x%02x%02x)", data->lanHeadStruct.d_ymdhms[3],data->lanHeadStruct.d_ymdhms[4],data->lanHeadStruct.d_ymdhms[5]);
	NSLog(@"SendData MD: (%02x)", data->lanHeadStruct.d_md);
	NSLog(@"SendData 機種ID: (%c%c%c%c%c)", data->lanHeadStruct.d_kisyu_no[0],data->lanHeadStruct.d_kisyu_no[1],data->lanHeadStruct.d_kisyu_no[2],data->lanHeadStruct.d_kisyu_no[3],data->lanHeadStruct.d_kisyu_no[4]);
	NSLog(@"SendData リザーブ an: (%x)", data->lanHeadStruct.d_an);
	NSLog(@"SendData リザーブ  status: (%02x%02x)", data->lanHeadStruct.d_status[0],data->lanHeadStruct.d_status[1]);
	NSLog(@"SendData チェックサム: (%02x)", data->lanHeadStruct.d_chksum);
	NSLog(@"SendData PR指示: (%02x)", data->lanHeadStruct.d_pr);
	NSLog(@"SendData　データ長: (%02x%02x)", data->lanHeadStruct.d_datalen[0],data->lanHeadStruct.d_datalen[1]);
	
	NSLog(@"SendData OES HEADER OES区分: (%02x)", data->oesHeadStruct.d_oes);
	NSLog(@"SendData OES HEADER SN: (%02x)", data->oesHeadStruct.d_sn);
	NSLog(@"SendData OES HEADER APLID: (%02x)", data->oesHeadStruct.d_aplid);
	

	NSLog(@"------- 注文データヘッダ部生成処理 OUT <<------- ");
#endif
	
	return YES;
}	



/*----------------------------------------------*/
/*		注文照会　伝文 生成処理						*/
/*		引数説明	:								*/
/*			(I) 伝文データ 先頭ポインタ				*/
/*			(I) テーブルNO						*/
/*----------------------------------------------*/
- (NSInteger) makeDataOrderDspRequest:(TableNo_ReqStruct*)data tableno:(NSString*) tableNo
{
	//const char *a;				// 文字列変換バッファ
	
	/*---- Start ----*/
	
#ifdef _DEBUG_DETAIL_
	NSLog(@"--------- 注文照会　伝文 生成処理 IN  data(%s)------->> ", data);
#endif
	
	//----------------------------------------
	// LAN ヘッダー部設定
	data->lanHeadStruct.d_head = 'T';
	data->lanHeadStruct.d_llr = ' ';
	data->lanHeadStruct.d_adp = 'C';
	
	// 伝文種別設定
	data->lanHeadStruct.d_knd[0] =  '2';	// 種別
	data->lanHeadStruct.d_knd[1] =  'L';	// 区分1(上位)
	data->lanHeadStruct.d_knd[2] =  '1';	// 区分1(下位)
	data->lanHeadStruct.d_knd[3] =  'H';	// 区分2
	data->lanHeadStruct.d_knd[4] =  'J';	// 区分3
	data->lanHeadStruct.d_knd[5] =  '0';	// タイプ
	
	// シーケンス番号の設定 (仕様上１固定)
	data->lanHeadStruct.d_seq_no[0] = '0';
	data->lanHeadStruct.d_seq_no[1] = '0';
	data->lanHeadStruct.d_seq_no[2] = '0';
	data->lanHeadStruct.d_seq_no[3] = '1';
	
	
	// 日時設定
	[self dateGet:&data->lanHeadStruct.d_ymdhms[0]];
	
	// MD
	data->lanHeadStruct.d_md = 'O';
	// 機種ID
	data->lanHeadStruct.d_kisyu_no[0] = 'O';
	data->lanHeadStruct.d_kisyu_no[1] = 'E';
	data->lanHeadStruct.d_kisyu_no[2] = 'S';
	data->lanHeadStruct.d_kisyu_no[3] = '9';
	data->lanHeadStruct.d_kisyu_no[4] = '0';
	// リザーブ
	data->lanHeadStruct.d_an = ' ';
	data->lanHeadStruct.d_status[0] = ' ';
	data->lanHeadStruct.d_status[1] = ' ';
	// PR指示子
	data->lanHeadStruct.d_pr = ' ';
	// データ長（テーブルNOでの要求なので固定）
	data->lanHeadStruct.d_datalen[0] = 0x00;
	data->lanHeadStruct.d_datalen[1] = 0x09;	// テーブルNO要求
	
	
	// OES ヘッダー部設定
	data->oesHeadStruct.d_oes = 0x00;
	data->oesHeadStruct.d_sn = 0x00;	
	
	// APLID の設定
	// 試験時は設定の関係で注文と注文照会は　　　0x0b とする
	//  正式には　0xC9 固定とする。
	data->oesHeadStruct.d_aplid = 0xc9;
	//data->oesHeadStruct.d_aplid = 0x0b;
	
	//------------------------------------
	// データ領域
	//   IC 設定　0x07 固定
	data->tableNoStruct.d_ic = 0x07;

	// テーブルNOの設定
	//  NSString -> unsigned char への変換
	char p[8];
	const char *ptr;
	ptr = &p[0];
	ptr = [tableNo UTF8String];
	char cbuf[8];
	memset( cbuf, (char)0x00, sizeof(cbuf) );
	sprintf( cbuf, "%5s",ptr);
	memcpy( (char*)&data->tableNoStruct.d_table_no[0], cbuf, 5 );
	
	// 顧客情報取得したテーブル番号と要求されたテーブル番号の整合性チェック
	if( memcmp(cbuf, saveOrderHeadData.d_table_no, 5) != 0 ){
		
		// テーブル番号不整合のメッセージを出力する
		NSString *string = [NSString stringWithFormat:@"伝票NOがありません。"];
		
		/*
		 data->orderHeadStruct.d_table_no[0],
		 data->orderHeadStruct.d_table_no[1],
		 data->orderHeadStruct.d_table_no[2],
		 data->orderHeadStruct.d_table_no[3],
		 data->orderHeadStruct.d_table_no[4]];
		 */
		
		UIAlertView * av = [[UIAlertView alloc] initWithTitle:@"エラーが発生しました"
													  message:string
													 delegate:nil
											cancelButtonTitle:@"はい"
											otherButtonTitles:nil];
		[av show];
		[av release];
		return -1;
	}
	
	
	
	
	
	
	// 伝文全体のチェックサム計算を行う
	data->lanHeadStruct.d_chksum = [self checkSum: (unsigned char*) data startAddr:0  endAddr:40];
	
	
#ifdef _DEBUG_DETAIL_
	NSLog(@"SendData 固定値: (%c)", data->lanHeadStruct.d_head);
	NSLog(@"SendData LLR: (%c)", data->lanHeadStruct.d_llr);
	NSLog(@"SendData ADP: (%c)", data->lanHeadStruct.d_adp);
	NSLog(@"SendData 伝文種別　種別: (%c)", data->lanHeadStruct.d_knd[0]);
	NSLog(@"SendData 伝文種別　区分１: (%c%c)", data->lanHeadStruct.d_knd[1],data->lanHeadStruct.d_knd[2]);
	NSLog(@"SendData 伝文種別　区分２: (%c)", data->lanHeadStruct.d_knd[3]);
	NSLog(@"SendData 伝文種別　区分３: (%c)", data->lanHeadStruct.d_knd[4]);
	NSLog(@"SendData 伝文種別　タイプ: (%c)", data->lanHeadStruct.d_knd[5]);
	NSLog(@"SendData 通番: (%02x%02x%02x%02x)", data->lanHeadStruct.d_seq_no[0],data->lanHeadStruct.d_seq_no[1],
		  data->lanHeadStruct.d_seq_no[2],data->lanHeadStruct.d_seq_no[3]);
	NSLog(@"SendData 日付: (%02x%02x%02x)", data->lanHeadStruct.d_ymdhms[0],data->lanHeadStruct.d_ymdhms[1],data->lanHeadStruct.d_ymdhms[2]);
	NSLog(@"SendData 時刻: (%02x%02x%02x)", data->lanHeadStruct.d_ymdhms[3],data->lanHeadStruct.d_ymdhms[4],data->lanHeadStruct.d_ymdhms[5]);
	NSLog(@"SendData MD: (%02x)", data->lanHeadStruct.d_md);
	NSLog(@"SendData 機種ID: (%c%c%c%c%c)", data->lanHeadStruct.d_kisyu_no[0],data->lanHeadStruct.d_kisyu_no[1],data->lanHeadStruct.d_kisyu_no[2],data->lanHeadStruct.d_kisyu_no[3],data->lanHeadStruct.d_kisyu_no[4]);
	NSLog(@"SendData リザーブ an: (%02x)", data->lanHeadStruct.d_an);
	NSLog(@"SendData リザーブ  status: (%02x%02x)", data->lanHeadStruct.d_status[0],data->lanHeadStruct.d_status[1]);
	NSLog(@"SendData チェックサム: (%02x)", data->lanHeadStruct.d_chksum);
	NSLog(@"SendData PR指示: (%02x)", data->lanHeadStruct.d_pr);
	NSLog(@"SendData　データ長: (%02x%02x)", data->lanHeadStruct.d_datalen[0],data->lanHeadStruct.d_datalen[1]);
	
	NSLog(@"SendData OES HEADER OES区分: (%02x)", data->oesHeadStruct.d_oes);
	NSLog(@"SendData OES HEADER SN: (%02x)", data->oesHeadStruct.d_sn);
	NSLog(@"SendData OES HEADER APLID: (%02x)", data->oesHeadStruct.d_aplid);
	
	NSLog(@"SendData TableNO IC: (%02x)", data->tableNoStruct.d_ic);
	NSLog(@"SendData TableNO IC: (%02x%02x%02x%02x%02x)", data->tableNoStruct.d_table_no[0],data->tableNoStruct.d_table_no[1],
		  data->tableNoStruct.d_table_no[2],data->tableNoStruct.d_table_no[3],data->tableNoStruct.d_table_no[4]);
	
	
	NSLog(@"------------- 注文照会　伝文 生成処理 OUT <<------- ");
#endif
	
	return 0;
	
	
}

/*----------------------------------------------*/
/* 注文アイテム数カウント							*/
/*		引数説明：									*/
/*			注文データ(NSArray*)					*/
/*		戻り値	:								*/
/*			アイテム数								*/
/*												*/
/*----------------------------------------------*/
-(unsigned int)itemCountGet:(NSArray*)items
{
	unsigned int cnt = 0;
	NSString *theObject;
	
	// メニューアイテム数分データを生成する
	for (id temp in items) {
		cnt++;
		theObject = [temp objectForKey:kItemSetItemkey];
		if ([theObject isKindOfClass:[NSArray class]]) {
			NSArray * aArray = (NSArray *)theObject;
			for (id aTemp in aArray) {
				cnt++;
				//theObject = aTemp;
				if ([aTemp isKindOfClass:[NSArray class]]) {
					NSArray * aaArray = (NSArray *)aTemp;
					for (id aaTemp in aaArray) {
						cnt++;
						
					}
				}
			}
		}
	}
	
	return cnt;
}



////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
#pragma mark --
#pragma mark iPad Interface Method
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

/********************************************************/
/*			画面から呼び出されるメソッド　　　　				*/
/********************************************************/

/*----------------------------------------------*/
/*		顧客照会 I/F								*/
/*		引数説明	:								*/
/*			(I) テーブルNO						*/
/*		戻り値	:								*/
/*			リクエストNO							*/
/*												*/
/*----------------------------------------------*/
- (NSNumber*) customerInfoFromTableID:(NSString *)tableID
{
	
	/*------ Start ------*/
	
	[self countUP];
	NSNumber * num = [NSNumber numberWithInt:reqNo];
	
#ifdef _DEBUG_DETAIL_
	NSLog(@"kolSocket--> 顧客照会(customerInfoFromTableID):テーブルNO(%@) リクエストNO(%d) IN --->>",tableID,reqNo);
	NSLog(@" IPアドレス　　　　　(%@)",hostAddr);
	NSLog(@" ポート番号（要求）　(%@)",portReq);
	NSLog(@" ポート番号（照会）　(%@)",portAsk);
	NSLog(@" リトライ　　　　　　(%@)",rtry);
#endif
	
	
	TableNo_ReqStruct tableReq_str_data;
	
	//----------------------------------
	// 顧客照会伝文 生成処理
	[self makeDataCustomerRequest:(TableNo_ReqStruct*)&tableReq_str_data 
										  tableno:( NSString *) tableID];
	//ret;
	NSData *ndata;
	ndata = [NSData data];
	ndata = [NSData dataWithBytes:&tableReq_str_data length:sizeof(tableReq_str_data)];

	
	// ソケットオープン
	if( ![self kolSocketOpen: hostAddr port:portAsk retry:rtry ] ){
		NSLog(@"kolSocketOpen:   Error!!");
		return num;
	}
	
    // add by n.sasaki 2012.03.06 志対応
    [Logger WriteLog:ndata sendrecv:true];
    
	//-----------------------------------
	// データ送信
	[self.asyncSocket writeData:ndata withTimeout:-1 tag:0];	// n.sasaki 2012.01.23 memoryleak対応
	
#ifdef _DEBUG_
	NSLog(@"=====================================================================");
	NSLog(@"テーブル番号(%@)の顧客照会をSTNへ送信しました　リクエスト番号(%@)で返します-------<<",tableID,num);
	NSLog(@"=====================================================================");
#endif

	return num;
}


/*----------------------------------------------*/
/* 注文 I/F										*/
/*		引数説明：									*/
/*			注文データ(NSArray*)					*/
/*		戻り値	:								*/
/*			リクエストNO							*/
/*												*/
/*----------------------------------------------*/
-(NSNumber*)orderingOfItems:(NSString*)tableID orderItems:(NSArray*)items
{
	unsigned char	chksum;			// チェックサム計算値
	unsigned char	*ptr_org;		// メニューアイテムデータ領域　先頭ポインタバッファ
	int				sizeItem = 0;	// メニューアイテム数
	int				size = 0;		// NSMutableDataのサイズ
	const void		*cp;			// NSMutableDataをCで認識できるByteデータに変換したバッファ
	NSData			*ndata;			// メニューアイテムデータ領域
	NSInteger		ret = 0;
	NSError			**error;


	/*------ Start -------*/
	
	// 追加処理
	// saveOrderHeader内のテーブル番号と引数のテーブル番号を比較して違う場合は
	// テーブル番号不正です。画面再起動してくださいのメッセージが必要である

	[self countUP];
	NSNumber * num = [NSNumber numberWithInt:reqNo];

#ifdef _DEBUG_DETAIL_
	NSLog(@"kolSocket--> 注文(orderingOfItems): リクエストNO(%d) IN ---->> ",reqNo);
	NSLog(@"items(%@)",items);
#endif
	
	

	//-------------------------------------
	// 注文データ生成処理
	//	ヘッダー部とメニューアイテム部は分けて生成する
	
	//
	//   ヘッダー部生成処理
	//		生成データ領域を引数で渡してメソッド内でデータのセットを行う
	OrderRequestHeadStruct orderReq;
	BOOL bolRet = [self makeDataOrderingHead:tableID data:&orderReq error:(NSError**)error];
    
    // 変数のダミー参照
	//bolRet;

    // Add Start 2012-03-11 kitada
    // 通信制御不具合改修(志様・01CAFE障害対応)
    // 注文ヘッダ部生成時に伝票NOが未取得（テーブルNOが不整合）であれば、
    // 注文データの送信は行わずに画面に通知する。
	if( bolRet == NO ){
		[self performSelector:@selector(nopSocket) withObject:nil afterDelay:0.75];
		return num;
	}
    // Add End 2012-03-11 kitada    
    
	//
	//   メニューアイテム部生成処理	
	//　		注文件数の取得	
	//       A - D
	//         - A -D
	//             -D
	//
	//
	int itemCnt = [self itemCountGet:items];
	
#ifdef _DEBUG_DETAIL_
	printf(" \n-------- 注文データ件数(%d)\n",itemCnt);
#endif	
	
	// メニューアイテムがある場合はデータ作成を行う
	if( itemCnt > 0 ){

		// 注文品情報のデータ領域確保を行う
		//  (オーダーアイテム個数　× １注文アイテム情報）
		OrderItemStruct orderItem;
		sizeItem = (int)itemCnt * sizeof(orderItem);
		OrderItemStruct *p = malloc( sizeItem );
		ptr_org = (unsigned char*)p ;			// 解放用にアドレス退避
		
		// 注文データの設定メソッドを呼ぶ
		//  配列で渡された注文データを電文形式にする
		ret = [self makeDataOrdering:(NSArray*)items buffer:(OrderItemStruct*)p error:( NSError **) error];
		
		
		// メニューアイテムデータ領域を作成する
		ndata = [NSData data];
		//ndata = [NSData dataWithBytes:p length:sizeof(orderReq)];
		ndata = [NSData dataWithBytes:p length:sizeItem];

		// メニューアイテム部の領域を解放する
		free(ptr_org);
		
#ifdef _DEBUG_DETAIL_
		NSLog(@"    ndata length(%d) ndata(%@",size,ndata);
#endif
		
	}else {
		
		// 注文メニューが無い場合はこちら
		sizeItem = 0;
	}

	// メニューアイテム数をセット
	orderReq.d_rc = itemCnt;
	
	// データ長の算出を行い ビッグエンディアンへ変換して設定する
	// OESヘッダー部より最後までを算出する
	short dataLen = sizeof(orderReq) - sizeof(LanHeadStruct) +  sizeItem;
	short b_dataLen;
	b_dataLen = NSSwapHostShortToBig(dataLen);
	memcpy( orderReq.lanHeadStruct.d_datalen, &b_dataLen, 2 );
	
	// ヘッダー部とメニューアイテム部を結合する
	//	変更可能なデータを作成する
	//  LANヘッダー部から メニューアイテム部の手前までのデータを作成する
	NSMutableData *nmdata;
	nmdata = [NSMutableData	dataWithBytes:&orderReq length:sizeof(orderReq)];
	
	// メニューアイテムがある場合はヘッダとメニューアイテムデータを結合する	
	if( itemCnt > 0 ){
		
		// 結合
		[nmdata appendData:ndata];
		
	}

	// チェックサム計算のための処理
	//	NSMutableDataをCで認識できるByteデータに変換してデータ長を取得する
	cp = [nmdata bytes];
	size = [nmdata length];
	

	// チェックサム計算（LANヘッダーからメニューアイテムの最後までを計算する）
	// 設定バージョンの前の[CS]項目には入れなくてもよい
	chksum = [self checkSum:(unsigned char*)cp startAddr:0  endAddr:size-1];	
	[nmdata replaceBytesInRange:NSMakeRange(28, 1) withBytes:&chksum];	 

#ifdef _DEBUG_DETAIL_
	NSLog(@"    アイテムカウント数(%02x) checkSum 0x(%02x)",orderReq.d_rc,chksum);
	NSLog(@"    データ長(設定バージョンから電文最後まで) (%d)",dataLen);
	NSLog(@"    nmdata length(%d) nmdata(%@",size,nmdata);
#endif	

	// ソケットオープン
	if( ![self kolSocketOpen: hostAddr port:portReq retry:rtry] ){
		
		NSLog(@"kolSocketOpen:   Error!!");
		[self performSelector:@selector(nopSocket) withObject:nil afterDelay:0.75];
		return num;
	}
	
    // add by n.sasaki 2012.03.06 志対応
    [Logger WriteLog:nmdata sendrecv:true];
	// データ送信
	[self.asyncSocket writeData:nmdata withTimeout:-1 tag:0];   // n.sasaki 2012.01.23 memoryleak対応
	
	
#ifdef _DEBUG_
	NSLog(@"=====================================================================");
	NSLog(@" テーブル番号(%@)の注文データをSTNへ送信しました　リクエスト番号(%@)で返します-------<<",tableID,num);
	NSLog(@"=====================================================================");
#endif
	
	return num;
	//ret;
}


/*----------------------------------------------*/
/*		注文照会 I/F								*/
/*		引数説明	:								*/
/*			(I) テーブルNO						*/
/*		戻り値	:								*/
/*			リクエストNO							*/
/*												*/
/*----------------------------------------------*/
- (NSNumber*) orderHistoryFromTableID:( NSString *) tableID
{

	[self countUP];
	NSNumber * num = [NSNumber numberWithInt:reqNo];
	
#ifdef _DEBUG_DETAIL_
	NSLog(@"kolSocket--> 注文照会(orderHistoryFromTableID): テーブルNO(%@) リクエストNO(%d)"
							,tableID,reqNo);
#endif
	
	
	//注文照会伝文 生成処理
	TableNo_ReqStruct tableReq_str_data;	
	NSInteger ret = [self makeDataOrderDspRequest:(TableNo_ReqStruct*)&tableReq_str_data 
										   tableno:( NSString *) tableID];

	// 注文照会伝文生成エラーのため送信せずに画面に返す。
	// 画面側のキューにデータが残るために delegate 通知をする
	if( ret != 0 ){
		
		[self performSelector:@selector(nopSocket) withObject:nil afterDelay:0.75];
		return num;
	}
		
	// 送信メソッドの引数型にあわせるためNSData型に変換する
	NSData *ndata;
	ndata = [NSData data];
	ndata = [NSData dataWithBytes:&tableReq_str_data length:sizeof(tableReq_str_data)];

	// ソケットオープン
	if( ![self kolSocketOpen: hostAddr port:portReq retry:rtry ] ){
		NSLog(@"kolSocketOpen:   Error!!");
		[self performSelector:@selector(nopSocket) withObject:nil afterDelay:0.75];
		return num;
	}
	
    // add by n.sasaki 2012.03.06 志対応
    [Logger WriteLog:ndata sendrecv:true];
    
	// データ送信
    
	[self.asyncSocket writeData:ndata withTimeout:-1 tag:0];    // 2012.01.23 n.sasaki memoryleak対応
	
	
#ifdef _DEBUG_
	NSLog(@"=====================================================================");
	NSLog(@"テーブル番号(%@)の注文照会要求をSTNへ送信しました　リクエスト番号(%@)で返します-------<<",tableID,num);
	NSLog(@"=====================================================================");
#endif
	
	
	return num;
}

@end
/*
 *  kolSocketStruct.h
 *  socketTab
 *
 *  Created by Kobe Digital Lab on 10/11/25.
 *  Updated by Kobe Digital Labo on 10/11/28.
 *  Copyright 2010 Kobe Digital Lab. All rights reserved.
 *
 */

/****************************************************************/
/*			iPad-OES 伝文構造体　定義								*/
/****************************************************************/

/*--------------------------------------------------*/
/* 共通ヘッダ											*/
/*--------------------------------------------------*/
//
// LAN ヘッダー　構造体
//
typedef struct {
	unsigned char d_head;			// 固定値　'T' 固定
	unsigned char d_llr;			// LLR指示子　スペース固定
	unsigned char d_adp;			// ADP種別
	unsigned char d_knd[6];			// 伝文種別
	unsigned char d_seq_no[4];		// 通番
	unsigned char d_ymdhms[6];		// 日時
	unsigned char d_md;				// MD
	unsigned char d_kisyu_no[5];	// 機種ID
	unsigned char d_an;				// ACK/NAK種別
	unsigned char d_status[2];		// ステータス
	unsigned char d_chksum;			// チェックサム
	unsigned char d_pr;				// PR指示子
	unsigned char d_datalen[2];		// データ長
} LanHeadStruct;


//
// OES ヘッダー　構造体
//
typedef struct {
	unsigned char d_oes;			// OES区分
	unsigned char d_sn;				// SN
	unsigned char d_aplid;			// APLID
} OesHeadStruct;


/*--------------------------------------------------*/
/* 顧客照会　<送信>									*/
/*--------------------------------------------------*/
//
//		APLデータ部
//			テーブルNoでのリクエスト用
typedef struct {
	unsigned char d_ic;				// IC (ITEM CODE)
	unsigned char d_table_no[5];	// テーブルNO
} TableNoStruct;


//
//		全体構造体	
//
typedef struct {
	LanHeadStruct lanHeadStruct;	// LANヘッダー構造体
	OesHeadStruct oesHeadStruct;	// OESヘッダー構造体
	TableNoStruct tableNoStruct;	// テーブルNOでのリクエスト構造体
} TableNo_ReqStruct;



/*--------------------------------------------------*/
/* 顧客照会　<受信>									*/
/*--------------------------------------------------*/
//
//		ACK/NAK共通部
//
typedef struct {
	LanHeadStruct lanHeadStruct;	// LANヘッダー構造体
	OesHeadStruct oesHeadStruct;	// OESヘッダー構造体
} ResponceStruct;



//
//		ACK 応答伝文 ミニヘッダ 構造体
//
typedef struct {
	unsigned char d_cs;				// チェックサム
	unsigned char d_set_version[5];	// 設定バージョン
	unsigned char d_htl_status[4];	// HTLステータス
} AckResHeadStruct;


//
//		オーダーヘッダー部
//
typedef struct {
	unsigned char d_denpyo_no[3];		// 伝票NO
	unsigned char d_table_no[5];		// テーブルNO
	unsigned char d_nokeytable_no[5];	// ノンキーテーブルNO
	unsigned char d_ninzuu[5];			// 人数
	unsigned char d_otooshi[5];			// お通し人数
	unsigned char d_tantou[5];			// 担当者NO
	unsigned char d_ccpno[5];			// CCP出力先NO
	unsigned char d_kpno[5];			// KP出力先NO
	unsigned char d_etc1[5];			// 任意情報1
	unsigned char d_etc2[5];			// 任意情報2
	unsigned char d_etc3[5];			// 任意情報3
	unsigned char d_etc4[5];			// 任意情報4
	unsigned char d_kyakusou1[2];		// 客層1
	unsigned char d_kyakusou2[2];		// 客層2
	unsigned char d_kyakusou3[2];		// 客層3
	unsigned char d_kyakusou4[2];		// 客層4
	unsigned char d_kyakusou5[2];		// 客層5
} OrderHeadStruct;


//
//		オーダーサブヘッダー部
//
typedef struct {
	unsigned char d_denpyo_eda_no;		// 伝票枝番号
	unsigned char d_denpyo_seq_no[3];	// 伝票一連番号
	unsigned char d_new_order_time[6];	// 新規オーダー時刻
	unsigned char d_add_order_time[6];	// 追加オーダー時刻
	unsigned char d_server_time[6];		// 料理提供時刻
	unsigned char d_menu_syoukei[5];	// メニュー小計金額
	unsigned char d_maeuke[5];			// 前受け金額
	unsigned char d_houshi[5];			// 奉仕料金額
	unsigned char d_sekiryou[5];		// 席料金額
	unsigned char d_soyuhizei[5];		// 特消税金額
	unsigned char d_sotozei[5];			// 外税金額
	unsigned char d_goukei[5];			// 合計金額
	unsigned char d_torikeshi_su[3];	// 取消点数
	unsigned char d_torikeshi_gaku[5];	// 取消金額
	unsigned char d_table_name[8];		// テーブル名称
	unsigned char d_zeikbn;				// 席 奉税区分
	unsigned char d_ccp;				// CCP出力先
	unsigned char d_kp[4];				// KP出力先
	unsigned char d_desyapu[4];			// デシャップ出力先
	unsigned char d_err;				// エラー出力先
	unsigned char d_ichicode[8];		// 位置コード0 - 7
	unsigned char d_mainmenu_su[3];		// メインメニュー点数
	unsigned char d_submenu_su[3];		// サブメニュー点数
	unsigned char d_commentmenu_su[3];	// コメントメニュー点数
	unsigned char d_nomihoudai_starttime[2];	// 飲み放題開始時刻
	unsigned char d_ffu[14];			// FFU
	unsigned char d_rc;					// RC オーダーアイテム個数
} OrderSubHeadStruct;



//
//		オーダーアイテム部（最大１６０アイテム数）
//
typedef struct {
	unsigned char d_menucode[2];		// メニューコード
	unsigned char d_kaisou;				// 階層、指示ステータス
	unsigned char d_siji;				// 指示NO
	unsigned char d_st[7];				// ST1 - 7
	unsigned char d_suuryou[2];			// 数量
	unsigned char d_tanka[4];			// 単価
	unsigned char d_commentno[2];		// コメントNO
	unsigned char d_ordertime[2];		// オーダー時刻
} OrderItemTimeStruct;



//
//		ACK応答伝文 全体構造体
//
typedef struct {
	LanHeadStruct		lanHeadStruct;		// LAN HEADER
	OesHeadStruct		oesHeadStruct;		// OES HEADER
	AckResHeadStruct	ackResHeadStruct;	// ACK 応答ヘッダ部
	OrderHeadStruct		orderHeadStruct;	// オーダーヘッダー部
	OrderSubHeadStruct	orderSubHeadStruct;	// オーダーサブヘッダー部
	unsigned char d_ic;						// IC (ITEM CODE)
} AckResponceStruct;




/*--------------------------------------------------*/
/* 注文　<送信>										*/
/*--------------------------------------------------*/
//
//		HTL STATUS
//			ACK 応答伝文 ミニヘッダ 構造体が同じなので
//			AckResHeadStruct を使う
//
//
//		オーダーアイテム部（最大１６０アイテム数）
//
typedef struct {
	unsigned char d_menucode[2];		// メニューコード
	unsigned char d_kaisou;				// 階層、指示ステータス
	unsigned char d_siji;				// 指示NO
	unsigned char d_st[7];				// ST1 - 7
	unsigned char d_suuryou[2];			// 数量
	unsigned char d_tanka[4];			// 単価
	unsigned char d_commentno[2];		// コメントNO
} OrderItemStruct;




//
//		注文伝文　<送信> 全体構造体
//
typedef struct {
	LanHeadStruct		lanHeadStruct;		// LAN HEADER
	OesHeadStruct		oesHeadStruct;		// OES HEADER
	AckResHeadStruct	ackResHeadStruct;	// HTL STATUS
	OrderHeadStruct		orderHeadStruct;	// オーダーヘッダー部
	unsigned char d_rc;						// RC（注文商品数）
} OrderRequestHeadStruct;




/*--------------------------------------------------*/
/* 注文	<受信>										*/
/*--------------------------------------------------*/
//
//		残数不足メニューコード構造体　（未使用）
//
typedef struct {
	unsigned char d_fusoku_menucd[2];			// 残数不足メニューコード
} FusokuMenuCdStruct;

//
//		注文伝文　<受信>　全体構造体
//
typedef struct {
	LanHeadStruct		lanHeadStruct;		// LAN HEADER
	OesHeadStruct		oesHeadStruct;		// OES HEADER
	unsigned char d_ic_s;						// IC 品切れ用(ITEM CODE)
	unsigned char d_sinagire_flg[1200];			// メニュー品切れフラグ
	unsigned char d_ic_k;						// IC KCP用(ITEM CODE)
	unsigned char d_kcp_flg[32];				// KCP状況フラグ
} OrderResStruct;


/*--------------------------------------------------*/
/* 注文照会	<送信>									*/
/*--------------------------------------------------*/
//
//		全体構造体	
//
//			顧客ファイル呼出リクエストと同一構造体を使用
//			TableNo_ReqStruct
//


/*--------------------------------------------------*/
/* 注文照会	<受信>									*/
/*--------------------------------------------------*/
//
//		全体構造体	
//
//			顧客ファイル呼出応答と同一構造体を使用
//			AckResponceStruct
//			OrderItemTimeStruct


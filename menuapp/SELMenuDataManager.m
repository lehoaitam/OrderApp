//
//  SELMenuDataManager.m
//  menuapp
//
//  Created by dpcc on 2014/04/08.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELMenuDataManager.h"
#import "SSZipArchive.h"
#import "UUIDUtil.h"
#import "SELSettingDataManager.h"
#import "SELUserData.h"
#import "AFNetworking.h"
#import "SELItemDataManager.h"
#import "NSDate+Utilities.h"

//#import "KKMeasureTimeLogger.h"

NSString *const SELMenuChangeNotification = @"SELMenuChangeNotification";
NSString *const SELUISettingChangeNotification = @"SELUISettingChangeNotification";

NSString *const SELUpdateMenuSuccessNotification = @"SELUpdateMenuSuccessNotification";
NSString *const SELUpdateMenuErrorNotification = @"SELUpdateMenuErrorNotification";
NSString *const SELUpdateMenuStatusNotification = @"SELUpdateMenuStatusNotification";

@implementation SELMenuDataManager

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
//        [self UpdateMenuPages];
    }
    return self;
}

- (void)CreateDemoData
{
    // demozipfile
    NSBundle *bundle = [NSBundle mainBundle];
    NSString *demofilepath = [bundle pathForResource:@"gae_upload" ofType:@"zip"];
    //NSURL *url = [NSURL fileURLWithPath:demofilepath];
    
    // 解凍先はDocument/URLCache/decode(フォルダ名なしでの解凍)
    NSString *zipPath = demofilepath;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [paths objectAtIndex:0];
    NSString *destinationPath = [documentPath stringByAppendingPathComponent:@"/URLCache/decode"];
    
    // 一旦ファイルを削除
    [[NSFileManager defaultManager] removeItemAtPath:[documentPath stringByAppendingString:@"/URLCache"] error:nil];
    
    // zip展開
    [SSZipArchive unzipFileAtPath:zipPath toDestination:destinationPath];
}

- (NSURL*)createLocalURL:(NSString*)path
{
    // アプリのDocumentディレクトリ + 引数のpathのURLを作成する
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString *documentDirPath = [searchPaths objectAtIndex:0];
    NSString *filePath = [documentDirPath stringByAppendingPathComponent:path];
    NSURL *url = [NSURL fileURLWithPath:filePath];
    return url;
}

- (NSString*)getMenuPath:(NSInteger)menuNumber
{
    // currentMenuNumberに対応するpathを返す
    switch (menuNumber) {
        case 1:
            // 1の場合のみMenu
            return @"html";
            break;
        default:
            // それ以外の場合はMenuXX
            return [NSString stringWithFormat:@"html%ld", (long)menuNumber];
            break;
    }
}

- (NSString*)getCurrentMenuWorkPath
{
    SELSettingDataManager* settingDataManager = [SELSettingDataManager instance];
    NSInteger menuNumber = [settingDataManager GetMenuNumber];
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* decodePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/"];
    NSString* workPath = [decodePath stringByAppendingPathComponent:[self getMenuPath:menuNumber]];
    
    return workPath;
}

- (NSString *)GetMenuName:(NSInteger)menuNumber
{
    // menuset_data.jsonを読み込む
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* jsonPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/menuset_data.json"];
    
    NSData *data = [NSData dataWithContentsOfFile:jsonPath];
    if (!data) {
        return @"";
    }
    
    NSError *error = nil;
    
    NSDictionary* jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                              options:kNilOptions
                                                error:&error];
    
    NSDictionary* menuNameDict = [jsonObject objectForKey:@"list"];
    NSString* menuName = [menuNameDict objectForKey:[NSString stringWithFormat:@"%ld", (long)menuNumber]];
    
    return menuName;
}

- (NSString *)GetMenuLocalization:(NSInteger)menuNumber
{
    // menuset_data.jsonを読み込む
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* jsonPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/menuset_data_detail.json"];
    
    NSData *data = [NSData dataWithContentsOfFile:jsonPath];
    if (!data) {
        return @"ja";   // 無い場合は日本語
    }
    
    NSError *error = nil;
    
    NSDictionary* jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                               options:kNilOptions
                                                                 error:&error];
    
    NSDictionary* menuNameDict = [jsonObject objectForKey:@"list"];
    NSDictionary* menuData = [menuNameDict objectForKey:[NSString stringWithFormat:@"%ld", (long)menuNumber]];
    NSString* localization = [menuData objectForKey:@"language"];
    
    return localization;
}

- (NSArray *)GetMenus
{
    // メニューURLリスト（複数メニュー対応）を返す
    NSMutableArray* menus = [[NSMutableArray array]init];
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* decodePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/"];

    // Menuの数を調べる
    int nMenuNumber = 1;
    while (TRUE) {
        // MenuDirがあるか調べる
        NSString* menuPath = [decodePath stringByAppendingPathComponent:[self getMenuPath:nMenuNumber]];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:menuPath]) {
            NSURL* url = [NSURL fileURLWithPath:menuPath];
            [menus addObject:url];
        }
        else{
            // Menuが無い場合は終了
            break;
        }
        nMenuNumber++;
    }

    return menus;
}

- (NSURL*)GetTopMenu
{
    //
    SELSettingDataManager* settingDataManager = [SELSettingDataManager instance];
    NSInteger menuNumber = [settingDataManager GetMenuNumber];
    
    // toppageのurlを返す(/URLCache/decode/htmlXX/topView.html)
    NSString* menuPath = [@"/URLCache/decode/" stringByAppendingPathComponent:[self getMenuPath:menuNumber]];
    NSString* topMenuHTMLPath = [menuPath stringByAppendingPathComponent:@"topView.html"];
    NSURL* url = [self createLocalURL:topMenuHTMLPath];
    return url;
}

- (void)UpdateMenuPages
{
    //initialize and start a measurement
//    [KKMeasureTimeLogger startWithLogMode:KKMeasureTimeLogModeAfter];
    
    //
    SELSettingDataManager* settingDataManager = [SELSettingDataManager instance];
    NSInteger menuNumber = [settingDataManager GetMenuNumber];
    
    // メニューリスト（複数メニュー対応）を返す
    self.MenuPages = [[NSMutableArray array]init];
    
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* decodePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/"];
    NSString* workPath = [decodePath stringByAppendingPathComponent:[self getMenuPath:menuNumber]];
    
    int nPage = 1;
    while (TRUE) {
        // ページ.htmlがあるか調べる
        NSString* fileName = [NSString stringWithFormat:@"%d.html", nPage];
        NSString* filePath = [workPath stringByAppendingPathComponent:fileName];
        
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
//            NSURL* url = [NSURL fileURLWithPath:filePath];
            [self.MenuPages addObject:filePath];
        }
        else{
            // ページが無い場合は終了
            break;
        }
        nPage++;
    }
    
    //stop
//    [KKMeasureTimeLogger stop];
}

#pragma region - Data Update

- (void)Update
{
    // オペレーションキューを作成
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    [queue addOperationWithBlock:^{
        
        // サーバーと認証を行い、MenuURLを取得する
        NSString* dataURL = [self authenticate];
        if (!dataURL) {
            return ;
        }
        
        // Dataをダウンロードする
        [self downloadData:dataURL];
    }];
}

- (void)notificationStatus:(NSString*)status progress:(CGFloat)progressF
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    NSMutableDictionary* dict = [[NSMutableDictionary alloc]init];
    [dict setObject:status forKey:@"status"];
    
    NSNumber* progress = [NSNumber numberWithFloat:progressF];
    [dict setObject:progress forKey:@"progress"];
    
    dispatch_async(dispatch_get_main_queue(),^{
        [notificationCenter postNotificationName:SELUpdateMenuStatusNotification object:dict];
    });
}

- (NSString*)authenticate
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    [self notificationStatus:@"サーバー通信中\n（認証処理中）" progress:0];
    
    // UserDataを取得
    SELSettingDataManager* settingDataManager = [SELSettingDataManager instance];
    SELUserData* userData = [settingDataManager GetUserData];
    if (!userData) {
        //
        dispatch_async(dispatch_get_main_queue(),^{
            [notificationCenter postNotificationName:SELUpdateMenuErrorNotification object:@"ユーザーデータが設定されていません"];
        });
        return NULL;
    }
    
    // menuURLを取得する
    NSString* UUID = [UUIDUtil stringWithUUID];
    
    // テスト環境
//    NSString* getmenuURL = [[NSString alloc] initWithFormat:@"https://dev01-so.kdlapps.net/getmenu.php?name=%@&code=%@&pass=%@&uuid=%@", userData.CompanyName, userData.CompanyCode, userData.CompanyPass, UUID];
    // 本番環境
    NSString* getmenuURL = [[NSString alloc] initWithFormat:@"https://www2.ipadso.net/getmenu.php?name=%@&code=%@&pass=%@&uuid=%@", userData.CompanyName, userData.CompanyCode, userData.CompanyPass, UUID];
    
    NSURLRequest *getmenuRequest = [NSURLRequest requestWithURL:[NSURL URLWithString:getmenuURL]];
    NSError* error = nil;
    
    // 認証処理(同期処理)
    NSData *json_data = [NSURLConnection sendSynchronousRequest:getmenuRequest returningResponse:nil error:&error];
    if (json_data == NULL) {
        NSLog(@"getmenu connection error: %@", error);
        dispatch_async(dispatch_get_main_queue(),^{
            [notificationCenter postNotificationName:SELUpdateMenuErrorNotification object:@"通信エラーが発生しました"];
        });
        return NULL;
    }
    NSDictionary *jsonObject = [NSJSONSerialization JSONObjectWithData:json_data options:NSJSONReadingAllowFragments error:&error];
    if (jsonObject == NULL) {
        NSString *str= [[NSString alloc] initWithData:json_data encoding:NSUTF8StringEncoding];
        NSLog(@"getmenu return error: %@",str);
        dispatch_async(dispatch_get_main_queue(),^{
            [notificationCenter postNotificationName:SELUpdateMenuErrorNotification object:@"認証処理でエラーが発生しました"];
        });
        return NULL;
    }
    
    // 認証結果から、ダウンロードパスを取得する
    NSNumber* nResult = [jsonObject objectForKey:@"result"];
    if ([nResult intValue] == 0) {
        dispatch_async(dispatch_get_main_queue(),^{
            [notificationCenter postNotificationName:SELUpdateMenuErrorNotification object:@"認証処理でエラーが発生しました"];
        });
        return NULL;
    }
    
    // 更新されているかどうか
    
    // サーバー側の最終更新日時
    NSString* updated = [jsonObject objectForKey:@"updated"];
    NSDate* updatedDate = [NSDate dateFromString:updated];
    // データの最終更新日時
    NSDate* lastModifiedDate = [[NSUserDefaults standardUserDefaults] objectForKey:@"lastModifiedDate"];
    
    if ([updatedDate isEqualToDate:lastModifiedDate]) {
        dispatch_async(dispatch_get_main_queue(),^{
            [notificationCenter postNotificationName:SELUpdateMenuErrorNotification object:nil];
        });
        return NULL;
    }
    
    NSString* dataURL = [jsonObject objectForKey:@"link"];
    return dataURL;
}

- (void)downloadData:(NSString*)dataURL
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    
    // ダウンロード先のURLを設定したNSURLRequestインスタンスを生成する
    NSMutableURLRequest *request =
    [manager.requestSerializer requestWithMethod:@"GET" URLString:dataURL parameters:nil error:nil];
    
    // ダウンロード処理を実行するためのAFHTTPRequestOperationインスタンスを生成する
    AFHTTPRequestOperation *operation =
    [manager HTTPRequestOperationWithRequest:request
                                     success:^(AFHTTPRequestOperation *operation, id responseObject) {
                                         // ダウンロードに成功したらコンソールに成功した旨を表示する
                                         NSLog(@"データ更新完了！");
//                                         NSLog(@"%@", [[operation.response allHeaderFields] description]);
                                         
                                         // http responseのLast-Modifiedを最終更新日として持つ
                                         NSDictionary* responseHeader = [operation.response allHeaderFields];
                                         NSString* lastModifiedString = [responseHeader objectForKey:@"Last-Modified"];
                                         [[SELSettingDataManager instance] SetMenuDataLastModified:lastModifiedString];
                                         
                                         // ダウンロードデータを展開する
                                         [self updateDownloadData];
                                         
                                         dispatch_async(dispatch_get_main_queue(),^{
                                             [notificationCenter postNotificationName:SELUpdateMenuSuccessNotification object:nil];
                                         });

                                     } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
                                         // エラーの場合はエラーの内容をコンソールに出力する
                                         NSLog(@"データ更新エラー: %@", error);
                                         dispatch_async(dispatch_get_main_queue(),^{
                                             [notificationCenter postNotificationName:SELUpdateMenuErrorNotification object:error];
                                         });
                                     }];
    
    // データを受信する度に実行される処理を設定する
//    __weak NSOperation* weakOperation = operation;
    [operation setDownloadProgressBlock:^(NSUInteger bytesRead, long long totalBytesRead, long long totalBytesExpectedToRead) {
//        NSLog(@"Read %lld/%lld", totalBytesRead, totalBytesExpectedToRead);
//        if (weakOperation.isCancelled) {
//            NSLog(@"canceled...");
//            return;
//        }
        CGFloat progressF = (CGFloat)totalBytesRead / totalBytesExpectedToRead;
        [self notificationStatus:@"データ更新中..." progress:progressF];
    }];
    
    // <Application_Home>/Library/Cachesディレクトリのパスを取得する
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    // <Application_Home>/Library/Caches/gae_upload.zip
    NSString * zipFilePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"gae_upload.zip"];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    if ([fileManager fileExistsAtPath:zipFilePath]) {
        [fileManager removeItemAtPath:zipFilePath error:nil];
    }
    
    // ファイルの保存先を指定する
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:zipFilePath append:NO];
    
    // ダウンロードを開始する
    [manager.operationQueue addOperation:operation];
}

- (void)updateDownloadData
{
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];

    NSFileManager *fm = [NSFileManager defaultManager];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString * workPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"URLCache"];
    
    // 解凍先ディレクトリを一旦削除
    [fm removeItemAtPath:workPath error:nil];
    
    // 解凍先ディレクトリを作成する
    if (![fm createDirectoryAtPath:workPath withIntermediateDirectories:NO attributes:nil error:nil]) {
        dispatch_async(dispatch_get_main_queue(),^{
            [notificationCenter postNotificationName:SELUpdateMenuErrorNotification object:@"ディレクトリ作成に失敗しました"];
        });
        return;
    }
    
    // 解凍先はDocument/URLCache/decode (フォルダ名なしでの解凍)
    NSString *destinationPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode"];
    NSString * zipFilePath = [[paths objectAtIndex:0]stringByAppendingPathComponent:@"gae_upload.zip"];
    [SSZipArchive unzipFileAtPath:zipFilePath toDestination:destinationPath];

    // Setting.json -> NSUserDefaultにセットする
    SELSettingDataManager* settingDataManager = [SELSettingDataManager instance];
    [settingDataManager UpdateSettingData];
    
    // 商品データなどを更新する
    SELItemDataManager* itemDataManager = [SELItemDataManager instance];
    [itemDataManager reload];
    
    // ダウンロードが終わった場合、メニューは最初のメニューとする
    [settingDataManager SetMenuNumber:1];
    
    // メニューURLリストを更新する
    [self UpdateMenuPages];
}

@end

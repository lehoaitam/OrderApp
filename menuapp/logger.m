//
//  WriteFile.m
//  MenuApp
//
//  Created by  on 12/03/08.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "logger.h"

// Add Start 2012-03-11 kitada
// 通信制御不具合改修(志様・01CAFE障害対応)
// 電文ログファイル削除基準日
#define LOG_DELETE_BASE_DATE 30
// Add End 2012-03-11 kitada

@implementation NSData (NSData_Conversion)

#pragma mark - String Conversion
- (NSString *)hexadecimalString {
    /* Returns hexadecimal string of NSData. Empty string if data is empty.   */
    
    const unsigned char *dataBuffer = (const unsigned char *)[self bytes];
    
    if (!dataBuffer)
        return [NSString string];
    
    NSUInteger          dataLength  = [self length];
    NSMutableString     *hexString  = [NSMutableString stringWithCapacity:(dataLength * 2)];
    
    for (int i = 0; i < dataLength; ++i)
        [hexString appendString:[NSString stringWithFormat:@"%02x", (unsigned long)dataBuffer[i]]];
    
    return [NSString stringWithString:hexString];
}

@end

@implementation Logger

+ (void)WriteLog:(NSData*)data sendrecv:(BOOL)isSend{
    
    NSDate* now = [NSDate date];
    
    // NSDateFormatter を用意します。
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    // 変換用の書式を設定します。
    [formatter setDateFormat:@"YYYYMMdd"];
    // NSDate を NSString に変換します。
    NSString* fileName = [NSString stringWithFormat:@"%@.txt", [formatter stringFromDate:now]];
    
    [formatter setDateFormat:@"YYYY-MM-dd HH:mm:ss"];
    NSString* logDate = [NSString stringWithFormat:@"%@", [formatter stringFromDate:now]];
    
    // 使い終わった NSDateFormatter を解放します。
    [formatter release];
    //ホームディレクトリ直下にあるDocumentsフォルダを取得する
    NSArray *paths = NSSearchPathForDirectoriesInDomains(
                                                         NSDocumentDirectory
                                                         , NSUserDomainMask
                                                         , YES
                                                         );
    
    // 日付のファイル名を作成する
    NSString *dataPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:fileName];
    
    // 既存チェック
    NSFileManager* fileManager = [NSFileManager defaultManager];
    if (![fileManager fileExistsAtPath:dataPath]) {
        // 新規の場合は空のファイルを作成
        [fileManager createFileAtPath:dataPath
                             contents:[NSData data]
                           attributes:nil];
    }
    
    NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:dataPath];
    [fh seekToEndOfFile];
    
    NSString *sendrecv = (isSend)?@"s":@"r";
    
    NSString* logText = [NSString stringWithFormat:@"%@[%@]:%@\n",
                         logDate,
                         sendrecv,
                         [data hexadecimalString]];
    NSData* logData = [logText dataUsingEncoding:NSUTF8StringEncoding];
    [fh writeData:logData];
    [fh closeFile];
}

// Add Start 2012-03-11 kitada
// 通信制御不具合改修(志様・01CAFE障害対応)
// 電文ログ削除
+ (void)DeleteLog {
    
    // 電文ログファイル削除基準日取得
    NSDateFormatter * dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
    dateFormatter.locale = [[[NSLocale alloc] initWithLocaleIdentifier:@"ja_JP"] autorelease];
    dateFormatter.calendar = [[[NSCalendar alloc] initWithCalendarIdentifier: NSJapaneseCalendar] autorelease];    
    dateFormatter.dateFormat = @"YYYYMMdd";
    NSTimeInterval interVal = (60 * 60 * 24 * LOG_DELETE_BASE_DATE) * -1;
    NSDate * dDelBaseDate = [[NSDate date] dateByAddingTimeInterval:interVal];
    int iDelBaseDate = [[dateFormatter stringFromDate:dDelBaseDate] intValue];
    NSLog(@"電文ログ削除基準日：%d", iDelBaseDate);
    
    // ドキュメントフォルダの場所を取得
    NSArray * paths = NSSearchPathForDirectoriesInDomains(
                                                         NSDocumentDirectory,
                                                         NSUserDomainMask,
                                                         YES);  
    NSString * docpath = [paths objectAtIndex:0];
    NSLog(@"ドキュメントフォルダパス：%@", docpath);
    
    // ファイル一覧の取得  
    NSFileManager * fileManager = [NSFileManager defaultManager];  
    NSArray * items = [fileManager contentsOfDirectoryAtPath:docpath error:nil];
    
//    NSLog(@"フォルダのファイル：%@", items);

    // ドキュメントフォルダ内の電文ログファイルを捜索  
    for(NSString * item in items) {

        // 拡張子がtxtのファイルのみを対象にする
        if([[[item pathExtension] lowercaseString] isEqualToString:@"txt"] == NO) {
            continue;
        }
        
        int iFileNameDate = [item intValue];
        if( iFileNameDate < iDelBaseDate ) {
            // 電文ログファイル名の日付が削除基準日より過去の日付であれば削除
            NSLog(@"削除ファイル名：%d.txt", iFileNameDate);
            NSString * delfilename = [NSString stringWithFormat:@"%@/%@", docpath, item];
            [fileManager removeItemAtPath:delfilename error:nil];
        }
        
    }
    
}
// Add End 2012-03-11 kitada

@end

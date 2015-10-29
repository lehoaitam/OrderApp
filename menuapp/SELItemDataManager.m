//
//  SELItemDataManager.m
//  menuapp
//
//  Created by dpcc on 2014/04/11.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import "SELItemDataManager.h"
#import "NSArray+csvsupport.h"
#import "SELSettingDataManager.h"

@implementation SELItemDataManager

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
        // dataをロード
        [self reload];
    }
    return self;
}

- (void)reload
{
    // データをCSVからロードする
    [self LoadItemData];
    [self LoadItemDataMultiLanguage];
    [self LoadCustomOrderData];
    [self LoadCustomOrderDataMultiLanguage];
    [self LoadToppingGroupItemData];
    [self LoadToppingGroupItemDataMultiLanguage];
    [self LoadCategoryData];
    [self LoadCategoryDataMultiLanguage];
    
    [self LoadPrinterGroupData];
//    [self setPrinterGroupData];
}

- (BOOL)LoadItemData
{
    _itemDict = [[NSMutableDictionary alloc]init];
    
    // CSVからデータを読み込む
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/index.csv"];
    NSURL* url = [NSURL fileURLWithPath:filePath];
    NSData* loadData = [NSData dataWithContentsOfURL:url];
    NSString* csvString = [[NSString alloc] initWithData:loadData encoding:NSUTF8StringEncoding];
    NSArray* csvDataList = [NSArray arrayWithCSV:csvString];
    
    for (NSDictionary* csvData in csvDataList) {
        
        if (![csvData objectForKey:@"menuCode"]) {
            continue;
        }
        
        SELItemData* itemData = [[SELItemData alloc]init];
        for (id key in [csvData keyEnumerator]) {
//            NSLog(@"Key:%@ Value:%@", key, [csvData valueForKey:key]);
            if ([key isEqualToString:@""]) {
                continue;
            }
            [itemData setValue:[csvData valueForKey:key] forKey:key];
        }
        [_itemDict setObject:itemData forKey:[csvData objectForKey:@"menuCode"]];
    }
    
    //イメージパス取得用のリストを作成しておく
//    NSMutableDictionary* imageList = [NSMutableDictionary dictionary];
//    for(id e in self.itemList)
//    {
//        NSMutableDictionary *values = (NSMutableDictionary*)e;
//        if(!(values[@"menuCode"] == nil || [values[@"menuCode"] isEqualToString:@""]))
//        {
//            [imageList setObject:values[@"image"] forKey:values[@"menuCode"]];
//        }
//    }
//    self._menuImageList = imageList;
    
    // カテゴリデータ展開
//    NSString* categoryUrlPath = [workPath stringByAppendingPathComponent:CATEGORY_CSV];
//    NSURL* categoryUrl = [NSURL fileURLWithPath:categoryUrlPath];
//    NSData * categoryLoadData = [NSData dataWithContentsOfURL:categoryUrl];
//    NSString * categoryCsvData = [[NSString alloc] initWithData:categoryLoadData encoding:NSUTF8StringEncoding];
//    
//    self._categoryList = [NSArray arrayWithCSV:categoryCsvData];
    
    return TRUE;
}

- (BOOL)LoadItemDataMultiLanguage
{
    // CSVからデータを読み込む
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/index_multilang.csv"];
    NSURL* url = [NSURL fileURLWithPath:filePath];
    NSData* loadData = [NSData dataWithContentsOfURL:url];
    NSString* csvString = [[NSString alloc] initWithData:loadData encoding:NSUTF8StringEncoding];
    NSArray* csvDataList = [NSArray arrayWithCSV:csvString];
    
    for (NSDictionary* csvData in csvDataList) {
        
        if (![csvData objectForKey:@"menuCode"] || [[csvData objectForKey:@"menuCode"] isEqualToString:@""]) {
            continue;
        }
        SELItemData* itemData = [_itemDict objectForKey:[csvData objectForKey:@"menuCode"]];
        if (itemData == nil){
            continue;
        }
        
        if (!itemData.MLItemNameList) {
            itemData.MLItemNameList = [[NSMutableDictionary alloc]init];
        }
        if (!itemData.MLDescList) {
            itemData.MLDescList = [[NSMutableDictionary alloc]init];
        }
        
        // 言語名
        NSString* language = [csvData objectForKey:@"language"];
        // 商品名
        NSString* itemName = [csvData objectForKey:@"itemName"];
        // 商品説明
        NSString* desc = [csvData objectForKey:@"desc"];
        
        [itemData.MLItemNameList setValue:itemName forKey:language];
        [itemData.MLDescList setValue:desc forKey:language];
    }
    return TRUE;
}

- (BOOL)LoadCustomOrderData
{
    _customOrderDict = [[NSMutableDictionary alloc]init];
    
    // CSVからデータを読み込む
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/subcomment.csv"];
    NSURL* url = [NSURL fileURLWithPath:filePath];
    NSData* loadData = [NSData dataWithContentsOfURL:url];
    NSString* csvString = [[NSString alloc] initWithData:loadData encoding:NSUTF8StringEncoding];
    NSArray* csvDataList = [NSArray arrayWithCSV:csvString];
    
    for (NSDictionary* csvData in csvDataList) {
        
        SELCustomOrderData* customOrderData = [[SELCustomOrderData alloc]init];
        
        if (![csvData objectForKey:@"no"]) {
            continue;
        }
        
        customOrderData.no = [csvData objectForKey:@"no"];
        customOrderData.message = [csvData objectForKey:@"guidance"];
        
        customOrderData.itemlist = [[NSMutableArray alloc]init];
        
        // CustomOrderにItemDataのひも付け
        for (int i=1; i < 17; i++) {
            NSString* key = [NSString stringWithFormat:@"menu%d", i];
            NSString* itemCode = [csvData objectForKey:key];
            
            SELItemData* itemData = [self getItemData:itemCode];
            if (itemData != NULL) {
                [customOrderData.itemlist addObject:itemData];
            }
        }
        
        [_customOrderDict setObject:customOrderData forKey:customOrderData.no];
    }
    
    return TRUE;
}

- (BOOL)LoadCustomOrderDataMultiLanguage
{
    // CSVからデータを読み込む
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/subcomment_multilang.csv"];
    NSURL* url = [NSURL fileURLWithPath:filePath];
    NSData* loadData = [NSData dataWithContentsOfURL:url];
    NSString* csvString = [[NSString alloc] initWithData:loadData encoding:NSUTF8StringEncoding];
    NSArray* csvDataList = [NSArray arrayWithCSV:csvString];
    
    for (NSDictionary* csvData in csvDataList) {
        
        if (![csvData objectForKey:@"no"] || [[csvData objectForKey:@"no"] isEqualToString:@""]) {
            continue;
        }
        SELCustomOrderData* customOrderData = [_customOrderDict objectForKey:[csvData objectForKey:@"no"]];
        if (customOrderData == nil){
            continue;
        }
        
        if (!customOrderData.MLMessageList) {
            customOrderData.MLMessageList = [[NSMutableDictionary alloc]init];
        }
        
        // 言語名
        NSString* language = [csvData objectForKey:@"language"];
        // 表示メッセージ
        NSString* message = [csvData objectForKey:@"guidance"];
        
        [customOrderData.MLMessageList setValue:message forKey:language];
    }
    return TRUE;
}

- (BOOL)LoadToppingGroupItemData
{
    _toppingGroupItemDict = [[NSMutableDictionary alloc]init];
    
    // CSVからデータを読み込む(toppinggroup)
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/toppinggroup.csv"];
    NSURL* url = [NSURL fileURLWithPath:filePath];
    NSData* loadData = [NSData dataWithContentsOfURL:url];
    NSString* csvString = [[NSString alloc] initWithData:loadData encoding:NSUTF8StringEncoding];
    NSArray* csvDataList = [NSArray arrayWithCSV:csvString];
    
    for (NSDictionary* csvData in csvDataList) {
        
        SELToppingGroupData* toppingGroupData = [[SELToppingGroupData alloc]init];
        
        if (![csvData objectForKey:@"itemToppingGroupId"]) {
            continue;
        }
        
        toppingGroupData.itemToppingGroupId = [csvData objectForKey:@"itemToppingGroupId"];
        toppingGroupData.itemToppingGroupName = [csvData objectForKey:@"itemToppingGroupName"];
        toppingGroupData.min = [csvData objectForKey:@"min"];
        toppingGroupData.max = [csvData objectForKey:@"max"];
        
        [_toppingGroupItemDict setObject:toppingGroupData forKey:toppingGroupData.itemToppingGroupId];
    }
    
    // CSVからデータを読み込む(toppinggroupitem)
    filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/toppinggroupitem.csv"];
    url = [NSURL fileURLWithPath:filePath];
    loadData = [NSData dataWithContentsOfURL:url];
    csvString = [[NSString alloc] initWithData:loadData encoding:NSUTF8StringEncoding];
    csvDataList = [NSArray arrayWithCSV:csvString];
    
    for (NSDictionary* csvData in csvDataList) {
        
        if (![csvData objectForKey:@"itemToppingId"]) {
            continue;
        }
        
        NSString* itemToppingGroupID = [csvData objectForKey:@"itemToppingGroupId"];
        NSString* itemID = [csvData objectForKey:@"itemId"];

        // itemToppingGroupを取得
        SELToppingGroupData* toppingGroupData = [_toppingGroupItemDict objectForKey:itemToppingGroupID];
        
        // itemを取得
        SELItemData* itemData = [self getItemData:itemID];
        if (itemData == NULL) {
            NSLog(@"トッピングデータひも付けエラー:%@", itemID);
            continue;
        }
        
        // 追加する
        [toppingGroupData.itemlist addObject:itemData];
    }
    
    return TRUE;
}

- (BOOL)LoadToppingGroupItemDataMultiLanguage
{
    // CSVからデータを読み込む
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/toppinggroup_multilang.csv"];
    NSURL* url = [NSURL fileURLWithPath:filePath];
    NSData* loadData = [NSData dataWithContentsOfURL:url];
    NSString* csvString = [[NSString alloc] initWithData:loadData encoding:NSUTF8StringEncoding];
    NSArray* csvDataList = [NSArray arrayWithCSV:csvString];
    
    for (NSDictionary* csvData in csvDataList) {
        
        if (![csvData objectForKey:@"itemToppingGroupId"] || [[csvData objectForKey:@"itemToppingGroupId"] isEqualToString:@""]) {
            continue;
        }
        SELToppingGroupData* toppingGroupData = [_toppingGroupItemDict objectForKey:[csvData objectForKey:@"itemToppingGroupId"]];
        if (toppingGroupData == nil){
            continue;
        }
        
        if (!toppingGroupData.MLGroupNameList) {
            toppingGroupData.MLGroupNameList = [[NSMutableDictionary alloc]init];
        }
        
        // 言語名
        NSString* language = [csvData objectForKey:@"language"];
        // トッピンググループ名
        NSString* groupName = [csvData objectForKey:@"itemToppingGroupName"];
        
        [toppingGroupData.MLGroupNameList setValue:groupName forKey:language];
    }
    return TRUE;
}

- (BOOL)LoadCategoryData
{
    _mainCategoryDict = [[NSMutableDictionary alloc]init];
    _subCategoryDict = [[NSMutableDictionary alloc]init];
    
    // CSVからデータを読み込む
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/category.csv"];
    NSURL* url = [NSURL fileURLWithPath:filePath];
    NSData* loadData = [NSData dataWithContentsOfURL:url];
    NSString* csvString = [[NSString alloc] initWithData:loadData encoding:NSUTF8StringEncoding];
    NSArray* csvDataList = [NSArray arrayWithCSV:csvString];
    
    for (NSDictionary* csvData in csvDataList) {
        
        SELCategoryData* categoryData = [[SELCategoryData alloc]init];
        
        if (![csvData objectForKey:@"kind"]) {
            continue;
        }
        
        NSString* kind = [csvData objectForKey:@"kind"];
        categoryData.code = [csvData objectForKey:@"code"];
        categoryData.name = [csvData objectForKey:@"name"];
        categoryData.image = [csvData objectForKey:@"image"];
        
        if ([kind isEqualToString:@"1"]) {
            [_mainCategoryDict setObject:categoryData forKey:categoryData.code];
        }
        else if([kind isEqualToString:@"2"]){
            [_subCategoryDict setObject:categoryData forKey:categoryData.code];
        }
    }
    
    return TRUE;
}

- (BOOL)LoadCategoryDataMultiLanguage
{
    // CSVからデータを読み込む
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* filePath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/category_multilang.csv"];
    NSURL* url = [NSURL fileURLWithPath:filePath];
    NSData* loadData = [NSData dataWithContentsOfURL:url];
    NSString* csvString = [[NSString alloc] initWithData:loadData encoding:NSUTF8StringEncoding];
    NSArray* csvDataList = [NSArray arrayWithCSV:csvString];
    
    for (NSDictionary* csvData in csvDataList) {
        
        if (![csvData objectForKey:@"code"] || [[csvData objectForKey:@"code"] isEqualToString:@""] ) {
            continue;
        }
        
        SELCategoryData* categoryData = nil;
        NSString* kind = [csvData objectForKey:@"kind"];
        
        if ([kind isEqualToString:@"1"]) {
            categoryData = [_mainCategoryDict objectForKey:[csvData objectForKey:@"code"]];
        }
        else if([kind isEqualToString:@"2"]){
            categoryData = [_subCategoryDict objectForKey:[csvData objectForKey:@"code"]];
        }
        if (categoryData == nil){
            continue;
        }
        
        if (!categoryData.MLNameList) {
            categoryData.MLNameList = [[NSMutableDictionary alloc]init];
        }
        if (!categoryData.MLImageList) {
            categoryData.MLImageList = [[NSMutableDictionary alloc]init];
        }
        
        // 言語名
        NSString* language = [csvData objectForKey:@"language"];
        // カテゴリ名
        NSString* name = [csvData objectForKey:@"name"];
        // カテゴリイメージ
        NSString* image = [csvData objectForKey:@"image"];
        
        [categoryData.MLNameList setValue:name forKey:language];
        [categoryData.MLImageList setValue:image forKey:language];
    }
    return TRUE;
}

- (BOOL)LoadPrinterGroupData
{
    _printerGroupList = [[NSMutableArray alloc]init];
    
    // printergroup.jsonを読み込む
    NSArray* paths = NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES);
    NSString* jsonPath = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"/URLCache/decode/printergroup.json"];
    
    NSData *data = [NSData dataWithContentsOfFile:jsonPath];
    if (!data) {
        return false;
    }
    
    NSError *error = nil;
    
    NSDictionary* jsonObject = [NSJSONSerialization JSONObjectWithData:data
                                                               options:kNilOptions
                                                                 error:&error];
    if (!jsonObject) {
        return false;
    }
    
    _printerGroupList = [jsonObject objectForKey:@"printergroups"];
//    NSString* menuName = [menuNameDict objectForKey:[NSString stringWithFormat:@"%ld", (long)menuNumber]];
    
    return true;
}

- (SELItemData *)getItemDataFromIndex:(NSInteger)index
{
    SELItemData* itemData = [_itemDict objectForKey:[[_itemDict allKeys] objectAtIndex:index]];
    return itemData;
}

- (SELItemData *)getItemData:(NSString *)itemCode
{
    SELItemData* itemData = [_itemDict objectForKey:itemCode];
    return itemData;
}

- (SELCustomOrderData *)getCustomOrderData:(NSString *)no
{
    SELCustomOrderData* customOrderData = [_customOrderDict objectForKey:no];
    return customOrderData;
}

- (SELToppingGroupData *)getToppingGroupData:(NSString *)itemToppingGroupId
{
    SELToppingGroupData* toppingGroupData = [_toppingGroupItemDict objectForKey:itemToppingGroupId];
    return toppingGroupData;
}

- (SELCategoryData *)getMainCategoryData:(NSString *)code
{
    SELCategoryData* categoryData = [_mainCategoryDict objectForKey:code];
    return categoryData;
}

- (SELCategoryData *)getSubCategoryData:(NSString *)code
{
    SELCategoryData* categoryData = [_subCategoryDict objectForKey:code];
    return categoryData;
}

- (NSArray *)getMainCategoryItems:(NSString *)code
{
    NSMutableArray* ret = [[NSMutableArray alloc]init];
    // itemループ
    for (NSString* itemKey in [_itemDict allKeys]) {
        SELItemData* itemData = [_itemDict objectForKey:itemKey];
        if ([itemData.category1_code isEqualToString:code]) {
            [ret addObject:itemData];
        }
    }
    return ret;
}

- (NSArray *)getSubCategoryItems:(NSString *)code
{
    NSMutableArray* ret = [[NSMutableArray alloc]init];
    // itemループ
    for (NSString* itemKey in [_itemDict allKeys]) {
        SELItemData* itemData = [_itemDict objectForKey:itemKey];
        if ([itemData.category2_code isEqualToString:code]) {
            [ret addObject:itemData];
        }
    }
    return ret;
}

- (NSString *)getPrinterGroupIPAddress:(NSString *)categoryCode
{
    // printerGroupが選択されているかどうか
    SELSettingDataManager* settingManager = [SELSettingDataManager instance];
    NSString* printerGroupKey = [settingManager GetPrinterGroupKey];
    if (!printerGroupKey) {
        return nil;
    }
    
    // printerGroups内に一致するPrinterGroupがあるか
    NSDictionary* printerGroup = nil;
    SELItemDataManager* dataManager = [SELItemDataManager instance];
    for (NSDictionary* tempPrinterGroup in dataManager.printerGroupList) {
        NSString* tempPrinterGroupKey = [tempPrinterGroup objectForKey:@"id"];
        if ([printerGroupKey isEqualToString:tempPrinterGroupKey]) {
            // 一致するPrinterGroupを発見
            printerGroup = tempPrinterGroup;
            break;
        }
    }
    if (!printerGroup) {
        return nil;
    }
    
    // printerGroup内に一致するCategoryがあるか
    NSDictionary* categoryData = [printerGroup objectForKey:@"category"];
    if (!categoryData || categoryData.count == 0) {
        return nil;
    }
    
    // printerGroup内にカテゴリのデータがあるかどうか
    NSDictionary* printerData = [categoryData objectForKey:categoryCode];
    if (!printerData) {
        return nil;
    }

    NSString* ipaddress = [printerData objectForKey:@"ipaddress"];
    return ipaddress;
}

- (void)setPrinterGroupData
{
    // itemループ
    for (NSString* itemKey in [_itemDict allKeys]) {
        SELItemData* itemData = [_itemDict objectForKey:itemKey];
        // プリンターグループが設定されている場合は、itemDataのPrinterIPを置き換える
        NSString* ip = [self getPrinterGroupIPAddress:itemData.category1_code];
        if (ip != nil && ![ip isEqualToString:@""]) {
            itemData.printerIP = ip;
        }
    }
}

- (NSString *)getKaikeiPrinterIPAddress
{
    // printerGroupが選択されているかどうか
    SELSettingDataManager* settingManager = [SELSettingDataManager instance];
    NSString* printerGroupKey = [settingManager GetPrinterGroupKey];
    if (!printerGroupKey) {
        return nil;
    }
    
    NSDictionary* printerGroup = nil;
    SELItemDataManager* dataManager = [SELItemDataManager instance];
    for (NSDictionary* tempPrinterGroup in dataManager.printerGroupList) {
        NSString* tempPrinterGroupKey = [tempPrinterGroup objectForKey:@"id"];
        if ([printerGroupKey isEqualToString:tempPrinterGroupKey]) {
            // 一致するPrinterGroupを発見
            printerGroup = tempPrinterGroup;
            break;
        }
    }
    if (!printerGroup) {
        return nil;
    }

    NSString* printerIPAddress = [printerGroup objectForKey:@"printerIPAddress"];

    return printerIPAddress;
}

@end

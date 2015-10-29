//
//  SELItemDataManager.h
//  menuapp
//
//  Created by dpcc on 2014/04/11.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SELItemData.h"
#import "SELCustomOrderData.h"
#import "SELToppingGroupData.h"
#import "SELCategoryData.h"

@interface SELItemDataManager : NSObject {
    NSMutableDictionary* _itemDict;
    NSMutableDictionary* _customOrderDict;
    NSMutableDictionary* _toppingGroupItemDict;

    NSMutableDictionary* _mainCategoryDict;
    NSMutableDictionary* _subCategoryDict;
    
    NSMutableArray* _printerGroupList;
}

+ (id)instance;

- (SELItemData*)getItemData:(NSString*)itemCode;
- (SELCustomOrderData*)getCustomOrderData:(NSString*)no;
- (SELToppingGroupData*)getToppingGroupData:(NSString*)itemToppingGroupId;

- (SELCategoryData*)getMainCategoryData:(NSString*)code;
- (SELCategoryData*)getSubCategoryData:(NSString*)code;
- (NSArray*)getMainCategoryItems:(NSString*)code;
- (NSArray*)getSubCategoryItems:(NSString*)code;

- (SELItemData*)getItemDataFromIndex:(NSInteger)index;

- (NSString*)getPrinterGroupIPAddress:(NSString*)categoryCode;

- (NSString*)getKaikeiPrinterIPAddress;

- (void)reload;

@property (nonatomic, retain)NSMutableDictionary* itemDict;
@property (nonatomic, retain)NSMutableDictionary* mainCategoryDict;
@property (nonatomic, retain)NSMutableDictionary* subCategoryDict;

@property (nonatomic, retain)NSMutableArray* printerGroupList;

@end

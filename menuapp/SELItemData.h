//
//  SELItemData.h
//  menuapp
//
//  Created by dpcc on 2014/04/11.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SELItemData : NSObject

- (UIImage*)getItemImage;

@property (nonatomic, retain)NSString* no;
@property (nonatomic, retain)NSString* menuCode;
@property (nonatomic, retain)NSString* image;
@property (nonatomic, retain)NSString* itemName;
@property (nonatomic, retain)NSString* price;
@property (nonatomic, retain)NSString* subprice;
@property (nonatomic, retain)NSString* category1_code;
@property (nonatomic, retain)NSString* category1_name;
@property (nonatomic, retain)NSString* category2_code;
@property (nonatomic, retain)NSString* category2_name;
@property (nonatomic, retain)NSString* itemToppingGroupId;
@property (nonatomic, retain)NSString* suggest1;
@property (nonatomic, retain)NSString* suggest2;
@property (nonatomic, retain)NSString* suggest3;
@property (nonatomic, retain)NSString* adLink;
@property (nonatomic, retain)NSString* desc;
@property (nonatomic, retain)NSString* other1;
@property (nonatomic, retain)NSString* other2;
@property (nonatomic, retain)NSString* isComment;
@property (nonatomic, retain)NSString* isSub;
@property (nonatomic, retain)NSString* isSet;
@property (nonatomic, retain)NSString* SCP1;
@property (nonatomic, retain)NSString* SCP2;
@property (nonatomic, retain)NSString* SCP3;
@property (nonatomic, retain)NSString* SCP4;
@property (nonatomic, retain)NSString* SCP5;
@property (nonatomic, retain)NSString* SCP6;
@property (nonatomic, retain)NSString* SCP7;
@property (nonatomic, retain)NSString* SCP8;
@property (nonatomic, retain)NSString* SCP9;
@property (nonatomic, retain)NSString* SCP10;
@property (nonatomic, retain)NSString* SCP11;
@property (nonatomic, retain)NSString* SCP12;
@property (nonatomic, retain)NSString* startTime;
@property (nonatomic, retain)NSString* endTime;
@property (nonatomic, retain)NSString* printerIP;
@property (nonatomic, retain)NSString* printerPort;

// 多言語対応
@property (nonatomic, retain)NSMutableDictionary* MLItemNameList;
@property (nonatomic, retain)NSMutableDictionary* MLDescList;

@property (nonatomic, retain)NSString* itemNameJA;

@property(readonly) NSString* customOrderDataNo;

@end

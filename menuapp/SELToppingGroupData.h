//
//  SELToppingGroupData.h
//  menuapp
//
//  Created by dpcc on 2014/05/16.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SELToppingGroupData : NSObject

@property (nonatomic, retain)NSString* itemToppingGroupId;
@property (nonatomic, retain)NSString* itemToppingGroupName;
@property (nonatomic, retain)NSString* min;
@property (nonatomic, retain)NSString* max;

@property (nonatomic, retain)NSMutableArray* itemlist;

// 多言語対応
@property (nonatomic, retain)NSMutableDictionary* MLGroupNameList;

@end

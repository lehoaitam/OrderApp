//
//  SELCustomOrderData.h
//  menuapp
//
//  Created by dpcc on 2014/04/14.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SELItemData.h"

@interface SELCustomOrderData : NSObject

@property (nonatomic, retain)NSString* no;
@property (nonatomic, retain)NSString* message;
@property (nonatomic, retain)NSMutableArray* itemlist;

// 多言語対応
@property (nonatomic, retain)NSMutableDictionary* MLMessageList;

@end

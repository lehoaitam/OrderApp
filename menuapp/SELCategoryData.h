//
//  SELCategoryData.h
//  selforder
//
//  Created by dpcc on 2014/06/05.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SELCategoryData : NSObject

@property (nonatomic, retain)NSString* code;
@property (nonatomic, retain)NSString* name;
@property (nonatomic, retain)NSString* image;

// 多言語対応
@property (nonatomic, retain)NSMutableDictionary* MLNameList;
@property (nonatomic, retain)NSMutableDictionary* MLImageList;

@end

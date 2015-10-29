//
//  MSTecConnection.h
//  selforder
//
//  Created by dpcc on 2015/01/23.
//  Copyright (c) 2015年 kdl. All rights reserved.
//

#import "SELConnectionBase.h"
#import "kolSocket.h"

@interface MSTecConnection : SELConnectionBase<KolSocketDelegate> {
    // 通信中のリスト
    NSMutableArray * _reqList;
}

@end

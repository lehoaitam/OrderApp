//
//  PrintData.h
//  MobileOrder
//
//  Created by Ryutaro Minato on 12/06/12.
//  Copyright (c) 2012年 genephics design,Inc. All rights reserved.
//

//#import "EntityBase.h"
#import "Printer.h"
#import "StarPrinterUtil.h"

@interface PrintData : NSObject
@property (nonatomic, retain) Printer* printer;
@property (nonatomic, retain) NSMutableData* data;
@property (nonatomic) StarPrinterPrintStatus status;
@property (nonatomic) BOOL abort;
@property (nonatomic, readonly) BOOL isDone;
- (id) initWithData:(NSMutableData*)data printer:(Printer*)printer;
@end

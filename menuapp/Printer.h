//
//  Printer.h
//  MobilePOS
//
//  Created by Ryutaro Minato on 11/07/21.
//  Copyright 2011 genephics design,Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "EntityBase.h"


@interface Printer : NSObject

@property (nonatomic, copy) NSString* printerId;
@property (nonatomic, copy) NSString* printerName;
@property (nonatomic, copy) NSString* ipAddress;
@property (nonatomic, copy) NSString* storeId;
@property (nonatomic, copy) NSNumber* sort;
@property (nonatomic, copy) NSString* header;
@property (nonatomic, copy) NSString* footer;
@property (nonatomic, copy) NSString* airPrintLogo;
@property (nonatomic, copy) NSString* airPrintCss;

@property (readonly) NSString* printerNameIpAddressLabel;

@end

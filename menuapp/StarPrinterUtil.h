//
//  StarPrinterUtil.h
//  MobileOrder
//
//  Created by Ryutaro Minato on 12/04/26.
//  Copyright (c) 2012 genephics design,Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
//#import "MobileOrderDefine.h"
#import "StarIO/Port.h"


typedef enum {
    StarPrinterPrintStatusUnknown,
    StarPrinterPrintStatusSuccess,
    StarPrinterPrintStatusDisabled,
    StarPrinterPrintStatusConnectError,
    StarPrinterPrintStatusCoverOpen,
    StarPrinterPrintStatusRunOutOfPaper,
    StarPrinterPrintStatusError,
} StarPrinterPrintStatus;


typedef enum {
    BarcodeTypeUPC_E = 0x00,
    BarcodeTypeUPC_A,
    BarcodeTypeEAN8,
    BarcodeTypeEAN13,
    BarcodeTypeCode39,
    BarcodeTypeITF,
    BarcodeTypeCode128,
    BarcodeTypeCode93,
    BarcodeTypeNW_7,
} BarcodeType;

typedef enum {
    BarcodeOptionLF = 0x01,
    BarcodeOptionCharsAndLF,
    BarcodeOptionNone,
    BarcodeOptionChars,
} BarcodeOption;

typedef enum {
    BarcodeMode2Dot = 0x01,
    BarcodeMode3Dot,
    BarcodeMode4Dot,
} BarcodeMode;

typedef enum {
    PrintAlignLeft = 0x00,
    PrintAlignCenter,
    PrintAlignRight,
} PrintAlign;


//#define PRINTER_PORT 4000
#define PRINTER_PORT 9100       // n.sasaki スマレジ対応

#define CHARS_PER_LINE 48.0f

#define CMD_LF (u_int8_t[]){0x0A}
#define CMD_RUNOVER(n) (u_int8_t[]){0x1B, 0x61, n}

#define CMD_CUTTER(n) (u_int8_t[]){0x1B, 0x64, n}
#define CMD_CUTTER_CURRENT_FULL CMD_CUTTER(0x00)
#define CMD_CUTTER_CURRENT_PARTIAL CMD_CUTTER(0x01)
#define CMD_CUTTER_RUNOVER_FULL CMD_CUTTER(0x02)
#define CMD_CUTTER_RUNOVER_PARTIAL CMD_CUTTER(0x03)

#define CMD_MOVE(n1, n2) (u_int8_t[]){0x1B, 0x1D, 0x41, n1, n2}
#define CMD_MOVE_LEFT CMD_MOVE(0x00, 0x00)
#define CMD_MOVE_CENTER CMD_MOVE(0xf0, 0x00)
#define CMD_MOVE_RIGHT CMD_MOVE(0xc8, 0x01)

#define CMD_ALIGN(n) (u_int8_t[]){0x1B, 0x1D, 0x61, n}
#define CMD_ALIGN_LEFT CMD_ALIGN(PrintAlignLeft)
#define CMD_ALIGN_CENTER CMD_ALIGN(PrintAlignCenter)
#define CMD_ALIGN_RIGHT CMD_ALIGN(PrintAlignRight)

#define CMD_UNDERLINE(n) (u_int8_t[]){0x1B, 0x2D, n}
#define CMD_UNDERLINE_START CMD_UNDERLINE(0x01)
#define CMD_UNDERLINE_END CMD_UNDERLINE(0x00)

#define CMD_EMPHASIZE(n) (u_int8_t[]){0x1B, n}
#define CMD_EMPHASIZE_START CMD_EMPHASIZE(0x45)
#define CMD_EMPHASIZE_END CMD_EMPHASIZE(0x46)

#define CMD_INVERSE(n) (u_int8_t[]){0x1B, n}
#define CMD_INVERSE_START CMD_INVERSE(0x34)
#define CMD_INVERSE_END CMD_INVERSE(0x35)

#define CMD_CHARACTER_SIZE(n) (u_int8_t[]){0x1B, 0x69, n, n}
#define CMD_CHARACTER_SIZE_1x CMD_CHARACTER_SIZE(0x00)
#define CMD_CHARACTER_SIZE_2x CMD_CHARACTER_SIZE(0x01)
#define CMD_CHARACTER_SIZE_3x CMD_CHARACTER_SIZE(0x02)
#define CMD_CHARACTER_SIZE_4x CMD_CHARACTER_SIZE(0x03)
#define CMD_CHARACTER_SIZE_5x CMD_CHARACTER_SIZE(0x04)
#define CMD_CHARACTER_SIZE_6x CMD_CHARACTER_SIZE(0x05)

#define CMD_OPEN_DRAWER (u_int8_t[]){0x07}

#define CMD_PLAY_SOUND(n, c) (u_int8_t[]){0x1B, 0x1D, 0x73, 0x4F, 0x00, 0x01, n, c, 0x00, 0x00, 0x00, 0x00, 0x00}
#define CMD_PLAY_SOUND_WELCOME CMD_PLAY_SOUND(0x01, 0x01)
#define CMD_PLAY_SOUND_THANKS CMD_PLAY_SOUND(0x02, 0x01)
#define CMD_PLAY_SOUND_ORDER CMD_PLAY_SOUND(0x03, 0x01)

#define CMD_PLAY_SOUND_TEST (u_int8_t[]){0x1B, 0x1D, 0x07, 0x01, 0x05, 0x05}

#define CMD_SPACE_FOR_KANJI(n1, n2) (u_int8_t[]){0x1B, 0x73, n1, n2}

#define CMD_BARCODE_START(type, option, mode, h) (u_int8_t[]){0x1B, 0x62, type, option, mode, h}
#define CMD_BARCODE_END (u_int8_t[]){0x1E}

#define CMD_LINE(s) (u_int8_t[]){0x1b, 0x4B, s, 0x00}

@interface StarPrinterUtil : NSObject

@property (nonatomic) BOOL showErrorMessage;
@property (nonatomic) BOOL enabledPrint;
@property (nonatomic, copy) NSString* ipAddress;

+ (id) starPrinterUtilWithIpAddress:(NSString*)ipAddress;

- (StarPrinterPrintStatus) print:(NSMutableData*)data withCut:(BOOL)cut;

- (NSData*) dataWithLF:(NSString*)string printAlign:(PrintAlign)align;
- (NSData*) dataWithLF:(NSString*)string;
- (NSData*) dataWithLFAlignRight:(NSString*)string;
- (NSData*) dataWithLFAlignCenter:(NSString*)string;
- (NSData*) dataWithCaptionAndContent:(NSString*)caption content:(NSString*)content captionLength:(NSInteger)length;
- (NSData*) dataWithCaptionAndContent:(NSString*)caption content:(NSString*)content;
- (NSData*) dataWithCaptionAndContent2x:(NSString*)caption content:(NSString*)content;

- (NSData*) dataBarcode:(NSString*)barcode barcodeType:(BarcodeType)type barcodeOption:(BarcodeOption)option barcodeMode:(BarcodeMode)mode height:(int)height;
- (NSData*) dataBarcodeCode128:(NSString*)barcode barcodeOption:(BarcodeOption)option barcodeMode:(BarcodeMode)mode height:(int)height;
- (NSData*) dataBarcodeCode128:(NSString*)barcode;

- (NSData*) dataOpenDrawer;
- (NSData*) dataLine:(NSInteger)thick;

+ (NSString*) trimString:(NSString*)string lengthOfLimit:(int)length;
+ (NSString*) stringByPaddingLeftSpace:(NSString*)string newLength:(NSUInteger)newLength;
+ (NSString*) concatWithSpace:(NSString*)value1 :(NSString*)value2 :(NSInteger)length;
+ (NSData*) createImageCommand:(UIImage*)image maxWidth:(int)maxWidth;
+ (NSData*) createImageTextCommand:(NSString*)text fontSize:(CGFloat)size;

@end

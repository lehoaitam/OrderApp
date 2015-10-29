//
//  OrderEpsonPrinter.h
//  selforder
//
//  Created by dpcc on 2014/09/18.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "OrderStarPrinter.h"
#import "StarPrinterUtil.h"

#import "OrderHeader.h"
#import "OrderDetail.h"

#undef CMD_RUNOVER
#define CMD_RUNOVER(n) (u_int8_t[]){0x1B, 0x4A, 0x01}

// カット
#undef CMD_CUTTER
#define CMD_CUTTER(n) (u_int8_t[]){0x1D, 0x56, 0x41, 0x00}

// 文字の大きさ
#undef CMD_CHARACTER_SIZE
#undef CMD_CHARACTER_SIZE_1x
#undef CMD_CHARACTER_SIZE_2x
#undef CMD_CHARACTER_SIZE_3x
#undef CMD_CHARACTER_SIZE_4x
#undef CMD_CHARACTER_SIZE_5x
#undef CMD_CHARACTER_SIZE_6x
#define CMD_CHARACTER_SIZE(n) (u_int8_t[]){0x1D, 0x21, n}
#define CMD_CHARACTER_SIZE_1x CMD_CHARACTER_SIZE(0x00)
#define CMD_CHARACTER_SIZE_2x CMD_CHARACTER_SIZE(0x11)
#define CMD_CHARACTER_SIZE_3x CMD_CHARACTER_SIZE(0x22)
#define CMD_CHARACTER_SIZE_4x CMD_CHARACTER_SIZE(0x33)
#define CMD_CHARACTER_SIZE_5x CMD_CHARACTER_SIZE(0x44)
#define CMD_CHARACTER_SIZE_6x CMD_CHARACTER_SIZE(0x55)

// 白黒反転
#undef CMD_INVERSE
#undef CMD_INVERSE_START
#undef CMD_INVERSE_END
#define CMD_INVERSE(n) (u_int8_t[]){0x1D, 0x42, n}
#define CMD_INVERSE_START CMD_INVERSE(0x01)
#define CMD_INVERSE_END CMD_INVERSE(0x00)

// 文字の位置
#undef CMD_ALIGN
#undef CMD_ALIGN_LEFT
#undef CMD_ALIGN_CENTER
#undef CMD_ALIGN_RIGHT
#define CMD_ALIGN(n) (u_int8_t[]){0x1B, 0x61, n}
#define CMD_ALIGN_LEFT CMD_ALIGN(0x00)
#define CMD_ALIGN_CENTER CMD_ALIGN(0x01)
#define CMD_ALIGN_RIGHT CMD_ALIGN(0x02)

// LINE
#undef CMD_LINE
#define CMD_LINE (u_int8_t[]){0x1B, 0x2A, 0x00}

// Image

// 文字の強調
#undef CMD_EMPHASIZE_START
#undef CMD_EMPHASIZE_END
#define CMD_EMPHASIZE_START (u_int8_t[]){0x1B, 0x21, 0x08}
#define CMD_EMPHASIZE_END (u_int8_t[]){0x1B, 0x21, 0x00}

// 音声
#undef CMD_PLAY_SOUND
#undef CMD_PLAY_SOUND_ORDER
//#define CMD_PLAY_SOUND (u_int8_t[]){0x1B, 0x28, 0x41}
#define CMD_PLAY_SOUND (u_int8_t[]){0x10, 0x14, 0x03, 0x03, 0x00, 0x01, 0x01, 0x00}
#define CMD_PLAY_SOUND_ORDER CMD_PLAY_SOUND

@interface OrderEpsonPrinter : OrderStarPrinter

- (void) printOrder:(OrderHeader*)orderHeader details:(NSArray*)orderDetailList;
- (BOOL) printCallStuff:(OrderHeader*)orderHeader;

@end

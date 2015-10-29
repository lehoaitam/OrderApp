//
//  SELBadgeView.h
//  menuapp
//
//  Created by dpcc on 2014/04/17.
//  Copyright (c) 2014年 kdl. All rights reserved.
//

#import <UIKit/UIKit.h>

// Enums
typedef enum {
    LKBadgeViewHorizontalAlignmentLeft = 0,
    LKBadgeViewHorizontalAlignmentCenter,
    LKBadgeViewHorizontalAlignmentRight
    
} LKBadgeViewHorizontalAlignment;

typedef enum {
    LKBadgeViewWidthModeStandard = 0,     // 30x20
    LKBadgeViewWidthModeSmall            // 22x20
} LKBadgeViewWidthMode;

typedef enum {
    LKBadgeViewHeightModeStandard = 0,    // 20
    LKBadgeViewHeightModeLarge             // 30
} LKBadgeViewHeightMode;


// Constants
#define LK_BADGE_VIEW_STANDARD_HEIGHT       20.0
#define LK_BADGE_VIEW_LARGE_HEIGHT          30.0
#define LK_BADGE_VIEw_STANDARD_WIDTH        30.0
#define LK_BADGE_VIEw_MINIMUM_WIDTH         22.0
#define LK_BADGE_VIEW_FONT_SIZE             16.0

@interface SELBadgeView : UIView

@property (nonatomic, copy) NSString* text;
@property (nonatomic, retain) UIColor* textColor;
@property (nonatomic, retain) UIFont* font;
@property (nonatomic, retain) UIColor* badgeColor;
@property (nonatomic, retain) UIColor* outlineColor;
@property (nonatomic, assign) CGFloat outlineWidth;
@property (nonatomic, assign) BOOL outline;
@property (nonatomic, assign) LKBadgeViewHorizontalAlignment horizontalAlignment;
@property (nonatomic, assign) LKBadgeViewWidthMode widthMode;
@property (nonatomic, assign) LKBadgeViewHeightMode heightMode;
@property (nonatomic, assign) BOOL shadow;
@property (nonatomic, assign) CGSize shadowOffset;
@property (nonatomic, assign) CGFloat shadowBlur;
@property (nonatomic, retain) UIColor* shadowColor;
@property (nonatomic, assign) BOOL shadowOfOutline;
@property (nonatomic, assign) BOOL shadowOfText;
@property (nonatomic, assign) CGSize textOffset;

+ (CGFloat)badgeHeight; // @depricated
- (CGFloat)badgeHeight;

@end

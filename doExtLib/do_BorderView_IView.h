//
//  do_BorderView_UI.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol do_BorderView_IView <NSObject>

@required
//属性方法
- (void)change_bottomView:(NSString *)newValue;
- (void)change_centerFillParent:(NSString *)newValue;
- (void)change_centerView:(NSString *)newValue;
- (void)change_leftView:(NSString *)newValue;
- (void)change_rightView:(NSString *)newValue;
- (void)change_topView:(NSString *)newValue;
- (void)change_items:(NSString *)newValue;
//同步或异步方法
- (void)getView:(NSArray *)parms;

@end
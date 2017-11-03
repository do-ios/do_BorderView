//
//  do_BorderView_Model.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import "do_BorderView_UIModel.h"
#import "doProperty.h"
#import "do_BorderView_UIView.h"

@implementation do_BorderView_UIModel

#pragma mark - 注册属性（--属性定义--）
/*
[self RegistProperty:[[doProperty alloc]init:@"属性名" :属性类型 :@"默认值" : BOOL:是否支持代码修改属性]];
 */
-(void)OnInit
{
    [super OnInit];    
    //属性声明
	[self RegistProperty:[[doProperty alloc]init:@"bottomView" :String :@"" :NO]];
	[self RegistProperty:[[doProperty alloc]init:@"centerFillParent" :Bool :@"false" :NO]];
	[self RegistProperty:[[doProperty alloc]init:@"centerView" :String :@"" :NO]];
	[self RegistProperty:[[doProperty alloc]init:@"leftView" :String :@"" :NO]];
	[self RegistProperty:[[doProperty alloc]init:@"rightView" :String :@"" :NO]];
	[self RegistProperty:[[doProperty alloc]init:@"topView" :String :@"" :NO]];
	[self RegistProperty:[[doProperty alloc]init:@"items" :String :@"" :NO]];
}

- (void)DidLoadView
{
    [super DidLoadView];
    [((do_BorderView_UIView *)self.CurrentUIModuleView) loadModuleJS];
}

@end
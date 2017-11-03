//
//  do_BorderView_View.h
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "do_BorderView_IView.h"
#import "do_BorderView_UIModel.h"
#import "doIUIModuleView.h"

@interface do_BorderView_UIView : UIView<do_BorderView_IView, doIUIModuleView>
//可根据具体实现替换UIView
{
	@private
		__weak do_BorderView_UIModel *_model;
}
- (void)loadModuleJS;
@end

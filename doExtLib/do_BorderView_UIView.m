//
//  do_BorderView_View.m
//  DoExt_UI
//
//  Created by @userName on @time.
//  Copyright (c) 2015年 DoExt. All rights reserved.
//
#import <Foundation/Foundation.h>

#import "do_BorderView_UIView.h"
#import "doDefines.h"
#import "doInvokeResult.h"
#import "doUIModuleHelper.h"
#import "doScriptEngineHelper.h"
#import "doIScriptEngine.h"
#import "doISourceFS.h"
#import "doUIContainer.h"
#import "doIPage.h"
#import "doServiceContainer.h"
#import "doILogEngine.h"
#import "doJsonHelper.h"

static NSString *didBeginEdit = @"DODidBeginEditNotification";
static NSString *keyboardShow = @"DOKeyboardShowNotification";
static NSString *keyboardHide = @"DOKeyboardHideNotification";
//不可修改

@interface do_BorderView_UIView()

@property (nonatomic,assign) CGRect originFrame;

@end

@implementation do_BorderView_UIView
{
    BOOL _iscenterFillParent;
    
    NSString *_bottomTemplate;
    NSString *_centerTemplate;
    NSString *_leftTemplate;
    NSString *_rightTemplate;
    NSString *_topTemplate;
    
    UIView *_bottomView;
    UIView *_centerView;
    UIView *_leftView;
    UIView *_rightView;
    UIView *_topView;
    
    
    UIView *_bottomSuperView;
    UIView *_centerSuperView;
    UIView *_leftSuperView;
    UIView *_rightSuperView;
    UIView *_topSuperView;
    
    doUIModule *_bottomModule;
    doUIModule *_centerModule;
    doUIModule *_leftModule;
    doUIModule *_rightModule;
    doUIModule *_topModule;
    
    doUIContainer *_bottomContainer;
    doUIContainer *_centerContainer;
    doUIContainer *_leftContainer;
    doUIContainer *_rightContainer;
    doUIContainer *_topContainer;
    
    BOOL _isFirstLoad;
    
    CGRect _keyBoardFrame;
    
    UIView *_firstResponse;
    
    BOOL _isEdit;
    
    NSMutableDictionary *_jsonDict;
    
    NSMutableDictionary *_templates;
    
    NSMutableDictionary *_observers;
}
@synthesize originFrame = _originFrame;
#pragma mark - doIUIModuleView协议方法（必须）
//引用Model对象
- (void) LoadView: (doUIModule *) _doUIModule
{
    _model = (typeof(_model)) _doUIModule;
    
    _iscenterFillParent = NO;
    
    _isFirstLoad = YES;
    
    self.clipsToBounds = YES;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardShow:) name:keyboardShow object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardHide:) name:keyboardHide object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didBeginEdit:) name:didBeginEdit object:nil];

    _keyBoardFrame = CGRectZero;
    _originFrame = CGRectZero;
    
    _isEdit = NO;
    
    _jsonDict = [NSMutableDictionary dictionary];
    _templates = [NSMutableDictionary dictionary];
    _observers = [NSMutableDictionary dictionary];
    [_observers setObject:@"0" forKey:@"top"];
    [_observers setObject:@"0" forKey:@"bottom"];
    [_observers setObject:@"0" forKey:@"left"];
    [_observers setObject:@"0" forKey:@"right"];
    [_observers setObject:@"0" forKey:@"center"];
}

//销毁所有的全局对象
- (void) OnDispose
{
    //自定义的全局属性,view-model(UIModel)类销毁时会递归调用<子view-model(UIModel)>的该方法，将上层的引用切断。所以如果self类有非原生扩展，需主动调用view-model(UIModel)的该方法。(App || Page)-->强引用-->view-model(UIModel)-->强引用-->view
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self clearTop];
    [self clearLeft];
    [self clearRight];
    [self clearCenter];
    [self clearBottom];
    [_jsonDict removeAllObjects];
    _jsonDict = nil;
    [_templates removeAllObjects];
    _templates = nil;
    [_observers removeAllObjects];
    _observers = nil;
}
//实现布局
- (void) OnRedraw
{
    //实现布局相关的修改,如果添加了非原生的view需要主动调用该view的OnRedraw，递归完成布局。view(OnRedraw)<显示布局>-->调用-->view-model(UIModel)<OnRedraw>
    if (_isEdit) {
        return;
    }

    if (!_isFirstLoad) {
        [self generateSubViews];
    }

    //重新调整视图的x,y,w,h
    if ([self isAutoHeight] || [self isAutoWidth]) {
        [doUIModuleHelper OnRedraw:_model];
        [self redrawSubviews:NO :YES];
        [doUIModuleHelper OnResize:_model];
    }else{
        [doUIModuleHelper OnRedraw:_model];
        [self redrawSubviews:NO :YES];
    }
    
    if (_bottomView) {
        if (_isEdit) {
            [self responseKeyBoard:YES];
        }
    }

    _isFirstLoad = NO;
}
- (CGRect)originFrame
{
    _originFrame.origin.x = _model.RealX;
    _originFrame.origin.y = _model.RealY;
    
    return _originFrame;
}
- (BOOL)isAutoHeight
{
    BOOL isAutoHeight = [[_model GetPropertyValue:@"height"] isEqualToString:@"-1"];
    return isAutoHeight;
}
- (BOOL)isAutoWidth
{
    BOOL isAutoWidth = [[_model GetPropertyValue:@"width"] isEqualToString:@"-1"];
    return isAutoWidth;
}
- (void)generateSubViews
{
    if (_topModule) {
        [_topModule.CurrentUIModuleView OnRedraw];
    }
    if (_leftModule) {
        [_leftModule.CurrentUIModuleView OnRedraw];
    }
    if (_rightModule) {
        [_rightModule.CurrentUIModuleView OnRedraw];
    }
    if (_bottomModule) {
        [_bottomModule.CurrentUIModuleView OnRedraw];
    }
    if (_centerModule) {
        [_centerModule.CurrentUIModuleView OnRedraw];
    }
}
#pragma mark - TYPEID_IView协议方法（必须）
#pragma mark - Changed_属性
/*
 如果在Model及父类中注册过 "属性"，可用这种方法获取
 NSString *属性名 = [(doUIModule *)_model GetPropertyValue:@"属性名"];
 
 获取属性最初的默认值
 NSString *属性名 = [(doUIModule *)_model GetProperty:@"属性名"].DefaultValue;
 */
#pragma mark - bottomView
- (void)change_bottomView:(NSString *)newValue
{
    //自己的代码实现
    if (!newValue || newValue.length == 0) {
        _isEdit = NO;
    }
    
    [self generateBottomView:newValue];
    
    if (!_isFirstLoad) {
        [self redrawSubviews:NO :YES];
    }
    
    [_templates setObject:newValue forKey:@"bottomView"];
}
- (void)clearBottom
{
    if ([[_observers objectForKey:@"bottom"] isEqualToString:@"1"]) {
        [_observers setObject:@"0" forKey:@"bottom"];
        [_bottomView removeObserver:self forKeyPath:@"frame"];
    }
    [_bottomContainer Dispose];
    _bottomContainer = nil;
    [_bottomView removeFromSuperview];
    _bottomView = nil;
    [_bottomModule Dispose];
    _bottomModule = nil;
    
    [_bottomSuperView removeFromSuperview];
    _bottomSuperView = nil;
}
- (void)generateBottomView:(NSString *)newValue
{
    _bottomTemplate = newValue;
    NSArray *a = [self getLayoutView:_bottomTemplate :@"bottomView"];
    
    [self clearBottom];
    if (a&&a.count==3) {
        _bottomView = [a objectAtIndex:0];
        _bottomContainer = [a objectAtIndex:1];
        _bottomModule = [a objectAtIndex:2];

        _bottomSuperView = [[UIView alloc] initWithFrame:_bottomView.frame];
        _bottomSuperView.backgroundColor = [UIColor clearColor];
        [_observers setObject:@"1" forKey:@"bottom"];
        [_bottomView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    }
}


#pragma mark - centerView
- (void)change_centerFillParent:(NSString *)newValue
{
    //自己的代码实现
    _iscenterFillParent = [newValue boolValue];
    if (_iscenterFillParent) {
        [_observers setObject:@"1" forKey:@"center"];
        [_centerSuperView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    }else{
        if ([[_observers objectForKey:@"center"] isEqualToString:@"1"]) {
            [_observers setObject:@"0" forKey:@"center"];
            [_centerSuperView removeObserver:self forKeyPath:@"frame"];
        }
    }

    if (!_isFirstLoad) {
        [self redrawSubviews:NO :YES];
    }
}
- (void)change_centerView:(NSString *)newValue
{
    //自己的代码实现
    [self generateCenterView:newValue];
    
    if (!_isFirstLoad) {
        [self redrawSubviews:NO :YES];
    }
    
    [_templates setObject:newValue forKey:@"centerView"];
}
- (void)clearCenter
{
    if ([[_observers objectForKey:@"center"] isEqualToString:@"1"]) {
        [_observers setObject:@"0" forKey:@"center"];
        [_centerSuperView removeObserver:self forKeyPath:@"frame"];
    }
    [_centerContainer Dispose];
    _centerContainer = nil;
    [_centerView removeFromSuperview];
    _centerView = nil;
    [_centerModule Dispose];
    _centerModule = nil;
    
    [_centerSuperView removeFromSuperview];
    _centerSuperView = nil;
}
- (void)generateCenterView:(NSString *)newValue
{
    _centerTemplate = newValue;
    NSArray *a = [self getLayoutView:_centerTemplate :@"centerView"];
    
    [self clearCenter];
    
    if (a&&a.count==3) {
        _centerView = [a objectAtIndex:0];
        _centerContainer = [a objectAtIndex:1];
        _centerModule = [a objectAtIndex:2];

        _centerSuperView = [[UIView alloc] initWithFrame:_centerView.frame];
        _centerSuperView.backgroundColor = [UIColor clearColor];
        if (_iscenterFillParent) {
            [_observers setObject:@"1" forKey:@"center"];
            [_centerSuperView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
        }
    }
}

#pragma mark - leftView
- (void)change_leftView:(NSString *)newValue
{
    //自己的代码实现
    [self generateLeftView:newValue];
    
    if (!_isFirstLoad) {
        [self redrawSubviews:NO :YES];
    }
    
    [_templates setObject:newValue forKey:@"leftView"];
}
- (void)clearLeft
{
    if ([[_observers objectForKey:@"left"] isEqualToString:@"1"]) {
        [_observers setObject:@"0" forKey:@"left"];
        [_leftView removeObserver:self forKeyPath:@"frame"];
    }
    [_leftContainer Dispose];
    _leftContainer = nil;
    [_leftView removeFromSuperview];
    _leftView = nil;
    [_leftModule Dispose];
    _leftModule = nil;
    
    [_leftSuperView removeFromSuperview];
    _leftSuperView = nil;
}
- (void)generateLeftView:(NSString *)newValue
{
    _leftTemplate = newValue;
    NSArray *a = [self getLayoutView:_leftTemplate :@"leftView"];
    
    [self clearLeft];
    
    if (a&&a.count==3) {
        _leftView = [a objectAtIndex:0];
        _leftContainer = [a objectAtIndex:1];
        _leftModule = [a objectAtIndex:2];
        
        _leftSuperView = [[UIView alloc] initWithFrame:_leftView.frame];
        _leftSuperView.backgroundColor = [UIColor clearColor];
        [_observers setObject:@"1" forKey:@"left"];
        [_leftView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    }
}

#pragma mark - rightView
- (void)change_rightView:(NSString *)newValue
{
    //自己的代码实现
    [self generateRightView:newValue];
    
    if (!_isFirstLoad) {
        [self redrawSubviews:NO :YES];
    }
    
    [_templates setObject:newValue forKey:@"rightView"];
}
- (void)clearRight
{
    if ([[_observers objectForKey:@"right"] isEqualToString:@"1"]) {
        [_observers setObject:@"0" forKey:@"right"];
        [_rightView removeObserver:self forKeyPath:@"frame"];
    }
    [_rightContainer Dispose];
    _rightContainer = nil;
    [_rightView removeFromSuperview];
    _rightView = nil;
    [_rightModule Dispose];
    _rightModule = nil;
    
    [_rightSuperView removeFromSuperview];
    _rightSuperView = nil;
}
- (void)generateRightView:(NSString *)newValue
{
    _rightTemplate = newValue;
    NSArray *a = [self getLayoutView:_rightTemplate :@"rightView"];
    
    [self clearRight];
    
    if (a&&a.count==3) {
        _rightView = [a objectAtIndex:0];
        _rightContainer = [a objectAtIndex:1];
        _rightModule = [a objectAtIndex:2];
        
        _rightSuperView = [[UIView alloc] initWithFrame:_rightView.frame];
        _rightSuperView.backgroundColor = [UIColor clearColor];
        [_observers setObject:@"1" forKey:@"right"];
        [_rightView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    }
}

#pragma mark - topView
- (void)change_topView:(NSString *)newValue
{
    //自己的代码实现
    [self generateTopView:newValue];
    
    if (!_isFirstLoad) {
        [self redrawSubviews:NO :YES];
    }
    
    [_templates setObject:newValue forKey:@"topView"];
}
- (void)clearTop
{
    if ([[_observers objectForKey:@"top"] isEqualToString:@"1"]) {
        [_observers setObject:@"0" forKey:@"top"];
        [_topView removeObserver:self forKeyPath:@"frame"];
    }
    [_topContainer Dispose];
    _topContainer = nil;
    [_topView removeFromSuperview];
    _topView = nil;
    [_topModule Dispose];
    _topModule = nil;
    
    [_topSuperView removeFromSuperview];
    _topSuperView = nil;
}
- (void)generateTopView:(NSString *)newValue
{
    _topTemplate = newValue;
    NSArray *a = [self getLayoutView:_topTemplate :@"topView"];
    
    [self clearTop];
    
    if (a&&a.count==3) {
        _topView = [a objectAtIndex:0];
        _topContainer = [a objectAtIndex:1];
        _topModule = [a objectAtIndex:2];
        
        _topSuperView = [[UIView alloc] initWithFrame:_topView.frame];
        _topSuperView.backgroundColor = [UIColor clearColor];
        [_observers setObject:@"1" forKey:@"top"];
        [_topView addObserver:self forKeyPath:@"frame" options:NSKeyValueObservingOptionNew context:nil];
    }
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"frame"]) {
        CGRect rect = [[change objectForKey:@"new"] CGRectValue];
        if (object == _bottomView) {
            CGRect r = _bottomSuperView.frame;
            r.size.width = CGRectGetWidth(rect);
            r.size.height = CGRectGetHeight(rect);
            _bottomSuperView.frame = r;
        }else if (object == _topView) {
            CGRect r = _topSuperView.frame;
            r.size.width = CGRectGetWidth(rect);
            r.size.height = CGRectGetHeight(rect);
            _topSuperView.frame = r;
        }else if (object == _leftView) {
            CGRect r = _leftSuperView.frame;
            r.size.width = CGRectGetWidth(rect);
            r.size.height = CGRectGetHeight(rect);
            _leftSuperView.frame = r;
        }else if (object == _rightView) {
            CGRect r = _rightSuperView.frame;
            r.size.width = CGRectGetWidth(rect);
            r.size.height = CGRectGetHeight(rect);
            _rightSuperView.frame = r;
        }else if (object == _centerSuperView) {
            CGRect r = _centerView.frame;
            r.size.width = CGRectGetWidth(rect);
            r.size.height = CGRectGetHeight(rect);
            _centerView.frame = r;
        }
    }
}

#pragma mark - items
- (void)change_items:(NSString *)newValue
{
    NSMutableDictionary *dict =[doJsonHelper LoadDataFromText : newValue];
    if (dict.allKeys.count==0) {
        [[doServiceContainer Instance].LogEngine WriteError:nil :@"items不是一个node"];
    }else
        _jsonDict = dict;
    NSArray *views = @[@"leftView",@"rightView",@"centerView",@"topView",@"bottomView"];
    for (id obj in views) {
        id json = [dict objectForKey:obj];
        if (json && ![json isKindOfClass:[NSNull class]]) {
            [_jsonDict setObject:json forKey:obj];
        }else
            continue ;
        
        SEL selector = NSSelectorFromString([NSString stringWithFormat:@"change_%@:",obj]);
        if ([self respondsToSelector:selector]) {
            SUPPRESS_PERFORM_SELECTOR_LEAK_WARNING(
                                                   [self performSelector:selector withObject:[_templates objectForKey:obj]];
                                                   );
            [self redrawSubviews:_isEdit :YES];
        }
    }
}

#pragma mark - private
- (NSArray *)getLayoutView:(NSString *)template  :(NSString *)v
{
    if (!template || template.length == 0) {
        return nil;
    }
    doSourceFile *source = [[[_model.CurrentPage CurrentApp] SourceFS] GetSourceByFileName:template];
    if(!source)
    {
        [[doServiceContainer Instance].LogEngine WriteError:nil :[NSString stringWithFormat:@"无效的模板 %@",template]];
        return nil;
    }
    id<doIPage> pageModel = _model.CurrentPage;
    doUIModule* module;
    UIView *view ;
    doUIContainer *container = [[doUIContainer alloc] init:pageModel];
    [container LoadFromFile:source:nil:nil];
    module = container.RootView;
    if (pageModel) {
        [container LoadDefalutScriptFile:template];
    }

    view = (UIView*)(((doUIModule*)module).CurrentUIModuleView);
    id<doIUIModuleView> modelView =((doUIModule*) module).CurrentUIModuleView;
    id obj = [_jsonDict objectForKey:v];
    if (obj) {
        [module SetModelData:obj];
    }
    [modelView OnRedraw];
    
    return @[view,container,module];
}

- (void)loadModuleJS
{
    if (_topContainer) {
        NSString *top = [_model GetPropertyValue:@"topView"];
        [_topContainer LoadDefalutScriptFile:top];
    }
    if (_bottomContainer) {
        NSString *bottom = [_model GetPropertyValue:@"bottomView"];
        [_bottomContainer LoadDefalutScriptFile:bottom];
    }
    if (_leftContainer) {
        NSString *left = [_model GetPropertyValue:@"leftView"];
        [_leftContainer LoadDefalutScriptFile:left];
    }
    if (_rightContainer) {
        NSString *right = [_model GetPropertyValue:@"rightView"];
        [_rightContainer LoadDefalutScriptFile:right];
    }
    if (_centerContainer) {
        NSString *center = [_model GetPropertyValue:@"centerView"];
        [_centerContainer LoadDefalutScriptFile:center];
    }
    
    if (_topModule) {
        [_topModule DidLoadView];
    }
    if (_bottomModule) {
        [_bottomModule DidLoadView];
    }
    if (_leftModule) {
        [_leftModule DidLoadView];
    }
    if (_rightModule) {
        [_rightModule DidLoadView];
    }
    if (_centerModule) {
        [_centerModule DidLoadView];
    }
}

- (void)redrawSubviews:(BOOL)isKeyBoard :(BOOL)isReset
{
    if (isReset) {
        [self resetSubViews];
    }

    CGFloat originX = 0;
    CGFloat originY = 0;
    
    CGFloat totalHeight = 0;
    CGFloat totalWidth = 0;
    
    CGFloat lw = 0,rw = 0,th = 0,bh = 0,lh = 0,rh = 0,tw = 0,bw = 0,ch = 0,cw = 0;
    if (_topView) {
        th = CGRectGetHeight(_topView.frame);
        tw = CGRectGetWidth(_topView.frame);
    }
    if (_bottomView) {
        bh = CGRectGetHeight(_bottomView.frame);
        bw = CGRectGetWidth(_bottomView.frame);
    }
    if (_leftView) {
        lw = CGRectGetWidth(_leftView.frame);
        lh = CGRectGetHeight(_leftView.frame);
    }
    if (_rightView) {
        rw = CGRectGetWidth(_rightView.frame);
        rh = CGRectGetHeight(_rightView.frame);
    }
    if (_centerView) {
        cw = CGRectGetWidth(_centerView.frame);
        ch = CGRectGetHeight(_centerView.frame);
    }
    
    if (![self isAutoHeight]) {
        totalHeight = CGRectGetHeight(self.frame);
    }else{
        if (isKeyBoard) {
            totalHeight = CGRectGetHeight(self.frame);
        }else{
            CGFloat hh = MAX(lh, rh);
            if (hh<=0) {
                if (!_iscenterFillParent) {
                    hh = ch;
                }
            }
            totalHeight = th+hh+bh;
        }
    }
    
    if (![self isAutoWidth]) {
        totalWidth = CGRectGetWidth(self.frame);
    }else{
        CGFloat ww = MAX(bw, tw);
        CGFloat ww1 = lw+rw;
        CGFloat maxww = MAX(ww, ww1);
        if (maxww<=0) {
            if (!_iscenterFillParent) {
                maxww = cw;
            }
        }
        totalWidth = maxww;
    }
    
    if (_topSuperView) {
        CGRect r = _topSuperView.frame;
        r.origin.x = originX;
        r.origin.y = originY;
        _topSuperView.frame = r;
        originY = CGRectGetHeight(_topSuperView.frame);
    }
    if (_leftSuperView) {
        CGRect r = _leftSuperView.frame;
        r.origin.x = originX;
        r.origin.y = originY;
        _leftSuperView.frame = r;
    }
    if (_rightSuperView) {
        CGRect r = _rightSuperView.frame;
        originX = totalWidth-CGRectGetWidth(r);
        r.origin.x = originX;
        r.origin.y = originY;
        _rightSuperView.frame = r;
    }
    if (_bottomSuperView) {
        CGRect r = _bottomSuperView.frame;
        originX = 0;
        originY = totalHeight-CGRectGetHeight(_bottomSuperView.frame);
        r.origin.x = originX;
        r.origin.y = originY;
        _bottomSuperView.frame = r;
    }
    if (_centerSuperView) {
        if (!_iscenterFillParent) {
            CGPoint p = CGPointMake(totalWidth/2, totalHeight/2);
            _centerSuperView.center = p;
        }else{
            CGRect r = _centerSuperView.frame;

            if (th+bh>=totalHeight) {
                r.size.height = 0;
            }else
                r.size.height = totalHeight-(th+bh);

            if (lw+rw>=totalWidth) {
                r.size.width = 0;
            }else
                r.size.width = totalWidth-(lw+rw);

            r.origin.x = lw;
            r.origin.y = th;
            
            _centerSuperView.frame = r;
        }
    }
    if ([self isAutoWidth] || [self isAutoHeight]) {
        CGRect r = self.frame;
        r.size.height = totalHeight;
        r.size.width = totalWidth;
        self.frame = r;
    }
    
    if (!isKeyBoard) {
        if (CGRectGetHeight(self.frame)>0&&CGRectGetWidth(self.frame)>0) {
            _originFrame = self.frame;
        }
    }
    
    //防止redraw之后出现空白的cell
    if ([_centerView conformsToProtocol:@protocol(UITableViewDelegate)]) {
        [((UITableView *)_centerView) reloadData];
    }
    
    [self complateSubViewsLayout:isReset];
    
    [self setNeedsLayout];
}

- (void)resetSubViews
{
    if (_topSuperView) {
        [_topSuperView removeFromSuperview];
    }
    if (_centerSuperView) {
        [_centerSuperView removeFromSuperview];
    }
    if (_bottomSuperView) {
        [_bottomSuperView removeFromSuperview];
    }
    if (_leftSuperView) {
        [_leftSuperView removeFromSuperview];
    }
    if (_rightSuperView) {
        [_rightSuperView removeFromSuperview];
    }
}

- (void)complateSubViewsLayout:(BOOL)isReset
{
    if (_topSuperView) {
        if (isReset) {
            CGRect r = _topView.frame;
            r.origin.x = 0;
            r.origin.y = 0;
            _topView.frame = r;
            [_topSuperView addSubview:_topView];
            [self addSubview:_topSuperView];
        }
    }
    if (_leftSuperView) {
        if (isReset) {
            CGRect r = _leftView.frame;
            r.origin.x = 0;
            r.origin.y = 0;
            _leftView.frame = r;
            [_leftSuperView addSubview:_leftView];
            [self addSubview:_leftSuperView];
        }
    }
    if (_rightSuperView) {
        if (isReset) {
            CGRect r = _rightView.frame;
            r.origin.x = 0;
            r.origin.y = 0;
            _rightView.frame = r;
            [_rightSuperView addSubview:_rightView];
            [self addSubview:_rightSuperView];
        }
    }
    if (_bottomSuperView) {
        if (isReset) {
            CGRect r = _bottomView.frame;
            r.origin.x = 0;
            r.origin.y = 0;
            _bottomView.frame = r;
            [_bottomSuperView addSubview:_bottomView];
            [self addSubview:_bottomSuperView];
        }
    }
    if (_centerSuperView) {
        if (isReset) {
            CGRect r = _centerView.frame;
            r.origin.x = 0;
            r.origin.y = 0;
            _centerView.frame = r;
            [_centerSuperView addSubview:_centerView];
            [self addSubview:_centerSuperView];
        }
    }
}

- (void)getView:(NSArray *)parms
{
    NSDictionary *_dictParas = [parms objectAtIndex:0];
//    id<doIScriptEngine> _scritEngine = [parms objectAtIndex:1];
    doInvokeResult *_invokeResult = [parms objectAtIndex:2];
    
    NSString *direction = [doJsonHelper GetOneText: _dictParas :@"direction" :@"left"];

    doUIModule *moudle;
    
    if ([direction isEqualToString:@"left"]) {
        moudle = _leftModule;
    }else if ([direction isEqualToString:@"right"]) {
        moudle = _rightModule;
    }else if ([direction isEqualToString:@"top"]) {
        moudle = _topModule;
    }else if ([direction isEqualToString:@"bottom"]) {
        moudle = _bottomModule;
    }else if ([direction isEqualToString:@"center"]) {
        moudle = _centerModule;
    }
    [_invokeResult SetResultText:moudle.UniqueKey];
}


#pragma mark - keyboard
//开始编辑的时候收到抬起的通知，键盘消失的时候收到放下通知（键盘放下通知不能放到文本框结束编辑的时候，否则在bottomview有两个文本框互相切换的时候，borderview会上下反复收放）
- (void)keyboardShow:(NSNotification *)noti
{
    if (!_bottomView) {
        return;
    }
    _firstResponse = [noti object];
    if ([self findFirstResponder:_bottomView]) {
        NSDictionary *info = [noti userInfo];
        NSValue *value = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
        _keyBoardFrame = [value CGRectValue];
        
        [self responseKeyBoard:YES];
    }
}
- (void)didBeginEdit:(NSNotification *)noti
{
    if (!_bottomView) {
        return;
    }
    if (CGRectGetHeight(_keyBoardFrame)==0) {
        return;
    }
    _isEdit = YES;
    _firstResponse = [noti object];
    if ([self findFirstResponder:_bottomView]) {
        [self responseKeyBoard:YES];
    }
}
- (void)keyboardHide:(NSNotification *)noti
{
    if (!_bottomView) {
        return;
    }
    _isEdit = NO;
    _firstResponse = [noti object];
    if ([self findFirstResponder:_bottomView]) {
        [self responseKeyBoard:NO];
    }
}
- (BOOL)findFirstResponder:(UIView *)view {
    NSArray *subviews = [view subviews];
    
    BOOL isFirst = NO;

    if ([subviews count] == 0)
        isFirst = NO;
    
    for (UIView *subview in subviews) {
        if ([subview isEqual:_firstResponse]) {
            isFirst = YES;
            break;
        }else{
            isFirst = [self findFirstResponder:subview];
            if (isFirst) {
                break;
            }
        }
        
    }
    return isFirst;
}

- (void)responseKeyBoard:(BOOL)isShow
{
    CGRect r = self.originFrame;
    CGFloat diffHeight = CGRectGetMaxY([self rectInRootView])-CGRectGetMinY(_keyBoardFrame);
    if (isShow) {
        if (diffHeight>0&&CGRectGetHeight(_keyBoardFrame)>0) {
            r.size.height = CGRectGetHeight(r)-diffHeight;
        }
        self.frame = r;
        [self redrawSubviews:YES :NO];
    }else{
        self.frame = r;
        [self redrawSubviews:YES :NO];
    }
}

- (CGRect)rectInRootView
{
    UIView *rootView = ((UIViewController *)_model.CurrentPage.PageView).view;
    CGRect rect = [self.superview convertRect:self.originFrame toView:rootView];
    return rect;
}
#pragma mark - doIUIModuleView协议方法（必须）<大部分情况不需修改>
- (BOOL) OnPropertiesChanging: (NSMutableDictionary *) _changedValues
{
    //属性改变时,返回NO，将不会执行Changed方法
    return YES;
}
- (void) OnPropertiesChanged: (NSMutableDictionary*) _changedValues
{
    //_model的属性进行修改，同时调用self的对应的属性方法，修改视图
    [doUIModuleHelper HandleViewProperChanged: self :_model : _changedValues ];
}
- (BOOL) InvokeSyncMethod: (NSString *) _methodName : (NSDictionary *)_dicParas :(id<doIScriptEngine>)_scriptEngine : (doInvokeResult *) _invokeResult
{
    //同步消息
    return [doScriptEngineHelper InvokeSyncSelector:self : _methodName :_dicParas :_scriptEngine :_invokeResult];
}
- (BOOL) InvokeAsyncMethod: (NSString *) _methodName : (NSDictionary *) _dicParas :(id<doIScriptEngine>) _scriptEngine : (NSString *) _callbackFuncName
{
    //异步消息
    return [doScriptEngineHelper InvokeASyncSelector:self : _methodName :_dicParas :_scriptEngine: _callbackFuncName];
}
- (doUIModule *) GetModel
{
    //获取model对象
    return _model;
}

@end

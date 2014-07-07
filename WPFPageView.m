//
//  WPFPageView.m
//  DoitiPhone
//
//  Created by PanFengfeng on 14-7-3.
//  Copyright (c) 2014年 SnowOrange. All rights reserved.
//

#import "WPFPageView.h"

#pragma mark - DITabPageContainerView
@interface DIPageContainerView : UIView

@property (nonatomic, strong)UIView *contentView;
@property (nonatomic, assign)CGFloat pagePadding;
@property (nonatomic, assign)NSUInteger index;

@end

@implementation DIPageContainerView

+ (DIPageContainerView *)containerView:(UIView *)contentView pagePadding:(CGFloat)pagePadding {
    DIPageContainerView *container = [[DIPageContainerView alloc] initWithFrame:CGRectZero];
    container.contentView = contentView;
    container.pagePadding = pagePadding;
    
    return container;
}

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    
    if (self) {
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (void)setContentView:(UIView *)contentView {
    if (contentView == _contentView) {
        return;
    }
    
    [_contentView removeFromSuperview];
    _contentView = contentView;
    [self addSubview:_contentView];
    [self setNeedsLayout];
}

- (void)setPagePadding:(CGFloat)pagePadding {
    if (_pagePadding == pagePadding) {
        return;
    }
    
    _pagePadding = pagePadding;
    [self setNeedsLayout];
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _contentView.frame = CGRectMake(self.pagePadding/2., 0,
                                    CGRectGetWidth(self.bounds) - self.pagePadding,
                                    CGRectGetHeight(self.bounds));
}


@end

#pragma mark  - DIPageView
NSString *PageViewInsertAnimationKey = @"wpf.pageview.insert.animate";
NSString *PageViewDeleteAnimationKey = @"wpf.pageview.delete.animate";

const CGFloat WPFPageViewAnimationDuration = .3;

@interface WPFPageView () {
    CABasicAnimation *_insertAnimation;
    CABasicAnimation *_deleteAnimation;
    
    NSUInteger        _pageCount;
}

@property (nonatomic, strong)NSMutableArray *pages;

@end

@implementation WPFPageView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.pagingEnabled = YES;
        self.pagePadding = 10;
        
        self.pages = [NSMutableArray array];
        
        _insertAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
        _insertAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(.001, .001, 1.)];
        _insertAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
        _insertAnimation.removedOnCompletion = YES;
        _insertAnimation.duration = WPFPageViewAnimationDuration;
        
        _deleteAnimation = [CABasicAnimation animationWithKeyPath:@"transform"];
        _deleteAnimation.fromValue = [NSValue valueWithCATransform3D:CATransform3DIdentity];
        _deleteAnimation.toValue = [NSValue valueWithCATransform3D:CATransform3DMakeScale(.001, .001, 1.)];
        _deleteAnimation.removedOnCompletion = NO;
        _deleteAnimation.fillMode = kCAFillModeForwards;
        _deleteAnimation.duration = WPFPageViewAnimationDuration;
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)setPagePadding:(CGFloat)pagePadding {
    if (_pagePadding == pagePadding) {
        return;
    }
    
    _pagePadding = pagePadding;
    [self setNeedsLayout];
}

- (NSUInteger)currentPageIndex {
    return self.contentOffset.x / CGRectGetWidth(self.frame);
}

- (void)setDatasource:(id<WPFPageViewDatasource>)datasource {
    if (_datasource == datasource) {
        return;
    }
    
    [self willChangeValueForKey:@"datasource"];
    _datasource = datasource;
    [self didChangeValueForKey:@"datasource"];
    
    [self reloadData];
}

- (void)reloadData {
    [self.pages enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [obj removeFromSuperview];
    }];
    [self.pages removeAllObjects];
    
    NSUInteger count = [self p_pageCount];
    _pageCount = count;
    self.contentSize = CGSizeMake(CGRectGetWidth(self.frame) * count,
                                  CGRectGetHeight(self.frame));
    [self p_loadPagesForPoint:self.contentOffset];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.contentSize = CGSizeMake(CGRectGetWidth(self.frame) * _pageCount,
                                  CGRectGetHeight(self.frame));
    [self p_updatePageFrame];
}

- (void)setContentOffset:(CGPoint)contentOffset {
    [super setContentOffset:contentOffset];
    
    [self p_loadPagesForPoint:contentOffset];
}

- (void)deletePageAtIndex:(NSUInteger)index animated:(BOOL)animated {

}

- (void)insertPage:(UIView *)view AtIndex:(NSUInteger)index animated:(BOOL)animated {
    if (animated) {
        [self p_insertView:view atIndex:index withAnimation:_insertAnimation];
    }else {
        [self p_insertView:view atIndex:index withAnimation:nil];
    }
}




#pragma mark Private API
- (void)p_addPage:(DIPageContainerView *)page {
    NSCAssert([page isKindOfClass:[DIPageContainerView class]], @"ADD PAGE IS NOT DIPAGECONTAINERview");
    
    [self addSubview:page];
    [self.pages addObject:page];
    
}

- (void)p_removePage:(DIPageContainerView *)page {
    NSCAssert([page isKindOfClass:[DIPageContainerView class]], @"ADD PAGE IS NOT DIPAGECONTAINERview");
    
    [page removeFromSuperview];
    [self.pages removeObject:page];
}

- (NSUInteger)p_pageCount {
    if ([self.datasource respondsToSelector:@selector(numberOfPagesInView:)]) {
        return [self.datasource numberOfPagesInView:self];
    }
    
    return 0;
}

- (DIPageContainerView *)p_removePageAtIndex:(NSUInteger)index {
    __block DIPageContainerView *existPage = nil;
    [self.pages enumerateObjectsUsingBlock:^(DIPageContainerView *obj, NSUInteger idx, BOOL *stop) {
        if (obj.index == index) {
            existPage = obj;
            *stop = YES;
        }
    }];
    
    if (existPage) {
        [self p_removePage:existPage];
    }
    
    return existPage;
}

- (DIPageContainerView *)p_pageForIndexFromDatasource:(NSUInteger)index {
    if (index >= _pageCount) {
        return nil;
    }

    
    if ([self.datasource respondsToSelector:@selector(pageView:viewAtIndex:)]) {
        UIView *contentView = [self.datasource pageView:self viewAtIndex:index];
        DIPageContainerView *containView = [DIPageContainerView containerView:contentView pagePadding:self.pagePadding];
        containView.index = index;
        containView.frame = CGRectMake(index * CGRectGetWidth(self.frame), 0,
                                       CGRectGetWidth(self.frame),
                                       CGRectGetHeight(self.frame));
        return containView;
    }
    
    return nil;
}

- (DIPageContainerView *)p_pageAtIndex:(NSUInteger)index {
    if (index >= _pageCount) {
        return nil;
    }
    
    __block DIPageContainerView *existPage = nil;
    [self.pages enumerateObjectsUsingBlock:^(DIPageContainerView *obj, NSUInteger idx, BOOL *stop) {
        if (obj.index == index) {
            existPage = obj;
            *stop = YES;
        }
    }];
    
    if (existPage) {
        return existPage;
    }
    
    DIPageContainerView *newPage = [self p_pageForIndexFromDatasource:index];
    [self p_addPage:newPage];
    
    return newPage;
}

- (void)p_updatePageFrame {
    [self.pages enumerateObjectsUsingBlock:^(DIPageContainerView *obj, NSUInteger idx, BOOL *stop) {
        obj.frame = CGRectMake(obj.index * CGRectGetWidth(self.frame),
                               0, CGRectGetWidth(self.frame),
                               CGRectGetHeight(self.frame));
    }];
}

- (void)p_loadPagesForPoint:(CGPoint)point {
    NSUInteger pageCount = _pageCount;
    if (pageCount == 0) {
        return;
    }
    
    //增加page
    NSUInteger index = point.x / CGRectGetWidth(self.frame);
    [self p_pageAtIndex:index];
    
    CGFloat cacheCount = 4;
    for (int j = 1; index - j < pageCount && j <= cacheCount/2.; ++j) {
        [self p_pageAtIndex:index - j];
    }
    
    for (int j = 1; index + j < pageCount && j <= cacheCount/2.; ++j) {
        [self p_pageAtIndex:index + j];
    }
    
    
    //除去缓存外page
    NSMutableArray *pagesToRemove = [NSMutableArray array];
    [self.pages enumerateObjectsUsingBlock:^(DIPageContainerView *obj, NSUInteger idx, BOOL *stop) {
        if (obj.index > index + cacheCount/2. ||
            obj.index < index - cacheCount/2.) {
            [pagesToRemove addObject:obj];
        }
    }];
    
    [pagesToRemove enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        [self p_removePage:obj];
    }];
}

- (void)p_insertView:(UIView *)view atIndex:(NSUInteger)index withAnimation:(CAAnimation *)animation {
    NSCAssert(_pageCount + 1 == [self p_pageCount], @"datasource page count must add 1 when insert pageView");
    
    DIPageContainerView *containView = [DIPageContainerView containerView:view pagePadding:self.pagePadding];
    containView.index = index;
    containView.frame = CGRectMake(index * CGRectGetWidth(self.frame), 0,
                                   CGRectGetWidth(self.frame),
                                   CGRectGetHeight(self.frame));
    
    NSMutableArray *changeFramePages = [NSMutableArray array];
    [self.pages enumerateObjectsUsingBlock:^(DIPageContainerView *obj, NSUInteger idx, BOOL *stop) {
        if (obj.index >= index) {
            obj.index++;
            [changeFramePages addObject:obj];
        }
    }];
    
    _pageCount += 1;
    
    if (animation) {
        [UIView animateWithDuration:WPFPageViewAnimationDuration delay:0.
                            options:UIViewAnimationOptionBeginFromCurrentState
                         animations:^{
                             [changeFramePages enumerateObjectsUsingBlock:^(DIPageContainerView *obj, NSUInteger idx, BOOL *stop) {
                                 obj.frame = CGRectMake(obj.index * CGRectGetWidth(self.frame),
                                                        0, CGRectGetWidth(self.frame),
                                                        CGRectGetHeight(self.frame));
                                 
                             }];
                             
                         } completion:^(BOOL finish) {
                             [self p_addPage:containView];
                             [containView.layer addAnimation:animation forKey:PageViewInsertAnimationKey];
                             
                             self.contentSize = CGSizeMake(CGRectGetWidth(self.frame) * _pageCount,
                                                           CGRectGetHeight(self.frame));
                         }];

        
    }else {
        [self p_addPage:containView];
        self.contentSize = CGSizeMake(CGRectGetWidth(self.frame) * _pageCount,
                                      CGRectGetHeight(self.frame));
        [self p_updatePageFrame];

    }

}

@end

//
//  WPFPageView.h
//  DoitiPhone
//
//  Created by PanFengfeng on 14-7-3.
//  Copyright (c) 2014年 SnowOrange. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol WPFPageViewDatasource;

@interface WPFPageView : UIScrollView

@property (nonatomic, weak)id<WPFPageViewDatasource> datasource;
@property (nonatomic, assign)CGFloat pagePadding;

- (NSUInteger)currentPageIndex;

- (void)reloadData;

- (void)deletePageAtIndex:(NSUInteger)index animated:(BOOL)animated;
- (void)insertPage:(UIView *)view AtIndex:(NSUInteger)index animated:(BOOL)animated;


@end

@protocol WPFPageViewDatasource <NSObject>

- (NSUInteger)numberOfPagesInView:(WPFPageView *)pageView;
- (UIView *)pageView:(WPFPageView *)pageView viewAtIndex:(NSUInteger)index;

@end
//
//  TabBarView.m
//  ActecBluetoothNorDic
//
//  Created by AcTEC on 2017/4/13.
//  Copyright © 2017年 BAO. All rights reserved.
//

#import "TabBarView.h"
#import "TabBarButton.h"

@interface TabBarView ()
{
    NSMutableArray *_buttons;
    NSArray *_normalImages;
    NSArray *_highlightImages;
}
@end

@implementation TabBarView

@synthesize selectedIndex = _selectedIndex;
-(id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.userInteractionEnabled = YES;
        self.backgroundColor = [UIColor blackColor];
        _buttons = [NSMutableArray arrayWithCapacity:3];
        NSArray *titles = @[@"Lamps",@"Gallery",@"Scenes",@"More"];
        _normalImages = @[@"lampActiveImage",@"galleryActiveImage",@"sceneActiveImage",@"moreActiveImage"];
        _highlightImages = @[@"lampImage",@"galleryImage",@"sceneImage",@"moreImage"];
        for (int i=0; i<titles.count; i++) {
            UIImage *normalImage = [UIImage imageNamed:_normalImages[i]];
            TabBarButton *barButton = [[TabBarButton alloc] initWithImage:normalImage title:titles[i]];
            [barButton addTarget:self action:@selector(clickBarButton:) forControlEvents:UIControlEventTouchUpInside];
            barButton.tag = i;
            [_buttons addObject:barButton];
            [self addSubview:barButton];
            
            [self setSelectedIndex:0];
            
        }
        self.selectedIndex = 0;
    }
    return self;
}
-(void)layoutSubviews
{
    [super layoutSubviews];
    CGFloat w = CGRectGetWidth(self.frame);
    CGFloat h = CGRectGetHeight(self.frame);
    CGFloat perW = w/_buttons.count;
    for (int i=0; i<_buttons.count; i++) {
        UIButton *button = _buttons[i];
        button.frame = CGRectMake(perW*i, 0, perW, h);
    }
}
-(void)setSelectedIndex:(NSInteger)selectedIndex
{
    if (selectedIndex < _buttons.count) {
        _selectedIndex = selectedIndex;
        for (int i=0 ; i<_buttons.count; i++) {
            TabBarButton *button = _buttons[i];
            if (i == selectedIndex) {
                [button setTitleColor:[UIColor orangeColor] forState:UIControlStateNormal];
                [button setImage:[UIImage imageNamed:[_highlightImages objectAtIndex:i]] forState:UIControlStateNormal];
            }else
            {
                [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
                [button setImage:[UIImage imageNamed:[_normalImages objectAtIndex:i]] forState:UIControlStateNormal];
            }
        }
    }
}

-(void)clickBarButton:(TabBarButton *)button
{
    
    self.selectedIndex = button.tag;
    if (self.delegate) {
        [self.delegate didSelectedAtIndex:self.selectedIndex];
    }
}


-(void)dealloc
{
    [_buttons removeAllObjects];
    _buttons = nil;
}

@end

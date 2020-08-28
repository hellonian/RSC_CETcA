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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(languageChange) name:ZZAppLanguageDidChangeNotification object:nil];
        self.userInteractionEnabled = YES;
        UIView *lineView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, WIDTH, 1)];
        lineView.backgroundColor = [UIColor colorWithRed:179/255.0 green:179/255.0 blue:179/255.0 alpha:1];
        [self addSubview:lineView];
        _buttons = [NSMutableArray arrayWithCapacity:3];
        NSArray *titles = @[AcTECLocalizedStringFromTable(@"Main", @"Localizable"),AcTECLocalizedStringFromTable(@"Gallery", @"Localizable"),AcTECLocalizedStringFromTable(@"Setting", @"Localizable")];
        _normalImages = @[@"main_normal",@"gallery_normal",@"setting_normal"];
        _highlightImages = @[@"main_highlighted",@"gallery_highlighted",@"setting_highlighted"];
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
                [button setTitleColor:DARKORAGE forState:UIControlStateNormal];
                [button setImage:[UIImage imageNamed:[_highlightImages objectAtIndex:i]] forState:UIControlStateNormal];
            }else
            {
                [button setTitleColor:[UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1] forState:UIControlStateNormal];
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

- (void)languageChange {

    NSArray *titles = @[AcTECLocalizedStringFromTable(@"Main", @"Localizable"),AcTECLocalizedStringFromTable(@"Gallery", @"Localizable"),AcTECLocalizedStringFromTable(@"Setting", @"Localizable")];
    
    [_buttons enumerateObjectsUsingBlock:^(TabBarButton *barButton, NSUInteger idx, BOOL * _Nonnull stop) {
        [barButton setTitle:titles[idx] forState:UIControlStateNormal];
    }];
}

@end

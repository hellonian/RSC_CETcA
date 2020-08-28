//
//  TabBarView.h
//  ActecBluetoothNorDic
//
//  Created by AcTEC on 2017/4/13.
//  Copyright © 2017年 BAO. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol TabBarDelegate <NSObject>

-(void)didSelectedAtIndex:(NSInteger)index;

@end

@interface TabBarView : UIView

@property (nonatomic,assign)NSInteger selectedIndex;

@property (nonatomic,assign) id<TabBarDelegate> delegate;

@end

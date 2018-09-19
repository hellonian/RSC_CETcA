//
//  CustomizeProgressHud.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/9/19.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface CustomizeProgressHud : UIView

@property (nonatomic,strong) NSString *text;

- (void)updateProgress:(CGFloat)percentage;

@end

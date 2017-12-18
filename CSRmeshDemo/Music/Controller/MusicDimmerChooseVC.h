//
//  MusicDimmerChooseVC.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/12/8.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface MusicDimmerChooseVC : UITableViewController

@property (nonatomic,copy) void (^hande)(NSMutableArray *);

@end

//
//  EveTypeViewController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2017/9/13.
//  Copyright © 2017年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "CSRmeshDevice.h"
#import "DataModelManager.h"

@interface EveTypeViewController : UIViewController

@property (nonatomic,copy) NSString *deviceShortName;
@property (nonatomic,copy) void (^setEveType)(NSString *eveType,CGFloat level);

@end

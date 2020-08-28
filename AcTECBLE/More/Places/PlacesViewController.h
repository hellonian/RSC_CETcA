//
//  PlacesViewController.h
//  AcTECBLE
//
//  Created by AcTEC on 2017/12/22.
//  Copyright © 2017年 AcTEC(Fuzhou) Electronics Co., Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface PlacesViewController : UIViewController

@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (nonatomic, retain) NSURL *importedURL;

@end

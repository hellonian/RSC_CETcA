//
//  ThermoregulatorViewController.h
//  AcTECBLE
//
//  Created by AcTEC on 2021/4/29.
//  Copyright © 2021 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ThermoregulatorViewController : UIViewController

@property (nonatomic,strong) NSNumber *deviceId;
typedef void (^RenameBlock)(void);
@property (nonatomic, copy) RenameBlock renameBlock;
@property (nonatomic, assign) NSInteger source;
typedef void (^ReloadDataHandle)(void);
@property (nonatomic, copy) ReloadDataHandle reloadDataHandle;
 
@end

NS_ASSUME_NONNULL_END

//
//  MCPickerAlertController.h
//  CSRmeshDemo
//
//  Created by AcTEC on 2020/8/17.
//  Copyright © 2020 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef void (^PickerViewDidSelectedBlock) (NSInteger row);

@interface MCPickerAlertController : UIAlertController

@property (nonatomic, copy) PickerViewDidSelectedBlock pickerViewBlock;
@property (nonatomic, strong) UIPickerView *pickerView;
@property (nonatomic, assign) NSInteger selectedRow;

+ (MCPickerAlertController *)MCAlertControllerWithTitle:(NSString *)title dataArray:(NSArray *)array;

@end

NS_ASSUME_NONNULL_END

//
//  MCPickerAlertController.m
//  AcTECBLE
//
//  Created by AcTEC on 2020/8/17.
//  Copyright © 2020 AcTEC ELECTRONICS Ltd. All rights reserved.
//

#import "MCPickerAlertController.h"

@interface MCPickerAlertController ()<UIPickerViewDelegate, UIPickerViewDataSource>

@property (nonatomic, strong) NSArray *pickerDataArray;

@end

@implementation MCPickerAlertController

+ (MCPickerAlertController *)MCAlertControllerWithTitle:(NSString *)title dataArray:(NSArray *)array {
    MCPickerAlertController *alerVC;
    alerVC = [MCPickerAlertController alertControllerWithTitle:title message:@"\n\n\n\n\n\n\n" preferredStyle:UIAlertControllerStyleAlert];
    NSMutableAttributedString *mutableTitle = [[NSMutableAttributedString alloc] initWithString:title];
    [mutableTitle addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:100/255.0 green:100/255.0 blue:100/255.0 alpha:1] range:NSMakeRange(0, [mutableTitle length])];
    [alerVC setValue:mutableTitle forKey:@"attributedTitle"];
    [alerVC.view setTintColor:DARKORAGE];
    alerVC.pickerDataArray = array;
    
    alerVC.pickerView = [[UIPickerView alloc] init];
    alerVC.pickerView.frame = CGRectMake(0, 45, 270, 140);
    alerVC.pickerView.delegate = alerVC;
    alerVC.pickerView.dataSource = alerVC;
    alerVC.pickerView.backgroundColor = [UIColor clearColor];
    [alerVC.view addSubview:alerVC.pickerView];
    
    return alerVC;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
    return self.pickerDataArray.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
    return self.pickerDataArray[row];
}

- (UIView *)pickerView:(UIPickerView *)pickerView viewForRow:(NSInteger)row forComponent:(NSInteger)component reusingView:(UIView *)view {
    
    for (UIView *line in pickerView.subviews) {
        if (line.frame.size.height < 1) {
            line.backgroundColor = [UIColor clearColor];
        }
    }
    
    UILabel *label = (UILabel *)view;
    if (label == nil) {
        label = [[UILabel alloc] init];
        label.font = [UIFont systemFontOfSize:17.0f];
        if (row == _selectedRow) {
            label.textColor = DARKORAGE;
        }else {
            label.textColor = [UIColor colorWithRed:150/255.0 green:150/255.0 blue:150/255.0 alpha:1];
        }
        [label setTextAlignment:NSTextAlignmentCenter];
        [label setBackgroundColor:[UIColor clearColor]];
    }
    label.text = [self pickerView:pickerView titleForRow:row forComponent:component];
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
    if (_pickerViewBlock) {
        _pickerViewBlock(row);
    }
    _selectedRow = row;
    [pickerView reloadAllComponents];
}



@end

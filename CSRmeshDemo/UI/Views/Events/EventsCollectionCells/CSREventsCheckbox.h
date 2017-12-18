//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>

@interface CSREventsCheckbox : UIControl

//! The control state.
@property (nonatomic, readwrite, getter = isChecked) BOOL checked;

//! The color of the box surrounding the tappable area of the Checkbox control.
//!
//! In iOS 7, all views have a tintColor property.  We redeclare that property
//! here to accommodate tint color customization for iOS 6 devices.
@property (nonatomic, strong) UIColor *tintColor;

@end

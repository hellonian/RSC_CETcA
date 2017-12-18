//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>

@class CSRCheckbox;

@protocol CSRCheckboxDelegate <NSObject>

@optional

- (void)checkbox:(CSRCheckbox*)sender stateChangeTo:(BOOL)state;

@end

@interface CSRCheckbox : UIButton

@property (assign, nonatomic) id <CSRCheckboxDelegate> delegate;

- (void)invertColors:(int)checkBoxMode;

@end

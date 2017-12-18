//
// Copyright 2016 Qualcomm Technologies International, Ltd.
//

#import <UIKit/UIKit.h>

@protocol CSRLightColorDelegate <NSObject>

- (void)selectedColor:(UIColor *)color;

@end

@interface CSRLightRGBVC : UIViewController <UITextFieldDelegate>

@property (nonatomic, strong) NSNumber *deviceId;

@property (weak, nonatomic) IBOutlet UITextField *redTextField;
@property (weak, nonatomic) IBOutlet UITextField *greenTextField;
@property (weak, nonatomic) IBOutlet UITextField *blueTextField;
@property (weak, nonatomic) IBOutlet UIButton *doneAction;
- (IBAction)doneAction:(id)sender;
- (IBAction)cancelAction:(id)sender;

@property (nonatomic, assign) id<CSRLightColorDelegate> lightDelegate;

@end

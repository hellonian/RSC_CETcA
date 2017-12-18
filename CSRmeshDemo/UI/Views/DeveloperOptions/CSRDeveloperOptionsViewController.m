//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import "CSRDeveloperOptionsViewController.h"
#import "CSRAppStateManager.h"
#import "CSRUtilities.h"
#import "CSRmesh/ExtensionModelApi.h"
#import "CSRmesh/PingModelApi.h"
#import "CSRmesh/ActuatorModelApi.h"

@interface CSRDeveloperOptionsViewController () <ExtensionModelApiDelegate>
{
    UIToolbar * toolbar;
    UISegmentedControl * segmentedControl;
    UITextField *activeField;
    CGFloat scrollYPosition;
    
    NSMutableString *validationMessage;
    NSMutableDictionary *textFieldsDict;
    UIAlertController *alertController;
}


@end

@implementation CSRDeveloperOptionsViewController

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // pass the value to parent/super for inheritance and cover display
    self.isModal = YES;
   
    _networkIdTF.tag = 0;
    _placeIdTF.tag = 1;
    _tenantIdTF.tag = 2;
    _meshIdTF.tag = 3;
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    textFieldsDict = [NSMutableDictionary new];
    [self initiateTextField:_cloudHostTF];
//    [self initiateTextField:_networkIdTF];
//    [self initiateTextField:_placeIdTF];
//    [self initiateTextField:_tenantIdTF];
//    [self initiateTextField:_meshIdTF];
    
    [self registerForKeyboardNotifications];
    
    // Set the content size of the scroll view to match the size of the content view:
    [_scrollView setContentSize:CGSizeMake(_cloudHostTF.frame.size.width + 30., 450.)];
    
    [[ExtensionModelApi sharedInstance] addDelegate:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self readAllData];
    
    CGRect frame = _scrollView.frame;
    
    frame.origin.x = 0.;
    frame.origin.y = 0.;
    
    [_scrollView scrollRectToVisible:frame animated:YES];
    //Customizing the back button
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Back"
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:nil
                                                                            action:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    float scrollViewContentHeight;
    
    for (UIView *view in _scrollView.subviews) {
        
        if ([view isKindOfClass:[UITextField class]]) {
            
            scrollViewContentHeight += (view.frame.size.height + 8.);
            
        }
        
    }
    
    //Add top and bottom offsets
    scrollViewContentHeight += (60. - 8.);
    
    [_scrollView setContentSize:CGSizeMake(_scrollView.frame.size.width, scrollViewContentHeight)];
    
}

#pragma mark - Helper methods

- (void)readAllData
{
    // TODO: check if there is any data for text fields already in database and prefill it before presenting
    
    _cloudHostTF.text = [CSRAppStateManager sharedInstance].globalCloudHost;
    
    _networkIdTF.text = @"";
    _placeIdTF.text = @"";
    _tenantIdTF.text = @"";
    _meshIdTF.text = @"";
    
}

- (BOOL)validateEntries
{
    
    validationMessage = [[NSMutableString alloc] initWithString:@""];
    
    if ([CSRUtilities isStringEmpty:_cloudHostTF.text]) {
        [validationMessage appendString:@"Please enter valid Cloud host"];
    }
    
//    if ([CSRUtilities isStringEmpty:_networkIdTF.text]) {
//        [validationMessage appendString:@"Please enter valid Network ID"];
//    }
//    
//    if ([CSRUtilities isStringEmpty:_placeIdTF.text]) {
//        
//        if (![CSRUtilities isStringEmpty:validationMessage]) {
//            [validationMessage appendString:@"\n"];
//        }
//        
//        [validationMessage appendString:@"Please enter valid Place ID"];
//    }
//    
//    if ([CSRUtilities isStringEmpty:_tenantIdTF.text]) {
//        
//        if (![CSRUtilities isStringEmpty:validationMessage]) {
//            [validationMessage appendString:@"\n"];
//        }
//        
//        [validationMessage appendString:@"Please enter valid Tenant ID"];
//    }
//    
//    if ([CSRUtilities isStringEmpty:_meshIdTF.text]) {
//        
//        if (![CSRUtilities isStringEmpty:validationMessage]) {
//            [validationMessage appendString:@"\n"];
//        }
//        
//        [validationMessage appendString:@"Please enter valid Mesh ID"];
//    }
    
    if ([CSRUtilities isStringEmpty:validationMessage]) {
        return YES;
    }
    
    return NO;
}

#pragma mark - Actions

- (IBAction)saveAll:(id)sender
{
    if ([self validateEntries]) {
        
        [CSRAppStateManager sharedInstance].globalCloudHost = _cloudHostTF.text;
        [CSRUtilities saveObject:[CSRAppStateManager sharedInstance].globalCloudHost toDefaultsWithKey:kCSRGlobalCloudHost];
        
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (IBAction)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - UITextField helper methods

- (void)initiateTextField:(UITextField*)textField
{
    textField.delegate = self;
    [textFieldsDict addEntriesFromDictionary:[NSDictionary dictionaryWithObject:textField forKey:[NSString stringWithFormat:@"%ld", (long)textField.tag]]];
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    _scrollView.scrollEnabled = NO;
    
    [self addAccessoryViewToTextField:textField];
    activeField = textField;
    
    CGPoint offsetPoint = [_scrollView convertPoint:activeField.frame.origin fromView:activeField.superview];
    
    scrollYPosition = offsetPoint.y;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    activeField = nil;
}

#pragma mark - Keyboard events

- (void)registerForKeyboardNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification
                                               object:nil];
    
}

- (void)unregisterFromKeyboardNotifications {
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardDidHideNotification
                                                  object:nil];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIKeyboardWillHideNotification
                                                  object:nil];
    
}

// Called when the UIKeyboardDidShowNotification is sent.
- (void)keyboardWasShown:(NSNotification*)aNotification
{
    CGRect kbounds;
    NSDictionary *userInfo = [aNotification userInfo];
    [(NSValue *)[userInfo objectForKey:@"UIKeyboardFrameEndUserInfoKey"] getValue:&kbounds];
    
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, (kbSize.width > kbSize.height ? kbSize.height : kbSize.width), 0);
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
    
    BOOL usingHardwareKeyboard;
    
    if (kbounds.origin.x < 0) {
        
        usingHardwareKeyboard = YES;
        
    } else {
        
        usingHardwareKeyboard = NO;
        
    }
    
    CGRect aRect = self.view.frame;
    aRect.size.height -= (kbSize.width > kbSize.height ? kbSize.height : kbSize.width);
    
    if (!usingHardwareKeyboard) {
        
        CGPoint pointInWindow = [self.view convertPoint:activeField.frame.origin fromView:activeField.superview];
        
        if (!CGRectContainsPoint(aRect, pointInWindow)) {
            
            CGPoint translatedPoint = [_scrollView convertPoint:activeField.frame.origin fromView:activeField.superview];
            CGRect scrollToFrame = CGRectMake(0., translatedPoint.y + 5., activeField.frame.size.width, activeField.frame.size.height);
            
            [_scrollView scrollRectToVisible:scrollToFrame animated:YES];
            
        }
        
    }
    
}

// Called when the UIKeyboardWillHideNotification is sent
- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    _scrollView.contentInset = contentInsets;
    _scrollView.scrollIndicatorInsets = contentInsets;
    
    CGRect frame = _scrollView.frame;
    
    [_scrollView scrollRectToVisible:frame animated:YES];
    
}

#pragma mark - Input Accessory view methods

- (void)addAccessoryViewToTextField:(UITextField*)textField
{
    NSUInteger tag = textField.tag;
    
    toolbar = [[UIToolbar alloc] init];
    toolbar.barStyle = UIBarStyleDefault;
    toolbar.translucent = YES;
    [toolbar sizeToFit];
    
    UIBarButtonItem *prevButton = [[UIBarButtonItem alloc] initWithTitle:@"Previous" style:UIBarButtonItemStyleDone target:self action:@selector(prevTapped:)];
    prevButton.tag = tag;
    
    UIBarButtonItem *nextButton = [[UIBarButtonItem alloc] initWithTitle:@"Next" style:UIBarButtonItemStyleDone target:self action:@selector(nextTapped:)];
    nextButton.tag = tag;
    
    UIBarButtonItem *flexButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
    
    UIBarButtonItem * doneButton =[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(doneTapped:)];
    doneButton.tag = tag;
    
    NSArray *statusItems = [[NSArray alloc] initWithObjects:@"Previous",@"Next", nil];
    segmentedControl = [[UISegmentedControl alloc] initWithItems:statusItems];
    segmentedControl.tintColor = [UIColor whiteColor];
    [segmentedControl addTarget:self action:@selector(segmentedControlClicked:) forControlEvents:UIControlEventValueChanged];
    segmentedControl.tag = tag;
    UIBarButtonItem *segmentItem = [[UIBarButtonItem alloc] initWithCustomView:segmentedControl];
    segmentItem.tag = tag;
    
    NSArray *itemsArray =  [NSArray arrayWithObjects:segmentItem, flexButton, doneButton, nil];
    
    [toolbar setItems:itemsArray];
    [toolbar setBarStyle: UIBarStyleBlackTranslucent];
    
    
    [textField setInputAccessoryView:toolbar];
    
}

- (void)nextTapped:(id)sender
{
    //    UIBarButtonItem *barButtonItem = sender;
    NSUInteger tag = segmentedControl.tag;
    NSUInteger tagToActivate = tag + 1;
    UITextField *textField = [textFieldsDict objectForKey:[NSString stringWithFormat:@"%ld", (long)tagToActivate]];
    
    if (tagToActivate >= [textFieldsDict count]) {
        
        return;
        
    } else {
        
        [textField becomeFirstResponder];
        
    }
    
    activeField = textField;
    
    return;
}

- (void)prevTapped:(id)sender
{
    
    NSInteger tag = segmentedControl.tag;
    NSInteger tagToActivate = tag - 1;
    UITextField *textField = [textFieldsDict objectForKey:[NSString stringWithFormat:@"%ld", (long)tagToActivate]];
    
    if (tagToActivate < 0) {
        
        activeField = nil;
        return;
        
    } else {
        
        [textField becomeFirstResponder];
        
    }
    
    activeField = textField;
    
    return;
}

- (void)doneTapped:(id)sender
{
    
    [activeField resignFirstResponder];
    _scrollView.scrollEnabled = YES;
    
}

- (void)segmentedControlClicked:(id)sender
{
    
    switch ([sender selectedSegmentIndex]) {
            
        case 0:
            [self prevTapped:nil];
            break;
            
        case 1:
            [self nextTapped:nil];
            break;
    }
    
}

- (IBAction)testingApis:(id)sender {
    
    [[ExtensionModelApi sharedInstance] registerForResponseOpcode:@(0xAB01)
                                                            range:@2
                                                          failure:^(NSError * _Nonnull error) {
                                                              
                                                          }];
    
    [[ExtensionModelApi sharedInstance] extensionRequestWithproviderCode:@"1234"
                                                          proposedOpCode:@(0xAB00)
                                                                   range:@(2)
                                                                 failure:^(NSError * _Nonnull error) {
                                                                     
                                                                 }];
    
    uint8_t dummy[] = {0,1};
    NSData *dummyData = [NSData dataWithBytes:&dummy length:sizeof(dummy)];

    
    [[ExtensionModelApi sharedInstance] extensionSendMessage:@0
                                                      opcode:@(0xAB00)
                                                     message:dummyData
                                                     failure:^(NSError * _Nonnull error) {
                                                         
                                                     }];
    
    [[ExtensionModelApi sharedInstance] opcodeMessage:@(0xAB01)
                                           replyAfter:@1
                                              failure:^(NSError * _Nonnull error) {
                                                  
                                              }];
    
    
}
- (void)didGetExtensionConflict:(NSNumber * _Nonnull)deviceId
                   providerCode:(NSString * _Nullable)providerCode
                 proposedOpCode:(NSNumber * _Nullable)proposedOpCode
                         reason:(NSNumber * _Nullable)reason
{
    NSLog(@"deviceId=%@, providerCode=%@, proposedOpCode=%@, reason=%@", deviceId, providerCode, proposedOpCode, reason);
}

- (void)didGetExpectedOpcode:(NSNumber * _Nonnull)deviceId
                      opcode:(NSNumber * _Nullable)opcode
                 messageBody:(NSData * _Nullable)messageBody
{
    NSLog(@"deviceId=%@, opcode=%@, messageBody=%@", deviceId, opcode, messageBody);
}


//- (IBAction)testingRestApis:(id)sender {
//    
//    
//}
@end

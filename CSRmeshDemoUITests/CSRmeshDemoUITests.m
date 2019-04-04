//
// Copyright 2015 Qualcomm Technologies International, Ltd.
//

#import <XCTest/XCTest.h>
#import "CSRUtilities.h"
//#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonCrypto.h>


@interface CSRmeshDemoUITests : XCTestCase

@end

@implementation CSRmeshDemoUITests

- (void)setUp {
    [super setUp];
    
    // Put setup code here. This method is called before the invocation of each test method in the class.
    
    // In UI tests it is usually best to stop immediately when a failure occurs.
    self.continueAfterFailure = YES;
    // UI tests must launch the application that they test. Doing this in setup will make sure it happens for each test method.
    [[[XCUIApplication alloc] init] launch];
    
    // In UI tests it’s important to set the initial state - such as interface orientation - required for your tests before they run. The setUp method is a good place to do this.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}


@end

//
//  UIImage+Darkness.m
//  BluetoothTest
//
//  Created by hua on 5/31/16.
//  Copyright © 2016 hua. All rights reserved.
//

#import "UIImage+Darkness.h"
#import <CoreImage/CoreImage.h>

@implementation UIImage (Darkness)

- (UIImage*)darkerImage {
    /*
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [[CIImage alloc] initWithImage:self];
    
    CIFilter *filter= [CIFilter filterWithName:@"CIColorControls"];
    [filter setValue:inputImage forKey:@"inputImage"];
    [filter setValue:[NSNumber numberWithFloat:0.1] forKey:@"inputBrightness"];
    [filter setValue:[NSNumber numberWithFloat:2.0] forKey:@"inputContrast"];
    
    UIImage *outputImage = [UIImage imageWithCGImage:[context createCGImage:filter.outputImage fromRect:filter.outputImage.extent]];
    return outputImage;
    */
    
    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage = [[CIImage alloc] initWithImage:self];
    
    CIFilter *filter= [CIFilter filterWithName:@"CIExposureAdjust"];
    [filter setValue:inputImage forKey:@"inputImage"];
    [filter setValue:[NSNumber numberWithFloat:-3.0] forKey:@"inputEV"];
    
    UIImage *outputImage = [UIImage imageWithCGImage:[context createCGImage:filter.outputImage fromRect:filter.outputImage.extent]];
    return outputImage;
}

@end

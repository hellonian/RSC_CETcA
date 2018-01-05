//
//  GalleryViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/2.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "GalleryViewController.h"
#import "GalleryDetailViewController.h"
#import "CSRAppStateManager.h"
#import "GalleryEntity.h"

@interface GalleryViewController ()<UINavigationControllerDelegate,UIImagePickerControllerDelegate>

@end

@implementation GalleryViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"bgImage"]];
    imageView.frame = [UIScreen mainScreen].bounds;
    [self.view addSubview:imageView];
    
    self.navigationItem.title = @"Gallery";
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(galleryEditAction:)];
    self.navigationItem.rightBarButtonItem = edit;
    self.navigationItem.leftBarButtonItem = nil;
    
}

- (void)galleryEditAction:(UIBarButtonItem *)item {
    UIBarButtonItem *done = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(galleryDoneAction:)];
    self.navigationItem.rightBarButtonItem = done;
    UIBarButtonItem *add = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(galleryAddAction:)];
    self.navigationItem.leftBarButtonItem = add;
}

- (void)galleryDoneAction:(UIBarButtonItem *)item {
    UIBarButtonItem *edit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit target:self action:@selector(galleryEditAction:)];
    self.navigationItem.rightBarButtonItem = edit;
    self.navigationItem.leftBarButtonItem = nil;
    
    NSArray *galleryArray = [[CSRAppStateManager sharedInstance].selectedPlace.gallerys allObjects];
    NSLog(@">> >> %ld",galleryArray.count);
    
    
    [galleryArray enumerateObjectsUsingBlock:^(GalleryEntity *galleryEntity, NSUInteger idx, BOOL * _Nonnull stop) {
        NSLog(@">> >> %@ >> >> %lu",galleryEntity.galleryID,(unsigned long)galleryEntity.drops.count);
        NSLog(@">> %@",galleryEntity);
        NSArray *dropArray = [galleryEntity.drops allObjects];
        for (DropEntity *dropEntity in dropArray) {
            NSLog(@">> %@",dropEntity);
        }
    }];
}

- (void)galleryAddAction:(UIBarButtonItem *)item {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *camera = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self alertAction:0];
        
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    UIAlertAction *album = [UIAlertAction actionWithTitle:@"Choose from Album" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self alertAction:1];
        
        [alert dismissViewControllerAnimated:YES completion:nil];
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:camera];
    [alert addAction:album];
    [alert addAction:cancel];
    
    alert.popoverPresentationController.barButtonItem = self.navigationItem.leftBarButtonItem;
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)alertAction:(NSInteger)tag {
    UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
    if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
        imagePickerController.delegate = self;
        imagePickerController.allowsEditing = YES;
        if (tag == 0) {
            imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }
        if (tag == 1) {
            imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
            [self presentViewController:imagePickerController animated:YES completion:nil];
        }
    }else {
        imagePickerController.delegate = self;
        imagePickerController.allowsEditing = YES;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        [self presentViewController:imagePickerController animated:YES completion:nil];
    }
}

#pragma mark - <UINavigationControllerDelegate,UIImagePickerControllerDelegate>

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    GalleryDetailViewController *gdvc = [[GalleryDetailViewController alloc] init];
    gdvc.image = [self fixOrientation:image];
    gdvc.isEditing = YES;
    [self.navigationController pushViewController:gdvc animated:NO];
    
    
}

//相机拍的照片带有imageOrientation属性，在显示的时候会自动摆正方向，而存放的时候按统一方向存放，开发使用时需摆正方向。
- (UIImage *)fixOrientation:(UIImage *)aImage {
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}






- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end

//
//  GroupViewController.m
//  CSRmeshDemo
//
//  Created by AcTEC on 2018/1/30.
//  Copyright © 2018年 Cambridge Silicon Radio Ltd. All rights reserved.
//

#import "GroupViewController.h"
#import "PlaceColorIconPickerView.h"
#import "PureLayout.h"


@interface GroupViewController ()<UITextFieldDelegate,PlaceColorIconPickerViewDelegate,UINavigationControllerDelegate,UIImagePickerControllerDelegate,MainCollectionViewDelegate>
{
    PlaceColorIconPickerView *pickerView;
}

@property (weak, nonatomic) IBOutlet UIButton *editItem;
@property (weak, nonatomic) IBOutlet UIButton *backItem;
@property (weak, nonatomic) IBOutlet UITextField *groupNameTF;
@property (weak, nonatomic) IBOutlet UIButton *iconEditBtn;
@property (weak, nonatomic) IBOutlet UIImageView *groupIconImageView;

@end

@implementation GroupViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    self.groupNameTF.delegate = self;
    if (self.isEditing) {
        [self.editItem setTitle:@"Done" forState:UIControlStateNormal];
        self.backItem.hidden = YES;
        [self.groupNameTF becomeFirstResponder];
        self.groupNameTF.backgroundColor = [UIColor whiteColor];
        self.iconEditBtn.hidden = NO;
    }
    
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc] init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
    flowLayout.minimumLineSpacing = WIDTH*8.0/640.0;
    flowLayout.minimumInteritemSpacing = WIDTH*8.0/640.0;
    flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 0, WIDTH*3/160.0);
    flowLayout.itemSize = CGSizeMake(WIDTH*5/16.0, WIDTH*9/32.0);
    
    _devicesCollectionView = [[MainCollectionView alloc] initWithFrame:CGRectMake(WIDTH*3/160.0, WIDTH*302/640.0+64, WIDTH*157/160.0, HEIGHT-64-WIDTH*3/160.0) collectionViewLayout:flowLayout cellIdentifier:@"MainCollectionViewCell"];
    _devicesCollectionView.mainDelegate = self;
    [_devicesCollectionView.dataArray addObject:@1];
    [self.view addSubview:_devicesCollectionView];
    
    
}

#pragma mark - buttonAction

- (IBAction)backAction:(UIButton *)sender {
    CATransition *animation = [CATransition animation];
    [animation setDuration:0.3];
    [animation setType:kCATransitionMoveIn];
    [animation setSubtype:kCATransitionFromLeft];
    [self.view.window.layer addAnimation:animation forKey:nil];
    [self dismissViewControllerAnimated:NO completion:nil];
}

- (IBAction)editItemAction:(UIButton *)sender {
    if ([sender.titleLabel.text isEqualToString:@"Edit"]) {
        _isEditing = YES;
        [sender setTitle:@"Done" forState:UIControlStateNormal];
        self.backItem.hidden = YES;
        self.iconEditBtn.hidden = NO;
        self.groupNameTF.enabled = YES;
        self.groupNameTF.backgroundColor = [UIColor whiteColor];
    }
    else {
        _isEditing = NO;
        [sender setTitle:@"Edit" forState:UIControlStateNormal];
        self.backItem.hidden = NO;
        self.iconEditBtn.hidden = YES;
        self.groupNameTF.enabled = NO;
        self.groupNameTF.backgroundColor = [UIColor clearColor];
    }
    
}

- (IBAction)iconEditAction:(UIButton *)sender {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    [alert.view setTintColor:DARKORAGE];
    
    UIAlertAction *icon = [UIAlertAction actionWithTitle:@"Select default iocn" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        if (!pickerView) {
            pickerView = [[PlaceColorIconPickerView alloc] initWithFrame:CGRectMake((WIDTH-277)/2, (HEIGHT-240)/2, 277, 240) withMode:CollectionViewPickerMode_GroupIconPicker];
            pickerView.delegate = self;
            [UIView animateWithDuration:0.5 animations:^{
                [self.view addSubview:pickerView];
                [pickerView autoCenterInSuperview];
                [pickerView autoSetDimensionsToSize:CGSizeMake(277, 240)];
            }];
        }
        
    }];
    UIAlertAction *camera = [UIAlertAction actionWithTitle:@"Camera" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self alertAction:0];
        
    }];
    UIAlertAction *album = [UIAlertAction actionWithTitle:@"Choose from Album" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        [self alertAction:1];
        
    }];
    UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
    }];
    [alert addAction:icon];
    [alert addAction:camera];
    [alert addAction:album];
    [alert addAction:cancel];
    
    alert.popoverPresentationController.sourceView = sender;
    alert.popoverPresentationController.sourceRect = sender.bounds;
    
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

#pragma mark - MainCollectionViewDelegate

- (void)mainCollectionViewTapCellAction:(NSNumber *)cellDeviceId cellIndexPath:(NSIndexPath *)indexPath {
    NSLog(@"group");
    if ([cellDeviceId isEqualToNumber:@4000]) {
        NSLog(@"grouppppppp");
        NSLog(@"dd");
    }
}

#pragma mark - <UIImagePickerControllerDelegate>

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
    [picker dismissViewControllerAnimated:YES completion:nil];
    UIImage *image = [info objectForKey:UIImagePickerControllerOriginalImage];
    
    self.groupIconImageView.image = [self fixOrientation:image];
    
    
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

#pragma mark - PlaceColorIconPickerViewDelegate

- (id)selectedItem:(id)item {
    NSString *imageString = (NSString *)item;
    
    NSLog(@"%@",imageString);
    self.groupIconImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@_highlight",imageString]];
    
    return nil;
}

- (void)cancel:(UIButton *)sender {
    if (pickerView) {
        [UIView animateWithDuration:0.5 animations:^{
            [pickerView removeFromSuperview];
            pickerView = nil;
        }];
    }
}


#pragma mark - UITextFieldDelegate methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [textField resignFirstResponder];
    return NO;
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

//
//  ViewController.m
//  JJFaceDetector_demo1
//
//  Created by lucy on 2018/1/30.
//  Copyright © 2018年 com.daoKeLegend. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@property (nonatomic, strong) UIImageView *pictureImageView;

@end

@implementation ViewController

#pragma mark - Override Base Function

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self initUI];
    [self detectFaceWithImage];
}

#pragma mark - Object Private Function

- (void)initUI
{
    UIImageView *pictureImageView = [[UIImageView alloc] initWithFrame:self.view.bounds];
    pictureImageView.contentMode = UIViewContentModeScaleAspectFit;
    pictureImageView.image = [UIImage imageNamed:@"face"];
    self.pictureImageView = pictureImageView;
    [self.view addSubview:pictureImageView];
}

- (void)detectFaceWithImage
{
    UIImage *image = [UIImage imageNamed:@"face"];
    // 图像识别能力：可以在CIDetectorAccuracyHigh(较强的处理能力)与CIDetectorAccuracyLow(较弱的处理能力)中选择，因为想让准确度高一些在这里选择CIDetectorAccuracyHigh
    NSDictionary *opts = [NSDictionary dictionaryWithObject:
                          CIDetectorAccuracyHigh forKey:CIDetectorAccuracy];
    // 将图像转换为CIImage
    CIImage *faceImage = [CIImage imageWithCGImage:image.CGImage];
    CIDetector *faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:opts];
    // 识别出人脸数组
    NSArray *features = [faceDetector featuresInImage:faceImage];
    // 得到图片的尺寸
    CGSize inputImageSize = [faceImage extent].size;
    //将image沿y轴对称
    CGAffineTransform transform = CGAffineTransformScale(CGAffineTransformIdentity, 1, -1);
    //将图片上移
    transform = CGAffineTransformTranslate(transform, 0, -inputImageSize.height);
    
    // 取出所有人脸
    for (CIFaceFeature *faceFeature in features){
        //获取人脸的frame
        CGRect faceViewBounds = CGRectApplyAffineTransform(faceFeature.bounds, transform);
        CGSize viewSize = self.pictureImageView.bounds.size;
        CGFloat scale = MIN(viewSize.width / inputImageSize.width,
                            viewSize.height / inputImageSize.height);
        CGFloat offsetX = (viewSize.width - inputImageSize.width * scale) / 2;
        CGFloat offsetY = (viewSize.height - inputImageSize.height * scale) / 2;
        // 缩放
        CGAffineTransform scaleTransform = CGAffineTransformMakeScale(scale, scale);
        // 修正
        faceViewBounds = CGRectApplyAffineTransform(faceViewBounds,scaleTransform);
        faceViewBounds.origin.x += offsetX;
        faceViewBounds.origin.y += offsetY;
        
        //描绘人脸区域
        UIView* faceView = [[UIView alloc] initWithFrame:faceViewBounds];
        faceView.layer.borderWidth = 2;
        faceView.layer.borderColor = [[UIColor redColor] CGColor];
        [self.pictureImageView addSubview:faceView];
        
        // 判断是否有左眼位置
        if(faceFeature.hasLeftEyePosition){
            NSLog(@"检测到左眼");
        }
        // 判断是否有右眼位置
        if(faceFeature.hasRightEyePosition){
            NSLog(@"检测到右眼");
        }
        // 判断是否有嘴位置
        if(faceFeature.hasMouthPosition){
            NSLog(@"检测到嘴部");
        }
    }
}

@end



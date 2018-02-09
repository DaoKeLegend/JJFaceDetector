//
//  ViewController.m
//  JJFaceDetector_demo2
//
//  Created by mac on 2018/1/31.
//  Copyright © 2018年 DaoKeLegend. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <AVCaptureVideoDataOutputSampleBufferDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *captureVideoDeviceInput;
@property (nonatomic, strong) AVCaptureVideoDataOutput *captureMovieFileOutput;
@property (nonatomic, strong) AVCaptureConnection *captureConnection;
@property (nonatomic, strong) AVCaptureVideoPreviewLayer *previewLayer;
@property (nonatomic, strong) NSMutableArray <UIView *> *faceViewArrM;

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.faceViewArrM = [NSMutableArray array];
    
    self.captureSession = [[AVCaptureSession alloc] init];
    if ([self.captureSession canSetSessionPreset:AVCaptureSessionPresetHigh]) {
        self.captureSession.sessionPreset = AVCaptureSessionPresetHigh;
    }
    else {
        self.captureSession.sessionPreset = AVCaptureSessionPreset1280x720;
    }
    
    for (AVCaptureDevice *device in [AVCaptureDevice devices]) {
        if ([device hasMediaType:AVMediaTypeVideo]) {
            if (device.position == AVCaptureDevicePositionFront) {
                self.captureDevice = device;
            }
        }
    }
    
    //添加输入
    [self addVideoInput];
    
    //添加输出
    [self addVideoOutput];
    
    //添加预览图层
    [self addPreviewLayer];
    
    [self.captureSession commitConfiguration];
    [self.captureSession startRunning];

}

#pragma mark -  Object Private Function

- (void)addVideoInput
{
    NSError *error;
    self.captureVideoDeviceInput = [AVCaptureDeviceInput deviceInputWithDevice:self.captureDevice error:&error];
    if (error) {
        return;
    }
    if ([self.captureSession canAddInput:self.captureVideoDeviceInput]) {
        [self.captureSession addInput:self.captureVideoDeviceInput];
    }
}

- (void)addVideoOutput
{
    self.captureMovieFileOutput = [[AVCaptureVideoDataOutput alloc] init];
    [self.captureMovieFileOutput setSampleBufferDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
//    self.captureMovieFileOutput.videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithUnsignedInt:kCVPixelFormatType_32BGRA], (id)kCVPixelBufferPixelFormatTypeKey, nil];
    if ([self.captureSession canAddOutput:self.captureMovieFileOutput]) {
        [self.captureSession addOutput:self.captureMovieFileOutput];
    }
    
    //设置链接管理对象
    self.captureConnection = [self.captureMovieFileOutput connectionWithMediaType:AVMediaTypeVideo];
    //视频旋转方向设置
    self.captureConnection.videoScaleAndCropFactor = self.captureConnection.videoMaxScaleAndCropFactor;;
    //视频稳定设置
    if ([self.captureConnection isVideoStabilizationSupported]) {
        self.captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
    
//    AVCaptureFileOutputDelegate *del = nil;
}

- (void)addPreviewLayer
{
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    self.previewLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.previewLayer];
}

- (void)detectFaceWithImage:(UIImage *)image
{
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
    
    //清空数组
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.faceViewArrM enumerateObjectsUsingBlock:^(UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [obj removeFromSuperview];
             obj = nil;
        }];
    });
    
    // 取出所有人脸
    for (CIFaceFeature *faceFeature in features){
        //获取人脸的frame
        CGRect faceViewBounds = CGRectApplyAffineTransform(faceFeature.bounds, transform);
        CGSize viewSize = self.previewLayer.bounds.size;
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
        dispatch_async(dispatch_get_main_queue(), ^{
            UIView* faceView = [[UIView alloc] initWithFrame:faceViewBounds];
            faceView.layer.borderWidth = 2;
            faceView.layer.borderColor = [[UIColor redColor] CGColor];
            [self.view addSubview:faceView];
            [self.faceViewArrM addObject:faceView];
        });
        
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

#pragma mark -  AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureFileOutput *)output didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer fromConnection:(AVCaptureConnection *)connection
{
    NSLog(@"----------");

    [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
    CVImageBufferRef buffer;
    buffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    
    CVPixelBufferLockBaseAddress(buffer, 0);
    uint8_t *base;
    size_t width, height, bytesPerRow;
    base = (uint8_t *)CVPixelBufferGetBaseAddress(buffer);
    width = CVPixelBufferGetWidth(buffer);
    height = CVPixelBufferGetHeight(buffer);
    bytesPerRow = CVPixelBufferGetBytesPerRow(buffer);
    
    CGColorSpaceRef colorSpace;
    CGContextRef cgContext;
    colorSpace = CGColorSpaceCreateDeviceRGB();
    cgContext = CGBitmapContextCreate(base, width, height, 8, bytesPerRow, colorSpace, kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    CGColorSpaceRelease(colorSpace);
    
    CGImageRef cgImage;
    UIImage *image;
    cgImage = CGBitmapContextCreateImage(cgContext);
    image = [UIImage imageWithCGImage:cgImage];
    [self detectFaceWithImage:image];
    CGImageRelease(cgImage);
    CGContextRelease(cgContext);
    
    CVPixelBufferUnlockBaseAddress(buffer, 0);
}

@end

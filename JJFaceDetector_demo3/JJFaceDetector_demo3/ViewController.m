//
//  ViewController.m
//  JJFaceDetector_demo3
//
//  Created by mac on 2018/1/31.
//  Copyright © 2018年 DaoKeLegend. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>

@interface ViewController () <AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic, strong) AVCaptureSession *captureSession;
@property (nonatomic, strong) AVCaptureDevice *captureDevice;
@property (nonatomic, strong) AVCaptureDeviceInput *captureVideoDeviceInput;
@property (nonatomic, strong) AVCaptureMetadataOutput *metaDataOutput;
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
    self.metaDataOutput = [[AVCaptureMetadataOutput alloc] init];
    [self.metaDataOutput setMetadataObjectsDelegate:self queue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0)];
    if ([self.captureSession canAddOutput:self.metaDataOutput]) {
        [self.captureSession addOutput:self.metaDataOutput];
    }
    
    self.metaDataOutput.metadataObjectTypes =  @[AVMetadataObjectTypeFace];
    
    //设置链接管理对象
    self.captureConnection = [self.metaDataOutput connectionWithMediaType:AVMediaTypeVideo];
    //视频旋转方向设置
    self.captureConnection.videoScaleAndCropFactor = self.captureConnection.videoMaxScaleAndCropFactor;;
    //视频稳定设置
    if ([self.captureConnection isVideoStabilizationSupported]) {
        self.captureConnection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }
}

- (void)addPreviewLayer
{
    self.previewLayer = [AVCaptureVideoPreviewLayer layerWithSession:self.captureSession];
    [self.previewLayer setVideoGravity:AVLayerVideoGravityResizeAspect];
    self.previewLayer.frame = self.view.bounds;
    [self.view.layer addSublayer:self.previewLayer];
}

#pragma mark -  AVCaptureVideoDataOutputSampleBufferDelegate

- (void)captureOutput:(AVCaptureOutput *)output didOutputMetadataObjects:(NSArray<__kindof AVMetadataObject *> *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects.count > 0) {
        NSLog(@"检测到了人脸，数目为%ld", metadataObjects.count);
        NSLog(@"%@", metadataObjects);
    }
}


@end

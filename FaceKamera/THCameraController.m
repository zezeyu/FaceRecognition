
#import "THCameraController.h"
#import <AVFoundation/AVFoundation.h>

@interface THCameraController ()<AVCaptureMetadataOutputObjectsDelegate>

@property(nonatomic,strong)AVCaptureMetadataOutput *metadataOutput;

@end

@implementation THCameraController

- (BOOL)setupSessionOutputs:(NSError **)error {

    self.metadataOutput = [[AVCaptureMetadataOutput alloc] init];
    
    if ([self.captureSession canAddOutput:self.metadataOutput]) {
        [self.captureSession addOutput:_metadataOutput];
        ///获取人脸属性
        NSArray *metadatObjectTypes = @[AVMetadataObjectTypeFace];
        
        self.metadataOutput.metadataObjectTypes = metadatObjectTypes;
        
        dispatch_queue_t mainQueue = dispatch_get_main_queue();
        
        ///一次可以同时获取10张人脸，不能再多了！！！
        [self.metadataOutput setMetadataObjectsDelegate:self queue:mainQueue];
        
        return YES;
        
    }else{
        NSLog(@"Set Session Error!");
        return NO;
    }
    return NO;
}
#pragma --mark 代理方法
- (void)captureOutput:(AVCaptureOutput *)captureOutput
didOutputMetadataObjects:(NSArray *)metadataObjects
       fromConnection:(AVCaptureConnection *)connection {

    //captureOutput 表示是从哪里输出
    //相机可以识别多种数据，人脸数据，二维码数据  metadataObjects怎么区分两个数据？
    //通过captureOutput输出
    
    for (AVMetadataFaceObject *face in metadataObjects) {
        ///一个人脸的唯一标识
        NSLog(@"Face ID -- %li",(long)face.faceID);
        
        NSLog(@"Face bounds --%@",NSStringFromCGRect(face.bounds));
    }
    
    [self.faceDetectionDelegate didDetectFaces:metadataObjects];

}

@end


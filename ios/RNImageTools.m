
#import "RNImageTools.h"
#import "React/RCTLog.h"
#import "React/RCTConvert.h"

@implementation RNImageTools

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(mask:(NSString *)imageURLString
                  maskImageURLString:(NSString *)maskImageURLString
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSURL *imageURL = [RCTConvert NSURL:imageURLString];
    NSURL *maskImageURL = [RCTConvert NSURL:maskImageURLString];
    NSData *imageData = [[NSData alloc] initWithContentsOfURL:imageURL];
    NSData *maskImageData = [[NSData alloc] initWithContentsOfURL:maskImageURL];
    UIImage *image = [[UIImage alloc] initWithData:imageData];
    UIImage *maskImage = [[UIImage alloc] initWithData:maskImageData];
    UIImage *maskedImage = [self maskImage:image withMask:maskImage];
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, maskImage.size.width, maskImage.size.height)];
    imageView.image = maskedImage;
    
    UIImage *imageFromLayer = [self imageFromLayer:imageView.layer];
    NSString *imagePath = [self saveImage:imageFromLayer];

    resolve(@{
              @"path": imagePath,
              @"width": [NSNumber numberWithFloat:maskedImage.size.width],
              @"height": [NSNumber numberWithFloat:maskedImage.size.height]
              });
}

- (UIImage*) maskImage:(UIImage *) image withMask:(UIImage *) mask
{
    CGImageRef imageReference = image.CGImage;
    CGImageRef maskReference = mask.CGImage;
    
    CGImageRef imageMask = CGImageMaskCreate(CGImageGetWidth(maskReference),
                                             CGImageGetHeight(maskReference),
                                             CGImageGetBitsPerComponent(maskReference),
                                             CGImageGetBitsPerPixel(maskReference),
                                             CGImageGetBytesPerRow(maskReference),
                                             CGImageGetDataProvider(maskReference),
                                             NULL, // Decode is null
                                             YES // Should interpolate
                                             );
    
    CGImageRef maskedReference = CGImageCreateWithMask(imageReference, imageMask);
    CGImageRelease(imageMask);
    
    UIImage *maskedImage = [UIImage imageWithCGImage:maskedReference];
    CGImageRelease(maskedReference);
    
    return maskedImage;
}

- (NSString *)saveImage:(UIImage *)image {
    NSString *fileName = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@.png", [self getPathForDirectory:NSDocumentDirectory], fileName];
    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:fullPath atomically:YES];
    return fullPath;
}

- (NSString *)getPathForDirectory:(int)directory
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(directory, NSUserDomainMask, YES);
    return [paths firstObject];
}

- (UIImage *)imageFromLayer:(CALayer *)layer
{
    UIGraphicsBeginImageContextWithOptions(layer.frame.size, NO, 0);
    
    [layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return outputImage;
}

@end
  

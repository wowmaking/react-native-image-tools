
#import "RNImageTools.h"
#import "React/RCTLog.h"
#import "React/RCTConvert.h"

@implementation RNImageTools

- (dispatch_queue_t)methodQueue
{
    return dispatch_get_main_queue();
}
RCT_EXPORT_MODULE()

RCT_EXPORT_METHOD(transform:(NSString *)imageURLString
                  translateX:(double)translateX
                  translateY:(double)translateY
                  rotate:(double)rotate
                  scale:(double)scale
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    UIImage *image = [self getUIImageFromURLString:imageURLString];
    UIImage *translatedImage = [self translateImage:image byX:translateX byY:translateY];
    UIImage *scaledImage = [self scaleImage:translatedImage sx:scale sy:scale];
    UIImage *rotatedImage = [self rotateImage:scaledImage byDegree:rotate];
    UIImage *noTransparencyImage = [self removeTransparencyFromImage:rotatedImage];
    
    UIImage *resultImage = noTransparencyImage;
    
    NSString *imagePath = [self saveImage:resultImage withPostfix:@"transformed"];
    
    resolve(@{
              @"uri": imagePath,
              @"width": [NSNumber numberWithFloat:resultImage.size.width],
              @"height": [NSNumber numberWithFloat:resultImage.size.height]
              });
}

RCT_EXPORT_METHOD(crop:(NSString *)imageURLString
                  x:(CGFloat)x
                  y:(CGFloat)y
                  width:(CGFloat)width
                  height:(CGFloat)height
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    NSURL *imageURL = [RCTConvert NSURL:imageURLString];
    NSData *imageData = [[NSData alloc] initWithContentsOfURL:imageURL];
    UIImage *image = [self fixImageOrientation:[[UIImage alloc] initWithData:imageData]];
    UIImage *croppedImage = [self cropImage:image toRect:CGRectMake(x, y, width, height)];
    
    NSString *imagePath = [self saveImage:croppedImage withPostfix:@"cropped"];
    
    resolve(@{
              @"uri": imagePath,
              @"width": [NSNumber numberWithFloat:croppedImage.size.width],
              @"height": [NSNumber numberWithFloat:croppedImage.size.height]
              });
}

RCT_EXPORT_METHOD(mask:(NSString *)imageURLString
                  maskImageURLString:(NSString *)maskImageURLString
                  options:(NSDictionary *)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    UIImage *image = [self getUIImageFromURLString:imageURLString];
    UIImage *maskImage = [self getUIImageFromURLString:maskImageURLString];
    BOOL trimTransparency = [RCTConvert BOOL:options[@"trimTransparency"]];
    
    // Crop
    CGFloat newWidth = maskImage.size.width * image.size.height / maskImage.size.height;
    CGFloat newHeight = image.size.height;
    CGFloat newX = (image.size.width - newWidth) / 2;
    CGFloat newY = 0;
    UIImage *croppedImage = [self cropImage:image toRect:CGRectMake(newX, newY, newWidth, newHeight)];
    
    UIImage *maskedImage = [self maskImage:croppedImage withMask:maskImage];
    UIImageView *maskedImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, maskedImage.size.width, maskedImage.size.height)];
    maskedImageView.image = maskedImage;
    UIImage *maskedImageFromLayer = [self imageFromLayer:maskedImageView.layer];
    
    UIImage *resultImage = trimTransparency ? [self trimTransparentPixels:maskedImageFromLayer requiringFullOpacity:NO] : maskedImageFromLayer;
    NSString *imagePath = [self saveImage:resultImage withPostfix:@"masked"];
    
    resolve(@{
              @"uri": imagePath,
              @"width": [NSNumber numberWithFloat:maskedImage.size.width],
              @"height": [NSNumber numberWithFloat:maskedImage.size.height]
              });
}

RCT_EXPORT_METHOD(resize:(NSString *)imageURLString
                  toWidth:(CGFloat)width
                  toHeight:(CGFloat)height
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    UIImage *image = [self getUIImageFromURLString:imageURLString];
    
    image = [self resizeImage:image toWidth:width toHeight:height];
    
    NSString *imagePath = [self saveImage:image withPostfix:@"resized"];
    
    resolve(@{
              @"uri": imagePath,
              @"width": [NSNumber numberWithFloat:image.size.width],
              @"height": [NSNumber numberWithFloat:image.size.height]
              });
}

RCT_EXPORT_METHOD(delete:(NSString *)imageURLString
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    [self deleteImageAtPath:imageURLString];
    resolve(nil);
}

RCT_EXPORT_METHOD(createMaskFropShape:(NSDictionary*)options
                  resolver:(RCTPromiseResolveBlock)resolve
                  rejector:(RCTPromiseRejectBlock)reject)
{
    CGFloat width = [RCTConvert CGFloat:options[@"width"]];
    CGFloat height = [RCTConvert CGFloat:options[@"height"]];
    NSArray *points = [RCTConvert NSArray:options[@"points"]];
    BOOL inverted = [RCTConvert BOOL:options[@"inverted"]];
    
    NSMutableArray *pointsWithCGPoints = [[NSMutableArray alloc] init];
    for (NSInteger i = 0; i < [points count]; i++) {
        CGPoint convertedCGPoint = [RCTConvert CGPoint:[points objectAtIndex:i]];
        [pointsWithCGPoints addObject:[NSValue valueWithCGPoint:convertedCGPoint]];
    }
    
    UIImage *image = [self createMaskImageFropShape:pointsWithCGPoints withWidth:width height:height invert:inverted];
    
    NSString *imagePath = [self saveImage:image withPostfix:@"shape"];
    
    resolve(@{
              @"uri": imagePath,
              @"width": [NSNumber numberWithFloat:image.size.width],
              @"height": [NSNumber numberWithFloat:image.size.height]
              });
}

- (UIImage*) getUIImageFromURLString:(NSString *)imageURLString {
    NSURL *imageURL = [RCTConvert NSURL:imageURLString];
    NSData *imageData = [[NSData alloc] initWithContentsOfURL:imageURL];
    UIImage *image = [self fixImageOrientation:[[UIImage alloc] initWithData:imageData]];
    return image;
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

- (NSString *)saveImage:(UIImage *)image withPostfix:(NSString *)postfix {
    NSString *fileName = [[NSProcessInfo processInfo] globallyUniqueString];
    NSString *fullPath = [NSString stringWithFormat:@"%@/%@_%@.png", [self getPathForDirectory:NSDocumentDirectory], fileName, postfix];
    NSData *imageData = UIImagePNGRepresentation(image);
    [imageData writeToFile:fullPath atomically:YES];
    return fullPath;
}

- (void)deleteImageAtPath:(NSString *)path {
    NSError *error;
    if ([[NSFileManager defaultManager] isDeletableFileAtPath:path]) {
        BOOL success = [[NSFileManager defaultManager] removeItemAtPath:path error:&error];
        if (!success) {
            NSLog(@"Error removing file at path: %@", error.localizedDescription);
        }
    }
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

-(UIImage *) fixImageOrientation:(UIImage *) image {
    
    if (image.imageOrientation == UIImageOrientationUp) {
        return image;
    }
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (image.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, image.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, image.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
            
        default: break;
    }
    
    switch (image.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            // CORRECTION: Need to assign to transform here
            transform = CGAffineTransformTranslate(transform, image.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            // CORRECTION: Need to assign to transform here
            transform = CGAffineTransformTranslate(transform, image.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        default: break;
    }
    
    CGContextRef ctx = CGBitmapContextCreate(nil, image.size.width, image.size.height, CGImageGetBitsPerComponent(image.CGImage), 0, CGImageGetColorSpace(image.CGImage), kCGImageAlphaPremultipliedLast);
    
    CGContextConcatCTM(ctx, transform);
    
    switch (image.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.height, image.size.width), image.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
            break;
    }
    
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    
    return [UIImage imageWithCGImage:cgImage];
}

- (UIImage*) translateImage:(UIImage *) image byX:(double) x byY:(double) y
{
    CGContextRef ctx = CGBitmapContextCreate(nil, image.size.width, image.size.height, CGImageGetBitsPerComponent(image.CGImage), 0, CGImageGetColorSpace(image.CGImage), kCGImageAlphaPremultipliedLast);
    
    CGContextSetFillColorWithColor(ctx, [UIColor whiteColor].CGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, image.size.width, image.size.height));
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, x, y);
    
    CGContextConcatCTM(ctx, transform);
    CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    
    return [UIImage imageWithCGImage:cgImage];
}

- (UIImage*) rotateImage:(UIImage *) image byDegree:(double) degree
{
    CGContextRef ctx = CGBitmapContextCreate(nil, image.size.width, image.size.height, CGImageGetBitsPerComponent(image.CGImage), 0, CGImageGetColorSpace(image.CGImage), kCGImageAlphaPremultipliedLast);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, image.size.width / 2, image.size.height / 2);
    transform = CGAffineTransformRotate(transform, M_PI / 180 * degree);
    transform = CGAffineTransformTranslate(transform, -image.size.width / 2, -image.size.height / 2);
    
    CGContextConcatCTM(ctx, transform);
    CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    
    return [UIImage imageWithCGImage:cgImage];
}

- (UIImage*) scaleImage:(UIImage *)image sx:(CGFloat)sx sy:(CGFloat) sy
{
    CGContextRef ctx = CGBitmapContextCreate(nil, image.size.width, image.size.height, CGImageGetBitsPerComponent(image.CGImage), 0, CGImageGetColorSpace(image.CGImage), kCGImageAlphaPremultipliedLast);
    
    CGAffineTransform transform = CGAffineTransformIdentity;
    transform = CGAffineTransformTranslate(transform, -image.size.width * (sx - 1) / 2, -image.size.height * (sy - 1) / 2);
    transform = CGAffineTransformScale(transform, sx, sy);
    
    CGContextConcatCTM(ctx, transform);
    CGContextDrawImage(ctx, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    
    return [UIImage imageWithCGImage:cgImage];
}

- (UIImage*) cropImage:(UIImage *) image toRect:(CGRect) rect
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], rect);
    UIImage *cropped = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return cropped;
}

- (UIImage*) resizeImage:(UIImage *)image toWidth:(CGFloat)width toHeight:(CGFloat)height
{
    CGContextRef ctx = CGBitmapContextCreate(nil, width, height, CGImageGetBitsPerComponent(image.CGImage), 0, CGImageGetColorSpace(image.CGImage), kCGImageAlphaPremultipliedLast);
    
    CGFloat rectWidth;
    CGFloat rectHeight;
    CGFloat rectX;
    CGFloat rectY;
    
    if (image.size.width > image.size.height) {
        rectWidth = width;
        rectHeight = image.size.height * width / image.size.width;
        rectX = 0;
        rectY = height / 2 - rectHeight / 2;
    } else {
        rectWidth = image.size.width * height / image.size.height;
        rectHeight = height;
        rectX = width / 2 - rectWidth / 2;
        rectY = 0;
    }
    CGContextDrawImage(ctx, CGRectMake(rectX, rectY, rectWidth, rectHeight), image.CGImage);

    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    
    return [UIImage imageWithCGImage:cgImage];
}

- (UIImage*) createMaskImageFropShape:(NSArray*)points withWidth:(CGFloat)width height:(CGFloat)height invert:(BOOL)inverted
{
    CGContextRef ctx = CGBitmapContextCreate(nil, width, height, 8, 0, CGColorSpaceCreateWithName(kCGColorSpaceGenericRGB), kCGImageAlphaPremultipliedLast);
    
    NSInteger count = [points count];
    CGPoint cPoints[count];
    
    for (int i = 0; i < count; i++) {
        cPoints[i] = [[points objectAtIndex:i] CGPointValue];
    }
    
    CGColorRef rectCGColor = inverted ? [UIColor whiteColor].CGColor : [UIColor blackColor].CGColor;
    CGColorRef shapeCGColor = inverted ? [UIColor blackColor].CGColor : [UIColor whiteColor].CGColor;
    
    CGContextSetFillColorWithColor(ctx, rectCGColor);
    CGContextFillRect(ctx, CGRectMake(0, 0, width, height));
    
    CGContextSetFillColorWithColor(ctx, shapeCGColor);
    CGContextAddLines(ctx, cPoints, count);
    CGContextFillPath(ctx);
    
    CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
    CGContextRelease(ctx);
    
    return [UIImage imageWithCGImage:cgImage];
}

- (UIImage *) trimTransparentPixels:(UIImage *)image requiringFullOpacity:(BOOL)fullyOpaque
{
    if (image.size.height < 2 || image.size.width < 2) {
        
        return image;
        
    }
    
    CGRect rect = CGRectMake(0, 0, image.size.width * image.scale, image.size.height * image.scale);
    UIEdgeInsets crop = [self transparencyInsets:image requiringFullOpacity:fullyOpaque];
    
    UIImage *img = image;
    
    if (crop.top == 0 && crop.bottom == 0 && crop.left == 0 && crop.right == 0) {
        
        // No cropping needed
        
    } else {
        
        // Calculate new crop bounds
        rect.origin.x += crop.left;
        rect.origin.y += crop.top;
        rect.size.width -= crop.left + crop.right;
        rect.size.height -= crop.top + crop.bottom;
        
        // Crop it
        CGImageRef newImage = CGImageCreateWithImageInRect([image CGImage], rect);
        
        // Convert back to UIImage
        img = [UIImage imageWithCGImage:newImage scale:image.scale orientation:image.imageOrientation];
        
        CGImageRelease(newImage);
    }
    
    return img;
}

- (UIEdgeInsets)transparencyInsets:(UIImage*)image requiringFullOpacity:(BOOL)fullyOpaque
{
    // Draw our image on that context
    NSInteger width  = (NSInteger)CGImageGetWidth([image CGImage]);
    NSInteger height = (NSInteger)CGImageGetHeight([image CGImage]);
    NSInteger bytesPerRow = width * (NSInteger)sizeof(uint8_t);
    
    // Allocate array to hold alpha channel
    uint8_t * bitmapData = calloc((size_t)(width * height), sizeof(uint8_t));
    
    // Create alpha-only bitmap context
    CGContextRef contextRef = CGBitmapContextCreate(bitmapData, (NSUInteger)width, (NSUInteger)height, 8, (NSUInteger)bytesPerRow, NULL, kCGImageAlphaOnly);
    
    CGImageRef cgImage = image.CGImage;
    CGRect rect = CGRectMake(0, 0, width, height);
    CGContextDrawImage(contextRef, rect, cgImage);
    
    // Sum all non-transparent pixels in every row and every column
    uint16_t * rowSum = calloc((size_t)height, sizeof(uint16_t));
    uint16_t * colSum = calloc((size_t)width,  sizeof(uint16_t));
    
    // Enumerate through all pixels
    for (NSInteger row = 0; row < height; row++) {
        
        for (NSInteger col = 0; col < width; col++) {
            
            if (fullyOpaque) {
                
                // Found non-transparent pixel
                if (bitmapData[row*bytesPerRow + col] == UINT8_MAX) {
                    
                    rowSum[row]++;
                    colSum[col]++;
                    
                }
                
            } else {
                
                // Found non-transparent pixel
                if (bitmapData[row*bytesPerRow + col]) {
                    
                    rowSum[row]++;
                    colSum[col]++;
                    
                }
                
            }
            
        }
        
    }
    
    // Initialize crop insets and enumerate cols/rows arrays until we find non-empty columns or row
    UIEdgeInsets crop = UIEdgeInsetsZero;
    
    // Top
    for (NSInteger i = 0; i < height; i++) {
        
        if (rowSum[i] > 0) {
            
            crop.top = i;
            break;
            
        }
        
    }
    
    // Bottom
    for (NSInteger i = height - 1; i >= 0; i--) {
        
        if (rowSum[i] > 0) {
            crop.bottom = MAX(0, height - i - 1);
            break;
        }
        
    }
    
    // Left
    for (NSInteger i = 0; i < width; i++) {
        
        if (colSum[i] > 0) {
            crop.left = i;
            break;
        }
        
    }
    
    // Right
    for (NSInteger i = width - 1; i >= 0; i--) {
        
        if (colSum[i] > 0) {
            
            crop.right = MAX(0, width - i - 1);
            break;
            
        }
    }
    
    free(bitmapData);
    free(colSum);
    free(rowSum);
    
    CGContextRelease(contextRef);
    
    return crop;
}

- (UIImage *) removeTransparencyFromImage:(UIImage *)image {
    CGImageAlphaInfo alpha = CGImageGetAlphaInfo(image.CGImage);
    if (alpha == kCGImageAlphaPremultipliedLast || alpha == kCGImageAlphaPremultipliedFirst ||
        alpha == kCGImageAlphaLast || alpha == kCGImageAlphaFirst || alpha == kCGImageAlphaOnly)
    {
        // create the context with information from the original image
        CGContextRef bitmapContext = CGBitmapContextCreate(NULL,
                                                           image.size.width,
                                                           image.size.height,
                                                           CGImageGetBitsPerComponent(image.CGImage),
                                                           CGImageGetBytesPerRow(image.CGImage),
                                                           CGImageGetColorSpace(image.CGImage),
                                                           CGImageGetBitmapInfo(image.CGImage)
                                                           );
        
        // draw white rect as background
        CGContextSetFillColorWithColor(bitmapContext, [UIColor whiteColor].CGColor);
        CGContextFillRect(bitmapContext, CGRectMake(0, 0, image.size.width, image.size.height));
        
        // draw the image
        CGContextDrawImage(bitmapContext, CGRectMake(0, 0, image.size.width, image.size.height), image.CGImage);
        CGImageRef resultNoTransparency = CGBitmapContextCreateImage(bitmapContext);
        
        // get the image back
        image = [UIImage imageWithCGImage:resultNoTransparency];
        
        // do not forget to release..
        CGImageRelease(resultNoTransparency);
        CGContextRelease(bitmapContext);
    
    }
    return image;
}

@end

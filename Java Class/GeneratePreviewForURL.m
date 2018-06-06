#include <CoreFoundation/CoreFoundation.h>
#include <CoreServices/CoreServices.h>
#include <QuickLook/QuickLook.h>
#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options);
void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview);

/* -----------------------------------------------------------------------------
   Generate a preview for file

   This function's job is to create preview for designated file
   ----------------------------------------------------------------------------- */

OSStatus GeneratePreviewForURL(void *thisInterface, QLPreviewRequestRef preview, CFURLRef url, CFStringRef contentTypeUTI, CFDictionaryRef options)
{
    
    @autoreleasepool {
        
        if (QLPreviewRequestIsCancelled(preview)) {
            return noErr;
        }
        
        NSBundle *bundle = [NSBundle bundleWithIdentifier:@"pl.jhartman.Java-Class"];
        NSURL *javaCliJar = [NSURL fileURLWithPath:[[bundle bundlePath] stringByAppendingPathComponent:@"Contents/Resources/jd-cli-dist/jd-cli.jar"]];

        NSURL *fileName = (__bridge NSURL *)url;
        
        NSPipe *pipe = [NSPipe pipe];
        NSFileHandle *file = pipe.fileHandleForReading;
    
        
        NSTask *task = [[NSTask alloc] init];
        task.launchPath = @"/usr/bin/env";
        task.arguments = @[@"java", @"-jar", javaCliJar.path, @"-g", @"OFF", fileName.path];
        task.standardOutput = pipe;
        
        [task launch];
        [task waitUntilExit];
        
        NSData *data = [file readDataToEndOfFile];
        [file closeFile];
        
        NSString *grepOutput = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        NSMutableString *text = [[NSMutableString alloc] initWithString:grepOutput];
        
        NSDictionary *properties = @{
                                     (__bridge NSString *)kQLPreviewPropertyTextEncodingNameKey : @"UTF-8",
                                     (__bridge NSString *)kQLPreviewPropertyMIMETypeKey : @"text/plain" };
        
        QLPreviewRequestSetDataRepresentation(preview, (__bridge CFDataRef)[text dataUsingEncoding:NSUTF8StringEncoding], kUTTypePlainText, (__bridge CFDictionaryRef)properties);
        
        return noErr;
    }
    
    return noErr;
}

void CancelPreviewGeneration(void *thisInterface, QLPreviewRequestRef preview)
{
    // Implement only if supported
}

//
//  FLEXWebViewController.m
//  Flipboard
//
//  Created by Ryan Olson on 6/10/14.
//  Copyright (c) 2020 FLEX Team. All rights reserved.
//

#import "FLEXWebViewController.h"
#import "FLEXUtility.h"
#import <WebKit/WebKit.h>

@interface FLEXWebViewController () <WKNavigationDelegate>

@property (nonatomic) WKWebView *webView;
@property (nonatomic) NSString *originalText;

@end

@implementation FLEXWebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];

        if (@available(iOS 10.0, *)) {
            configuration.dataDetectorTypes = WKDataDetectorTypeLink;
        }

        self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
        self.webView.navigationDelegate = self;
    }
    return self;
}

- (id)initWithText:(NSString *)text {
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.originalText = text;

        // Loading message
        NSString *loadingHTML = @"<head><style>:root{ color-scheme: light dark; }</style>"
            "<meta name='viewport' content='initial-scale=1.0'></head><body><pre>Loading...</pre></body>";
        [self.webView loadHTMLString:loadingHTML baseURL:nil];

        // Process content on a background thread
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *htmlString = [self htmlStringForText:text];

            // Update webview on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.webView loadHTMLString:htmlString baseURL:nil];
            });
        });
    }

    return self;
}

- (id)initWithURL:(NSURL *)url {
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.webView];
    self.webView.frame = self.view.bounds;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if (self.originalText.length > 0) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
            initWithTitle:@"Copy" style:UIBarButtonItemStylePlain target:self action:@selector(copyButtonTapped:)
        ];
    }
}

- (void)copyButtonTapped:(id)sender {
    [UIPasteboard.generalPasteboard setString:self.originalText];
}


#pragma mark - HTML Generation

- (NSString *)htmlStringForText:(NSString *)text {
    // Try to parse as JSON
    if ([self isValidJSON:text]) {
        return [self htmlStringForJSON:text];
    }
    
    // Try to parse as URL-encoded form data
    if ([self isURLEncodedForm:text]) {
        return [self htmlStringForURLEncodedForm:text];
    }
    
    // Fallback to plain text
    NSString *escapedText = [FLEXUtility stringByEscapingHTMLEntitiesInString:text];
    NSString *html = @"<head><style>:root{ color-scheme: light dark; }</style>"
        "<meta name='viewport' content='initial-scale=1.0'></head><body><pre>%@</pre></body>";
    return [NSString stringWithFormat:html, escapedText];
}

- (BOOL)isValidJSON:(NSString *)string {
    if (string.length == 0) {
        return NO;
    }
    
    NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
    if (!data) {
        return NO;
    }
    
    NSError *error = nil;
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    return (jsonObject != nil && error == nil);
}

- (NSString *)htmlStringForJSON:(NSString *)jsonString {
    // Pretty print JSON first
    NSData *data = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    id jsonObject = [NSJSONSerialization JSONObjectWithData:data options:0 error:nil];
    NSData *prettyData = [NSJSONSerialization dataWithJSONObject:jsonObject
                                                         options:NSJSONWritingPrettyPrinted
                                                           error:nil];
    NSString *prettyJSON = [[NSString alloc] initWithData:prettyData encoding:NSUTF8StringEncoding];
    NSString *escapedJSON = [FLEXUtility stringByEscapingHTMLEntitiesInString:prettyJSON];
    
    NSString *html = @"<html>"
        "<head>"
        "<meta name='viewport' content='initial-scale=1.0'>"
        "<style>"
        ":root { color-scheme: light dark; }"
        "body { margin: 0; padding: 12px; font-family: -apple-system, monospace; font-size: 13px; }"
        "pre { margin: 0; white-space: pre-wrap; word-wrap: break-word; }"
        ".json-key { color: #881391; font-weight: bold; }"
        ".json-string { color: #C41A16; }"
        ".json-number { color: #1C00CF; }"
        ".json-boolean { color: #1C00CF; font-weight: 500; }"
        ".json-null { color: #1C00CF; font-style: italic; }"
        "@media (prefers-color-scheme: dark) {"
        "  .json-key { color: #FF7AB2; }"
        "  .json-string { color: #FF8170; }"
        "  .json-number { color: #D9C97C; }"
        "  .json-boolean { color: #D9C97C; }"
        "  .json-null { color: #D9C97C; }"
        "}"
        "</style>"
        "</head>"
        "<body><pre id='json'>%@</pre>"
        "<script>"
        "function syntaxHighlight() {"
        "  var json = document.getElementById('json').textContent;"
        "  json = json.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');"
        "  json = json.replace(/(\"[^\"]+\")\\s*:/g, '<span class=\"json-key\">$1</span>:');"
        "  json = json.replace(/:\\s*(\"[^\"]*\")/g, ': <span class=\"json-string\">$1</span>');"
        "  json = json.replace(/:\\s*(-?\\d+\\.?\\d*)/g, ': <span class=\"json-number\">$1</span>');"
        "  json = json.replace(/:\\s*(true|false)/g, ': <span class=\"json-boolean\">$1</span>');"
        "  json = json.replace(/:\\s*(null)/g, ': <span class=\"json-null\">$1</span>');"
        "  document.getElementById('json').innerHTML = json;"
        "}"
        "syntaxHighlight();"
        "</script>"
        "</body></html>";
    
    return [NSString stringWithFormat:html, escapedJSON];
}

- (BOOL)isURLEncodedForm:(NSString *)string {
    if (string.length == 0) {
        return NO;
    }
    
    // Check if string contains & and = characters (typical URL-encoded format)
    if ([string containsString:@"="] && [string containsString:@"&"]) {
        // Must have at least 2 parameters
        NSArray *components = [string componentsSeparatedByString:@"&"];
        if (components.count >= 2) {
            // Check if each component has key=value format
            for (NSString *component in components) {
                if (![component containsString:@"="]) {
                    return NO;
                }
            }
            return YES;
        }
    }
    
    return NO;
}

- (NSString *)htmlStringForURLEncodedForm:(NSString *)formString {
    NSMutableString *htmlContent = [NSMutableString string];
    
    // Split by & and process each parameter
    NSArray *parameters = [formString componentsSeparatedByString:@"&"];
    
    for (NSString *param in parameters) {
        NSRange equalRange = [param rangeOfString:@"="];
        if (equalRange.location != NSNotFound) {
            NSString *key = [param substringToIndex:equalRange.location];
            NSString *value = [param substringFromIndex:equalRange.location + 1];
            
            // URL decode
            key = [key stringByRemovingPercentEncoding] ?: key;
            value = [value stringByRemovingPercentEncoding] ?: value;
            
            // Escape HTML
            key = [FLEXUtility stringByEscapingHTMLEntitiesInString:key];
            value = [FLEXUtility stringByEscapingHTMLEntitiesInString:value];
            
            [htmlContent appendFormat:@"<span class=\"param-key\">%@</span>=<span class=\"param-value\">%@</span>\n", key, value];
        }
    }
    
    NSString *html = @"<html>"
        "<head>"
        "<meta name='viewport' content='initial-scale=1.0'>"
        "<style>"
        ":root { color-scheme: light dark; }"
        "body { margin: 0; padding: 12px; font-family: -apple-system, monospace; font-size: 13px; }"
        "pre { margin: 0; white-space: pre-wrap; word-wrap: break-word; line-height: 1.6; }"
        ".param-key { color: #0E6EBE; font-weight: bold; }"
        ".param-value { color: #1C00CF; }"
        "@media (prefers-color-scheme: dark) {"
        "  .param-key { color: #63B4F6; font-weight: bold; }"
        "  .param-value { color: #D9C97C; }"
        "}"
        "</style>"
        "</head>"
        "<body><pre>%@</pre></body></html>";
    
    return [NSString stringWithFormat:html, htmlContent];
}


#pragma mark - WKWebView Delegate

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                                                     decisionHandler:(void (^)(WKNavigationActionPolicy))handler {
    WKNavigationActionPolicy policy = WKNavigationActionPolicyCancel;
    if (navigationAction.navigationType == WKNavigationTypeOther) {
        // Allow the initial load
        policy = WKNavigationActionPolicyAllow;
    } else {
        // For clicked links, push another web view controller onto the navigation stack
        // so that hitting the back button works as expected.
        // Don't allow the current web view to handle the navigation.
        NSURLRequest *request = navigationAction.request;
        FLEXWebViewController *webVC = [[[self class] alloc] initWithURL:request.URL];
        webVC.title = request.URL.absoluteString;
        [self.navigationController pushViewController:webVC animated:YES];
    }

    handler(policy);
}


#pragma mark - Class Helpers

+ (BOOL)supportsPathExtension:(NSString *)extension {
    BOOL supported = NO;
    NSSet<NSString *> *supportedExtensions = [self webViewSupportedPathExtensions];
    if ([supportedExtensions containsObject:extension.lowercaseString]) {
        supported = YES;
    }
    return supported;
}

+ (NSSet<NSString *> *)webViewSupportedPathExtensions {
    static NSSet<NSString *> *pathExtensions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // Note that this is not exhaustive, but all these extensions should work well in the web view.
        // See https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/CreatingContentforSafarioniPhone/CreatingContentforSafarioniPhone.html#//apple_ref/doc/uid/TP40006482-SW7
        pathExtensions = [NSSet<NSString *> setWithArray:@[
            @"jpg", @"jpeg", @"png", @"gif", @"pdf", @"svg", @"tiff", @"3gp", @"3gpp", @"3g2",
            @"3gp2", @"aiff", @"aif", @"aifc", @"cdda", @"amr", @"mp3", @"swa", @"mp4", @"mpeg",
            @"mpg", @"mp3", @"wav", @"bwf", @"m4a", @"m4b", @"m4p", @"mov", @"qt", @"mqv", @"m4v"
        ]];
        
    });

    return pathExtensions;
}

@end

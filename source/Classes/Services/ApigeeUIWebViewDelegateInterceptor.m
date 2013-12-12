//
//  ApigeeUIWebViewDelegateIntercept.m
//  ApigeeAppMonitor
//
//  Copyright (c) 2012 Apigee. All rights reserved.
//

#import "NSDate+Apigee.h"
#import "ApigeeQueue+NetworkMetrics.h"
#import "ApigeeNetworkEntry.h"
#import "ApigeeUIWebViewDelegateInterceptor.h"
#import "ApigeeMonitoringClient.h"

@interface ApigeeUIWebViewDelegateInterceptor()

@property (weak) id<UIWebViewDelegate> target;
@property (assign) uint64_t started;
@property (strong) ApigeeNetworkEntry *networkEntry;
@end

@implementation ApigeeUIWebViewDelegateInterceptor

- (id) initAndInterceptFor:(id<UIWebViewDelegate>) target
{
    self = [super init];
    
    if (self) {
        self.target = target;
        self.networkEntry = [[ApigeeNetworkEntry alloc] init];
    }
    
    return self;
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if (!self.networkEntry) {
        self.networkEntry = [[ApigeeNetworkEntry alloc] init];
    }
    
    [self.networkEntry populateWithRequest:request];

    if ( self.target && [self.target respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)]) {
        return [self.target webView:(UIWebView *)webView shouldStartLoadWithRequest:request navigationType:navigationType];
    }

    return YES;
}

- (void) webViewDidStartLoad:(UIWebView *) webView
{
    self.started = [ApigeeNetworkEntry machTime];
    
    if (self.target && [self.target respondsToSelector:@selector(webViewDidStartLoad:)]) {
        [self.target webViewDidStartLoad:webView];
    }
}

- (void) webViewDidFinishLoad:(UIWebView *) webView
{
    uint64_t ended = [ApigeeNetworkEntry machTime];
    
    if (self.target && [self.target respondsToSelector:@selector(webViewDidFinishLoad:)]) {
        [self.target webViewDidFinishLoad:webView];
    }
    
    ApigeeMonitoringClient* monitoringClient = [ApigeeMonitoringClient sharedInstance];
    if (![monitoringClient isPaused]) {
        [self.networkEntry populateStartTime:self.started ended:ended];
        [monitoringClient recordNetworkEntry:self.networkEntry];
    }
    
    self.networkEntry = nil;
}

- (void) webView:(UIWebView *) webView didFailLoadWithError:(NSError *) error
{
    uint64_t ended = [ApigeeNetworkEntry machTime];
    
    if (self.target && [self.target respondsToSelector:@selector(webView:didFailLoadWithError:)]) {
        [self.target webView:webView didFailLoadWithError:error];
    }
    
    ApigeeMonitoringClient* monitoringClient = [ApigeeMonitoringClient sharedInstance];
    if (![monitoringClient isPaused]) {
        [self.networkEntry populateWithError:error];
        [self.networkEntry populateStartTime:self.started ended:ended];
        [monitoringClient recordNetworkEntry:self.networkEntry];
    }
    
    self.networkEntry = nil;
}


@end

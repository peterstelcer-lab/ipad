#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <math.h>

@interface YTController : UIViewController <WKNavigationDelegate,WKUIDelegate,UIGestureRecognizerDelegate>
@property(nonatomic,strong) WKWebView *web;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UIProgressView *progress;
@property(nonatomic,strong) UIActivityIndicatorView *loading;
@property(nonatomic,strong) UIButton *backBtn,*nextBtn;
@property(nonatomic,strong) MPVolumeView *volumeView;
@property(nonatomic,weak) UISlider *volumeSlider;
@property(nonatomic,strong) UILabel *gestureHUD;
@property(nonatomic,strong) NSMutableArray<UIPanGestureRecognizer *> *edgeGestures;
@property(nonatomic,assign) BOOL draggingBrightness;
@property(nonatomic,assign) CGFloat dragOriginY,dragOriginValue;
@end
@implementation YTController
- (UIColor *)backgroundColor{return [UIColor colorWithRed:.035 green:.08 blue:.11 alpha:1];}
- (UIColor *)accentColor{return [UIColor colorWithRed:.12 green:.85 blue:.80 alpha:1];}
- (UIButton *)button:(NSString *)name selector:(SEL)sel {
 UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
 [b setTitle:name forState:UIControlStateNormal];[b setTitleColor:[self accentColor] forState:UIControlStateNormal];
 b.titleLabel.font=[UIFont boldSystemFontOfSize:14]; b.backgroundColor=[UIColor colorWithRed:.07 green:.16 blue:.2 alpha:1];
 b.layer.cornerRadius=5;[b addTarget:self action:sel forControlEvents:UIControlEventTouchUpInside];
 return b;
}
- (void)viewDidLoad {
 [super viewDidLoad];self.view.backgroundColor=[self backgroundColor];
 WKWebViewConfiguration *cfg=[WKWebViewConfiguration new];
 cfg.allowsInlineMediaPlayback=YES;
 cfg.mediaTypesRequiringUserActionForPlayback=WKAudiovisualMediaTypeAll;
 self.web=[[WKWebView alloc] initWithFrame:CGRectZero configuration:cfg];
 self.web.navigationDelegate=self;self.web.UIDelegate=self;self.web.allowsBackForwardNavigationGestures=YES;
 self.web.scrollView.backgroundColor=[UIColor blackColor];
 self.web.opaque=NO;self.web.backgroundColor=[UIColor blackColor];
 [self.view addSubview:self.web];
 self.backBtn=[self button:@"‹ SPÄŤ" selector:@selector(goBack)];
 self.nextBtn=[self button:@"ĎALEJ ›" selector:@selector(goForward)];
 NSArray *others=@[self.backBtn,self.nextBtn,
 [self button:@"DOMOV" selector:@selector(goHome)],
 [self button:@"OBNOVIŤ" selector:@selector(reload)],
 [self button:@"SAFARI" selector:@selector(openSafari)],
 [self button:@"MOJE ▾" selector:@selector(openPersonalMenu)]];
 for(NSInteger i=0;i<others.count;i++){UIButton *b=others[i];b.tag=100+i;[self.view addSubview:b];}
 self.status=[UILabel new];self.status.textColor=[UIColor colorWithWhite:.85 alpha:1];
 self.status.font=[UIFont systemFontOfSize:12];self.status.text=@"YouTube Web • pripravené";self.status.numberOfLines=1;self.status.textAlignment=NSTextAlignmentRight;self.status.adjustsFontSizeToFitWidth=YES;
 [self.view addSubview:self.status];
 self.progress=[UIProgressView new];self.progress.progressTintColor=[self accentColor];[self.view addSubview:self.progress];
 self.loading=[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhite];[self.view addSubview:self.loading];
 [self configureEdgeControls];
 [self goHome];
}
- (void)viewDidLayoutSubviews {
 [super viewDidLayoutSubviews];
 CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height;
 CGFloat top=self.view.safeAreaInsets.top,bottom=self.view.safeAreaInsets.bottom;
 CGFloat margin=8,gap=5,toolbarHeight=28,topY=top+3;
 CGFloat widths[]={76,76,69,90,70,89};
 CGFloat total=0;for(NSInteger i=0;i<6;i++)total+=widths[i];
 CGFloat statusWidth=MIN(210,MAX(90,w*.22));
 CGFloat scale=MIN(1,MAX(.70,(w-2*margin-statusWidth-20-5*gap)/total));
 CGFloat x=margin;
 for(NSInteger i=0;i<6;i++){
  CGFloat cw=widths[i]*scale;
  [self.view viewWithTag:100+i].frame=CGRectMake(x,topY,cw,toolbarHeight);
  x+=cw+gap;
 }
 CGFloat statusX=MAX(x+4,w-statusWidth-8);
 self.loading.frame=CGRectMake(statusX,topY+6,16,16);
 self.status.frame=CGRectMake(statusX+19,topY+2,MAX(15,w-statusX-27),toolbarHeight-2);
 self.progress.frame=CGRectMake(0,topY+toolbarHeight+2,w,2);
 CGFloat webY=topY+toolbarHeight+5;
 self.web.frame=CGRectMake(0,webY,w,MAX(100,h-webY-bottom));
}
// Version 1.2: Vertical gestures starting in the outer 10% of the video.
// Left: screen brightness. Right: system volume through public MPVolumeView API.
- (void)configureEdgeControls {
 self.edgeGestures=[NSMutableArray new];
 self.volumeView=[[MPVolumeView alloc] initWithFrame:CGRectMake(-300,-300,180,30)];
 self.volumeView.showsRouteButton=NO;
 self.volumeView.showsVolumeSlider=YES;
 [self.view addSubview:self.volumeView];
 self.gestureHUD=[[UILabel alloc] initWithFrame:CGRectZero];
 self.gestureHUD.backgroundColor=[UIColor colorWithWhite:0 alpha:.80];
 self.gestureHUD.textColor=[UIColor whiteColor];
 self.gestureHUD.font=[UIFont boldSystemFontOfSize:22];
 self.gestureHUD.textAlignment=NSTextAlignmentCenter;
 self.gestureHUD.layer.cornerRadius=12;
 self.gestureHUD.clipsToBounds=YES;
 self.gestureHUD.alpha=0;
 self.gestureHUD.userInteractionEnabled=NO;
 [self.view addSubview:self.gestureHUD];
 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoWindowBecameVisible:)
    name:UIWindowDidBecomeVisibleNotification object:nil];
}
- (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 for(UIWindow *window in UIApplication.sharedApplication.windows) [self installEdgeGesture:window];
}
- (void)videoWindowBecameVisible:(NSNotification *)notification {
 if([notification.object isKindOfClass:[UIWindow class]]) [self installEdgeGesture:notification.object];
}
- (void)installEdgeGesture:(UIWindow *)window {
 if(!window || window.screen!=UIScreen.mainScreen) return;
 NSString *windowClass=NSStringFromClass([window class]);
 if([windowClass rangeOfString:@"Keyboard" options:NSCaseInsensitiveSearch].location!=NSNotFound ||
    [windowClass rangeOfString:@"TextEffects" options:NSCaseInsensitiveSearch].location!=NSNotFound) return;
 for(UIPanGestureRecognizer *g in self.edgeGestures) if(g.view==window) return;
 UIPanGestureRecognizer *gesture=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleEdgeDrag:)];
 gesture.delegate=self;
 gesture.maximumNumberOfTouches=1;
 gesture.cancelsTouchesInView=YES;
 [window addGestureRecognizer:gesture];
 [self.edgeGestures addObject:gesture];
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
 UIView *host=gesture.view;
 if(!host) return NO;
 CGPoint start=[touch locationInView:host];
 CGFloat width=CGRectGetWidth(host.bounds);
 CGFloat edge=MIN(95,MAX(46,width*.11));
 // Keep our toolbar completely interactive in the regular application window.
 if(host==self.view.window && start.y<CGRectGetMinY(self.web.frame)) return NO;
 return start.x<=edge || start.x>=width-edge;
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture {
 UIPanGestureRecognizer *pan=(UIPanGestureRecognizer *)gesture;
 CGPoint v=[pan velocityInView:gesture.view];
 return fabs(v.y)>fabs(v.x)*1.2;
}
- (UISlider *)locateSlider:(UIView *)view {
 if([view isKindOfClass:[UISlider class]]) return (UISlider *)view;
 for(UIView *child in view.subviews) {
  UISlider *found=[self locateSlider:child];
  if(found) return found;
 }
 return nil;
}
- (UISlider *)systemVolumeSlider {
 UISlider *slider=self.volumeSlider;
 if(!slider) {
  [self.volumeView layoutIfNeeded];
  slider=[self locateSlider:self.volumeView];
  self.volumeSlider=slider;
 }
 return slider;
}
- (void)displayGestureHUD:(NSString *)message inWindow:(UIWindow *)window {
 if(!window) window=self.view.window;
 if(!window) return;
 if(self.gestureHUD.superview!=window) {
  [self.gestureHUD removeFromSuperview];
  [window addSubview:self.gestureHUD];
 }
 CGFloat width=MIN(290,CGRectGetWidth(window.bounds)-30);
 self.gestureHUD.frame=CGRectMake((CGRectGetWidth(window.bounds)-width)/2,
      (CGRectGetHeight(window.bounds)-65)/2,width,65);
 self.gestureHUD.text=message;
 [window bringSubviewToFront:self.gestureHUD];
 [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideGestureHUD) object:nil];
 self.gestureHUD.alpha=1;
}
- (void)hideGestureHUD {
 [UIView animateWithDuration:.25 animations:^{ self.gestureHUD.alpha=0; }];
}
- (void)handleEdgeDrag:(UIPanGestureRecognizer *)pan {
 UIWindow *window=[pan.view isKindOfClass:[UIWindow class]]?(UIWindow *)pan.view:self.view.window;
 CGPoint point=[pan locationInView:pan.view];
 if(pan.state==UIGestureRecognizerStateBegan) {
  self.draggingBrightness=point.x<CGRectGetMidX(pan.view.bounds);
  self.dragOriginY=point.y;
  self.dragOriginValue=self.draggingBrightness?UIScreen.mainScreen.brightness:[self systemVolumeSlider].value;
 }
 if(pan.state==UIGestureRecognizerStateBegan || pan.state==UIGestureRecognizerStateChanged ||
    pan.state==UIGestureRecognizerStateEnded) {
  CGFloat span=MAX(180,CGRectGetHeight(pan.view.bounds)*.7);
  CGFloat value=MAX(0,MIN(1,self.dragOriginValue+(self.dragOriginY-point.y)/span));
  if(self.draggingBrightness) {
   UIScreen.mainScreen.brightness=value;
   [self displayGestureHUD:[NSString stringWithFormat:@"JAS  %ld %%",(long)lround(value*100)] inWindow:window];
  } else {
   UISlider *slider=[self systemVolumeSlider];
   if(slider) {
    [slider setValue:value animated:NO];
    [slider sendActionsForControlEvents:UIControlEventValueChanged];
    [self displayGestureHUD:[NSString stringWithFormat:@"HLASITOSŤ  %ld %%",(long)lround(value*100)] inWindow:window];
   } else {
    [self displayGestureHUD:@"HLASITOSŤ: nedostupná" inWindow:window];
   }
  }
 }
 if(pan.state==UIGestureRecognizerStateEnded || pan.state==UIGestureRecognizerStateCancelled ||
    pan.state==UIGestureRecognizerStateFailed)
  [self performSelector:@selector(hideGestureHUD) withObject:nil afterDelay:1.0];
}
- (void)dealloc {
 [[NSNotificationCenter defaultCenter] removeObserver:self];
 [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideGestureHUD) object:nil];
}
- (void)sync {
 self.backBtn.enabled=self.web.canGoBack;self.nextBtn.enabled=self.web.canGoForward;
 self.backBtn.alpha=self.backBtn.enabled?1:.35;self.nextBtn.alpha=self.nextBtn.enabled?1:.35;
 self.progress.progress=self.web.estimatedProgress;
}
- (void)goHome {NSURL *u=[NSURL URLWithString:@"https://m.youtube.com/"];[self.web loadRequest:[NSURLRequest requestWithURL:u cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30]];}
- (void)reload {[self.web reload];}
- (void)openPersonalPath:(NSString *)path {
 NSURL *u=[NSURL URLWithString:[@"https://m.youtube.com" stringByAppendingString:path]];
 if(u)[self.web loadRequest:[NSURLRequest requestWithURL:u cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30]];
}
- (void)openPersonalMenu {
 UIAlertController *menu=[UIAlertController alertControllerWithTitle:@"Moje videá na YouTube"
  message:@"Otvoria sa príslušné stránky YouTube. Dostupnosť súkromných zoznamov závisí od prihlásenia v tomto okne." preferredStyle:UIAlertControllerStyleActionSheet];
 NSArray *labels=@[@"História",@"Pozrieť neskôr",@"Páči sa mi",@"Playlisty",@"Odbery"];
 NSArray *paths=@[@"/feed/history",@"/playlist?list=WL",@"/playlist?list=LL",@"/feed/playlists",@"/feed/subscriptions"];
 for(NSInteger i=0;i<labels.count;i++){
  NSString *path=paths[i];
  [menu addAction:[UIAlertAction actionWithTitle:labels[i] style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){[self openPersonalPath:path];}]];
 }
 [menu addAction:[UIAlertAction actionWithTitle:@"OTVORIŤ V SAFARI" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){[self openSafari];}]];
 [menu addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
 UIPopoverPresentationController *pop=menu.popoverPresentationController;
 UIView *origin=[self.view viewWithTag:105];
 if(pop){pop.sourceView=origin;pop.sourceRect=origin.bounds;}
 [self presentViewController:menu animated:YES completion:nil];
}
- (void)goBack {if(self.web.canGoBack)[self.web goBack];}
- (void)goForward {if(self.web.canGoForward)[self.web goForward];}
- (void)openSafari {
 NSURL *url=self.web.URL?:[NSURL URLWithString:@"https://m.youtube.com/"];
 if(![@[@"https",@"http"] containsObject:url.scheme])url=[NSURL URLWithString:@"https://m.youtube.com/"];
 [[UIApplication sharedApplication] openURL:url options:@{} completionHandler:nil];
}
- (void)webView:(WKWebView *)web didStartProvisionalNavigation:(WKNavigation *)nav {
 self.status.text=@"Načítavam YouTube...";[self.loading startAnimating];[self sync];
}
- (void)webView:(WKWebView *)web didFinishNavigation:(WKNavigation *)nav {
 [self.loading stopAnimating];self.status.text=@"Pripravené";[self sync];self.progress.progress=0;
}
- (void)webView:(WKWebView *)web didFailNavigation:(WKNavigation *)nav withError:(NSError *)error {
 [self failed:error];
}
- (void)webView:(WKWebView *)web didFailProvisionalNavigation:(WKNavigation *)nav withError:(NSError *)error {
 [self failed:error];
}
- (void)failed:(NSError *)error {
 [self.loading stopAnimating];[self sync];
 self.status.text=[NSString stringWithFormat:@"Načítanie zlyhalo: %@",error.localizedDescription?:@"neznáma chyba"];
}
- (void)webView:(WKWebView *)web decidePolicyForNavigationAction:(WKNavigationAction *)action decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
 NSURL *url=action.request.URL; NSString *scheme=url.scheme.lowercaseString;
 if([@[@"http",@"https"] containsObject:scheme])decisionHandler(WKNavigationActionPolicyAllow);
 else decisionHandler(WKNavigationActionPolicyCancel);
}
- (WKWebView *)webView:(WKWebView *)web createWebViewWithConfiguration:(WKWebViewConfiguration *)cfg forNavigationAction:(WKNavigationAction *)action windowFeatures:(WKWindowFeatures *)features {
 NSURL *url=action.request.URL;
 if(!action.targetFrame && [@[@"http",@"https"] containsObject:url.scheme.lowercaseString])[self.web loadRequest:[NSURLRequest requestWithURL:url]];
 return nil;
}
@end

@interface YTAppDelegate : UIResponder <UIApplicationDelegate>
@property(strong,nonatomic) UIWindow *window;
@end
@implementation YTAppDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
 self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
 self.window.rootViewController=[YTController new];[self.window makeKeyAndVisible];return YES;
}
@end
int main(int argc,char **argv){@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass(YTAppDelegate.class));}}

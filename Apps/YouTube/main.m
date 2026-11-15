#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <math.h>

// A transparent, non-key overlay remains in front of fullscreen WebKit video.
// Touches outside the narrow left/right strips pass through to YouTube.
@interface YTEdgeWindow : UIWindow
@property(nonatomic,assign) CGFloat stripWidth;
@end
@implementation YTEdgeWindow
- (UIView *)hitTest:(CGPoint)point withEvent:(UIEvent *)event {
 CGFloat width=CGRectGetWidth(self.bounds),height=CGRectGetHeight(self.bounds);
 if(point.y<48 || point.y>height-18) return nil; // top toolbar and home controls
 if(point.x>self.stripWidth && point.x<width-self.stripWidth) return nil;
 return [super hitTest:point withEvent:event];
}
@end

@interface YTController : UIViewController <WKNavigationDelegate,WKUIDelegate,UIGestureRecognizerDelegate>
@property(nonatomic,strong) WKWebView *web;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UIProgressView *progress;
@property(nonatomic,strong) UIActivityIndicatorView *loading;
@property(nonatomic,strong) UIButton *backBtn,*nextBtn;
@property(nonatomic,strong) MPVolumeView *volumeView;
@property(nonatomic,weak) UISlider *volumeSlider;
@property(nonatomic,strong) UILabel *gestureHUD;
@property(nonatomic,strong) YTEdgeWindow *edgeWindow;
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
 // Keep MPVolumeView inside the live view hierarchy, but behind the WebKit canvas.
 self.volumeView.frame=CGRectMake(8,webY+12,180,32);
}
// Version 1.3: narrow touch zones above the fullscreen video window.
- (void)configureEdgeControls {
 // Media volume is controlled using the system MPVolumeView slider (no private APIs).
 self.volumeView=[[MPVolumeView alloc] initWithFrame:CGRectMake(8,90,180,32)];
 self.volumeView.showsRouteButton=NO;
 self.volumeView.showsVolumeSlider=YES;
 self.volumeView.userInteractionEnabled=NO;
 // Displayed behind the web view, rather than offscreen as in V1.2.
 [self.view insertSubview:self.volumeView belowSubview:self.web];

 self.edgeWindow=[[YTEdgeWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
 self.edgeWindow.stripWidth=58;
 self.edgeWindow.backgroundColor=[UIColor clearColor];
 self.edgeWindow.opaque=NO;
 self.edgeWindow.windowLevel=UIWindowLevelAlert+5;
 UIViewController *root=[UIViewController new];
 root.view.backgroundColor=[UIColor clearColor];
 root.view.opaque=NO;
 self.edgeWindow.rootViewController=root;
 UIPanGestureRecognizer *pan=[[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(handleEdgeDrag:)];
 pan.maximumNumberOfTouches=1;
 pan.delegate=self;
 pan.cancelsTouchesInView=YES;
 [root.view addGestureRecognizer:pan];

 self.gestureHUD=[UILabel new];
 self.gestureHUD.backgroundColor=[UIColor colorWithWhite:0 alpha:.84];
 self.gestureHUD.textColor=[UIColor whiteColor];
 self.gestureHUD.font=[UIFont boldSystemFontOfSize:22];
 self.gestureHUD.textAlignment=NSTextAlignmentCenter;
 self.gestureHUD.layer.cornerRadius=12;
 self.gestureHUD.clipsToBounds=YES;
 self.gestureHUD.userInteractionEnabled=NO;
 self.gestureHUD.alpha=0;
 [root.view addSubview:self.gestureHUD];

 // Subtle edge grips make it clear where a gesture can start.
 for(NSInteger side=0;side<2;side++) {
  UIView *grip=[[UIView alloc] initWithFrame:CGRectZero];
  grip.tag=701+side;grip.userInteractionEnabled=NO;
  grip.backgroundColor=[[self accentColor] colorWithAlphaComponent:.55];
  grip.layer.cornerRadius=2;
  [root.view addSubview:grip];
 }

 [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateEdgeWindow)
  name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}
- (void)viewDidAppear:(BOOL)animated {
 [super viewDidAppear:animated];
 [self updateEdgeWindow];
}
- (void)updateEdgeWindow {
 if(!self.edgeWindow) return;
 self.edgeWindow.frame=UIScreen.mainScreen.bounds;
 UIView *root=self.edgeWindow.rootViewController.view;
 CGFloat w=CGRectGetWidth(root.bounds),h=CGRectGetHeight(root.bounds);
 CGFloat gripY=(h-66)/2;
 [root viewWithTag:701].frame=CGRectMake(2,gripY,3,66);
 [root viewWithTag:702].frame=CGRectMake(w-5,gripY,3,66);
 if(self.gestureHUD.alpha>0) [self layoutGestureHUD];
 // Do not call makeKeyAndVisible: the original main app window must remain key.
 self.edgeWindow.hidden=NO;
}
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gesture shouldReceiveTouch:(UITouch *)touch {
 UIView *v=gesture.view;
 if(!v) return NO;
 CGPoint p=[touch locationInView:v];
 CGFloat w=CGRectGetWidth(v.bounds),h=CGRectGetHeight(v.bounds);
 return p.y>=48 && p.y<=h-18 && (p.x<=self.edgeWindow.stripWidth || p.x>=w-self.edgeWindow.stripWidth);
}
- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gesture {
 UIPanGestureRecognizer *pan=(UIPanGestureRecognizer *)gesture;
 CGPoint translation=[pan translationInView:gesture.view];
 return fabs(translation.y)>fabs(translation.x)*1.10;
}
- (UISlider *)findSystemSlider:(UIView *)view {
 if([view isKindOfClass:[UISlider class]]) return (UISlider *)view;
 for(UIView *child in view.subviews) {
  UISlider *slider=[self findSystemSlider:child];
  if(slider) return slider;
 }
 return nil;
}
- (UISlider *)systemVolumeSlider {
 UISlider *slider=self.volumeSlider;
 if(!slider) {
  [self.volumeView layoutIfNeeded];
  slider=[self findSystemSlider:self.volumeView];
  self.volumeSlider=slider;
 }
 return slider;
}
- (void)layoutGestureHUD {
 UIView *v=self.edgeWindow.rootViewController.view;
 CGFloat w=CGRectGetWidth(v.bounds),h=CGRectGetHeight(v.bounds);
 CGFloat hudWidth=MIN(290,w-40);
 self.gestureHUD.frame=CGRectMake((w-hudWidth)/2,(h-64)/2,hudWidth,64);
 [v bringSubviewToFront:self.gestureHUD];
}
- (void)showGestureHUD:(NSString *)message {
 [self layoutGestureHUD];
 self.gestureHUD.text=message;
 [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideGestureHUD) object:nil];
 self.gestureHUD.alpha=1;
}
- (void)hideGestureHUD {
 [UIView animateWithDuration:.20 animations:^{ self.gestureHUD.alpha=0; }];
}
- (void)handleEdgeDrag:(UIPanGestureRecognizer *)pan {
 UIView *v=pan.view;
 if(!v) return;
 CGPoint current=[pan locationInView:v];
 CGPoint translation=[pan translationInView:v];
 if(pan.state==UIGestureRecognizerStateBegan) {
  CGFloat firstX=current.x-translation.x;
  self.draggingBrightness=firstX<CGRectGetMidX(v.bounds);
  self.dragOriginValue=self.draggingBrightness?UIScreen.mainScreen.brightness:[self systemVolumeSlider].value;
 }
 if(pan.state==UIGestureRecognizerStateBegan || pan.state==UIGestureRecognizerStateChanged ||
    pan.state==UIGestureRecognizerStateEnded) {
  CGFloat range=MAX(175,CGRectGetHeight(v.bounds)*.60);
  CGFloat value=MAX(0,MIN(1,self.dragOriginValue-translation.y/range));
  if(self.draggingBrightness) {
   UIScreen.mainScreen.brightness=value;
   [self showGestureHUD:[NSString stringWithFormat:@"☀ JAS  %ld %%",(long)lround(value*100)]];
  } else {
   UISlider *slider=[self systemVolumeSlider];
   if(slider) {
    [slider setValue:value animated:NO];
    [slider sendActionsForControlEvents:UIControlEventValueChanged];
    [self showGestureHUD:[NSString stringWithFormat:@"♪ HLASITOSŤ  %ld %%",(long)lround(value*100)]];
   } else {
    [self showGestureHUD:@"HLASITOSŤ: nedostupná"];
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

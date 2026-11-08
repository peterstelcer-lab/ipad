#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
static inline UIColor* C(int x){return [UIColor colorWithRed:((x>>16)&255)/255. green:((x>>8)&255)/255. blue:(x&255)/255. alpha:1];}
static inline UILabel* L(NSString*s,int n){UILabel*v=[UILabel new];v.text=s;v.textColor=UIColor.whiteColor;v.font=[UIFont systemFontOfSize:n];v.numberOfLines=2;return v;}
static inline UIButton* B(NSString*s,id t,SEL a,int tag){UIButton*b=[UIButton buttonWithType:UIButtonTypeSystem];[b setTitle:s forState:UIControlStateNormal];b.tag=tag;b.backgroundColor=C(0x173544);[b setTitleColor:C(0x42D5BE) forState:UIControlStateNormal];b.titleLabel.font=[UIFont boldSystemFontOfSize:13];b.layer.cornerRadius=9;[b addTarget:t action:a forControlEvents:UIControlEventTouchUpInside];return b;}
static inline void A(UIViewController*v,NSString*t,NSString*m){UIAlertController*a=[UIAlertController alertControllerWithTitle:t message:m preferredStyle:UIAlertControllerStyleAlert];[a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];[v presentViewController:a animated:YES completion:nil];}
static inline NSString* Shared(void){NSString*p=@"/var/mobile/Documents/NebulaShared";[[NSFileManager defaultManager] createDirectoryAtPath:p withIntermediateDirectories:YES attributes:nil error:nil];if(![[NSFileManager defaultManager] isWritableFileAtPath:p])p=[NSHomeDirectory() stringByAppendingPathComponent:@"Documents"];return p;}
@interface D : UIResponder <UIApplicationDelegate>
@property(nonatomic,strong) UIWindow*window;
@end

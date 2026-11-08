#import <UIKit/UIKit.h>
#import <math.h>

@interface TCScientificController : UIViewController @end
@interface TCUnitsController : UIViewController @end

@interface TechCalcController : UIViewController
@property(nonatomic,strong) UILabel *expression,*display,*memoryIndicator,*errorLabel;
@property(nonatomic,strong) UIView *displayPanel;
@property(nonatomic,strong) NSMutableArray *buttons;
@property(nonatomic,copy) NSString *entry,*pending,*repeatOperator;
@property(nonatomic,strong) NSDecimalNumber *lhs,*repeatArgument,*memory,*lastAnswer;
@property(nonatomic,assign) BOOL nextEntry,hasLhs,justEqual;
@end

@implementation TechCalcController
- (UIColor *)bg{return [UIColor colorWithRed:.018 green:.058 blue:.079 alpha:1];}
- (UIColor *)panel{return [UIColor colorWithRed:.052 green:.13 blue:.17 alpha:1];}
- (UIColor *)face{return [UIColor colorWithRed:.10 green:.20 blue:.25 alpha:1];}
- (UIColor *)accent{return [UIColor colorWithRed:.10 green:.88 blue:.82 alpha:1];}
- (UIColor *)pale{return [UIColor colorWithRed:.9 green:.96 blue:.99 alpha:1];}
- (UILabel *)label:(NSString *)name font:(CGFloat)size color:(UIColor *)color {
 UILabel *l=[UILabel new];l.text=name;l.font=[UIFont systemFontOfSize:size];l.textColor=color;return l;
}
- (void)viewDidLoad {
 [super viewDidLoad];self.view.backgroundColor=self.bg;
 self.displayPanel=[UIView new];self.displayPanel.backgroundColor=self.panel;self.displayPanel.layer.cornerRadius=14;
 self.displayPanel.layer.borderColor=[self.accent colorWithAlphaComponent:.28].CGColor;
 self.displayPanel.layer.borderWidth=1;[self.view addSubview:self.displayPanel];
 self.expression=[self label:@"" font:20 color:self.accent];
 self.expression.textAlignment=NSTextAlignmentRight;self.expression.adjustsFontSizeToFitWidth=YES;
 [self.displayPanel addSubview:self.expression];
 self.display=[self label:@"0" font:64 color:UIColor.whiteColor];
 self.display.textAlignment=NSTextAlignmentRight;
 self.display.font=[UIFont monospacedDigitSystemFontOfSize:64 weight:UIFontWeightLight];
 self.display.adjustsFontSizeToFitWidth=YES;self.display.minimumScaleFactor=.33;
 [self.displayPanel addSubview:self.display];
 self.memoryIndicator=[self label:@"" font:15 color:self.accent];
 self.memoryIndicator.font=[UIFont boldSystemFontOfSize:15];
 [self.displayPanel addSubview:self.memoryIndicator];
 self.errorLabel=[self label:@"" font:14 color:[UIColor colorWithRed:.96 green:.69 blue:.29 alpha:1]];
 self.errorLabel.textAlignment=NSTextAlignmentRight;[self.displayPanel addSubview:self.errorLabel];
 NSArray *rows=@[
 @[@"MC",@"MR",@"M+",@"M−",@"⌫"],
 @[@"C",@"CE",@"%",@"√x",@"x²"],
 @[@"7",@"8",@"9",@"÷",@"1/x"],
 @[@"4",@"5",@"6",@"×",@"±"],
 @[@"1",@"2",@"3",@"−",@"ANS"],
 @[@"0",@",",@"00",@"+",@"="]
 ];
 self.buttons=[NSMutableArray array];
 for(NSArray *row in rows)for(NSString *name in row){
  UIButton *button=[UIButton buttonWithType:UIButtonTypeSystem];
  [button setTitle:name forState:UIControlStateNormal];[button setTitleColor:self.pale forState:UIControlStateNormal];
  button.titleLabel.font=[UIFont boldSystemFontOfSize:34];
  button.titleLabel.adjustsFontSizeToFitWidth=YES;
  button.backgroundColor=self.face;button.layer.cornerRadius=8;
  button.layer.borderWidth=.8;button.layer.borderColor=[[UIColor colorWithWhite:1 alpha:.08] CGColor];
  if([@[@"+",@"−",@"×",@"÷"] containsObject:name]){
   button.backgroundColor=[UIColor colorWithRed:.015 green:.41 blue:.45 alpha:1];
   button.titleLabel.font=[UIFont boldSystemFontOfSize:38];
   [button setTitleColor:self.accent forState:UIControlStateNormal];
  }else if([name isEqualToString:@"="]){
   button.backgroundColor=[UIColor colorWithRed:.98 green:.66 blue:.13 alpha:1];[button setTitleColor:self.bg forState:UIControlStateNormal];
   button.titleLabel.font=[UIFont boldSystemFontOfSize:38];
  }else if([@[@"MC",@"MR",@"M+",@"M−",@"⌫",@"C",@"CE",@"%",@"√x",@"x²",@"1/x",@"ANS",@"±"] containsObject:name]){
   button.titleLabel.font=[UIFont boldSystemFontOfSize:27];
   [button setTitleColor:[UIColor colorWithRed:.99 green:.78 blue:.43 alpha:1] forState:UIControlStateNormal];
   button.backgroundColor=[UIColor colorWithRed:.065 green:.15 blue:.19 alpha:1];
  }
  if([name isEqualToString:@"C"]){
   button.backgroundColor=[UIColor colorWithRed:.83 green:.12 blue:.15 alpha:1];
   button.layer.borderColor=[UIColor colorWithRed:1 green:.46 blue:.40 alpha:1].CGColor;
   button.layer.borderWidth=1.5;
   [button setTitleColor:UIColor.whiteColor forState:UIControlStateNormal];
   button.titleLabel.font=[UIFont boldSystemFontOfSize:37];
  }
  button.accessibilityLabel=name;
  [button addTarget:self action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:button];[self.buttons addObject:button];
 }
 self.memory=[NSDecimalNumber zero];self.lastAnswer=[NSDecimalNumber zero];[self clearAll];
}
- (void)viewDidLayoutSubviews {
 [super viewDidLayoutSubviews];
 CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height;
 CGFloat margin=12;
 CGFloat gridWidth=MIN(w-2*margin,920);
 CGFloat left=(w-gridWidth)/2;
 CGFloat displayHeight=MIN(150,MAX(120,h*.21));
 self.displayPanel.frame=CGRectMake(left,3,gridWidth,displayHeight);
 CGFloat sw=self.displayPanel.bounds.size.width;
 self.expression.frame=CGRectMake(16,8,sw-32,30);
 self.display.frame=CGRectMake(16,31,sw-32,displayHeight-52);
 self.memoryIndicator.frame=CGRectMake(17,displayHeight-22,117,19);
 self.errorLabel.frame=CGRectMake(145,displayHeight-22,MAX(0,sw-164),19);
 CGFloat start=displayHeight+13,gap=8;
 CGFloat freeHeight=MAX(280,h-start-10);
 CGFloat cellWidth=(gridWidth-4*gap)/5;
 CGFloat cellHeight=MIN(91,(freeHeight-5*gap)/6);
 for(NSInteger i=0;i<self.buttons.count;i++){
  NSInteger row=i/5,col=i%5;
  UIButton *button=self.buttons[i];
  button.frame=CGRectMake(left+col*(cellWidth+gap),start+row*(cellHeight+gap),cellWidth,cellHeight);
 }
}
- (NSDecimalNumberHandler *)rule{
 return [NSDecimalNumberHandler decimalNumberHandlerWithRoundingMode:NSRoundPlain scale:12 raiseOnExactness:NO raiseOnOverflow:NO raiseOnUnderflow:NO raiseOnDivideByZero:NO];
}
- (BOOL)bad:(NSDecimalNumber *)n {
 return !n||[n isEqualToNumber:[NSDecimalNumber notANumber]];
}
- (NSDecimalNumber *)current{
 NSDecimalNumber *n=[NSDecimalNumber decimalNumberWithString:self.entry locale:@{NSLocaleDecimalSeparator:@"."}];
 return [self bad:n]?[NSDecimalNumber zero]:n;
}
- (NSString *)localized:(NSString *)s {
 return [s stringByReplacingOccurrencesOfString:@"." withString:@","];
}
- (void)draw{
 self.display.text=[self localized:self.entry?:@"0"];
 BOOL hasMemory=[self.memory compare:[NSDecimalNumber zero]]!=NSOrderedSame;
 self.memoryIndicator.text=hasMemory?@"M • PAMÄŤ":@"";
 if(self.pending.length && self.hasLhs){
  self.expression.text=[NSString stringWithFormat:@"%@  %@",[self localized:self.lhs.stringValue],self.pending];
 }else self.expression.text=self.justEqual?@"=":@"";
}
- (void)clearAll{
 self.entry=@"0";self.pending=nil;self.repeatOperator=nil;self.repeatArgument=nil;self.lhs=nil;
 self.nextEntry=YES;self.hasLhs=NO;self.justEqual=NO;self.errorLabel.text=@"";
 [self draw];
}
- (void)fail:(NSString *)reason {
 [self clearAll];self.errorLabel.text=reason;
}
- (BOOL)setNumber:(NSDecimalNumber *)n {
 if([self bad:n]||n.stringValue.length>36){[self fail:@"Príliš veľké číslo"];return NO;}
 self.entry=n.stringValue;self.nextEntry=YES;[self draw];return YES;
}
- (NSDecimalNumber *)evaluate:(NSString *)op a:(NSDecimalNumber *)a b:(NSDecimalNumber *)b{
 if([op isEqualToString:@"+"])return [a decimalNumberByAdding:b withBehavior:[self rule]];
 if([op isEqualToString:@"−"])return [a decimalNumberBySubtracting:b withBehavior:[self rule]];
 if([op isEqualToString:@"×"])return [a decimalNumberByMultiplyingBy:b withBehavior:[self rule]];
 if([op isEqualToString:@"÷"]){
  if([b compare:[NSDecimalNumber zero]]==NSOrderedSame)return nil;
  return [a decimalNumberByDividingBy:b withBehavior:[self rule]];
 }
 return nil;
}
- (void)digit:(NSString *)d{
 self.errorLabel.text=@"";
 if(self.justEqual){self.repeatOperator=nil;self.repeatArgument=nil;self.justEqual=NO;}
 if(self.nextEntry){
  self.entry=[d isEqualToString:@"00"]?@"0":d;self.nextEntry=NO;
 }else{
  NSString *digits=[[self.entry stringByReplacingOccurrencesOfString:@"-" withString:@""] stringByReplacingOccurrencesOfString:@"." withString:@""];
  if(digits.length>=15)return;
  if([self.entry isEqualToString:@"0"])self.entry=d;
  else if([self.entry isEqualToString:@"-0"])self.entry=[@"-" stringByAppendingString:d];
  else self.entry=[self.entry stringByAppendingString:d];
 }
 [self draw];
}
- (void)decimalPoint{
 self.errorLabel.text=@"";
 if(self.justEqual){self.repeatOperator=nil;self.repeatArgument=nil;self.justEqual=NO;}
 if(self.nextEntry){self.entry=@"0.";self.nextEntry=NO;}
 else if([self.entry rangeOfString:@"."].location==NSNotFound)self.entry=[self.entry stringByAppendingString:@"."];
 [self draw];
}
- (void)chooseOperator:(NSString *)op{
 self.errorLabel.text=@"";
 if(self.pending.length && !self.nextEntry){
  NSDecimalNumber *v=[self evaluate:self.pending a:self.lhs b:[self current]];
  if(!v){[self fail:@"Delenie nulou"];return;}
  if([self bad:v]){[self fail:@"Neplatný výpočet"];return;}
  self.lhs=v;self.entry=v.stringValue;
 }else if(!self.hasLhs)self.lhs=[self current];
 self.hasLhs=YES;self.pending=op;self.nextEntry=YES;self.justEqual=NO;
 self.repeatOperator=nil;self.repeatArgument=nil;[self draw];
}
- (void)equals {
 self.errorLabel.text=@"";
 NSDecimalNumber *a=nil,*b=[self current];NSString *op=nil;
 if(self.pending.length && self.hasLhs){
  a=self.lhs;op=self.pending;self.repeatArgument=b;self.repeatOperator=op;
 }else if(self.repeatOperator.length){
  a=b;b=self.repeatArgument;op=self.repeatOperator;
 }else {
  self.lastAnswer=b;self.nextEntry=YES;self.justEqual=YES;[self draw];return;
 }
 NSDecimalNumber *v=[self evaluate:op a:a b:b];
 if(!v){[self fail:@"Delenie nulou"];return;}
 self.lhs=nil;self.pending=nil;self.hasLhs=NO;
 if([self setNumber:v]){self.lastAnswer=v;self.justEqual=YES;}
 [self draw];
}
- (void)percent{
 NSDecimalNumber *v=[self current];
 if(self.hasLhs && [@[@"+",@"−"] containsObject:self.pending])
  v=[self.lhs decimalNumberByMultiplyingBy:v withBehavior:[self rule]];
 v=[v decimalNumberByDividingBy:[NSDecimalNumber decimalNumberWithString:@"100"] withBehavior:[self rule]];
 if([self setNumber:v])self.justEqual=NO;
}
- (void)backspace{
 if(self.nextEntry||self.justEqual){self.entry=@"0";self.nextEntry=YES;self.justEqual=NO;}
 else if(self.entry.length<=1||(self.entry.length==2&&[self.entry hasPrefix:@"-"]))self.entry=@"0";
 else self.entry=[self.entry substringToIndex:self.entry.length-1];
 [self draw];
}
- (void)tap:(UIButton *)button{
 NSString *k=button.currentTitle?:@"";
 if([k isEqualToString:@"C"]){[self clearAll];return;}
 if([k isEqualToString:@"CE"]){self.entry=@"0";self.nextEntry=YES;self.justEqual=NO;self.errorLabel.text=@"";[self draw];return;}
 if([k isEqualToString:@"⌫"]){[self backspace];return;}
 if([k isEqualToString:@","]){[self decimalPoint];return;}
 if([k isEqualToString:@"±"]){
  if([self.entry hasPrefix:@"-"])self.entry=[self.entry substringFromIndex:1];
  else if(![self.entry isEqualToString:@"0"])self.entry=[@"-" stringByAppendingString:self.entry];
  self.justEqual=NO;[self draw];return;
 }
 if([k isEqualToString:@"="]){[self equals];return;}
 if([@[@"+",@"−",@"×",@"÷"] containsObject:k]){[self chooseOperator:k];return;}
 if([k isEqualToString:@"%"]){[self percent];return;}
 if([k isEqualToString:@"√x"]){
  NSDecimalNumber *v=[self current];
  if([v compare:[NSDecimalNumber zero]]==NSOrderedAscending){[self fail:@"Odmocnina záporného čísla"];return;}
  double result=sqrt(v.doubleValue);
  if(!isfinite(result)){[self fail:@"Neplatná odmocnina"];return;}
  NSString *s=[NSString stringWithFormat:@"%.12f",result];
  [self setNumber:[NSDecimalNumber decimalNumberWithString:s locale:@{NSLocaleDecimalSeparator:@"."}]];return;
 }
 if([k isEqualToString:@"x²"]){
  NSDecimalNumber *v=[self current];
  [self setNumber:[v decimalNumberByMultiplyingBy:v withBehavior:[self rule]]];return;
 }
 if([k isEqualToString:@"1/x"]){
  NSDecimalNumber *v=[self current];
  if([v compare:[NSDecimalNumber zero]]==NSOrderedSame){[self fail:@"Delenie nulou"];return;}
  [self setNumber:[[NSDecimalNumber one] decimalNumberByDividingBy:v withBehavior:[self rule]]];return;
 }
 if([k isEqualToString:@"MC"]){self.memory=[NSDecimalNumber zero];[self draw];return;}
 if([k isEqualToString:@"MR"]){[self setNumber:self.memory];self.justEqual=NO;return;}
 if([k isEqualToString:@"M+"]||[k isEqualToString:@"M−"]){
  NSDecimalNumber *v=[self current],*n=nil;
  if([k isEqualToString:@"M+"])n=[self.memory decimalNumberByAdding:v withBehavior:[self rule]];
  else n=[self.memory decimalNumberBySubtracting:v withBehavior:[self rule]];
  if([self bad:n]){[self fail:@"Pamäť je príliš veľká"];return;}
  self.memory=n;[self draw];return;
 }
 if([k isEqualToString:@"ANS"]){[self setNumber:self.lastAnswer];self.justEqual=NO;return;}
 if([k isEqualToString:@"00"]||(k.length==1 && [k characterAtIndex:0]>='0' && [k characterAtIndex:0]<='9')){
  [self digit:k];return;
 }
}
@end

@interface TechCalcHost : UIViewController
@property(nonatomic,strong) NSArray *pages;
@property(nonatomic,strong) NSArray *modeButtons;
@property(nonatomic,assign) NSInteger selectedMode;
@property(nonatomic,strong) UIView *sidebar,*separator;
@end
@implementation TechCalcHost
- (void)viewDidLoad {
 [super viewDidLoad];
 self.view.backgroundColor=[UIColor colorWithRed:.018 green:.058 blue:.079 alpha:1];
 self.sidebar=[UIView new];
 self.sidebar.backgroundColor=[UIColor colorWithRed:.026 green:.093 blue:.116 alpha:1];
 self.sidebar.layer.cornerRadius=12;
 [self.view addSubview:self.sidebar];
 self.separator=[UIView new];self.separator.backgroundColor=[UIColor colorWithRed:.09 green:.49 blue:.48 alpha:.65];
 [self.view addSubview:self.separator];
 NSArray *titles=@[@"▦\nJEDNODUCHÁ",@"ƒ(x)\nVEDECKÁ",@"⇄\nJEDNOTKY"];
 NSMutableArray *buttons=[NSMutableArray array];
 for(NSInteger i=0;i<3;i++){
  UIButton *btn=[UIButton buttonWithType:UIButtonTypeSystem];
  [btn setTitle:titles[i] forState:UIControlStateNormal];
  btn.titleLabel.font=[UIFont boldSystemFontOfSize:20];
  btn.titleLabel.numberOfLines=2;btn.titleLabel.textAlignment=NSTextAlignmentCenter;
  btn.titleLabel.adjustsFontSizeToFitWidth=YES;
  btn.layer.cornerRadius=10;btn.layer.borderWidth=1.1;
  btn.tag=660+i;
  btn.accessibilityLabel=@[@"Jednoduchá kalkulačka",@"Vedecká kalkulačka",@"Prevod jednotiek"][i];
  [btn addTarget:self action:@selector(chooseMode:) forControlEvents:UIControlEventTouchUpInside];
  [self.sidebar addSubview:btn];[buttons addObject:btn];
 }
 self.modeButtons=buttons;
 self.pages=@[[TechCalcController new],[TCScientificController new],[TCUnitsController new]];
 for(UIViewController *page in self.pages){
  [self addChildViewController:page];
  [self.view addSubview:page.view];
  [page didMoveToParentViewController:self];
 }
 self.selectedMode=0;[self switchMode];
}
- (void)viewDidLayoutSubviews {
 [super viewDidLayoutSubviews];
 CGFloat top=self.view.safeAreaInsets.top+7,bottom=self.view.safeAreaInsets.bottom;
 CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height;
 CGFloat sideWidth=MIN(191,MAX(150,w*.185));
 CGFloat height=MAX(300,h-top-bottom-13);
 self.sidebar.frame=CGRectMake(9,top,sideWidth-6,height);
 self.separator.frame=CGRectMake(sideWidth+4,top+3,2,height-6);
 CGFloat modeGap=11;
 CGFloat modeHeight=MIN(92,MAX(77,height*.14));
 for(NSInteger i=0;i<3;i++){
  UIButton *btn=self.modeButtons[i];
  btn.frame=CGRectMake(9,12+i*(modeHeight+modeGap),sideWidth-24,modeHeight);
 }
 CGRect area=CGRectMake(sideWidth+11,top,w-sideWidth-17,height);
 for(UIViewController *page in self.pages)page.view.frame=area;
}
- (void)chooseMode:(UIButton *)sender {
 self.selectedMode=sender.tag-660;
 [self switchMode];
}
- (void)switchMode {
 UIColor *aqua=[UIColor colorWithRed:.09 green:.87 blue:.82 alpha:1];
 UIColor *dark=[UIColor colorWithRed:.025 green:.08 blue:.10 alpha:1];
 for(NSInteger i=0;i<self.modeButtons.count;i++){
  UIButton *btn=self.modeButtons[i];BOOL current=i==self.selectedMode;
  btn.backgroundColor=current?aqua:[UIColor colorWithRed:.047 green:.15 blue:.19 alpha:1];
  [btn setTitleColor:current?dark:[UIColor colorWithRed:.80 green:.92 blue:.94 alpha:1] forState:UIControlStateNormal];
  btn.layer.borderColor=(current?aqua:[UIColor colorWithRed:.13 green:.39 blue:.42 alpha:1]).CGColor;
 }
 for(NSInteger i=0;i<self.pages.count;i++){
  UIViewController *page=self.pages[i];page.view.hidden=i!=self.selectedMode;
 }
 [self.view endEditing:YES];
}
@end

@interface TechCalcDelegate : UIResponder<UIApplicationDelegate>
@property(strong,nonatomic) UIWindow *window;
@end
@implementation TechCalcDelegate
- (BOOL)application:(UIApplication *)app didFinishLaunchingWithOptions:(NSDictionary *)opts {
 self.window=[[UIWindow alloc] initWithFrame:UIScreen.mainScreen.bounds];
 self.window.rootViewController=[TechCalcHost new];[self.window makeKeyAndVisible];return YES;
}
@end
int main(int argc,char **argv){@autoreleasepool{return UIApplicationMain(argc,argv,nil,NSStringFromClass(TechCalcDelegate.class));}}

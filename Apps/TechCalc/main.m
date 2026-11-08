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
  button.accessibilityLabel=name;
  [button addTarget:self action:@selector(tap:) forControlEvents:UIControlEventTouchUpInside];
  [self.view addSubview:button];[self.buttons addObject:button];
 }
 self.memory=[NSDecimalNumber zero];self.lastAnswer=[NSDecimalNumber zero];[self clearAll];
}
- (void)viewDidLayoutSubviews {
 [super viewDidLayoutSubviews];
 CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height;
 CGFloat margin=10;
 CGFloat gridWidth=MIN(w-2*margin,805);
 CGFloat left=(w-gridWidth)/2;
 self.displayPanel.frame=CGRectMake(left,4,gridWidth,117);
 CGFloat sw=self.displayPanel.bounds.size.width;
 self.expression.frame=CGRectMake(18,5,sw-35,27);
 self.display.frame=CGRectMake(18,21,sw-35,78);
 self.memoryIndicator.frame=CGRectMake(18,96,110,18);
 self.errorLabel.frame=CGRectMake(133,96,MAX(0,sw-150),18);
 CGFloat start=133,gap=7;
 CGFloat freeHeight=MAX(260,h-start-8);
 CGFloat cellWidth=(gridWidth-4*gap)/5;
 CGFloat cellHeight=MIN(69,(freeHeight-5*gap)/6);
 for(NSInteger i=0;i<self.buttons.count;i++){
  NSInteger row=i/5,col=i%5;
  ((UIButton *)self.buttons[i]).frame=CGRectMake(left+col*(cellWidth+gap),start+row*(cellHeight+gap),cellWidth,cellHeight);
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
@property(nonatomic,strong) UISegmentedControl *modes;
@property(nonatomic,strong) NSArray *pages;
@end
@implementation TechCalcHost
- (void)viewDidLoad {
 [super viewDidLoad];
 self.view.backgroundColor=[UIColor colorWithRed:.018 green:.058 blue:.079 alpha:1];
 self.modes=[[UISegmentedControl alloc] initWithItems:@[@"JEDNODUCHÁ",@"VEDECKÁ",@"JEDNOTKY"]];
 self.modes.selectedSegmentIndex=0;
 [self.modes setTitleTextAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:17]} forState:UIControlStateNormal];
 [self.modes addTarget:self action:@selector(switchMode) forControlEvents:UIControlEventValueChanged];
 [self.view addSubview:self.modes];
 self.pages=@[[TechCalcController new],[TCScientificController new],[TCUnitsController new]];
 for(UIViewController *page in self.pages){
  [self addChildViewController:page];
  [self.view addSubview:page.view];
  [page didMoveToParentViewController:self];
 }
 [self switchMode];
}
- (void)viewDidLayoutSubviews {
 [super viewDidLayoutSubviews];
 CGFloat top=self.view.safeAreaInsets.top+4,bottom=self.view.safeAreaInsets.bottom;
 CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height;
 self.modes.frame=CGRectMake(10,top,w-20,43);
 CGFloat contentTop=top+48;
 CGRect area=CGRectMake(0,contentTop,w,MAX(120,h-contentTop-bottom));
 for(UIViewController *page in self.pages)page.view.frame=area;
}
- (void)switchMode {
 for(NSInteger i=0;i<self.pages.count;i++) {
  UIViewController *page=self.pages[i];
  page.view.hidden=(i!=self.modes.selectedSegmentIndex);
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

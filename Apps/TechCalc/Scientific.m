#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <math.h>

// A bounded recursive-descent evaluator; never evaluates source code, JavaScript or shell commands.
@interface TCFormula : NSObject
@property(nonatomic,copy) NSString *s;
@property(nonatomic,assign) NSUInteger p,depth;
@property(nonatomic,assign) BOOL error,degrees;
@property(nonatomic,assign) double x,a;
- (double)calculate:(NSString *)s x:(double)x a:(double)a degrees:(BOOL)deg;
@end
@implementation TCFormula
- (void)space{while(self.p<self.s.length && [[NSCharacterSet whitespaceAndNewlineCharacterSet] characterIsMember:[self.s characterAtIndex:self.p]])self.p++;}
- (BOOL)eat:(unichar)ch{[self space];if(self.p<self.s.length&&[self.s characterAtIndex:self.p]==ch){self.p++;return YES;}return NO;}
- (double)expr;
- (double)term;
- (double)unary;
- (double)power;
- (double)primary;
- (double)calculate:(NSString *)s x:(double)x a:(double)a degrees:(BOOL)deg {
 NSString *raw=s?:@"";
 self.s=[[raw stringByReplacingOccurrencesOfString:@"," withString:@"."] lowercaseString];
 self.p=0;self.depth=0;self.error=NO;self.degrees=deg;self.x=x;self.a=a;
 if(self.s.length>256){self.error=YES;return NAN;}
 double result=[self expr];[self space];if(self.p!=self.s.length||!isfinite(result))self.error=YES;
 return self.error?NAN:result;
}
- (double)expr {
 if(++self.depth>80){self.error=YES;self.depth--;return NAN;}
 double lhs=[self term];
 for(NSInteger guard=0;guard<256&&!self.error;guard++){
  if([self eat:'+'])lhs+=[self term];
  else if([self eat:'-'])lhs-=[self term];
  else break;
 }
 self.depth--;return lhs;
}
- (double)term {
 double lhs=[self unary];
 for(NSInteger guard=0;guard<256&&!self.error;guard++){
  if([self eat:'*'])lhs*=[self unary];
  else if([self eat:'/']){double rhs=[self unary];if(rhs==0){self.error=YES;return NAN;}lhs/=rhs;}
  else break;
 }
 return lhs;
}
- (double)unary {
 if([self eat:'+'])return [self unary];
 if([self eat:'-'])return -[self unary];
 return [self power];
}
- (double)power {
 double base=[self primary];
 while([self eat:'!']){
  if(base<0||base>170||floor(base)!=base){self.error=YES;return NAN;}
  double factorial=1;for(int i=2;i<=(int)base;i++)factorial*=i;
  base=factorial;
 }
 if([self eat:'^'])base=pow(base,[self unary]);
 return base;
}
- (double)primary {
 [self space];
 if([self eat:'(']) {
  double v=[self expr];
  if(![self eat:')'])self.error=YES;
  return v;
 }
 if(self.p>=self.s.length){self.error=YES;return NAN;}
 NSUInteger start=self.p;
 unichar ch=[self.s characterAtIndex:self.p];
 if((ch>='0'&&ch<='9')||ch=='.'){
  while(self.p<self.s.length) {
   unichar c=[self.s characterAtIndex:self.p];
   if((c>='0'&&c<='9')||c=='.')self.p++;else break;
  }
  NSString *text=[self.s substringWithRange:NSMakeRange(start,self.p-start)];
  double val=[text doubleValue];
  if(!isfinite(val)){self.error=YES;return NAN;}
  return val;
 }
 if([[NSCharacterSet letterCharacterSet] characterIsMember:ch]||ch==0x03C0){
  while(self.p<self.s.length){
   unichar c=[self.s characterAtIndex:self.p];
   if([[NSCharacterSet letterCharacterSet] characterIsMember:c]||c==0x03C0)self.p++;else break;
  }
  NSString *name=[self.s substringWithRange:NSMakeRange(start,self.p-start)];
  if([name isEqualToString:@"pi"]||[name isEqualToString:@"π"])return M_PI;
  if([name isEqualToString:@"e"])return M_E;
  if([name isEqualToString:@"x"])return self.x;
  if([name isEqualToString:@"a"])return self.a;
  if(![self eat:'(']){self.error=YES;return NAN;}
  double arg=[self expr];
  if(![self eat:')']){self.error=YES;return NAN;}
  double rad=self.degrees?arg*M_PI/180.0:arg;
  if([name isEqualToString:@"sin"])return sin(rad);
  if([name isEqualToString:@"cos"])return cos(rad);
  if([name isEqualToString:@"tan"])return tan(rad);
  if([name isEqualToString:@"asin"])return asin(arg)*(self.degrees?180/M_PI:1);
  if([name isEqualToString:@"acos"])return acos(arg)*(self.degrees?180/M_PI:1);
  if([name isEqualToString:@"atan"])return atan(arg)*(self.degrees?180/M_PI:1);
  if([name isEqualToString:@"sqrt"])return sqrt(arg);
  if([name isEqualToString:@"abs"])return fabs(arg);
  if([name isEqualToString:@"ln"])return log(arg);
  if([name isEqualToString:@"log"])return log10(arg);
  if([name isEqualToString:@"exp"])return exp(arg);
  if([name isEqualToString:@"floor"])return floor(arg);
  if([name isEqualToString:@"ceil"])return ceil(arg);
  self.error=YES;return NAN;
 }
 self.error=YES;return NAN;
}
@end

static UIColor *TCSurface(void){return [UIColor colorWithRed:.018 green:.058 blue:.079 alpha:1];}
static UIColor *TCCard(void){return [UIColor colorWithRed:.065 green:.16 blue:.20 alpha:1];}
static UIColor *TCMint(void){return [UIColor colorWithRed:.10 green:.88 blue:.82 alpha:1];}
static UIColor *TCGold(void){return [UIColor colorWithRed:.98 green:.74 blue:.38 alpha:1];}
static UIButton *TCButton(NSString *title,id target,SEL selector) {
 UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];
 b.backgroundColor=TCCard();[b setTitleColor:TCMint() forState:UIControlStateNormal];
 b.titleLabel.font=[UIFont boldSystemFontOfSize:18];b.titleLabel.adjustsFontSizeToFitWidth=YES;
 [b setTitle:title forState:UIControlStateNormal];b.layer.cornerRadius=7;
 [b addTarget:target action:selector forControlEvents:UIControlEventTouchUpInside];return b;
}
@interface TCGraphView : UIView
@property(nonatomic,copy) NSString *formula;
@property(nonatomic,assign) BOOL deg;
@property(nonatomic,assign) double a,range;
@end
@implementation TCGraphView
- (void)drawRect:(CGRect)rect {
 CGContextRef ctx=UIGraphicsGetCurrentContext();CGFloat w=rect.size.width,h=rect.size.height;
 CGContextSetFillColorWithColor(ctx,TCSurface().CGColor);CGContextFillRect(ctx,rect);
 double extent=MAX(1,self.range);
 CGFloat cx=w*.5,cy=h*.5;
 CGContextSetStrokeColorWithColor(ctx,[UIColor colorWithRed:.17 green:.29 blue:.33 alpha:1].CGColor);
 CGContextSetLineWidth(ctx,1);
 for(int i=-4;i<=4;i++){
  CGFloat x=cx+(w*.5)*(i/4.0);CGFloat y=cy+(h*.5)*(i/4.0);
  CGContextMoveToPoint(ctx,x,0);CGContextAddLineToPoint(ctx,x,h);
  CGContextMoveToPoint(ctx,0,y);CGContextAddLineToPoint(ctx,w,y);
 }
 CGContextStrokePath(ctx);
 CGContextSetStrokeColorWithColor(ctx,[UIColor colorWithWhite:.67 alpha:1].CGColor);
 CGContextMoveToPoint(ctx,cx,0);CGContextAddLineToPoint(ctx,cx,h);
 CGContextMoveToPoint(ctx,0,cy);CGContextAddLineToPoint(ctx,w,cy);CGContextStrokePath(ctx);
 if(!self.formula.length)return;
 CGContextSetStrokeColorWithColor(ctx,TCMint().CGColor);CGContextSetLineWidth(ctx,2.5);
 TCFormula *parser=[TCFormula new];BOOL started=NO;
 NSInteger samples=MIN(900,MAX(200,(NSInteger)(w*1.8)));
 for(NSInteger i=0;i<=samples;i++){
  double xv=-extent+2*extent*i/(double)samples;
  double yv=[parser calculate:self.formula x:xv a:self.a degrees:self.deg];
  if(!isfinite(yv)||fabs(yv)>extent*20){started=NO;continue;}
  CGFloat px=w*i/(CGFloat)samples,py=cy-(CGFloat)(yv/extent)*(h*.5);
  if(!isfinite(py)){started=NO;continue;}
  if(!started){CGContextMoveToPoint(ctx,px,py);started=YES;}
  else CGContextAddLineToPoint(ctx,px,py);
 }
 CGContextStrokePath(ctx);
 NSDictionary *atts=@{NSFontAttributeName:[UIFont systemFontOfSize:13],NSForegroundColorAttributeName:TCGold()};
 [[NSString stringWithFormat:@"X: ±%.0f   Y: ±%.0f",extent,extent] drawAtPoint:CGPointMake(10,8) withAttributes:atts];
}
@end

@interface TCScientificController : UIViewController <UITextFieldDelegate>
@property(nonatomic,strong) UITextField *formula,*xField;
@property(nonatomic,strong) UILabel *result,*summary,*historyLabel;
@property(nonatomic,strong) UIButton *degBtn,*graphBtn;
@property(nonatomic,strong) TCGraphView *graph;
@property(nonatomic,strong) NSMutableArray *keys;
@property(nonatomic,strong) NSMutableArray *history;
@property(nonatomic,assign) BOOL degrees;
@property(nonatomic,assign) double varA,lastResult;
@property(nonatomic,assign) NSUInteger graphRange;
@end
@implementation TCScientificController
- (void)viewDidLoad {
 [super viewDidLoad];self.view.backgroundColor=TCSurface();
 self.degrees=YES;self.graphRange=10;self.history=[NSMutableArray array];
 self.varA=[[NSUserDefaults standardUserDefaults] doubleForKey:@"techcalc-variable-A"];
 self.formula=[UITextField new];self.formula.backgroundColor=TCCard();
 self.formula.textColor=UIColor.whiteColor;self.formula.font=[UIFont systemFontOfSize:23];
 self.formula.layer.cornerRadius=7;self.formula.autocorrectionType=UITextAutocorrectionTypeNo;
 self.formula.autocapitalizationType=UITextAutocapitalizationTypeNone;
 self.formula.keyboardType=UIKeyboardTypeASCIICapable;
 self.formula.clearButtonMode=UITextFieldViewModeWhileEditing;
 self.formula.placeholder=@"Zadaj výraz, napr. sin(30)+2^3";
 self.formula.text=@"sin(30)+2^3";self.formula.delegate=self;[self.view addSubview:self.formula];
 self.result=[UILabel new];self.result.font=[UIFont monospacedDigitSystemFontOfSize:32 weight:UIFontWeightMedium];
 self.result.textColor=UIColor.whiteColor;self.result.textAlignment=NSTextAlignmentRight;
 self.result.adjustsFontSizeToFitWidth=YES;self.result.text=@"=";[self.view addSubview:self.result];
 self.summary=[UILabel new];self.summary.textColor=TCMint();self.summary.font=[UIFont systemFontOfSize:15];
 [self.view addSubview:self.summary];
 self.xField=[UITextField new];self.xField.text=@"0";self.xField.placeholder=@"X";
 self.xField.backgroundColor=TCCard();self.xField.layer.cornerRadius=5;
 self.xField.textAlignment=NSTextAlignmentCenter;self.xField.textColor=UIColor.whiteColor;
 self.xField.font=[UIFont boldSystemFontOfSize:19];self.xField.keyboardType=UIKeyboardTypeDecimalPad;
 [self.view addSubview:self.xField];
 self.degBtn=TCButton(@"DEG",self,@selector(switchAngle));[self.view addSubview:self.degBtn];
 self.graphBtn=TCButton(@"GRAF",self,@selector(plot));[self.view addSubview:self.graphBtn];
 NSArray *toolbar=@[@"VYPOČÍTAŤ",@"A ← VÝSLEDOK",@"ULOŽIŤ VZOREC",@"MOJE VZORCE",@"VYMAZAŤ"];
 NSArray *selectors=@[@"compute",@"storeA",@"saveFormula",@"savedFormulas",@"clearFormula"];
 for(NSInteger i=0;i<toolbar.count;i++){
  UIButton *b=TCButton(toolbar[i],self,NSSelectorFromString(selectors[i]));b.tag=500+i;[self.view addSubview:b];
 }
 self.graph=[TCGraphView new];self.graph.layer.cornerRadius=7;self.graph.clipsToBounds=YES;
 self.graph.backgroundColor=TCSurface();[self.view addSubview:self.graph];
 self.historyLabel=[UILabel new];self.historyLabel.font=[UIFont systemFontOfSize:14];
 self.historyLabel.textColor=[UIColor colorWithWhite:.72 alpha:1];
 self.historyLabel.numberOfLines=4;[self.view addSubview:self.historyLabel];
 NSArray *grid=@[
 @[@"7",@"8",@"9",@"/",@"sin("],
 @[@"4",@"5",@"6",@"*", @"cos("],
 @[@"1",@"2",@"3",@"-", @"tan("],
 @[@"0",@".",@"(",@")", @"+"],
 @[@"π",@"e", @"x",@"^",@"sqrt("],
 @[@"ln(",@"log(",@"abs(",@"! ",@"⌫"]
 ];
 self.keys=[NSMutableArray array];
 for(NSArray *r in grid)for(NSString *t in r){
  UIButton *b=TCButton(t,self,@selector(insertKey:));b.titleLabel.font=[UIFont boldSystemFontOfSize:22];
  if([@[@"+",@"-",@"*",@"/",@"^", @"sin(",@"cos(",@"tan(",@"sqrt(",@"ln(",@"log(",@"abs("] containsObject:t])
   [b setTitleColor:TCGold() forState:UIControlStateNormal];
  if([t isEqualToString:@"⌫"])[b setTitleColor:[UIColor colorWithRed:1 green:.52 blue:.50 alpha:1] forState:UIControlStateNormal];
  [self.view addSubview:b];[self.keys addObject:b];
 }
 [self updateSummary];[self compute];
}
- (void)viewDidLayoutSubviews {
 [super viewDidLayoutSubviews];CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height;
 CGFloat m=12,gap=7;
 self.formula.frame=CGRectMake(m,7,w-2*m,48);
 self.result.frame=CGRectMake(m,58,w-2*m,48);
 self.summary.frame=CGRectMake(m,107,w*.45,29);
 self.xField.frame=CGRectMake(w*.45,109,78,34);
 self.degBtn.frame=CGRectMake(w*.45+84,109,70,34);
 self.graphBtn.frame=CGRectMake(w*.45+160,109,91,34);
 CGFloat top=147,tw=(w-2*m-4*gap)/5;
 for(NSInteger i=0;i<5;i++)[self.view viewWithTag:500+i].frame=CGRectMake(m+i*(tw+gap),top,tw,38);
 CGFloat lowerTop=193,sideW=MAX(300,w*.55),graphW=w-sideW-3*m;
 CGFloat keypadHeight=MAX(230,h-lowerTop-12),keygap=6;
 CGFloat cellW=(sideW-2*m-4*keygap)/5,cellH=(keypadHeight-5*keygap)/6;
 for(NSInteger i=0;i<self.keys.count;i++){
  ((UIButton *)self.keys[i]).frame=CGRectMake(m+(i%5)*(cellW+keygap),lowerTop+(i/5)*(cellH+keygap),cellW,cellH);
 }
 CGFloat rightX=sideW+m;
 self.graph.frame=CGRectMake(rightX,lowerTop,graphW,MAX(175,keypadHeight*.73));
 self.historyLabel.frame=CGRectMake(rightX,lowerTop+MAX(175,keypadHeight*.73)+7,graphW,MAX(55,keypadHeight*.25-7));
}
- (BOOL)textFieldShouldReturn:(UITextField *)field {[field resignFirstResponder];[self compute];return YES;}
- (void)updateSummary {self.summary.text=[NSString stringWithFormat:@"A = %.8g   •   %@",self.varA,self.degrees?@"DEG":@"RAD"];}
- (void)switchAngle {self.degrees=!self.degrees;[self.degBtn setTitle:self.degrees?@"DEG":@"RAD" forState:UIControlStateNormal];[self updateSummary];[self compute];}
- (void)compute {
 [self.view endEditing:YES];
 double x=[[self.xField.text stringByReplacingOccurrencesOfString:@"," withString:@"."] doubleValue];
 TCFormula *p=[TCFormula new];
 double res=[p calculate:self.formula.text x:x a:self.varA degrees:self.degrees];
 if(p.error||!isfinite(res)){self.lastResult=NAN;self.result.text=@"Neplatný výraz";self.result.textColor=[UIColor colorWithRed:1 green:.5 blue:.4 alpha:1];return;}
 self.lastResult=res;self.result.text=[NSString stringWithFormat:@"= %.12g",res];
 self.result.textColor=UIColor.whiteColor;
 NSString *item=[NSString stringWithFormat:@"%@ = %.9g",self.formula.text,res];
 if(![self.history.firstObject isEqual:item])[self.history insertObject:item atIndex:0];
 while(self.history.count>4)[self.history removeLastObject];
 self.historyLabel.text=[self.history componentsJoinedByString:@"\n"];
}
- (void)plot {
 [self compute];
 if(!isfinite(self.lastResult)) {self.graph.formula=@"";[self.graph setNeedsDisplay];return;}
 self.graph.formula=self.formula.text;
 self.graph.deg=self.degrees;self.graph.a=self.varA;self.graph.range=(double)self.graphRange;
 [self.graph setNeedsDisplay];
 [self.graphBtn setTitle:[NSString stringWithFormat:@"±%lu", (unsigned long)self.graphRange] forState:UIControlStateNormal];
 self.graphRange=self.graphRange==10?5:(self.graphRange==5?20:10);
}
- (void)storeA {
 [self compute];if(!isfinite(self.lastResult))return;
 self.varA=self.lastResult;
 [[NSUserDefaults standardUserDefaults] setDouble:self.varA forKey:@"techcalc-variable-A"];[self updateSummary];
}
- (void)clearFormula {self.formula.text=@"";self.result.text=@"=";self.graph.formula=@"";[self.graph setNeedsDisplay];}
- (void)insertKey:(UIButton *)btn {
 NSString *key=btn.currentTitle?:@"";
 NSMutableString *m=[self.formula.text?:@"" mutableCopy];
 if([key isEqualToString:@"⌫"]){if(m.length)[m deleteCharactersInRange:NSMakeRange(m.length-1,1)];}
 else if(m.length+key.length<=256)[m appendString:key];
 self.formula.text=m;
}
- (void)saveFormula {
 NSString *s=[self.formula.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
 if(!s.length)return;
 UIAlertController *alert=[UIAlertController alertControllerWithTitle:@"Uložiť vzorec" message:@"Zadaj názov vlastného vzorca" preferredStyle:UIAlertControllerStyleAlert];
 [alert addTextFieldWithConfigurationHandler:^(UITextField *f){f.placeholder=@"Názov vzorca";}];
 [alert addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
 [alert addAction:[UIAlertAction actionWithTitle:@"ULOŽIŤ" style:UIAlertActionStyleDefault handler:^(UIAlertAction *a){
  NSString *name=[alert.textFields.firstObject.text stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
  if(!name.length)return;
  NSUserDefaults *defaults=NSUserDefaults.standardUserDefaults;
  NSMutableDictionary *stored=[[defaults dictionaryForKey:@"techcalc-formulas"] mutableCopy]?:[NSMutableDictionary dictionary];
  NSString *safeName=[name substringToIndex:MIN(name.length,40)];
  if(stored.count>=40&&!stored[safeName])return;
  stored[safeName]=s;
  [defaults setObject:stored forKey:@"techcalc-formulas"];
 }]];
 [self presentViewController:alert animated:YES completion:nil];
}
- (void)savedFormulas {
 NSDictionary *d=[NSUserDefaults.standardUserDefaults dictionaryForKey:@"techcalc-formulas"]?:@{};
 UIAlertController *menu=[UIAlertController alertControllerWithTitle:@"Uložené vzorce"
 message:d.count?@"Vyber vzorec":@"Zatiaľ nemáš uložený žiadny vzorec."
 preferredStyle:UIAlertControllerStyleActionSheet];
 for(NSString *name in [[d allKeys] sortedArrayUsingSelector:@selector(localizedStandardCompare:)]){
  NSString *formula=d[name];
  [menu addAction:[UIAlertAction actionWithTitle:name style:UIAlertActionStyleDefault handler:^(UIAlertAction *a){self.formula.text=formula;[self compute];}]];
 }
 [menu addAction:[UIAlertAction actionWithTitle:@"ZAVRIEŤ" style:UIAlertActionStyleCancel handler:nil]];
 UIPopoverPresentationController *pop=menu.popoverPresentationController;UIView *anchor=[self.view viewWithTag:503];
 if(pop){pop.sourceView=anchor;pop.sourceRect=anchor.bounds;}
 [self presentViewController:menu animated:YES completion:nil];
}
@end

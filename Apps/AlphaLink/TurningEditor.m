#import <UIKit/UIKit.h>
#import <CoreGraphics/CoreGraphics.h>
#import <math.h>

static UIColor *TBG(void){return [UIColor colorWithRed:.035 green:.08 blue:.11 alpha:1];}
static UIColor *TPANEL(void){return [UIColor colorWithRed:.07 green:.16 blue:.20 alpha:1];}
static UIColor *TCYAN(void){return [UIColor colorWithRed:.12 green:.85 blue:.80 alpha:1];}
static UIColor *TWHITE(void){return [UIColor colorWithWhite:.94 alpha:1];}
static NSString *TString(id o){return [o isKindOfClass:NSString.class]?o:@"";}
static double TNumber(id o,double fallback){double n=[o respondsToSelector:@selector(doubleValue)]?[o doubleValue]:fallback;return isfinite(n)?n:fallback;}
static double TParse(NSString *str){NSString *v=[TString(str) stringByReplacingOccurrencesOfString:@"," withString:@"."];return [v doubleValue];}
static NSArray *TDefs(NSString *kind){
 NSDictionary *all=@{
 @"diameter":@[@[@"zStart",@"Začiatok od čela Z (mm)",@0],@[@"zEnd",@"Koniec Z (mm)",@20],@[@"diameter",@"Výsledný priemer Ø (mm)",@30],@[@"step",@"Radiálny úber (mm)",@1]],
 @"face":@[@[@"amount",@"Úber čela (mm)",@0.5],@[@"step",@"Max. úber na prechod (mm)",@0.5]],
 @"taper":@[@[@"zStart",@"Začiatok Z (mm)",@5],@[@"zEnd",@"Koniec Z (mm)",@25],@[@"diameterStart",@"Počiatočný priemer Ø (mm)",@35],@[@"diameterEnd",@"Koncový priemer Ø (mm)",@25],@[@"step",@"Radiálny úber (mm)",@1]],
 @"groove":@[@[@"zStart",@"Poloha zápichu Z (mm)",@12],@[@"width",@"Šírka zápichu (mm)",@3],@[@"diameter",@"Priemer dna Ø (mm)",@25],@[@"step",@"Radiálny úber (mm)",@0.5]],
 @"chamfer":@[@[@"z",@"Poloha hrany Z (mm)",@0],@[@"size",@"Dĺžka skosenia v Z (mm)",@0.5],@[@"angle",@"Uhol od osi Z (°)",@45]],
 @"radius":@[@[@"z",@"Poloha hrany Z (mm)",@20],@[@"size",@"Rádius R (mm)",@1]],
 @"partoff":@[@[@"z",@"Poloha upichnutia Z (mm)",@50],@[@"width",@"Šírka noža (mm)",@2],@[@"step",@"Radiálny úber (mm)",@0.5]]
 };
 return all[kind]?:@[];
}
static NSDictionary *TNames(void){return @{@"diameter":@"STIAHNUŤ PRIEMER",@"face":@"ZAROVNAŤ ČELO",@"taper":@"ŠIKMINA / KUŽEĽ",@"groove":@"ZÁPICH",@"chamfer":@"ZRAZIŤ HRANU",@"radius":@"RÁDIUS",@"partoff":@"UPICHNÚŤ"};}

@interface CNCProfileView:UIView
@property(nonatomic,strong) NSDictionary *shape;
@property(nonatomic,assign) BOOL verified;
@end
@implementation CNCProfileView
- (void)drawRect:(CGRect)rect {
 CGContextRef c=UIGraphicsGetCurrentContext();CGFloat w=rect.size.width,h=rect.size.height;
 CGContextSetFillColorWithColor(c,TBG().CGColor);CGContextFillRect(c,rect);
 CGContextSetLineWidth(c,1);CGContextSetStrokeColorWithColor(c,[UIColor colorWithRed:.13 green:.24 blue:.29 alpha:1].CGColor);
 for(CGFloat x=25;x<w;x+=44){CGContextMoveToPoint(c,x,0);CGContextAddLineToPoint(c,x,h);}
 for(CGFloat y=25;y<h;y+=44){CGContextMoveToPoint(c,0,y);CGContextAddLineToPoint(c,w,y);}CGContextStrokePath(c);
 NSDictionary *m=self.shape, *stock=m[@"stock"];NSArray *pts=[m[@"profile"] isKindOfClass:NSArray.class]?m[@"profile"]:@[];
 CGFloat dia=TNumber(stock[@"diameter"],0),length=TNumber(m[@"finished_length"],0);
 if(length<=0)length=TNumber(stock[@"length"],0);
 NSDictionary *attrs=@{NSForegroundColorAttributeName:TWHITE(),NSFontAttributeName:[UIFont systemFontOfSize:16]};
 if(dia<=0||length<=0||pts.count<2) {
  [@"Zadaj polotovar a pridaj operáciu." drawAtPoint:CGPointMake(24,25) withAttributes:attrs];return;
 }
 CGFloat side=MAX(35,w*.055), usableW=w-2*side,usableH=h*.66;
 CGFloat scale=MIN(usableW/length,usableH/dia);
 CGFloat cw=length*scale, xL=(w-cw)/2,cy=h*.52,rr=dia*.5*scale;
 CGFloat (^X)(double)=^CGFloat(double z){return xL+(length-z)*scale;};
 CGFloat (^Y)(double)=^CGFloat(double r){return cy-r*scale;};
 CGContextSetFillColorWithColor(c,[UIColor colorWithRed:.35 green:.55 blue:.60 alpha:.19].CGColor);
 CGContextFillRect(c,CGRectMake(xL,cy-rr,cw,2*rr));
 CGFloat dashes[]={7,5}; CGContextSetLineDash(c,0,dashes,2);CGContextSetStrokeColorWithColor(c,[UIColor colorWithRed:.52 green:.71 blue:.74 alpha:1].CGColor);
 CGContextStrokeRectWithWidth(c,CGRectMake(xL,cy-rr,cw,2*rr),1.2);CGContextSetLineDash(c,0,NULL,0);
 UIBezierPath *fill=[UIBezierPath bezierPath],*edge=[UIBezierPath bezierPath];BOOL began=NO;
 for(id q in pts){if(![q isKindOfClass:NSArray.class]||[q count]<2)continue;
  CGPoint p=CGPointMake(X(TNumber(q[0],0)),Y(TNumber(q[1],0)));
  if(!began){[fill moveToPoint:p];[edge moveToPoint:p];began=YES;}else{[fill addLineToPoint:p];[edge addLineToPoint:p];}}
 if(!began)return;
 for(id q in [pts reverseObjectEnumerator]){if(![q isKindOfClass:NSArray.class]||[q count]<2)continue;
   [fill addLineToPoint:CGPointMake(X(TNumber(q[0],0)),cy+TNumber(q[1],0)*scale)];}
 [fill closePath];[[UIColor colorWithRed:.57 green:.65 blue:.68 alpha:.9] setFill];[fill fill];
 [TWHITE() setStroke];fill.lineWidth=1.2;[fill stroke];
 UIColor *strokeColor=self.verified?[UIColor colorWithRed:.16 green:.95 blue:.52 alpha:1]:TCYAN(); [strokeColor setStroke];
 edge.lineWidth=3;[edge stroke];
 CGContextSetLineDash(c,0,dashes,2);CGContextSetStrokeColorWithColor(c,[UIColor colorWithRed:.3 green:.7 blue:.78 alpha:1].CGColor);
 CGContextMoveToPoint(c,xL-8,cy);CGContextAddLineToPoint(c,xL+cw+8,cy);CGContextStrokePath(c);CGContextSetLineDash(c,0,NULL,0);
 for(id v in m[@"partoffs"]?:@[]){double z=TNumber(v[@"z"],-1);if(z<0||z>length)continue;
  CGContextSetStrokeColorWithColor(c,[UIColor orangeColor].CGColor);
  CGContextMoveToPoint(c,X(z),cy-rr-8);CGContextAddLineToPoint(c,X(z),cy+rr+8);CGContextStrokePath(c);}
 [@"Z0" drawAtPoint:CGPointMake(X(0)-18,13) withAttributes:attrs];
 [[NSString stringWithFormat:@"Z−%.1f",length] drawAtPoint:CGPointMake(MAX(8,X(length)-4),13) withAttributes:attrs];
 [[NSString stringWithFormat:@"POLOTOVAR Ø%.2f   •   DĹŽKA %.2f mm",dia,length] drawAtPoint:CGPointMake(18,h-42) withAttributes:attrs];
 NSString *label=self.verified?@"SERVER: GEOMETRIA OVERENÁ":@"LOKÁLNY NÁHĽAD – NEOVERENÉ";
 [label drawAtPoint:CGPointMake(18,h-20) withAttributes:@{NSForegroundColorAttributeName:TCYAN(),NSFontAttributeName:[UIFont boldSystemFontOfSize:15]}];
}
@end

@interface CNCTurningController:UIViewController <UITableViewDataSource,UITableViewDelegate,UITextFieldDelegate>
@property(nonatomic,copy) NSString *baseURL;
@property(nonatomic,strong) UISegmentedControl *tabs;
@property(nonatomic,strong) UILabel *status;
@property(nonatomic,strong) UIView *inputPage,*operationPage,*previewPage,*codePage,*projectsPage;
@property(nonatomic,strong) UIScrollView *inputScroll;
@property(nonatomic,strong) UIView *inputBody;
@property(nonatomic,strong) CNCProfileView *preview;
@property(nonatomic,strong) UITableView *operationTable,*projectsTable;
@property(nonatomic,strong) UITextView *gcode;
@property(nonatomic,strong) UITextField *codeName;
@property(nonatomic,strong) UIButton *kindButton,*commitButton;
@property(nonatomic,strong) UITextField *nameField,*diamField,*lengthField,*feedField,*spindleField;
@property(nonatomic,strong) NSMutableDictionary *paramFields;
@property(nonatomic,strong) NSMutableArray *stepperSlots;
@property(nonatomic,strong) NSMutableArray *operations;
@property(nonatomic,strong) NSArray *projects;
@property(nonatomic,copy) NSString *kind;
@property(nonatomic,assign) NSInteger editIndex,selectedOp,selectedProject;
@property(nonatomic,assign) BOOL busy,dirtyCode,verified;
@property(nonatomic,strong) NSDictionary *verifiedModel;
@end

@implementation CNCTurningController
- (instancetype)initWithBaseURL:(NSString *)url {
 if((self=[super init])){_baseURL=[url copy];_operations=[NSMutableArray array];_projects=@[];_kind=@"diameter";_editIndex=-1;_selectedOp=-1;_selectedProject=-1;}
 return self;
}
- (UIButton *)button:(NSString *)title action:(SEL)action {
 UIButton *b=[UIButton buttonWithType:UIButtonTypeSystem];[b setTitle:title forState:UIControlStateNormal];[b setTitleColor:TCYAN() forState:UIControlStateNormal];b.backgroundColor=TPANEL();b.layer.cornerRadius=8;
 b.titleLabel.font=[UIFont boldSystemFontOfSize:16];b.titleLabel.adjustsFontSizeToFitWidth=YES;
 [b addTarget:self action:action forControlEvents:UIControlEventTouchUpInside];return b;
}
- (UILabel *)label:(NSString *)text {
 UILabel *l=[UILabel new];l.text=text;l.textColor=TWHITE();l.font=[UIFont systemFontOfSize:16];l.numberOfLines=2;return l;
}
- (UITextField *)field:(NSString *)value numeric:(BOOL)num {
 UITextField *f=[UITextField new];f.text=value;f.backgroundColor=TPANEL();f.textColor=TWHITE();f.layer.cornerRadius=8;f.font=[UIFont systemFontOfSize:19];f.delegate=self;f.keyboardType=num?UIKeyboardTypeDecimalPad:UIKeyboardTypeDefault;f.autocorrectionType=UITextAutocorrectionTypeNo;f.autocapitalizationType=UITextAutocapitalizationTypeNone;
 [f addTarget:self action:@selector(fieldChanged) forControlEvents:UIControlEventEditingChanged];return f;
}
- (void)textFieldDidBeginEditing:(UITextField *)textField {
 [textField performSelector:@selector(selectAll:) withObject:nil afterDelay:0];
}
- (void)viewDidLoad {
 [super viewDidLoad];self.view.backgroundColor=TBG();
 UIButton *back=[self button:@"‹ SPÄŤ" action:@selector(close)];back.tag=900;[self.view addSubview:back];
 UILabel *heading=[self label:@"AlphaLink CAM iPad V1.6 • EDITOR"];heading.tag=901;heading.font=[UIFont boldSystemFontOfSize:21];heading.textColor=TCYAN();[self.view addSubview:heading];
 self.status=[self label:@"NOVÝ NÁVRH • geometria bude overená Raspberry Pi"];self.status.tag=902;[self.view addSubview:self.status];
 self.tabs=[[UISegmentedControl alloc] initWithItems:@[@"ZADANIE",@"OPERÁCIE",@"2D NÁHĽAD",@"G-KÓD",@"NÁVRHY"]];self.tabs.selectedSegmentIndex=0;
 [self.tabs setTitleTextAttributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:17]} forState:UIControlStateNormal];
 [self.tabs addTarget:self action:@selector(switchTab) forControlEvents:UIControlEventValueChanged];[self.view addSubview:self.tabs];
 self.inputPage=[UIView new];self.operationPage=[UIView new];self.previewPage=[UIView new];self.codePage=[UIView new];self.projectsPage=[UIView new];
 for(UIView *v in @[self.inputPage,self.operationPage,self.previewPage,self.codePage,self.projectsPage]){v.backgroundColor=TBG();[self.view addSubview:v];}
 self.inputScroll=[UIScrollView new];self.inputScroll.keyboardDismissMode=UIScrollViewKeyboardDismissModeInteractive;[self.inputPage addSubview:self.inputScroll];
 self.inputBody=[UIView new];[self.inputScroll addSubview:self.inputBody];
 self.nameField=[self field:@"O0001" numeric:NO];self.diamField=[self field:@"40" numeric:YES];self.lengthField=[self field:@"60" numeric:YES];self.feedField=[self field:@"0.2" numeric:YES];self.spindleField=[self field:@"800" numeric:YES];
 for(UITextField *f in @[self.nameField,self.diamField,self.lengthField,self.feedField,self.spindleField])[self.inputBody addSubview:f];
 self.paramFields=[NSMutableDictionary dictionary];self.stepperSlots=[NSMutableArray array];
 self.kindButton=[self button:@"OPERÁCIA: STIAHNUŤ PRIEMER ▾" action:@selector(chooseKind)];[self.inputBody addSubview:self.kindButton];
 self.commitButton=[self button:@"PRIDAŤ OPERÁCIU" action:@selector(commitOperation)];[self.inputBody addSubview:self.commitButton];
 UIButton *verify=[self button:@"OVERIŤ PROFIL NA PI" action:@selector(requestPreview)];verify.tag=911;[self.inputBody addSubview:verify];
 UIButton *toList=[self button:@"ZOZNAM OPERÁCIÍ ›" action:@selector(showOps)];toList.tag=912;[self.inputBody addSubview:toList];
 self.operationTable=[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];self.operationTable.backgroundColor=TBG();self.operationTable.separatorColor=TPANEL();self.operationTable.rowHeight=68;self.operationTable.delegate=self;self.operationTable.dataSource=self;[self.operationPage addSubview:self.operationTable];
 NSArray *opText=@[@"UPRAVIŤ",@"POSUNÚŤ ↑",@"POSUNÚŤ ↓",@"ODSTRÁNIŤ"];NSArray *opSEL=@[@"editSelected",@"moveUp",@"moveDown",@"removeSelected"];
 for(NSInteger i=0;i<4;i++){UIButton *b=[self button:opText[i] action:NSSelectorFromString(opSEL[i])];b.tag=920+i;[self.operationPage addSubview:b];}
 self.preview=[CNCProfileView new];self.preview.layer.cornerRadius=9;self.preview.layer.masksToBounds=YES;[self.previewPage addSubview:self.preview];
 UIButton *refresh=[self button:@"PREPOČÍTAŤ NA RASPBERRY PI" action:@selector(requestPreview)];refresh.tag=931;[self.previewPage addSubview:refresh];
 UILabel *previewHelp=[self label:@"Zelený profil = model overený serverom. Náhľad nie je kontrola kolízií ani simulácia obrábania."];previewHelp.tag=932;[self.previewPage addSubview:previewHelp];
 UILabel *codeInfo=[self label:@"CAM program .600 generuje AlphaLink na Raspberry Pi. Neskúšaj ho bez kontroly na stroji."];codeInfo.tag=941;[self.codePage addSubview:codeInfo];
 self.codeName=[self field:@"O0001" numeric:NO];[self.codePage addSubview:self.codeName];
 self.gcode=[[UITextView alloc] initWithFrame:CGRectZero];self.gcode.backgroundColor=TPANEL();self.gcode.textColor=TWHITE();self.gcode.font=[UIFont fontWithName:@"Menlo" size:18]?:[UIFont systemFontOfSize:18];self.gcode.layer.cornerRadius=8;[self.codePage addSubview:self.gcode];
 NSArray *codeTexts=@[@"GENEROVAŤ KÓD",@"ULOŽIŤ .600 NA PI"];NSArray *codeSEL=@[@"generateCode",@"saveCode"];
 for(NSInteger i=0;i<2;i++){UIButton *b=[self button:codeTexts[i] action:NSSelectorFromString(codeSEL[i])];b.tag=945+i;[self.codePage addSubview:b];}
 self.projectsTable=[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];self.projectsTable.backgroundColor=TBG();self.projectsTable.separatorColor=TPANEL();self.projectsTable.rowHeight=60;self.projectsTable.dataSource=self;self.projectsTable.delegate=self;[self.projectsPage addSubview:self.projectsTable];
 NSArray *projectTexts=@[@"OBNOVIŤ ZOZNAM",@"OTVORIŤ NÁVRH",@"ULOŽIŤ .HBJ",@"NOVÝ NÁVRH"];NSArray *projectSEL=@[@"refreshProjects",@"openProject",@"saveProject",@"newProject"];
 for(NSInteger i=0;i<4;i++){UIButton *b=[self button:projectTexts[i] action:NSSelectorFromString(projectSEL[i])];b.tag=950+i;[self.projectsPage addSubview:b];}
 [self fillParams:nil];[self switchTab];[self localPreview];
}
- (void)viewDidLayoutSubviews {
 [super viewDidLayoutSubviews];
 CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height,top=self.view.safeAreaInsets.top+8,bottom=self.view.safeAreaInsets.bottom;
 [self.view viewWithTag:900].frame=CGRectMake(16,top,100,48);
 [self.view viewWithTag:901].frame=CGRectMake(128,top,w-144,48);
 self.status.frame=CGRectMake(16,top+51,w-32,44);
 self.tabs.frame=CGRectMake(16,top+100,w-32,45);
 CGRect page=CGRectMake(14,top+155,w-28,MAX(150,h-bottom-top-167));
 NSArray *pages=@[self.inputPage,self.operationPage,self.previewPage,self.codePage,self.projectsPage];
 for(UIView *p in pages)p.frame=page;
 self.inputScroll.frame=self.inputPage.bounds;
 [self layoutForm];
 CGFloat pw=page.size.width,ph=page.size.height;
 self.operationTable.frame=CGRectMake(0,0,pw,MAX(100,ph-72));
 CGFloat opWidth=(pw-3*10)/4;for(NSInteger i=0;i<4;i++)[self.operationPage viewWithTag:920+i].frame=CGRectMake(i*(opWidth+10),ph-60,opWidth,56);
 self.preview.frame=CGRectMake(0,0,pw,MAX(100,ph-109));
 [self.previewPage viewWithTag:931].frame=CGRectMake(0,ph-98,MIN(400,pw),52);
 [self.previewPage viewWithTag:932].frame=CGRectMake(0,ph-42,pw,41);
 [self.codePage viewWithTag:941].frame=CGRectMake(0,0,pw,38);
 self.codeName.frame=CGRectMake(0,42,MIN(pw,400),50);
 self.gcode.frame=CGRectMake(0,100,pw,MAX(80,ph-168));
 [self.codePage viewWithTag:945].frame=CGRectMake(0,ph-60,(pw-10)/2,55);
 [self.codePage viewWithTag:946].frame=CGRectMake((pw+10)/2,ph-60,(pw-10)/2,55);
 self.projectsTable.frame=CGRectMake(0,0,pw,MAX(100,ph-72));
 CGFloat pb=(pw-3*10)/4;for(NSInteger i=0;i<4;i++)[self.projectsPage viewWithTag:950+i].frame=CGRectMake(i*(pb+10),ph-60,pb,55);
}
- (void)adjustNumber:(UIButton *)button {
 NSInteger index=(button.tag-2500)/2;
 if(index<0 || index>=self.stepperSlots.count)return;
 NSDictionary *slot=self.stepperSlots[index];
 UITextField *field=slot[@"field"];
 double increment=[slot[@"step"] doubleValue];
 NSInteger precision=[slot[@"digits"] integerValue];
 double current=TParse(field.text);
 BOOL increase=((button.tag-2500)%2==0);
 double value=current+(increase?increment:-increment);
 if(value<0)value=0;
 if(!isfinite(value))return;
 field.text=[NSString stringWithFormat:@"%.*f",(int)precision,value];
 [self fieldChanged];
}
- (void)inlineField:(UITextField *)field title:(NSString *)title x:(CGFloat)x y:(CGFloat)y width:(CGFloat)width step:(double)step digits:(NSInteger)digits {
 BOOL numeric=(step>0);
 CGFloat spinner=numeric?34:0;
 CGFloat valueW=numeric?100:138;
 CGFloat labelW=MAX(110,width-valueW-spinner-14);
 UILabel *label=[self label:title];
 label.font=[UIFont systemFontOfSize:17 weight:UIFontWeightMedium];
 label.adjustsFontSizeToFitWidth=YES;
 label.minimumScaleFactor=.83;
 label.numberOfLines=2;
 label.textColor=[UIColor colorWithRed:.72 green:.88 blue:.91 alpha:1];
 label.frame=CGRectMake(x,y,labelW,48);
 [self.inputBody addSubview:label];
 field.frame=CGRectMake(x+labelW+7,y+2,valueW,44);
 field.font=[UIFont boldSystemFontOfSize:22];
 field.textAlignment=NSTextAlignmentCenter;
 field.textColor=[UIColor whiteColor];
 field.backgroundColor=[UIColor colorWithRed:.10 green:.29 blue:.36 alpha:1];
 if(numeric){
  NSInteger slot=self.stepperSlots.count;
  [self.stepperSlots addObject:@{@"field":field,@"step":@(step),@"digits":@(digits)}];
  CGFloat bx=x+labelW+7+valueW+4;
  UIButton *up=[self button:@"▲" action:@selector(adjustNumber:)];
  UIButton *down=[self button:@"▼" action:@selector(adjustNumber:)];
  up.tag=2500+slot*2;down.tag=2501+slot*2;
  for(UIButton *b in @[up,down]){
   b.titleLabel.font=[UIFont boldSystemFontOfSize:17];
   b.backgroundColor=[UIColor colorWithRed:.12 green:.35 blue:.42 alpha:1];
   b.layer.cornerRadius=5;
   [self.inputBody addSubview:b];
  }
  up.frame=CGRectMake(bx,y+1,spinner,23);
  down.frame=CGRectMake(bx,y+25,spinner,23);
 }
}
- (void)layoutForm {
 CGFloat width=self.inputScroll.bounds.size.width;
 if(width<100)return;
 for(UIView *v in [self.inputBody.subviews copy]){
  if([v isKindOfClass:UILabel.class] || ([v isKindOfClass:UIButton.class] && v.tag>=2500 && v.tag<2600))
   [v removeFromSuperview];
 }
 [self.stepperSlots removeAllObjects];
 CGFloat margin=6,gap=12,col=(width-2*margin-gap)/2.0;
 CGFloat y=5;
 // Postup nastavovania: identifikácia návrhu → geometria polotovaru → rezné podmienky.
 [self inlineField:self.nameField title:@"01  Číslo návrhu" x:margin y:y width:col step:0 digits:0];
 UILabel *kindHint=[self label:@"HARRISON ALPHA 400  •  CAM .600"];
 kindHint.textColor=TCYAN();
 kindHint.font=[UIFont boldSystemFontOfSize:16];
 kindHint.frame=CGRectMake(margin+col+gap,y+1,col,45);
 [self.inputBody addSubview:kindHint];
 y+=55;
 [self inlineField:self.diamField title:@"02  Polotovar Ø" x:margin y:y width:col step:.1 digits:1];
 [self inlineField:self.lengthField title:@"Dĺžka L (mm)" x:margin+col+gap y:y width:col step:1 digits:0];
 y+=55;
 [self inlineField:self.feedField title:@"03  Posuv F" x:margin y:y width:col step:.01 digits:2];
 [self inlineField:self.spindleField title:@"Otáčky S" x:margin+col+gap y:y width:col step:10 digits:0];
 y+=55+3;
 UILabel *title=[self label:@"OBRÁBACIA OPERÁCIA"];
 title.font=[UIFont boldSystemFontOfSize:20];
 title.textColor=TCYAN();
 title.frame=CGRectMake(margin,y,width-2*margin,28);
 [self.inputBody addSubview:title];
 y+=29;
 self.kindButton.frame=CGRectMake(margin,y,width-2*margin,43);
 self.kindButton.titleLabel.font=[UIFont boldSystemFontOfSize:18];
 y+=49;
 NSArray *defs=TDefs(self.kind);
 NSInteger n=0;
 for(NSArray *d in defs){
  NSString *key=TString(d[0]);
  double step=0.1;NSInteger digits=1;
  if([key isEqualToString:@"angle"]){step=1;digits=0;}
  if([key isEqualToString:@"step"]){step=0.1;digits=2;}
  if([key isEqualToString:@"amount"]){step=0.1;digits=2;}
  UITextField *field=self.paramFields[key];
  [self inlineField:field title:TString(d[1]) x:margin+(n%2)*(col+gap) y:y+(n/2)*55 width:col step:step digits:digits];
  n++;
 }
 y+=ceil((double)defs.count/2.0)*55+5;
 CGFloat half=(width-2*margin-gap)/2;
 self.commitButton.frame=CGRectMake(margin,y,half,49);
 [self.inputBody viewWithTag:911].frame=CGRectMake(margin+half+gap,y,half,49);
 y+=55;
 [self.inputBody viewWithTag:912].frame=CGRectMake(margin,y,width-2*margin,48);
 y+=54;
 CGFloat available=self.inputScroll.bounds.size.height;
 self.inputBody.frame=CGRectMake(0,0,width,MAX(y,available));
 self.inputScroll.contentSize=CGSizeMake(width,MAX(y,available));
 if(y<=available+1){
  self.inputScroll.scrollEnabled=NO;
  self.inputScroll.contentOffset=CGPointZero;
 }else self.inputScroll.scrollEnabled=YES;
}
- (void)fillParams:(NSDictionary *)selected {
 [self.paramFields removeAllObjects];
 for(NSArray *spec in TDefs(self.kind)){
  id value=selected[spec[0]]?:spec[2];
  UITextField *f=[self field:[value description] numeric:YES];
  self.paramFields[spec[0]]=f;[self.inputBody addSubview:f];
 }
 [self.kindButton setTitle:[NSString stringWithFormat:@"OPERÁCIA: %@  ▾",TNames()[self.kind]?:self.kind] forState:UIControlStateNormal];
 [self.commitButton setTitle:self.editIndex>=0?@"ULOŽIŤ ÚPRAVU":@"PRIDAŤ OPERÁCIU" forState:UIControlStateNormal];
 [self layoutForm];
}
- (void)clearParams {
 for(UIView *v in self.paramFields.allValues)[v removeFromSuperview];
 [self fillParams:nil];
}
- (void)chooseKind {
 UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Vyber obrábaciu operáciu" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
 for(NSString *key in @[@"face",@"diameter",@"taper",@"groove",@"chamfer",@"radius",@"partoff"]) {
  [a addAction:[UIAlertAction actionWithTitle:TNames()[key] style:UIAlertActionStyleDefault handler:^(UIAlertAction *ac) {
   self.kind=key;self.editIndex=-1;[self clearParams];[self localPreview];
  }]];
 }
 [a addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
 UIPopoverPresentationController *pop=a.popoverPresentationController;
 if(pop){pop.sourceView=self.kindButton;pop.sourceRect=self.kindButton.bounds;}
 [self presentViewController:a animated:YES completion:nil];
}
- (void)showTab:(NSInteger)i {self.tabs.selectedSegmentIndex=i;[self switchTab];}
- (void)showOps{[self showTab:1];}
- (void)switchTab {
 NSArray *pages=@[self.inputPage,self.operationPage,self.previewPage,self.codePage,self.projectsPage];
 for(NSInteger i=0;i<pages.count;i++)[pages[i] setHidden:i!=self.tabs.selectedSegmentIndex];
 if(self.tabs.selectedSegmentIndex==4)[self refreshProjects];
 if(self.tabs.selectedSegmentIndex==2)[self localPreview];
}
- (void)close {[self dismissViewControllerAnimated:YES completion:nil];}
- (void)fieldChanged {self.verified=NO;self.verifiedModel=nil;[self localPreview];}
- (void)showError:(NSString *)e {self.status.text=e;UIAlertController *a=[UIAlertController alertControllerWithTitle:@"CNC MyLink" message:e preferredStyle:UIAlertControllerStyleAlert];[a addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];[self presentViewController:a animated:YES completion:nil];}
- (BOOL)validFields {
 double d=TParse(self.diamField.text),l=TParse(self.lengthField.text),f=TParse(self.feedField.text),r=TParse(self.spindleField.text);
 if(!isfinite(d)||d<=0||d>1000||!isfinite(l)||l<=0||l>3000){[self showError:@"Priemer musí byť 1–1000 mm a dĺžka 1–3000 mm."];return NO;}
 if(!isfinite(f)||f<.005||f>2||!isfinite(r)||r<50||r>5000){[self showError:@"Rozsah editora: F 0.005–2 mm/ot, S 50–5000 ot/min. Toto NIE SÚ overené limity stroja."];return NO;}
 if(!self.nameField.text.length){[self showError:@"Zadaj názov návrhu."];return NO;}
 return YES;
}
- (NSDictionary *)projectWith:(NSArray *)ops {
 return @{@"version":@3,@"name":self.nameField.text?:@"O0001",
 @"stock":@{@"diameter":@(TParse(self.diamField.text)),@"length":@(TParse(self.lengthField.text))},
 @"technology":@{@"feed":@(TParse(self.feedField.text)),@"spindle":@(TParse(self.spindleField.text))},
 @"operations":ops?:@[]};
}
- (void)request:(NSString *)path body:(NSDictionary *)body finished:(void (^)(NSDictionary *,NSError *))done {
 NSURL *url=[NSURL URLWithString:[self.baseURL stringByAppendingString:path]];
 if(!url){done(nil,[NSError errorWithDomain:@"CNC" code:-1 userInfo:@{NSLocalizedDescriptionKey:@"Neplatná adresa Raspberry Pi"}]);return;}
 NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:25];
 req.HTTPMethod=body?@"POST":@"GET";if(body){req.HTTPBody=[NSJSONSerialization dataWithJSONObject:body options:0 error:nil];[req setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];}
 [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data,NSURLResponse *resp,NSError *error){
  id parsed=data.length?[NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingMutableContainers error:nil]:nil;
  NSDictionary *j=[parsed isKindOfClass:NSDictionary.class]?parsed:nil;
  NSHTTPURLResponse *h=(NSHTTPURLResponse *)resp;
  if(!error && [resp isKindOfClass:NSHTTPURLResponse.class] && (h.statusCode<200||h.statusCode>=300)){
   NSString *msg=TString(j[@"error"]);if(!msg.length)msg=[NSString stringWithFormat:@"HTTP %ld",(long)h.statusCode];
   error=[NSError errorWithDomain:@"HTTP" code:h.statusCode userInfo:@{NSLocalizedDescriptionKey:msg}];
  }
  dispatch_async(dispatch_get_main_queue(),^{done(j,error);});
 }] resume];
}
- (NSDictionary *)localModel:(NSDictionary *)project {
 NSDictionary *stock=project[@"stock"];double dia=TNumber(stock[@"diameter"],40),l0=TNumber(stock[@"length"],60),face=0;
 for(NSDictionary *o in project[@"operations"])if([o[@"type"] isEqualToString:@"face"]){face=TNumber(o[@"amount"],0);break;}
 double len=MAX(1,l0-face);NSMutableArray *out=[NSMutableArray array],*parts=[NSMutableArray array];
 for(NSDictionary *o in project[@"operations"])if([o[@"type"] isEqualToString:@"partoff"])[parts addObject:@{@"z":o[@"z"]?:@0}];
 for(int i=180;i>=0;i--){
  double z=len*(double)i/180.0,r=dia*.5;
  for(NSDictionary *o in project[@"operations"]){
   NSString *type=o[@"type"];double shift=[o[@"frame"] isEqualToString:@"faced"]?0:-face;
   double start=TNumber(o[@"zStart"],0)+shift,end=TNumber(o[@"zEnd"],0)+shift,location=TNumber(o[@"z"],0)+shift;
   if([type isEqualToString:@"diameter"]&&z>=start&&z<=end)r=MIN(r,TNumber(o[@"diameter"],dia)*.5);
   if([type isEqualToString:@"groove"]&&z>=start&&z<=start+TNumber(o[@"width"],0))r=MIN(r,TNumber(o[@"diameter"],dia)*.5);
   if([type isEqualToString:@"taper"]&&z>=start&&z<=end&&end>start){
    double t=(z-start)/(end-start);r=MIN(r,(TNumber(o[@"diameterStart"],dia)+(TNumber(o[@"diameterEnd"],dia)-TNumber(o[@"diameterStart"],dia))*t)*.5);
   }
   if([type isEqualToString:@"chamfer"]&&fabs(location)<.01 && z>=0&&z<=TNumber(o[@"size"],0)){
    double width=TNumber(o[@"size"],0),angle=TNumber(o[@"angle"],45)*M_PI/180.0;
    r=MAX(.01,MIN(r,r-(width-z)*tan(angle)));
   }
  }
  [out addObject:@[@(z),@(MAX(0.01,r))]];
 }
 return @{@"stock":@{@"diameter":@(dia),@"length":@(l0)},@"finished_length":@(len),@"profile":out,@"partoffs":parts};
}
- (void)localPreview {
 if(self.verifiedModel){self.preview.shape=self.verifiedModel;self.preview.verified=YES;}
 else {self.preview.shape=[self localModel:[self projectWith:self.operations]];self.preview.verified=NO;}
 [self.preview setNeedsDisplay];
}
- (void)requestPreview {
 if(self.busy)return;if(![self validFields])return;
 self.busy=YES;self.status.text=@"Overujem 2D geometriu na Raspberry Pi...";
 [self request:@"/api/turning/preview" body:[self projectWith:self.operations] finished:^(NSDictionary *j,NSError *e){
  self.busy=NO;
  if(e||![j[@"profile"] isKindOfClass:NSArray.class]){[self showError:[NSString stringWithFormat:@"Overenie geometrie zlyhalo: %@",e.localizedDescription?:@"neplatná odpoveď"]];return;}
  self.verifiedModel=j;self.verified=YES;[self localPreview];self.status.text=@"Geometrický model overený na Raspberry Pi. Dráhy nástroja a kolízie NIE SÚ overené.";
  [self showTab:2];
 }];
}
- (NSDictionary *)enteredOperation {
 NSMutableDictionary *o=[NSMutableDictionary dictionaryWithObject:self.kind forKey:@"type"];
 for(NSArray *d in TDefs(self.kind)){
  NSString *key=d[0];NSString *v=[((UITextField *)self.paramFields[key]).text stringByReplacingOccurrencesOfString:@"," withString:@"."];
  if(!v.length)return nil;
  double n=[v doubleValue];if(!isfinite(n))return nil;
  o[key]=@(n);
 }
 if(![self.kind isEqualToString:@"face"]){
  BOOL faced=NO;
  for(NSInteger i=0;i<self.operations.count;i++){if(self.editIndex>=0 && i>=self.editIndex)break;if([self.operations[i][@"type"] isEqualToString:@"face"])faced=YES;}
  if(self.editIndex>=0){NSString *old=self.operations[self.editIndex][@"frame"];o[@"frame"]=old?: (faced?@"faced":@"raw");}
  else o[@"frame"]=faced?@"faced":@"raw";
 }
 return o;
}
- (void)commitOperation {
 if(self.busy)return;if(![self validFields])return;
 NSDictionary *op=[self enteredOperation];if(!op){[self showError:@"Vyplň všetky parametre obrábacej operácie."];return;}
 NSMutableArray *candidate=[self.operations mutableCopy];
 if(self.editIndex>=0 && self.editIndex<candidate.count)candidate[self.editIndex]=op;else[candidate addObject:op];
 [self verifyAndReplace:candidate message:@"Operácia pridaná alebo upravená."];
}
- (void)verifyAndReplace:(NSArray *)candidate message:(NSString *)msg {
 if(self.busy)return;
 self.busy=YES;self.status.text=@"Overujem operácie na Raspberry Pi...";
 [self request:@"/api/turning/preview" body:[self projectWith:candidate] finished:^(NSDictionary *j,NSError *e){
  self.busy=NO;
  if(e||![j[@"profile"] isKindOfClass:NSArray.class]){
   [self showError:[NSString stringWithFormat:@"Operácia nebola použitá. Server ju odmietol: %@",e.localizedDescription?:@"neplatná odpoveď."]];
   return;
  }
  self.operations=[candidate mutableCopy];self.editIndex=-1;self.selectedOp=-1;self.verifiedModel=j;self.verified=YES;
  [self clearParams];[self localPreview];[self.operationTable reloadData];
  self.status.text=[NSString stringWithFormat:@"%@ %lu operácií. %@",msg,(unsigned long)candidate.count,@"Bez testu kolízií."];
  [self showTab:1];
 }];
}
- (NSInteger)tableView:(UITableView *)table numberOfRowsInSection:(NSInteger)section {
 return table==self.operationTable?self.operations.count:self.projects.count;
}
- (UITableViewCell *)tableView:(UITableView *)table cellForRowAtIndexPath:(NSIndexPath *)path {
 UITableViewCell *cell=[table dequeueReusableCellWithIdentifier:@"Row"];
 if(!cell)cell=[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"Row"];
 cell.backgroundColor=TBG();cell.textLabel.textColor=TWHITE();cell.detailTextLabel.textColor=TCYAN();
 cell.textLabel.font=[UIFont boldSystemFontOfSize:18];cell.detailTextLabel.font=[UIFont systemFontOfSize:15];
 if(table==self.operationTable){
  NSDictionary *op=self.operations[path.row];cell.textLabel.text=[NSString stringWithFormat:@"%ld. %@",(long)path.row+1,TNames()[op[@"type"]]?:@"OPERÁCIA"];
  NSMutableArray *parts=[NSMutableArray array];
  for(NSArray *d in TDefs(op[@"type"]))if(op[d[0]])[parts addObject:[NSString stringWithFormat:@"%@: %@",d[0],op[d[0]]]];
  cell.detailTextLabel.text=[parts componentsJoinedByString:@"  •  "];
  cell.accessoryType=self.selectedOp==path.row?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
 }else {
  NSDictionary *p=self.projects[path.row];
  NSString *name=TString(p[@"name"]);cell.textLabel.text=[NSString stringWithFormat:@"%@.hbj",name];
  cell.detailTextLabel.text=[NSString stringWithFormat:@"Uložený návrh  •  %@",TString(p[@"modified"])];
  cell.accessoryType=self.selectedProject==path.row?UITableViewCellAccessoryCheckmark:UITableViewCellAccessoryNone;
 }
 return cell;
}
- (void)tableView:(UITableView *)table didSelectRowAtIndexPath:(NSIndexPath *)p {
 if(table==self.operationTable)self.selectedOp=p.row;else self.selectedProject=p.row;[table reloadData];
}
- (void)editSelected {
 if(self.selectedOp<0||self.selectedOp>=self.operations.count){[self showError:@"Vyber operáciu zo zoznamu."];return;}
 NSDictionary *op=self.operations[self.selectedOp];self.kind=TString(op[@"type"]);self.editIndex=self.selectedOp;
 for(UIView *v in self.paramFields.allValues)[v removeFromSuperview];[self fillParams:op];[self showTab:0];
}
- (void)removeSelected {
 if(self.selectedOp<0||self.selectedOp>=self.operations.count){[self showError:@"Vyber operáciu."];return;}
 NSMutableArray *arr=[self.operations mutableCopy];[arr removeObjectAtIndex:self.selectedOp];
 [self verifyAndReplace:arr message:@"Operácia odstránená."];
}
- (void)moveUp {[self moveOp:-1];}
- (void)moveDown {[self moveOp:1];}
- (void)moveOp:(NSInteger)delta {
 NSInteger n=self.selectedOp,to=n+delta;if(n<0||to<0||to>=self.operations.count){[self showError:@"Vyber operáciu, ktorú možno posunúť."];return;}
 NSMutableArray *arr=[self.operations mutableCopy];[arr exchangeObjectAtIndex:n withObjectAtIndex:to];
 [self verifyAndReplace:arr message:@"Poradie operácií zmenené."];
}
- (void)newProject {
 UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Začať nový návrh?" message:@"Neuložené operácie sa stratia." preferredStyle:UIAlertControllerStyleAlert];
 [a addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
 [a addAction:[UIAlertAction actionWithTitle:@"NOVÝ" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a){
  [self.operations removeAllObjects];self.selectedOp=-1;self.editIndex=-1;self.nameField.text=@"O0001";self.diamField.text=@"40";self.lengthField.text=@"60";self.feedField.text=@"0.2";self.spindleField.text=@"800";self.kind=@"diameter";
  [self clearParams];self.verifiedModel=nil;self.verified=NO;[self localPreview];[self.operationTable reloadData];[self showTab:0];self.status.text=@"Nový návrh vytvorený.";
 }]];
 [self presentViewController:a animated:YES completion:nil];
}
- (void)refreshProjects {
 [self request:@"/api/turning/projects" body:nil finished:^(NSDictionary *j,NSError *e){
  if(e||![j[@"projects"] isKindOfClass:NSArray.class]){self.status.text=[NSString stringWithFormat:@"Načítanie návrhov zlyhalo: %@",e.localizedDescription?:@"server neodpovedal"];return;}
  self.projects=j[@"projects"];self.selectedProject=-1;[self.projectsTable reloadData];
  self.status.text=[NSString stringWithFormat:@"Na Raspberry Pi: %lu návrhov .hbj",(unsigned long)self.projects.count];
 }];
}
- (void)openProject {
 if(self.selectedProject<0||self.selectedProject>=self.projects.count){[self showError:@"Vyber uložený návrh .hbj."];return;}
 NSString *name=TString(self.projects[self.selectedProject][@"name"]);
 if(!name.length){[self showError:@"Názov návrhu nie je platný."];return;}
 NSString *encoded=[name stringByAddingPercentEncodingWithAllowedCharacters:NSCharacterSet.URLQueryAllowedCharacterSet];
 [self request:[@"/api/turning/project?name=" stringByAppendingString:encoded] body:nil finished:^(NSDictionary *j,NSError *e){
  NSDictionary *p=j[@"project"];if(e||![p isKindOfClass:NSDictionary.class]){[self showError:e.localizedDescription?:@"Nepodarilo sa otvoriť návrh."];return;}
  NSArray *ops=[p[@"operations"] isKindOfClass:NSArray.class]?p[@"operations"]:@[];
  NSDictionary *stock=p[@"stock"]?:@{},*tech=p[@"technology"]?:@{};
  self.operations=[ops mutableCopy];self.nameField.text=TString(p[@"name"]);
  self.diamField.text=[stock[@"diameter"] description]?:@"40";self.lengthField.text=[stock[@"length"] description]?:@"60";
  self.feedField.text=[tech[@"feed"] description]?:@"0.2";self.spindleField.text=[tech[@"spindle"] description]?:@"800";
  self.editIndex=-1;self.selectedOp=-1;self.verifiedModel=nil;[self clearParams];[self localPreview];[self.operationTable reloadData];
  self.status.text=[NSString stringWithFormat:@"Otvorený návrh %@.hbj • %lu operácií",name,(unsigned long)ops.count];
  [self showTab:0];[self requestPreview];
 }];
}
- (void)saveProject {
 if(self.busy)return;if(![self validFields])return;
 if(self.editIndex>=0){[self showError:@"Najprv stlač ULOŽIŤ ÚPRAVU pre rozpracovanú operáciu."];return;}
 if(!self.operations.count){[self showError:@"Najprv pridaj aspoň jednu operáciu."];return;}
 NSString *name=self.nameField.text;
 BOOL exists=NO;for(NSDictionary *p in self.projects)if([TString(p[@"name"]) isEqualToString:name]){exists=YES;break;}
 UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Uložiť návrh na Raspberry Pi?"
 message:[NSString stringWithFormat:@"%@.hbj%@",name,exists?@"\nExistujúci návrh bude prepísaný.":@""] preferredStyle:UIAlertControllerStyleAlert];
 [a addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
 [a addAction:[UIAlertAction actionWithTitle:@"ULOŽIŤ" style:UIAlertActionStyleDefault handler:^(UIAlertAction *aa){
  self.busy=YES;
  [self request:@"/api/turning/save" body:[self projectWith:self.operations] finished:^(NSDictionary *j,NSError *e){
   self.busy=NO;
   if(e||![j[@"stored"] boolValue]||![j[@"verified"] boolValue]){[self showError:e.localizedDescription?:@"Server nepotvrdil uloženie návrhu."];return;}
   self.status.text=[NSString stringWithFormat:@"Návrh %@.hbj uložený a potvrdený serverom.",name];[self refreshProjects];
  }];
 }]];
 [self presentViewController:a animated:YES completion:nil];
}
- (void)generateCode {
 if(self.busy)return;if(![self validFields])return;
 if(self.editIndex>=0){[self showError:@"Najprv dokonči editáciu vybranej operácie."];return;}
 if(!self.operations.count){[self showError:@"Najprv pridaj obrábacie operácie."];return;}
 self.busy=YES;self.status.text=@"Generujem CAM .600 na AlphaLink serveri...";
 [self request:@"/api/turning/cam-preview" body:[self projectWith:self.operations] finished:^(NSDictionary *j,NSError *e){
  self.busy=NO;
  if(e || ![j[@"code"] isKindOfClass:NSString.class] || ![j[@"code"] length]){
   [self showError:e.localizedDescription?:@"Generovanie CAM programu sa nepodarilo."];return;
  }
  if(![j[@"sendable"] boolValue] || ![TString(j[@"format"]) isEqualToString:@"ALPHA400-CAM-600"]){
   [self showError:@"Raspberry Pi nepotvrdilo strojový formát ALPHA400-CAM-600 a sendable=true. Program nebude použitý."];
   return;
  }
  NSString *cam=j[@"code"];
  NSArray *lines=[cam componentsSeparatedByCharactersInSet:NSCharacterSet.newlineCharacterSet];
  NSString *header=lines.count?TString(lines[0]):@"";
  NSString *az=lines.count>1?TString(lines[1]):@"";
  if(![header hasPrefix:@"O"] || ![az isEqualToString:@"(AZ PS)"]){
   [self showError:@"CAM generátor nevrátil hlavičku O#### / (AZ PS). Uloženie je zastavené."];
   return;
  }
  self.gcode.text=cam;self.codeName.text=TString(j[@"name"]).length?j[@"name"]:self.nameField.text;
  self.status.text=@"CAM V34: serverový .600, G00 len na predpokladanej voľnej dráhe; skontroluj X/Z, skľučovadlo a korekcie.";
  [self showTab:3];
  NSArray *warnings=[j[@"warnings"] isKindOfClass:NSArray.class]?j[@"warnings"]:@[];
  if(warnings.count) {
   NSString *text=[warnings componentsJoinedByString:@"\n• "];
   [self showError:[NSString stringWithFormat:@"Upozornenia generátora V34 (nie sú dôkazom bezpečnosti dráhy):\n• %@",text]];
  }
 }];
}
- (void)saveCode {
 if(!self.gcode.text.length){[self showError:@"Najprv vygeneruj CAM program .600."];return;}
 NSString *name=self.codeName.text;
 if(!name.length){[self showError:@"Zadaj názov CAM programu."];return;}
 UIAlertController *a=[UIAlertController alertControllerWithTitle:@"Uložiť .600 do knižnice?"
 message:@"Program sa uloží na Raspberry Pi, ale NESPÚŠŤA sa na stroji. Pred obrábaním je nutná kontrola." preferredStyle:UIAlertControllerStyleAlert];
 [a addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
 [a addAction:[UIAlertAction actionWithTitle:@"ULOŽIŤ" style:UIAlertActionStyleDefault handler:^(UIAlertAction *aa){
  [self request:@"/api/turning/cam-save" body:@{@"name":name,@"text":self.gcode.text} finished:^(NSDictionary *j,NSError *e){
   if(e){[self showError:e.localizedDescription];return;}
   NSDictionary *validation=[j[@"validation"] isKindOfClass:NSDictionary.class]?j[@"validation"]:nil;
   if(![j[@"stored"] boolValue] || ![validation[@"valid"] boolValue]){
    [self showError:@"Server nepotvrdil uloženie a validáciu CAM programu. Skontroluj knižnicu na Raspberry Pi."];
    return;
   }
   self.status.text=[NSString stringWithFormat:@"CAM program %@ uložený a overený na Raspberry Pi.",TString(j[@"name"])];
  }];
 }]];
 [self presentViewController:a animated:YES completion:nil];
}
@end

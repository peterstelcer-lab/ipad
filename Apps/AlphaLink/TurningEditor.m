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
@property(nonatomic,strong) NSArray *operations;
@property(nonatomic,assign) BOOL verified;
@end
@implementation CNCProfileView
// V1.9: full-diameter dimensioned turning drawing, derived only from stored geometry.
// The preview is NOT a machining simulation or tool/chuck collision verification.
- (UIColor *)clr:(CGFloat)r g:(CGFloat)g b:(CGFloat)b {return [UIColor colorWithRed:r green:g blue:b alpha:1];}
- (void)label:(NSString *)value at:(CGPoint)pt size:(CGFloat)size color:(UIColor *)color bold:(BOOL)bold {
 if(!value.length)return;
 [value drawAtPoint:pt withAttributes:@{NSFontAttributeName:bold?[UIFont boldSystemFontOfSize:size]:[UIFont systemFontOfSize:size],
 NSForegroundColorAttributeName:color}];
}
- (void)line:(CGContextRef)c from:(CGPoint)a to:(CGPoint)b color:(UIColor *)color width:(CGFloat)width {
 CGContextSetStrokeColorWithColor(c,color.CGColor);CGContextSetLineWidth(c,width);
 CGContextMoveToPoint(c,a.x,a.y);CGContextAddLineToPoint(c,b.x,b.y);CGContextStrokePath(c);
}
- (void)arrow:(CGContextRef)c at:(CGPoint)p toward:(CGPoint)tip color:(UIColor *)color size:(CGFloat)size {
 CGFloat dx=tip.x-p.x,dy=tip.y-p.y,d=hypot(dx,dy);
 if(d<.001)return;dx/=d;dy/=d;
 CGPoint wing1=CGPointMake(tip.x-dx*size-dy*size*.4,tip.y-dy*size+dx*size*.4);
 CGPoint wing2=CGPointMake(tip.x-dx*size+dy*size*.4,tip.y-dy*size-dx*size*.4);
 CGContextSetFillColorWithColor(c,color.CGColor);CGContextMoveToPoint(c,tip.x,tip.y);
 CGContextAddLineToPoint(c,wing1.x,wing1.y);CGContextAddLineToPoint(c,wing2.x,wing2.y);
 CGContextClosePath(c);CGContextFillPath(c);
}
- (void)verticalDimension:(CGContextRef)c x:(CGFloat)x top:(CGFloat)top bottom:(CGFloat)bottom
 text:(NSString *)value color:(UIColor *)color {
 if(bottom-top<14)return;
 [self line:c from:CGPointMake(x,top) to:CGPointMake(x,bottom) color:color width:1.3];
 [self arrow:c at:CGPointMake(x,top+13) toward:CGPointMake(x,top) color:color size:8];
 [self arrow:c at:CGPointMake(x,bottom-13) toward:CGPointMake(x,bottom) color:color size:8];
 CGContextSaveGState(c);
 CGContextTranslateCTM(c,x-10,(top+bottom)*.5+20);
 CGContextRotateCTM(c,-M_PI_2);
 [self label:value at:CGPointMake(0,0) size:13 color:color bold:YES];
 CGContextRestoreGState(c);
}
- (void)horizontalDimension:(CGContextRef)c x1:(CGFloat)x1 x2:(CGFloat)x2 y:(CGFloat)y
 text:(NSString *)value color:(UIColor *)color {
 CGFloat lo=MIN(x1,x2),hi=MAX(x1,x2);
 if(hi-lo<26)return;
 [self line:c from:CGPointMake(lo,y) to:CGPointMake(hi,y) color:color width:1.1];
 [self arrow:c at:CGPointMake(lo+12,y) toward:CGPointMake(lo,y) color:color size:7];
 [self arrow:c at:CGPointMake(hi-12,y) toward:CGPointMake(hi,y) color:color size:7];
 NSDictionary *font=@{NSFontAttributeName:[UIFont boldSystemFontOfSize:13]};
 CGFloat tw=[value sizeWithAttributes:font].width;
 [self label:value at:CGPointMake((lo+hi-tw)*.5,y-21) size:13 color:color bold:YES];
}
- (void)drawRect:(CGRect)rect {
 CGContextRef c=UIGraphicsGetCurrentContext();
 CGFloat w=CGRectGetWidth(rect),h=CGRectGetHeight(rect);
 UIColor *bg=[self clr:.015 g:.055 b:.075],*grid=[self clr:.092 g:.17 b:.22],*gridMajor=[self clr:.16 g:.28 b:.34];
 UIColor *white=[self clr:.88 g:.95 b:.97],*soft=[self clr:.55 g:.71 b:.76],*green=[self clr:.20 g:.91 b:.47];
 UIColor *blue=[self clr:.18 g:.66 b:1],*red=[self clr:1 g:.25 b:.27],*cyan=[self clr:.15 g:.88 b:.90];
 CGContextSetFillColorWithColor(c,bg.CGColor);CGContextFillRect(c,rect);
 NSDictionary *model=[self.shape isKindOfClass:NSDictionary.class]?self.shape:@{};
 NSDictionary *stock=[model[@"stock"] isKindOfClass:NSDictionary.class]?model[@"stock"]:@{};
 NSArray *profile=[model[@"profile"] isKindOfClass:NSArray.class]?model[@"profile"]:@[];
 double diameter=TNumber(stock[@"diameter"],0);
 double stockLen=TNumber(stock[@"length"],0),length=TNumber(model[@"finished_length"],0);
 if(length<=0)length=stockLen;
 BOOL hasProfile=diameter>0&&length>0&&profile.count>=2;
 BOOL hasSidebar=w>660;
 CGFloat sideW=hasSidebar?MAX(185,MIN(226,w*.24)):0;
 CGFloat plotLeft=hasSidebar?58:52,plotRight=w-sideW-26;
 CGFloat plotTop=47,plotBottom=h-89;
 if(hasSidebar)plotRight-=12;
 if(!hasProfile||plotRight-plotLeft<170||plotBottom-plotTop<130){
  [self label:@"Zadaj polotovar a pridaj obrábaciu operáciu." at:CGPointMake(25,45) size:17 color:white bold:NO];
  return;
 }
 // Equal pixels/mm on both axes. The sampled profile is in RADII; plot one
 // radius above and its mirror below the centerline for the FULL diameter.
 CGFloat maxD=diameter;
 CGFloat scale=MIN((plotRight-plotLeft)/MAX((CGFloat)length,1),(plotBottom-plotTop)/MAX(maxD,1));
 if(scale<.02)return;
 CGFloat cx=plotRight,cy=(plotTop+plotBottom)*.5;
 CGFloat chuck=cx-(CGFloat)length*scale;
 CGFloat (^zx)(double)=^CGFloat(double z){return cx-(CGFloat)z*scale;};
 CGFloat (^yr)(double)=^CGFloat(double r){return cy-(CGFloat)r*scale;};
 CGFloat (^yb)(double)=^CGFloat(double r){return cy+(CGFloat)r*scale;};
 // Grid and quantitative rulers are anchored at the WORK FACE Z0 and X0.
 CGContextSaveGState(c);CGContextClipToRect(c,CGRectMake(plotLeft,plotTop,plotRight-plotLeft,plotBottom-plotTop));
 NSInteger minorZ=length>220?20:(length>90?10:5);
 NSInteger majorZ=minorZ*2;
 for(NSInteger iz=0;iz<=(NSInteger)ceil(length/minorZ);iz++){
  CGFloat x=zx((double)iz*minorZ);
  if(x<plotLeft||x>plotRight)continue;
  [self line:c from:CGPointMake(x,plotTop) to:CGPointMake(x,plotBottom)
      color:iz%2?grid:gridMajor width:iz%2?.6:.85];
 }
 double dgrid=diameter>160?20:(diameter>65?10:5);
 NSInteger yLines=(NSInteger)ceil((diameter/2)/dgrid);
 for(NSInteger i=-yLines;i<=yLines;i++){
  CGFloat y=cy+i*dgrid*scale;
  if(y<plotTop||y>plotBottom)continue;
  [self line:c from:CGPointMake(plotLeft,y) to:CGPointMake(plotRight,y)
      color:i%2?grid:gridMajor width:i%2?.65:.85];
 }
 CGContextRestoreGState(c);
 [self label:@"Z (mm)" at:CGPointMake(plotLeft,5) size:13 color:soft bold:YES];
 for(NSInteger iz=0;iz<=MIN(140,(NSInteger)ceil(length/majorZ));iz++){
  double z=(double)iz*majorZ;CGFloat x=zx(z);
  if(x<plotLeft+12||x>plotRight+2)continue;
  NSString *val=z<.001?@"0":[NSString stringWithFormat:@"−%.0f",z];
  [self label:val at:CGPointMake(x-12,24) size:11 color:soft bold:NO];
  [self line:c from:CGPointMake(x,41) to:CGPointMake(x,46) color:gridMajor width:1];
 }
 [self label:@"Ø X (mm)" at:CGPointMake(3,plotTop-22) size:11 color:soft bold:NO];
 for(NSInteger i=0;i<=MIN(15,(NSInteger)floor((diameter*.5)/dgrid));i++){
  CGFloat y=cy+i*dgrid*scale;
  if(y>plotBottom)continue;
  [self label:[NSString stringWithFormat:@"%.0f",i*dgrid*2] at:CGPointMake(7,y-7) size:11 color:soft bold:NO];
 }
 // Reference boundary at the left end of the defined model. Actual chuck
 // location has not been measured, so never present this as safe clearance.
 CGContextSetFillColorWithColor(c,[red colorWithAlphaComponent:.10].CGColor);
 CGContextFillRect(c,CGRectMake(chuck-14,plotTop,14,plotBottom-plotTop));
 [self line:c from:CGPointMake(chuck,plotTop-1) to:CGPointMake(chuck,plotBottom+1) color:red width:2.3];
 [self label:@"UPNUTIE • REFERENCIA" at:CGPointMake(MAX(plotLeft,chuck-12),plotTop+7) size:11 color:red bold:YES];
 // Real closed OD profile: top contour from rearmost Z to Z0, mirrored to bottom.
 UIBezierPath *outer=[UIBezierPath bezierPath],*upper=[UIBezierPath bezierPath],*lower=[UIBezierPath bezierPath];
 BOOL first=YES;
 for(id item in profile){
  if(![item isKindOfClass:NSArray.class]||[item count]<2)continue;
  double z=TNumber(item[0],0),r=MAX(0,TNumber(item[1],0));
  CGPoint point=CGPointMake(zx(z),yr(r));
  if(first){[outer moveToPoint:point];[upper moveToPoint:point];first=NO;}
  else {[outer addLineToPoint:point];[upper addLineToPoint:point];}
 }
 if(first)return;
 for(id item in [profile reverseObjectEnumerator]){
  if(![item isKindOfClass:NSArray.class]||[item count]<2)continue;
  double z=TNumber(item[0],0),r=MAX(0,TNumber(item[1],0));
  [outer addLineToPoint:CGPointMake(zx(z),yb(r))];
 }
 [outer closePath];
 for(id item in profile){
  if(![item isKindOfClass:NSArray.class]||[item count]<2)continue;
  CGPoint pt=CGPointMake(zx(TNumber(item[0],0)),yb(MAX(0,TNumber(item[1],0))));
  if(!lower.currentPoint.x&&!lower.currentPoint.y)[lower moveToPoint:pt];else [lower addLineToPoint:pt];
 }
 UIColor *metal=[self clr:.62 g:.71 b:.76];
 [[metal colorWithAlphaComponent:.92] setFill];[outer fill];
 // Light metallic highlights - clipped to the true shape, not a stock rectangle.
 CGContextSaveGState(c);[outer addClip];
 CGFloat band=MAX(1,diameter*scale*.10);
 CGContextSetFillColorWithColor(c,[[UIColor whiteColor] colorWithAlphaComponent:.18].CGColor);
 CGContextFillRect(c,CGRectMake(chuck,cy-diameter*scale*.28,plotRight-chuck,band));
 CGContextSetFillColorWithColor(c,[[UIColor blackColor] colorWithAlphaComponent:.16].CGColor);
 CGContextFillRect(c,CGRectMake(chuck,cy+diameter*scale*.25,plotRight-chuck,band));
 CGContextRestoreGState(c);
 [white setStroke];upper.lineWidth=1.9;[upper stroke];lower.lineWidth=1.9;[lower stroke];
 // Optional typed internal geometry. V34 itself currently supplies none.
 // Do not fabricate a bore when the source model has only an outer profile.
 NSArray *bores=[model[@"bores"] isKindOfClass:NSArray.class]?model[@"bores"]:@[];
 NSMutableArray *validBores=[NSMutableArray array];
 for(id raw in bores){
  if(![raw isKindOfClass:NSDictionary.class])continue;
  double d=TNumber(raw[@"diameter"],0),z1=TNumber(raw[@"zStart"],-1),z2=TNumber(raw[@"zEnd"],-1);
  if(d<=0||d>=diameter||z1<0||z2<=z1||z2>length)continue;
  [validBores addObject:@{@"diameter":@(d),@"zStart":@(z1),@"zEnd":@(z2)}];
 }
 for(NSDictionary *bore in validBores){
  double d=[bore[@"diameter"] doubleValue],z1=[bore[@"zStart"] doubleValue],z2=[bore[@"zEnd"] doubleValue];
  CGRect opening=CGRectMake(zx(z2),cy-(CGFloat)d*.5*scale,zx(z1)-zx(z2),(CGFloat)d*scale);
  CGContextSetFillColorWithColor(c,[self clr:.095 g:.17 b:.22].CGColor);CGContextFillRect(c,opening);
  CGContextSetStrokeColorWithColor(c,blue.CGColor);CGContextSetLineWidth(c,1.4);CGContextStrokeRect(c,opening);
  [self verticalDimension:c x:CGRectGetMidX(opening) top:CGRectGetMinY(opening) bottom:CGRectGetMaxY(opening)
                    text:[NSString stringWithFormat:@"Ø%.1f",d] color:blue];
  CGFloat yy=MIN(plotBottom+22,h-59);
  [self horizontalDimension:c x1:zx(z1) x2:zx(z2) y:yy
      text:[NSString stringWithFormat:@"%.1f DĹŽKA DIERY",z2-z1] color:blue];
 }
 // Dashed X0 reference is drawn ON TOP of the component.
 CGContextSaveGState(c);CGFloat dash[]={6,5};CGContextSetLineDash(c,0,dash,2);
 [self line:c from:CGPointMake(plotLeft,cy) to:CGPointMake(plotRight,cy) color:cyan width:1.2];
 CGContextRestoreGState(c);
 [self label:@"X0" at:CGPointMake(plotLeft+4,cy+4) size:13 color:cyan bold:YES];
 // Green Z0 face and red rear reference.
 [self line:c from:CGPointMake(cx,plotTop-3) to:CGPointMake(cx,plotBottom+2) color:green width:2.5];
 [self label:@"Z0" at:CGPointMake(cx-21,plotTop+5) size:13 color:green bold:YES];
 [self label:[NSString stringWithFormat:@"Z−%.0f",length] at:CGPointMake(MAX(plotLeft,chuck-16),plotBottom+5) size:11 color:red bold:YES];
 // Outside diameter dimensions. Position where the operation ACTUALLY acts.
 NSMutableArray *outerDims=[NSMutableArray array];
 double sampleZ=MIN(length*.56,length-.001);
 for(NSInteger i=0;i<profile.count;i++){
  NSArray *q=profile[i];if(![q isKindOfClass:NSArray.class]||q.count<2)continue;
  if(TNumber(q[0],0)<=sampleZ){double d=2*TNumber(q[1],0);if(d>0)[outerDims addObject:@{@"z":@(sampleZ),@"d":@(d)}];break;}
 }
 for(NSDictionary *op in self.operations?:@[]){
  NSString *kind=TString(op[@"type"]);
  if([kind isEqualToString:@"diameter"] || [kind isEqualToString:@"groove"]){
   double z=TNumber(op[@"zStart"],0),zend=[kind isEqualToString:@"groove"]?z+TNumber(op[@"width"],0):TNumber(op[@"zEnd"],z);
   if(zend<=z||z>length)continue;
   [outerDims addObject:@{@"z":@(MIN(length,(z+zend)*.5)),@"d":@([op[@"diameter"] doubleValue])}];
  }else if([kind isEqualToString:@"taper"]){
   double za=TNumber(op[@"zStart"],0),zb=TNumber(op[@"zEnd"],0);
   if(zb<=za||za>length)continue;
   [outerDims addObject:@{@"z":@(MIN(length,MAX(0,za))),@"d":@([op[@"diameterStart"] doubleValue])}];
   [outerDims addObject:@{@"z":@(MIN(length,MAX(0,zb))),@"d":@([op[@"diameterEnd"] doubleValue])}];
  }
 }
 // Up to six non-duplicated OD dimensions to retain legibility on old iPads.
 NSMutableArray *placed=[NSMutableArray array];
 for(NSDictionary *dim in outerDims){
  if(placed.count>=6)break;
  double z=TNumber(dim[@"z"],0),d=TNumber(dim[@"d"],0);
  if(d<=0||d>diameter+.01||z<0||z>length)continue;
  CGFloat x=zx(z);BOOL overlap=NO;
  for(NSNumber *v in placed)if(fabs(v.doubleValue-x)<43)overlap=YES;
  if(overlap)continue;
  [placed addObject:@(x)];
  [self verticalDimension:c x:x top:cy-d*.5*scale bottom:cy+d*.5*scale
      text:[NSString stringWithFormat:@"Ø%.1f",d] color:green];
 }
 // External Z lengths measured relative to the same finished face.
 NSInteger count=0;
 for(NSDictionary *op in self.operations?:@[]){
  NSString *kind=TString(op[@"type"]);
  if(![@[@"diameter",@"taper",@"groove"] containsObject:kind])continue;
  double za=TNumber(op[@"zStart"],0);
  double zb=[kind isEqualToString:@"groove"]?za+TNumber(op[@"width"],0):TNumber(op[@"zEnd"],0);
  if(!(za>=0&&zb>za&&zb<=length))continue;
  CGFloat yy=plotBottom+23+(count%2)*20;
  [self horizontalDimension:c x1:zx(za) x2:zx(zb) y:yy
      text:[NSString stringWithFormat:@"%.1f",zb-za] color:green];
  count++;if(count>=4)break;
 }
 [self horizontalDimension:c x1:chuck x2:cx y:h-22
   text:[NSString stringWithFormat:@"L %.1f",length] color:green];
 // Radius leader: arrow lands at a point half-way along the actual curved
 // sample interval, never on the sharp edge or at the radius center.
 NSInteger radIndex=0;
 for(NSDictionary *op in self.operations?:@[]){
  if(![TString(op[@"type"]) isEqualToString:@"radius"])continue;
  double z=TNumber(op[@"z"],-1),rad=TNumber(op[@"size"],0);
  if(z<0||rad<=0||z>length)continue;
  double mid=MIN(length-.001,MAX(.001,z+rad*.5));
  double bestDiff=DBL_MAX,bestR=0;
  for(id row in profile){
   if(![row isKindOfClass:NSArray.class]||[row count]<2)continue;
   double diff=fabs(TNumber(row[0],0)-mid);
   if(diff<bestDiff){bestDiff=diff;bestR=TNumber(row[1],0);}
  }
  if(bestDiff>MAX(1.,rad*.8))continue;
  CGPoint tip=CGPointMake(zx(mid),yr(bestR));
  CGPoint leader=CGPointMake(tip.x+19,tip.y-23);
  [self line:c from:CGPointMake(leader.x+9,leader.y-1) to:tip color:green width:1.3];
  [self arrow:c at:leader toward:tip color:green size:8];
  [self label:[NSString stringWithFormat:@"R%.1f",rad] at:CGPointMake(leader.x+11,leader.y-18) size:13 color:green bold:YES];
  radIndex++;if(radIndex>=3)break;
 }
 if(hasSidebar){
  CGFloat sx=w-sideW-8,sw=sideW-8;
  CGContextSetFillColorWithColor(c,[self clr:.038 g:.100 b:.135].CGColor);
  CGContextFillRect(c,CGRectMake(sx,0,w-sx,h));
  [self label:@"GEOMETRIA" at:CGPointMake(sx+10,12) size:14 color:cyan bold:YES];
  [self line:c from:CGPointMake(sx+8,35) to:CGPointMake(w-10,35) color:gridMajor width:1];
  NSArray *facts=@[
    [NSString stringWithFormat:@"Dĺžka    %.1f mm",length],
    [NSString stringWithFormat:@"Polotovar Ø%.1f",diameter],
    [NSString stringWithFormat:@"Vonkajší profil: ÁNO"],
    [NSString stringWithFormat:@"Vnútorné otvory: %lu",(unsigned long)validBores.count],
    [NSString stringWithFormat:@"Rozsah Z: −%.1f až 0",length]
  ];
  CGFloat fy=51;
  for(NSString *fact in facts){[self label:fact at:CGPointMake(sx+9,fy) size:12 color:white bold:NO];fy+=27;}
  [self line:c from:CGPointMake(sx+8,fy+4) to:CGPointMake(w-10,fy+4) color:gridMajor width:1];fy+=17;
  [self label:@"KÓTOVANIE" at:CGPointMake(sx+10,fy) size:14 color:cyan bold:YES];fy+=26;
  NSArray *keys=@[@"Vonkajší Ø / Z",@"Vnútorný Ø / Z",@"Stredová os X0",@"Čelo Z0",@"Referenčný okraj"];
  NSArray *colors=@[green,blue,cyan,green,red];
  for(NSInteger i=0;i<keys.count;i++){
   UIColor *keyColor=colors[i];
   [self line:c from:CGPointMake(sx+9,fy+7) to:CGPointMake(sx+33,fy+7) color:keyColor width:2];
   [self label:keys[i] at:CGPointMake(sx+39,fy) size:11 color:white bold:NO];fy+=25;
  }
  [self line:c from:CGPointMake(sx+8,fy+3) to:CGPointMake(w-10,fy+3) color:gridMajor width:1];fy+=13;
  [self label:@"MIERKA 1 : 1" at:CGPointMake(sx+9,fy) size:13 color:green bold:YES];fy+=26;
  [self label:@"Geometria ≠ kontrola" at:CGPointMake(sx+9,fy) size:11 color:soft bold:NO];fy+=17;
  [self label:@"kolízií a upnutia." at:CGPointMake(sx+9,fy) size:11 color:soft bold:NO];
 }
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
 UILabel *heading=[self label:@"AlphaLink CAM iPad V1.9 • EDITOR"];heading.tag=901;heading.font=[UIFont boldSystemFontOfSize:21];heading.textColor=TCYAN();[self.view addSubview:heading];
 self.status=[self label:@"NOVÝ NÁVRH • geometria bude overená Raspberry Pi"];self.status.tag=902;self.status.textAlignment=NSTextAlignmentRight;self.status.adjustsFontSizeToFitWidth=YES;self.status.minimumScaleFactor=.72;self.status.font=[UIFont systemFontOfSize:14];[self.view addSubview:self.status];
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
 self.preview=[CNCProfileView new];self.preview.contentMode=UIViewContentModeRedraw;self.preview.layer.cornerRadius=9;self.preview.layer.masksToBounds=YES;[self.previewPage addSubview:self.preview];
 UIButton *refresh=[self button:@"PREPOČÍTAŤ NA RASPBERRY PI" action:@selector(requestPreview)];refresh.tag=931;[self.previewPage addSubview:refresh];
 UILabel *previewHelp=[self label:@"Celý profil • mierka Z/X 1:1 • zelené vonkajšie a modré vnútorné kóty iba podľa geometrie. Náhľad nezaručuje bezpečnosť obrábania."];previewHelp.tag=932;[self.previewPage addSubview:previewHelp];
 UILabel *codeInfo=[self label:@"CAM program .600 generuje AlphaLink na Raspberry Pi. Neskúšaj ho bez kontroly na stroji."];codeInfo.tag=941;[self.codePage addSubview:codeInfo];
 self.codeName=[self field:@"O0001" numeric:NO];[self.codePage addSubview:self.codeName];
 self.gcode=[[UITextView alloc] initWithFrame:CGRectZero];self.gcode.backgroundColor=TPANEL();self.gcode.textColor=TWHITE();self.gcode.font=[UIFont fontWithName:@"Menlo" size:18]?:[UIFont systemFontOfSize:18];self.gcode.layer.cornerRadius=8;[self.codePage addSubview:self.gcode];
 NSArray *codeTexts=@[@"GENEROVAŤ KÓD",@"ULOŽIŤ .600 NA PI"];NSArray *codeSEL=@[@"generateCode",@"saveCode"];
 for(NSInteger i=0;i<2;i++){UIButton *b=[self button:codeTexts[i] action:NSSelectorFromString(codeSEL[i])];b.tag=945+i;[self.codePage addSubview:b];}
 self.projectsTable=[[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];self.projectsTable.backgroundColor=TBG();self.projectsTable.separatorColor=TPANEL();self.projectsTable.rowHeight=60;self.projectsTable.dataSource=self;self.projectsTable.delegate=self;
 UILabel *noProjects=[self label:@"Zatiaľ nie sú uložené žiadne návrhy .HBJ.\nV záložke ZADANIE pridaj operácie a tu stlač ULOŽIŤ .HBJ."];noProjects.textAlignment=NSTextAlignmentCenter;noProjects.numberOfLines=4;
 noProjects.textColor=[UIColor colorWithWhite:.72 alpha:1];noProjects.font=[UIFont systemFontOfSize:19];
 self.projectsTable.backgroundView=noProjects;[self.projectsPage addSubview:self.projectsTable];
 NSArray *projectTexts=@[@"OBNOVIŤ ZOZNAM",@"OTVORIŤ NÁVRH",@"ULOŽIŤ .HBJ",@"NOVÝ NÁVRH",@"ZMAZAŤ .HBJ"];NSArray *projectSEL=@[@"refreshProjects",@"openProject",@"saveProject",@"newProject",@"deleteProject"];
 for(NSInteger i=0;i<4;i++){UIButton *b=[self button:projectTexts[i] action:NSSelectorFromString(projectSEL[i])];b.tag=950+i;[self.projectsPage addSubview:b];}
 [self fillParams:nil];[self switchTab];[self localPreview];
}
- (void)viewDidLayoutSubviews {
 [super viewDidLayoutSubviews];
 CGFloat w=self.view.bounds.size.width,h=self.view.bounds.size.height,top=self.view.safeAreaInsets.top+8,bottom=self.view.safeAreaInsets.bottom;
 [self.view viewWithTag:900].frame=CGRectMake(16,top,100,48);
 [self.view viewWithTag:901].frame=CGRectMake(128,top,MIN(410,w*.42),48);
 self.status.frame=CGRectMake(MAX(500,w*.53),top+2,w-MAX(500,w*.53)-18,44);
 self.tabs.frame=CGRectMake(16,top+53,w-32,44);
 CGRect page=CGRectMake(14,top+105,w-28,MAX(150,h-bottom-top-117));
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
 CGFloat pb=(pw-4*8)/5;for(NSInteger i=0;i<5;i++)[self.projectsPage viewWithTag:950+i].frame=CGRectMake(i*(pb+8),ph-60,pb,55);
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
 // Match Pi V34's geometry_in_finished_frame for dimension placement.
 // Operations measured from the RAW face shift after a separate FACE cut.
 double face=0;
 for(NSDictionary *op in self.operations)if([TString(op[@"type"]) isEqualToString:@"face"]){face=TNumber(op[@"amount"],0);break;}
 NSMutableArray *labels=[NSMutableArray array];
 for(NSDictionary *op in self.operations){
  NSString *kind=TString(op[@"type"]);if([kind isEqualToString:@"face"])continue;
  NSMutableDictionary *converted=[op mutableCopy];
  double shift=[TString(op[@"frame"]) isEqualToString:@"faced"]?0:face;
  for(NSString *key in @[@"z",@"zStart",@"zEnd"]){
   if(converted[key])converted[key]=@(TNumber(converted[key],0)-shift);
  }
  double end=TNumber(converted[@"zEnd"],TNumber(converted[@"z"],0));
  if(([@[@"diameter",@"taper"] containsObject:kind] && end<=0)
      || ([@[@"radius",@"chamfer"] containsObject:kind] && TNumber(converted[@"z"],0)<0))continue;
  if(converted[@"zStart"]&&TNumber(converted[@"zStart"],0)<0)converted[@"zStart"]=@0;
  [labels addObject:converted];
 }
 self.preview.operations=labels;
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
  self.projects=j[@"projects"];self.selectedProject=-1;self.projectsTable.backgroundView.hidden=self.projects.count>0;[self.projectsTable reloadData];
  self.status.text=[NSString stringWithFormat:@"Na Raspberry Pi: %lu návrhov .hbj",(unsigned long)self.projects.count];
 }];
}
- (void)deleteProject {
 if(self.busy)return;
 if(self.selectedProject<0||self.selectedProject>=self.projects.count){[self showError:@"Vyber návrh .hbj zo zoznamu."];return;}
 NSString *name=TString(self.projects[self.selectedProject][@"name"]);
 if(!name.length){[self showError:@"Chýba názov vybraného návrhu."];return;}
 UIAlertController *confirm=[UIAlertController alertControllerWithTitle:@"Odstrániť návrh z Raspberry Pi?"
 message:[NSString stringWithFormat:@"Vymaže sa len %@.hbj z knižnice návrhov na Pi. Strojový .600 program ani pamäť CNC sa tým nemenia.",name] preferredStyle:UIAlertControllerStyleAlert];
 [confirm addAction:[UIAlertAction actionWithTitle:@"ZRUŠIŤ" style:UIAlertActionStyleCancel handler:nil]];
 [confirm addAction:[UIAlertAction actionWithTitle:@"ZMAZAŤ .HBJ" style:UIAlertActionStyleDestructive handler:^(UIAlertAction *a){
  NSString *encoded=[name stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLQueryAllowedCharacterSet]];
  NSURL *url=[NSURL URLWithString:[self.baseURL stringByAppendingFormat:@"/api/turning/delete?name=%@",encoded]];
  NSMutableURLRequest *req=[NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadIgnoringLocalCacheData timeoutInterval:25];
  req.HTTPMethod=@"POST";
  self.busy=YES;
  [[[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData *data,NSURLResponse *resp,NSError *error){
   NSDictionary *j=nil;if(data.length){id v=[NSJSONSerialization JSONObjectWithData:data options:0 error:nil];if([v isKindOfClass:NSDictionary.class])j=v;}
   NSInteger code=[resp isKindOfClass:NSHTTPURLResponse.class]?((NSHTTPURLResponse *)resp).statusCode:0;
   dispatch_async(dispatch_get_main_queue(),^{
    self.busy=NO;
    if(error||code<200||code>=300||![j[@"deleted"] boolValue]){[self showError:[NSString stringWithFormat:@"Vymazanie .hbj zlyhalo: %@",error.localizedDescription?:TString(j[@"error"]).length?j[@"error"]:@"HTTP chyba"]];return;}
    self.status.text=[NSString stringWithFormat:@"Návrh %@.hbj bol odstránený z Raspberry Pi.",name];
    [self refreshProjects];
   });
  }] resume];
 }]];
 [self presentViewController:confirm animated:YES completion:nil];
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

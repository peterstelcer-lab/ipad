import AppKit
import Foundation
let target=CommandLine.arguments[1]
try! FileManager.default.createDirectory(atPath:target,withIntermediateDirectories:true)
func tint(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=1)->NSColor {
 return NSColor(calibratedRed:r,green:g,blue:b,alpha:a)
}
func rounded(_ rect:NSRect,_ radius:CGFloat,_ fill:NSColor,_ outline:NSColor?=nil) {
 let path=NSBezierPath(roundedRect:rect,xRadius:radius,yRadius:radius)
 fill.setFill();path.fill()
 if let color=outline {color.setStroke();path.lineWidth=3;path.stroke()}
}
let aqua=tint(.09,.88,.81),dark=tint(.018,.06,.08)
let image=NSImage(size:NSSize(width:256,height:256))
image.lockFocus()
NSGradient(colors:[tint(.02,.21,.24),dark])!.draw(in:NSRect(x:0,y:0,width:256,height:256),angle:90)
rounded(NSRect(x:10,y:10,width:236,height:236),42,dark,aqua)
rounded(NSRect(x:43,y:31,width:170,height:191),23,tint(.09,.18,.21),tint(.75,.93,.94))
rounded(NSRect(x:56,y:151,width:144,height:56),9,tint(.015,.085,.10),aqua)
let text=NSAttributedString(string:"12 × 8",attributes:[NSAttributedString.Key.font:NSFont.monospacedDigitSystemFont(ofSize:34,weight:.bold),NSAttributedString.Key.foregroundColor:NSColor.white])
text.draw(in:NSRect(x:66,y:166,width:129,height:36))
for row in 0..<3 {
 for col in 0..<4 {
  let x=CGFloat(56+col*38),y=CGFloat(51+row*31)
  let fill=col==3?aqua:tint(.18,.32,.38)
  rounded(NSRect(x:x,y:y,width:32,height:25),5,fill)
 }
}
image.unlockFocus()
for (filename,n) in [("AppIcon76.png",76),("AppIcon76@2x.png",152),("AppIcon83.5@2x.png",167)] {
 let size=CGFloat(n),small=NSImage(size:NSSize(width:CGFloat(n),height:CGFloat(n)))
 small.lockFocus()
 NSGraphicsContext.current?.imageInterpolation = .high
 image.draw(in:NSRect(x:0,y:0,width:size,height:size),from:NSRect(x:0,y:0,width:256,height:256),operation:.copy,fraction:1)
 small.unlockFocus()
 let rep=NSBitmapImageRep(data:small.tiffRepresentation!)!
 try! rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:target).appendingPathComponent(filename))
}
print("TechCalc icon PNGs OK")

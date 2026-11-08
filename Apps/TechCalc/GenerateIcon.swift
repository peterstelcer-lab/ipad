import AppKit
import Foundation

// Independent industrial-design icon: calculator, compass and gears; not a clone of the CNC app icons.
let target = CommandLine.arguments[1]
try! FileManager.default.createDirectory(atPath:target,withIntermediateDirectories:true)
func c(_ r:CGFloat,_ g:CGFloat,_ b:CGFloat,_ a:CGFloat=1)->NSColor {
 return NSColor(calibratedRed:r,green:g,blue:b,alpha:a)
}
func box(_ r:NSRect,_ radius:CGFloat,_ fill:NSColor,_ stroke:NSColor?=nil,_ thickness:CGFloat=2) {
 let p=NSBezierPath(roundedRect:r,xRadius:radius,yRadius:radius)
 fill.setFill();p.fill()
 if let s=stroke{s.setStroke();p.lineWidth=thickness;p.stroke()}
}
func segment(_ points:[NSPoint],_ color:NSColor,_ thickness:CGFloat) {
 guard let first=points.first else{return}
 let p=NSBezierPath();p.move(to:first)
 for pt in points.dropFirst(){p.line(to:pt)}
 p.lineWidth=thickness;color.setStroke();p.stroke()
}
func gear(_ center:NSPoint,_ outer:CGFloat,_ inner:CGFloat,_ teeth:Int,_ fill:NSColor) {
 let p=NSBezierPath()
 for i in 0..<(teeth*4) {
  let t=CGFloat(i)*CGFloat.pi*2/CGFloat(teeth*4)
  let r=(i%4==1||i%4==2) ? outer : inner
  let pt=NSPoint(x:center.x+cos(t)*r,y:center.y+sin(t)*r)
  if i==0{p.move(to:pt)}else{p.line(to:pt)}
 }
 p.close();fill.setFill();p.fill()
 let hole=NSBezierPath(ovalIn:NSRect(x:center.x-10,y:center.y-10,width:20,height:20))
 c(0.03,0.11,0.15).setFill();hole.fill()
}
let image=NSImage(size:NSSize(width:256,height:256))
image.lockFocus()
NSGradient(colors:[c(0.11,0.24,0.29),c(0.008,0.04,0.055)])!.draw(in:NSRect(x:0,y:0,width:256,height:256),angle:105)
// Technical drawing diagonals and subtle industrial tooling.
for i in 0..<6 {
 let x=CGFloat(i*49-35)
 segment([NSPoint(x:x,y:0),NSPoint(x:x+145,y:256)],c(0.13,0.35,0.40,0.13),1)
}
let compass=c(0.68,0.80,0.83)
segment([NSPoint(x:39,y:78),NSPoint(x:66,y:201)],compass,8)
segment([NSPoint(x:66,y:201),NSPoint(x:94,y:78)],compass,7)
let pin=NSBezierPath(ovalIn:NSRect(x:56,y:191,width:20,height:20))
c(0.92,0.95,0.98).setFill();pin.fill()
c(0.24,0.38,0.43).setStroke();pin.lineWidth=2;pin.stroke()
let t=AffineTransform(translationByX:12,y:3)
let transform=NSAffineTransform(transform:t)
transform.translateX(by:17,yBy:4)
transform.rotate(byDegrees:-10)
transform.concat()
box(NSRect(x:55,y:35,width:153,height:202),23,c(0.24,0.34,0.40),c(0.84,0.91,0.94),5)
box(NSRect(x:67,y:145,width:129,height:68),10,c(0.005,0.10,0.13),c(0.09,0.92,0.83),3)
let title=NSAttributedString(string:"TechCalc",attributes:[
 .font:NSFont.systemFont(ofSize:22,weight:.semibold),
 .foregroundColor:c(0.18,0.98,0.92)])
title.draw(in:NSRect(x:73,y:169,width:125,height:30))
let keys:[String]=["7","8","9","÷","4","5","6","×","1","2","3","−","±","0",",","="]
for i in 0..<keys.count {
 let x=CGFloat(70+(i%4)*31),y=CGFloat(50+(3-i/4)*23)
 let op=i%4==3
 let fill=keys[i]=="="?c(1.0,0.69,0.23):(op?c(0.11,0.66,0.66):c(0.35,0.47,0.52))
 box(NSRect(x:x,y:y,width:26,height:20),4,fill,c(0.82,0.91,0.93,0.6),1)
 let att=NSAttributedString(string:keys[i],attributes:[
  .font:NSFont.boldSystemFont(ofSize:14),
  .foregroundColor:NSColor.white])
 att.draw(in:NSRect(x:x+7,y:y+3,width:20,height:18))
}
// Undo transform before drawing the foreground gear.
transform.invert()
transform.concat()
gear(NSPoint(x:213,y:47),34,27,12,c(0.72,0.82,0.85))
image.unlockFocus()
for (filename,px) in [("AppIcon76.png",76),("AppIcon76@2x.png",152),("AppIcon83.5@2x.png",167)]{
 let n=CGFloat(px)
 let resized=NSImage(size:NSSize(width:n,height:n))
 resized.lockFocus()
 NSGraphicsContext.current?.imageInterpolation = .high
 image.draw(in:NSRect(x:0,y:0,width:n,height:n),from:NSRect(x:0,y:0,width:256,height:256),operation:.copy,fraction:1)
 resized.unlockFocus()
 let rep=NSBitmapImageRep(data:resized.tiffRepresentation!)!
 try! rep.representation(using:.png,properties:[:])!.write(to:URL(fileURLWithPath:target).appendingPathComponent(filename))
}
print("TechCalc V2 original industrial icon rendered")

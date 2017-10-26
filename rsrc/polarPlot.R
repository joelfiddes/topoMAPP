args = commandArgs(trailingOnly=TRUE)
file=args[1]
#polarplot=function( ele=NULL){
library(colorRamps)

col='black'
lty=1
points=TRUE
by=400
pch=16


#file = "/home/joel/sim/compare_ERA/listpoints_test_era_new.txt"
#file = "/home/joel/sim/compare_ERA/listpoints_era5.txt"
#file = "/home/joel/sim/compare_ERA/listpoints_interim.txt"
lp = read.csv(file)


#pdf('polar_single.pdf',width=7,height=7)




ele<-c(lp$ele)
slp=c(lp$slp)
asp=c(lp$asp)
lp<-data.frame(ele,slp,asp)
length(lp$ele)->l

	
	ele <- lp$ele
	range=c(min(ele),max(ele))
	
 eleRange=round(seq(min(ele),max(ele),by=by) ,0)
	
	plot(seq(-1,1),seq(-1,1),type="n",axes=FALSE,xlab="",ylab="",xlim=c(-1.2,1.2),ylim=c(-1.2,1.2), )
	box(which="plot")
	text(1.1,0,"E");text(0,1.1,"N");text(-1.1,0,"W");text(0,-1.1,"S")
	
	
	exp=seq(0,360,1)/180*pi
	x=cos(exp);y=sin(exp)
	lines(x,y)
	lines(c(sin(pi/8),-sin(pi/8)),c(cos(pi/8),-cos(pi/8)))
	lines(c(cos(pi/8),-cos(pi/8)),c(sin(pi/8),-sin(pi/8)))
	lines(c(cos(pi/8),-cos(pi/8)),c(-sin(pi/8),sin(pi/8)))
	lines(c(sin(pi/8),-sin(pi/8)),c(-cos(pi/8),cos(pi/8)))
	
	
	n=length(eleRange)
	for (i in 1:n) {
		x=cos(exp)/n*i
		y=sin(exp)/n*i
		lines(x,y)
		text (0,i/n,labels=rev(eleRange)[i], cex=1)
	}



	#func 2
exp <- lp$asp
slp <- lp$slp

	
	exp=exp/180*pi
	ele =1-(ele-range[1])/(range[2]-range[1])
	y=ele*cos(exp)
	x=ele*sin(exp)
	if (points==FALSE) lines(x,y,col=col,lty=lty,lwd=2)	else 
		points(x,y,col=col)
	
	
	 cols=matlab.like2(4)
	
	 
	 
	 
	 
	 
	samples=seq(1,l,1)
	for(i in samples){
		if(slp[i]>=0 & slp[i]<10) col<-cols[1]
		if(slp[i]>=10 & slp[i]<30) col<-cols[2]
		if(slp[i]>=30 & slp[i]<60) col<-cols[3]
		if(slp[i]>=60 & slp[i]<90) col<-cols[4]
		#if(slp[i]>=70 & slp[i]<90) col<-cols[5]

#		if(slp[i]>=0 & slp[i]<10) col<-'green'
#		if(slp[i]>=10 & slp[i]<30) col<-'blue'
#		if(slp[i]>=30 & slp[i]<50) col<-'yellow'
#		if(slp[i]>=50 & slp[i]<70) col<-'orange'
#		if(slp[i]>=70 & slp[i]<90) col<-'red'

		if (points==FALSE) lines(x[i],y[i],col=col,lty=lty,lwd=2)	else 
			points(x[i],y[i],col=col, pch=pch, cex=1)
		legend("topleft",c("0-10", "10-30", "30-60", "60-90"),title='slope[deg]',col=cols,lty=c(1,1), cex=0.9, bty='n', pch=pch)
		
		
	}



#dev.off()
#}

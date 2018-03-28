require(raster)
f=list.files(pattern="^X100*")


brk = stack(f)

> brk[brk>0]<- NA
> brk[brk<=0]<- 1
> sum(brk)
^C
^C^C^C^C^C^C^C


> 
> 
> sbrk = sum(brk)

## generates ensemble matrix
# takes N ensemble memebers as arg
# need to use this ref https://www.the-cryosphere.net/10/103/2016/tc-10-103-2016.pdf
args = commandArgs(trailingOnly=TRUE)
N=as.numeric(args[1])
wd= args[2]
# source: https://msalganik.wordpress.com/2017/01/21/making-sense-of-the-rlnorm-function-in-r/

# FUNCTIONS
lognormDraws <- function(n, m,s)
	{
mu <- log(m^2 / sqrt(s^2 + m^2))
sigma <- sqrt(log(1 + (s^2 / m^2)))
draws <- rlnorm(n, mu, sigma)
	return(draws)
	}
	
normDraws <- function(n, m,s)
	{
draws <- rnorm(n, m, s)
	return(draws)
	}

logitnormDraws <- function(n, m,s)
	{
	require(logitnorm)
mu <- log(m^2 / sqrt(s^2 + m^2))
sigma <- sqrt(log(1 + (s^2 / m^2)))
draws <- rlogitnorm(n , mu, sigma)
	return(draws)
	}
	

# MAIN

cv=lognormDraws(N,0.4,0.01)	
alpha=lognormDraws(N,0.2,0.01)	# SoilAlbVisDry
#pbias=lognormDraws(N,1,0.5)	
pbias=lognormDraws(N,1,1.2)
tbias=normDraws(N,1,1.2)
swbias=normDraws(N,1,0.1)
	
lwbias=normDraws(N,1,0.1)

df=data.frame(pbias,tbias,swbias,lwbias)
write.csv(df,paste0(wd,'/ensemble.csv'))

pdf(paste0(wd,"/ensembleDistributions.pdf"))
	par(mfrow=c(2,2))
	plot(density(tbias))
	plot(density(pbias))
	plot(density(swbias))
	plot(density(lwbias))
dev.off()






 


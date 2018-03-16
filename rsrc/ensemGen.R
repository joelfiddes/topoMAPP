## generates ensemble matrix
# takes N ensemble memebers as arg
# need to use this ref https://www.the-cryosphere.net/10/103/2016/tc-10-103-2016.pdf
args = commandArgs(trailingOnly=TRUE)
N=as.numeric(args[1])
wd= args[2]
# source: https://msalganik.wordpress.com/2017/01/21/making-sense-of-the-rlnorm-function-in-r/

# all function args:  N obs, mean, sd
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


#alpha=lognormDraws(N,0.2,0.01)	# SoilAlbVisDry	
# henerate multiplicative perturbation factors for ensembleGen	
pbias=lognormDraws(N,1,0.5)
tbias=normDraws(N,1,0.005) # this is for K only, we convert C to K then multiply bias then K to C
swbias=normDraws(N,1,0.2)	
lwbias=normDraws(N,1,0.1)

# uncorrelated
df=data.frame(pbias,tbias,swbias,lwbias)

# co-correlation 

# refs
#http://scipy-cookbook.readthedocs.io/items/CorrelatedRandomSamples.html
# this one:
#http://www.cerebralmastication.com/2010/09/cholesk-post-on-correlated-random-normal-generation/

# todo
# 1. remove p from this needs to be done differntly as lognorm
# 2. check actual corelations from data (very similar to reported vals in NAvari 2016)

# cols/rows = T, P , SW, LW CONTRUCT DIRECTLY FROM DATA
cordat = c(1, 0.1, 0.3, 0.6, 0.1, 1, -0.1, 0.5, 0.3, -0.1, 1, -0.3, 0.6, 0.5, -0.3, 1) # Navari (not bad when compared to data), auto gen from all meteo in base run.

# precip vals (pos 2) are the expected means sd of the lognorm distribution. we compute the mead sd of norm distribution below and substitute.
sd_vec = c(0.005,0.5,0.2,0.1) # Navari, how to base this on the data?
mean_vec = c(1,1,1,1)

# precip is lognormally distributed as a transform from normal distribution in final step. Therefore we compute normal sd and mean from expected lognoral mean /sd
# https://stats.stackexchange.com/questions/173715/calculate-variance-and-standard-deviation-for-log-normal-distribution
lnorm.mean = mean_vec[2]
lnorm.sd = sd_vec[2]
lnorm.var = lnorm.sd^2

norm.sd = sqrt( log( (lnorm.var/lnorm.mean^2)+1  ))
norm.mean = log(lnorm.mean) - ((lnorm.sd^2)/2)

sd_vec[2] <- norm.sd
mean_vec[2] <- norm.mean

#https://stats.stackexchange.com/questions/82261/generating-correlated-distributions-with-a-certain-mean-and-standard-deviation
cormat = matrix(cordat, 4,4)

# convert cor2cov matrix: https://stackoverflow.com/questions/39843162/conversion-between-covariance-matrix-and-correlation-matrix/39843276#39843276
covmat <- sweep(sweep(cormat, 1L, sd_vec, "*"), 2L, sd_vec, "*") 

# check for posite definiteness of covariance matrix
stopifnot( eigen( covmat )$values > 0 )

# empirical = true gives exact correlations in result eg https://stats.stackexchange.com/questions/82261/generating-correlated-distributions-with-a-certain-mean-and-standard-deviation
res = mvrnorm(n=100, m=mean_vec, Sigma=covmat, empirical = TRUE)

#lognorm transform on P
plogN = exp(res[,2])

plot(plogN,type="l")
lines(res[,1],type="l", col="blue")
lines(res[,3],type="l", col="green")
lines(res[,4],type="l", col="red")


tbias=res[,1] # this is for K only, we convert C to K then multiply bias then K to C
pbias=plogN
swbias=res[,3]	
lwbias=res[,4]
df=data.frame(pbias,tbias,swbias,lwbias)
#m= 1
#s= 0.5
#X <- m + s*exp(res[,2])
#lines(X,type="l", col="pink", lwd = 3)

write.csv(df,paste0(wd,'/ensemble.csv'))

pdf(paste0(wd,"/ensembleDistributions.pdf"))
	par(mfrow=c(2,2))
	plot(density(tbias))
	plot(density(pbias))
	plot(density(swbias))
	plot(density(lwbias))
dev.off()


# correlated random vars
# https://stats.stackexchange.com/questions/38856/how-to-generate-correlated-random-numbers-given-means-variances-and-degree-of
# r package http://stat.ethz.ch/R-manual/R-patched/library/MASS/html/mvrnorm.html
# https://stats.stackexchange.com/questions/114979/r-random-sampling-for-multivariate-normal-and-log-normal-distributions
# 
# check
# plot(tbias,lwbias)


> require(MASS)
Loading required package: MASS
> mvrnom(n=100, m=rep(1,4), Sigma=cov.m)
cov.mat  cov.mcd  cov.mve  
> res = mvrnom(n=100, m=rep(1,4), Sigma=cov.mat)
Error in mvrnom(n = 100, m = rep(1, 4), Sigma = cov.mat) : 
  could not find function "mvrnom"
> res = mvrnorm(n=100, m=rep(1,4), Sigma=cov.mat)
> str(res)
 num [1:100, 1:4] 1 0.994 1.002 0.999 0.995 ...
 - attr(*, "dimnames")=List of 2
  ..$ : NULL
  ..$ : NULL
> plot(res[,1],type="l")
> plot(res[,1],type="l")
> lines(res[,2],type="l", col="red")
> lines(res[,3],type="l", col="green")
> lines(res[,4],type="l", col="blue")
> plot(res[,2],type="l")
> plot(res[,3],type="l")
> plot(res[,4],type="l")
> plot(res[,2],type="l")
> lines(res[,1],type="l", col="blue")
> lines(res[,3],type="l", col="green")
> lines(res[,4],type="l", col="red")


 


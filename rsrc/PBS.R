# R implementation of PBS in Aalstad et al.

PBS <- function( HX,Y,R){
## Efficient implementation of the Particle Batch Smoother
# presented in Margulis et al. (2015; JHM).
# N.B. The observation errors are assumed to be uncorrelated (diagonal R)
# and Gaussian.
#
# Dimensions: No = Number of observations in the batch to assimilate.
#                      Np = Number of parameters to update.
#                      Ne = Number of ensemble members. 
#
# -----------------------------------------------------------------------
# Inputs: 
#
#        
# HX   => No x Ne matrix containing an ensemble of Ne predicted
#         observation column vectors each with No entries.
# 
# Y     => No x 1 vector containing the batch of (unperturbed) observations.
#
# R     => No x No observation error covariance matrix; this may also be
#         specified as a scalar corresponding to the constant variance of
#         all the observations in the case that these are all from the same
#         instrument.
#
# -----------------------------------------------------------------------
# Outputs:
# 
# w     => 1 x Ne vector containing the ensemble of posterior weights,
#         the prior weights are implicitly 1/N_e.
#
# -----------------------------------------------------------------------
#Y=seq(1:5) #obs
#HX= (matrix(rep(Y,4), nrow=5, ncol=4)) # ensemble predictions rows = pred, cols = ensemble memmber
#R=0.016


# Calculate the diagonal of the inverse obs. error covariance.
No=length(Y)

if (length(R)==No){   
 
	if (dim(R)[2]==No){
	
        	Rinv=R^(-1)
        	
        	} else {
        	Rinv=t(R)^(-1)
		}
	}else if ( length(R)==1 ){
    Rinv=(1/R)*rep(1,No)
    } else {
    print('Expected numel(R)=No or scalar R')
}

# Calculate the likelihood.
Inn = kronecker(matrix(1,1,dim(HX)[2]),Y)-HX # innovation?





EObj=colSums(Rinv*(Inn^2),na.rm=TRUE)                     # [1 x Ne] ensemble objective function..
LH=exp(-0.5*EObj)                     # Scaled likelihood. 
# NB! The likelihood coefficient (1/sqrt(2*pi...)) is
# omitted because it drops out in the normalization
# of the likelihood. Including it (very small term) would lead
# to problems with FP division.
                                                    

# Calculate the posterior weights as the normalized likelihood. 
w=LH/sum(LH)                        # Posterior weights.

return(w)
}


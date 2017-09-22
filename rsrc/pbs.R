# R implementation of PBS in Aalstad et al.

w = PBS( HX,Y,R)
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


# Calculate the diagonal of the inverse obs. error covariance.
No=length(Y)

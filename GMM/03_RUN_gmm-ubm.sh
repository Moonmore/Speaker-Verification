#!/bin/bash

####################################################################
#	GMM-UBM speaker verification system   based on ALIZE 3.0


# 1. UBM training
	echo "Train Universal Background Model by EM algorithm"
	bin/TrainWorld --config cfg/TrainWorld.cfg &> log/TrainWorld.log
	echo "		done, see log/TrainWorld.log for details"

# 2. Speaker GMM model adaptation
	echo "Train Speaker dependent GMMs"
	bin/TrainTarget --config cfg/TrainTarget.cfg &> log/TrainTarget.cfg
	echo "		done, see log/TrainTarget.cfg for details"

# 3. Speaker model comparison
	echo "Compute Likelihood"
	bin/ComputeTest --config cfg/ComputeTest_GMM.cfg &> log/ComputeTest.cfg
	echo "		done, see log/ComputeTest.cfg"


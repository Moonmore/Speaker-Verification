#!/bin/bash

####################################################################
        echo "Normalise energy : `date` "
	CMD_NORM_E="bin/NormFeat --config cfg/NormFeat_energy_HTK.cfg --inputFeatureFilename data_10s/female_10s.lst --featureFilesPath data_10s/htk_female_10s/"
	echo $CMD_NORM_E
	$CMD_NORM_E
        echo "End normalise energy : `date`\n "

        echo "Energy Detector : `date` "
        CMD_ENERGY="bin/EnergyDetector  --config cfg/EnergyDetector_HTK.cfg --inputFeatureFilename data_10s/female_10s.lst --featureFilesPath data_10s/htk_female_10s/  --labelFilesPath  data_10s/lbl/"
	echo $CMD_ENERGY
	$CMD_ENERGY
        echo "End energy detector : `date`\n "

        echo "Normalise Features : `date`"
        CMD_NORM="bin/NormFeat --config cfg/NormFeat_HTK.cfg --inputFeatureFilename data_10s/female_10s.lst --featureFilesPath  data_10s/htk_female_10s/   --labelFilesPath  data_10s/lbl/"
	echo $CMD_NORM
	$CMD_NORM
        echo "End Normalise Features : `date`"


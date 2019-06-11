#!/bin/bash

. ./cmd.sh
. ./path.sh
set -e
mfccdir=`pwd`/mfcc
vaddir=`pwd`/mfcc

nnet_dir=exp/xvector_nnet_1a
trials_1s_utt=data/data_1s/trials_1s_utt
trials_1s_song=data/data_1s/trials_1s_song
trials_3s_utt=data/data_3s/trials_3s_utt
trials_3s_song=data/data_1s/trials_3s_song


stage=0

if [ $stage -le 1 ]; then
  # Make MFCCs and compute the energy-based VAD for each dataset
  for name in aishell aishell2 data_1s data_3s ; do
    steps/make_mfcc.sh  --mfcc-config conf/mfcc.conf --nj 30 --cmd "$train_cmd" \
      /newdisk/Share/shiyan/kaldi/egs/sre16/v2/dataset/${name} exp/make_mfcc $mfccdir
    utils/fix_data_dir.sh data/${name}
    sid/compute_vad_decision.sh --nj 30 --cmd "$train_cmd" \
      /newdisk/Share/shiyan/kaldi/egs/sre16/v2/dataset/${name} exp/make_vad $vaddir
    utils/fix_data_dir.sh data/${name}
  done
fi

if [ $stage -le 3 ]; then
  local/nnet3/xvector/prepare_feats_for_egs.sh --nj 30 --cmd "$train_cmd" \
    /newdisk/Share/shiyan/kaldi/egs/sre16/v2/dataset/AISHELL-2/iOS/data/ data/aishell2_no_sil exp/aishell2_no_sil
fi

  local/nnet3/xvector/run_xvector.sh --stage $stage --train-stage -1 \
  --data data/aishell2_no_sil --nnet-dir $nnet_dir \
  --egs-dir $nnet_dir/egs

if [ $stage -le 7 ]; then

  #  We'll use this for things like LDA or PLDA.
  sid/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd --mem 12G" --nj 40 \
    $nnet_dir data/aishell \
    exp/aishell

  sid/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd --mem 6G" --nj 40 \
    $nnet_dir data/data_1s \
    exp/data_1s

  sid/nnet3/xvector/extract_xvectors.sh --cmd "$train_cmd --mem 6G" --nj 40 \
    $nnet_dir data/data_3s \
    exp/data_3s
fi

if [ $stage -le 8 ]; then
  $train_cmd exp/aishell/log/compute_mean.log \
    ivector-mean scp:exp/xvectors_aishell/xvector.scp \
    exp/xvectors_aishell/mean.vec || exit 1;

  lda_dim=150
  $train_cmd exp/xvectors_aishell/log/lda.log \
    ivector-compute-lda --total-covariance-factor=0.0 --dim=$lda_dim \
    "ark:ivector-subtract-global-mean scp:exp/xvectors_aishell/xvector.scp ark:- |" \
    ark:data/sre_aishell/utt2spk exp/xvectors_aishell/transform.mat || exit 1;

  $train_cmd exp/xvectors_aishell/log/plda.log \
    ivector-compute-plda ark:data/aishell/spk2utt \
    "ark:ivector-subtract-global-mean scp:exp/xvectors_aishell/xvector.scp ark:- | transform-vec exp/xvectors_aishell/transform.mat ark:- ark:- | ivector-normalize-length ark:-  ark:- |" \
    exp/xvectors_aishell/plda || exit 1;
fi

if [ $stage -le 9 ]; then
  $train_cmd exp/scores/log/data_1s_eval_scoring.log \
    ivector-plda-scoring --normalize-length=true \
    --num-utts=ark:exp/xvectors_data_1s/num_utts.ark \
    "ivector-copy-plda --smoothing=0.0 exp/xvectors_aishell/plda - |" \
    "ark:ivector-mean ark:data/sre16_eval_enroll/spk2utt scp:exp/xvectors_data_1s/xvector.scp ark:- | ivector-subtract-global-mean exp/xvectors_aishell/mean.vec ark:- ark:- | transform-vec exp/xvectors_aishell/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
    "ark:ivector-subtract-global-mean exp/xvectors_aishell/mean.vec scp:exp/xvectors_aishell/xvector.scp ark:- | transform-vec exp/xvectors_aishell/transform.mat ark:- ark:- | ivector-normalize-length ark:- ark:- |" \
    "cat '$trials_1s_utt' | cut -d\  --fields=1,2 |" exp/scores/data_1s_eval_scores || exit 1;

  utils/filter_scp.pl $trials_1s_utt exp/scores/sre16_eval_scores > exp/scores/data_1s_utt_eval__scores
  utils/filter_scp.pl $trials_1s_song exp/scores/sre16_eval_scores > exp/scores/data_3s_song_eval_scores
fi


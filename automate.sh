#!/usr/bin/env bash
set -e

DATASET_ROOT="/data/work/datasets"
#DATASET_ROOT="/NAS/common_data"
LJSPEECH_LINK="https://data.keithito.com/data/speech/LJSpeech-1.1.tar.bz2"
VCTK_LINK="http://www.udialogue.org/download/VCTK-Corpus.tar.gz"

env_file="hacenv.yml"
env_name=$(grep ^name: $env_file | awk '{print $NF}')

# install espeak
espeak_installed=$(dpkg-query -W --showformat='${Status}\n' espeak | grep "install ok installed")
[[ "" = "$espeak_installed" ]] && sudo apt install espeak -y

# check for `jq`
[[ ! -x "$(command -v jq)" ]] && sudo apt install jq -y

conda env create -f $env_file
conda run -n $env_name update-moreh --force
pushd monotonic_align
mkdir -p monotonic_align/
conda run -n $env_name python3 setup.py build_ext --inplace
popd

if [[ ! -d "${DATASET_ROOT}/LJSpeech-1.1" ]]; then
    curl $LJSPEECH_LINK --output $DATASET_ROOT/ljspeech.tar.bz2 --silent
    tar xf $DATASET_ROOT/ljspeech.tar.bz2 -C $DATASET_ROOT
    rm -f $DATASET_ROOT/ljspeech.tar.bz2
fi

if [[ ! -L DUMMY1 ]]; then
    [[ -f DUMMY1 || -d DUMMY1 ]] && rm -rf DUMMY1
    ln -s $DATASET_ROOT/LJSpeech-1.1/wavs DUMMY1
else
    [[ "$(readlink DUMMY1)" != "${DATASET_ROOT}/LJSpeech-1.1/wavs" ]] \
        && rm DUMMY1 \
        && ln -s $DATASET_ROOT/LJSpeech-1.1/wavs DUMMY1
fi

if [[ ! -d "${DATASET_ROOT}/VCTK-Corpus" ]]; then
    curl $VCTK_LINK --output $DATASET_ROOT/vctk.tar.gz --silent
    tar xzf $DATASET_ROOT/vctk.tar.gz -C $DATASET_ROOT
    rm -f $DATASET_ROOT/vctk.tar.gz
fi

[[ ! -d "${DATASET_ROOT}/VCTK-Corpus/downsampled_wavs" ]] \
    && conda run -n $env_name ./downsample_wav.py \
        $DATASET_ROOT/VCTK-Corpus/wav48 \
        $DATASET_ROOT/VCTK-Corpus/downsampled_wavs \
        48000 22050

if [[ ! -L DUMMY2 ]]; then
    [[ -f DUMM2 || -d DUMMY2 ]] && rm -rf DUMMY2
    ln -s $DATASET_ROOT/VCTK-Corpus/downsampled_wavs DUMMY2
else
    [[ "$(readlink DUMMY2)" != "${DATASET_ROOT}/VCTK-Corpus/downsampled_wavs" ]] \
        && rm DUMMY2 \
        && ln -s $DATASET_ROOT/VCTK-Corpus/downsampled_wavs DUMMY2
fi

ljs_epochs=$(jq '.train.epochs' configs/ljs_base.json)
[[ $ljs_epochs -gt 2 ]] && echo "Num of epochs ${ljs_epochs} too large for testing" && exit 1
conda run -n $env_name python3 train.py -c configs/ljs_base.json -m ljs_base

vctk_epochs=$(jq '.train.epochs' configs/vctk_base.json)
[[ $vctk_epochs -gt 2 ]] && echo "Num of epochs ${vctk_epochs} too large for testing" && exit 1
conda run -n $env_name python3 train_ms.py -c configs/vctk_base.json -m vctk_base

conda env remove -n $env_name

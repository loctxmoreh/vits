# [Moreh] Running on Moreh AI Framework
![](https://badgen.net/badge/Moreh-HAC/fail/red) ![](https://badgen.net/badge/Nvidia-A100/passed/green)

## Prepare

### Code
```bash
git clone https://github.com/loctxmoreh/vits
cd vits
```

### Environment
Currently failing on HAC VM, so this is for A100 VM.
```bash
conda create -n vits python=3.8 -y
conda activate vits
```

#### `torch==1.7.1`
```bash
pip install torch==1.7.1+cu110 torchvision==0.8.2+cu110 torchaudio==0.7.2 -f https://download.pytorch.org/whl/torch_stable.html
```

#### `torch==1.12.1`
```bash
conda install pytorch torchvision torchaudio cudatoolkit=11.3 -c pytorch
```

#### The rest of requirements
Comment out `torch` and `torchvision` in `requirements.txt` and then:
```bash
pip install -r requirements.txt
```

Installing `espeak`:
```bash
sudo apt install espeak
```


### Data
Download and extract
[LJSpeech-1.1](https://data.keithito.com/data/speech/LJSpeech-1.1.tar.bz2)
and
[VCTK Corpus](http://www.udialogue.org/download/VCTK-Corpus.tar.gz)

With LJSpeech, symlink its `wavs/` directory to `./DUMMY1`
```bash
ln -s /path/to/LJSpeech-1.1/wavs DUMMY1
```

With VCTK Corpus, the `.wav` files coming from the dataset link above have
sampling rate of 48000Hz, while the repo requires sampling rate of 22050Hz.
Use `downsample_wav.py` script to do this:
```bash
./downsample_wav.py /path/to/VCTK-Corpus/wav48 /path/to/new/downsampled_wavs 48000 22050
```
Then, symlink this new `downsampled_wavs/` directory to `./DUMMY2`:
```bash
ln -s /path/to/new/downsampled_wavs DUMMY2
```

## Run
Edit `configs/ljs_base.json` and `configs/vctk_base.json` and change
`train.epochs` to 2 for testing.

```bash
# Training with LJSpeech
python train.py -c configs/ljs_base.json -m ljs_base

# Training with VCTK Corpus
python train_ms.py -c configs/vctk_base.json -m vctk_base
```

#!/usr/bin/env python3

"""Downsampling wav file of VCTK Corpus dataset"""

import sys
import os
from pathlib import Path
from multiprocessing.pool import Pool

import librosa
import soundfile as sf


NUM_AVAILABLE_CORES = len(os.sched_getaffinity(0))


def downsample(input_file, output_file, orig_sr, new_sr):
    y, sr_native = librosa.load(input_file, sr=None)

    if orig_sr != sr_native:
        raise ValueError(f"Original rate is {sr_native}Hz instead of {orig_sr}Hz")

    new_y = librosa.resample(y, orig_sr=orig_sr, target_sr=new_sr, res_type="kaiser_fast")
    sf.write(output_file, new_y, new_sr, "PCM_16")
    # print(f"Done: {input_file.name}")


def main(input_dir, output_dir, orig_sr, new_sr):
    in_dir = Path(input_dir)
    out_dir = Path(output_dir)

    for subdir in in_dir.iterdir():
        if not subdir.is_dir():
            continue
        (out_dir / subdir.name).mkdir(parents=True, exist_ok=True)

    def args_generator():
        for wav_file in in_dir.rglob("*.wav"):
            file_name = wav_file.name
            speaker = wav_file.resolve().parent.name
            yield (wav_file, out_dir / speaker / file_name, orig_sr, new_sr)

    # parallel computation, fast
    with Pool(processes=NUM_AVAILABLE_CORES) as pool:
        res = pool.starmap(downsample, args_generator())

    # sequential, 13x slower
    # for arg_ in args_generator():
    #     downsample(*arg_)


if __name__ == "__main__":
    if len(sys.argv) != 5:
        print("Usage: ./downsample_wav.py <input_dir> <output_dir> <orig_sr> <new_sr>")
        sys.exit(1)

    main(
        input_dir=sys.argv[1],
        output_dir=sys.argv[2],
        orig_sr=int(sys.argv[3]),
        new_sr=int(sys.argv[4]),
    )

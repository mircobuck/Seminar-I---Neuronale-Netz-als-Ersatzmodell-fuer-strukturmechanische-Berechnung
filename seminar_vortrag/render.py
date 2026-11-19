"""Render the scene using only project-local output and temporary paths."""
import argparse
import os
from pathlib import Path
import subprocess
import sys
from config import CFG

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--quality', choices=('preview','final'), default='preview')
    args = parser.parse_args()
    root = Path(__file__).resolve().parent
    os.chdir(root)
    temp = root / '.tmp'; temp.mkdir(exist_ok=True)
    env = os.environ.copy()
    env.update(TEMP=str(temp), TMP=str(temp), PYTHONPYCACHEPREFIX=str(root / '.pycache'))
    resolution = CFG.preview_resolution if args.quality == 'preview' else CFG.final_resolution
    fps = CFG.preview_fps if args.quality == 'preview' else CFG.final_fps
    command = [sys.executable, '-m', 'manim', '--renderer', 'cairo', '--disable_caching',
               '--media_dir', str(root / 'media'), '--resolution', f'{resolution[0]},{resolution[1]}',
               '--fps', str(fps), '-o', 'mlp_training.mp4', 'scene.py', 'MLPTraining']
    subprocess.run(command, check=True, env=env)
    source = root / 'media' / 'videos' / 'scene' / f'{resolution[1]}p{fps}' / 'mlp_training.mp4'
    destination = root / 'media' / args.quality / 'mlp_training.mp4'
    destination.parent.mkdir(parents=True, exist_ok=True)
    import shutil
    shutil.copy2(source, destination)
    print(f'Video: {destination}', flush=True)

if __name__ == '__main__': main()

#!/usr/bin/env python3

import distutils.spawn
import fnmatch
import glob
import os
import re
import subprocess
import sys

def print_usage():
  print("Usage: ", sys.argv[0], "source-directory-with-heic-images [target-directory]")

if distutils.spawn.find_executable("magick") == None:
  print("This script requires ImageMagick (and it is missing) executable to be on the path.")
  sys.exit(1)

if len(sys.argv) < 2:
  print_usage()
  sys.exit(1)

source_dir = sys.argv[1]
if not os.path.isdir(source_dir):
  print("Invalid directory: ", source_dir)
  sys.exit(1)

target_dir = source_dir
if len(sys.argv) >= 3:
  target_dir = sys.argv[2]
  if not os.path.isdir(target_dir):
    print("Creating target directory: ", target_dir)
    os.mkdir(target_dir, 0o750)

print("Source directory: ", source_dir)
print("Target directory: ", target_dir)

rule = re.compile(fnmatch.translate("*.heic"), re.IGNORECASE)
list = [n for n in os.listdir(os.path.expanduser(source_dir)) if rule.match(n)]
list.sort()

converted = skipped = failed = 0
for file in list:
  filename, ext = os.path.splitext(file)
  source_file = os.path.join(source_dir, file)
  target_file = os.path.join(target_dir, filename + ".JPG")

  if os.path.exists(target_file):
    subprocess.run(["touch", "-r", source_file, target_file])
    print("Skipping (duplicate) file: ", target_file)
    skipped += 1
    continue

  print("Converting from:", source_file, "to:", target_file)
  run_result = subprocess.run(["magick", "convert", source_file, target_file])
  if run_result.returncode != 0:
    print("Converting", source_file, "failed: ", run_result.stderr)
    failed += 1
    continue
  subprocess.run(["touch", "-r", source_file, target_file])

  converted += 1

print("Result: total files:", len(list), "; converted:", converted, "; skipped:", skipped, "; failed:", failed)

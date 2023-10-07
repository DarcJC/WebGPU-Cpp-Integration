@echo off

python -m pip install -r requirements.txt
git submodule update --init --recursive

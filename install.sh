source ~/miniconda/bin/activate
conda create -n cambrian python=3.10 -y
conda activate cambrian
which pip
pip install --upgrade pip  # enable PEP 660 support
pip install -e ".[tpu]"
pip install torch~=2.2.0 torch_xla[tpu]~=2.2.0 --use-deprecated=legacy-resolver -f https://storage.googleapis.com/libtpu-releases/index.html

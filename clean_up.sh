gcloud compute tpus tpu-vm ssh --zone "us-central2-b" "tpu-v4-64-pod" --project "focus-album-323718" --worker=all --command="tmux kill-session -t cambrian"
gcloud compute tpus tpu-vm ssh --zone "us-central2-b" "tpu-v4-64-pod" --project "focus-album-323718" --worker=all --command="rm -rf miniconda"
gcloud compute tpus tpu-vm ssh --zone "us-central2-b" "tpu-v4-64-pod" --project "focus-album-323718" --worker=all --command="rm -rf cambrian_code"
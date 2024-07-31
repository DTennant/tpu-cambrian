# Default arguments
DEFAULT_TPU_NAME="tpu-v3-64-pod-vm"
DEFAULT_TPU_TYPE="v3-64"
DEFAULT_PD_NAME="tpu-v3-64-pod-vm"
DEFAULT_ZONE="europe-west4-a"

# Set defaults if not provided
TPU_NAME="${TPU_NAME:-$DEFAULT_TPU_NAME}"
TPU_TYPE="${TPU_TYPE:-$DEFAULT_TPU_TYPE}"
PD_NAME="${PD_NAME:-$DEFAULT_PD_NAME}"
ZONE="${ZONE:-$DEFAULT_ZONE}"


gcloud compute tpus tpu-vm ssh --zone "$ZONE" "$TPU_NAME" --project "focus-album-323718" --worker=all --command="tmux kill-session -t cambrian"
gcloud compute tpus tpu-vm ssh --zone "$ZONE" "$TPU_NAME" --project "focus-album-323718" --worker=all --command="rm -rf miniconda"
gcloud compute tpus tpu-vm ssh --zone "$ZONE" "$TPU_NAME" --project "focus-album-323718" --worker=all --command="rm -rf cambrian_code"
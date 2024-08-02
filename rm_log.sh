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

gcloud alpha compute tpus tpu-vm ssh $TPU_NAME  --project="focus-album-323718" --zone=$ZONE --worker=all \
  --command "sudo rm -rf /tmp/tpu_logs/ "
gcloud alpha compute tpus tpu-vm ssh $TPU_NAME  --project="focus-album-323718" --zone=$ZONE --worker=all \
    --command "sudo rm  -rf /tmp/libtpu_lockfile/ "
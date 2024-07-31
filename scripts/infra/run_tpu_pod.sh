#!/bin/bash

# set -x
set -e

# Default arguments
DEFAULT_TPU_NAME="tpu-v4-64-pod"
DEFAULT_TPU_TYPE="v4-64"
DEFAULT_PD_NAME="tpu-v4-64-pod"
DEFAULT_BRANCH="ssl_eval"
DEFAULT_ZONE="us-central2-b"
PROJECT="focus-album-323718"
RUNTIME_VERSION="tpu-ubuntu2204-base"
SSH_KEY="id_rsa"

# Function to print logs with timestamp and color the time
log() {
    printf "\033[34m%s\033[0m %s\n" "$(date '+%Y-%m-%d %H:%M:%S')" "$1"
}

# Function to display usage
usage() {
    log "Usage: $0 --tpu_name <TPU_NAME> --tpu_type <TPU_TYPE> [options]"
    log "Options:"
    log "  --pd_name <PD_NAME>        (default: $DEFAULT_PD_NAME)"
    # log "  --branch <BRANCH>          (default: $DEFAULT_BRANCH)"
    log "  --zone <ZONE>              (default: $DEFAULT_ZONE)"
    log "  --script <SCRIPT>          (optional)"
    exit 1
}

# Parse command-line arguments
while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in
        --tpu_name)
            TPU_NAME="$2"
            shift; shift
            ;;
        --tpu_type)
            TPU_TYPE="$2"
            shift; shift
            ;;
        --pd_name)
            PD_NAME="$2"
            shift; shift
            ;;
        --branch)
            BRANCH="$2"
            shift; shift
            ;;
        --zone)
            ZONE="$2"
            shift; shift
            ;;
        --script)
            SCRIPT="$2"
            shift; shift
            ;;
        --help)
            usage
            ;;
        *)
            usage
            ;;
    esac
done

# Set defaults if not provided
TPU_NAME="${TPU_NAME:-$DEFAULT_TPU_NAME}"
TPU_TYPE="${TPU_TYPE:-$DEFAULT_TPU_TYPE}"
PD_NAME="${PD_NAME:-$DEFAULT_PD_NAME}"
BRANCH="${BRANCH:-$DEFAULT_BRANCH}"
ZONE="${ZONE:-$DEFAULT_ZONE}"

# Log starting parameters
log "Starting TPU setup with the following parameters:"
log "TPU Name: $TPU_NAME"
log "TPU Type: $TPU_TYPE"
log "Persistent Disk Name: $PD_NAME"
log "Branch: $BRANCH"
log "Zone: $ZONE"
log "HF Token: $HF_TOKEN"


sort_github() {
    log "Adding SSH key to pods..."
    gcloud compute tpus tpu-vm scp --zone "$ZONE" --project "$PROJECT" --worker=all ~/.ssh/$SSH_KEY $TPU_NAME:~/.ssh/$SSH_KEY
    if [ $? -ne 0 ]; then
        log "Error: Failed to copy SSH key to pods."
        exit 1
    fi
    # gcloud compute tpus tpu-vm ssh --zone "$ZONE" $TPU_NAME --project "$PROJECT" --worker=all \
    #     --command="chmod 600 ~/.ssh/$SSH_KEY && ssh-add ~/.ssh/$SSH_KEY && ssh -o StrictHostKeyChecking=no git@github.com"
    # # the above command is expected to error, do not check the return code
    # log "SSH key permissions set."
    # NOTE: run this below cmd every time?
    gcloud compute tpus tpu-vm ssh --zone "$ZONE" $TPU_NAME --project "$PROJECT" --worker=all \
        --command="ssh -o StrictHostKeyChecking=no git@github.com"

}

# Install dependencies and attach the persistent disk in parallel
install_dependencies() {

    log "Cloning the repository..."
    gcloud compute tpus tpu-vm ssh --zone "$ZONE" $TPU_NAME --project "$PROJECT" --worker=all \
        --command="git clone git@github.com:DTennant/tpu-cambrian.git cambrian_code"
    if [ $? -ne 0 ]; then
        log "Error: Failed to clone the repository."
        exit 1
    fi
    log "Repository cloned."
    
    log "Install miniconda"
    gcloud compute tpus tpu-vm scp --zone "$ZONE" --project "$PROJECT" --worker=all ~/miniconda3.sh $TPU_NAME:~/miniconda3.sh

    gcloud compute tpus tpu-vm ssh --zone "$ZONE" $TPU_NAME --project "$PROJECT" --worker=all \
        --command="bash miniconda3.sh -u -b -p ~/miniconda && source ~/miniconda/bin/activate && conda init --all"

    log "Installing the repository and dependencies..."
    gcloud compute tpus tpu-vm ssh --zone "$ZONE" $TPU_NAME --project "$PROJECT" --worker=all \
        --command="cd ~/cambrian_code && git pull && bash install.sh && sudo snap refresh google-cloud-cli"
    # gcloud compute tpus tpu-vm ssh --zone "$ZONE" $TPU_NAME --project "$PROJECT" --worker=all \
    #     --command="cd ~/cambrian_code && git fetch --all && git checkout $BRANCH && git pull && pip install --upgrade pip setuptools && pip install -e . && pip install -e .[tpu] && pip install torch==2.2.0 torch_xla[tpu]~=2.2.0 -f https://storage.googleapis.com/libtpu-releases/index.html && sudo snap refresh google-cloud-cli"
    # gcloud compute tpus tpu-vm ssh --zone "$ZONE" $TPU_NAME --project "$PROJECT" --worker=all \
    #     --command="cd ~/cambrian_code && git pull && /usr/bin/pip install --upgrade pip setuptools && /usr/bin/pip install -e . && /usr/bin/pip install -e .[tpu] && /usr/bin/pip install torch==2.2.0 torch_xla[tpu]~=2.2.0 -f https://storage.googleapis.com/libtpu-releases/index.html && sudo snap refresh google-cloud-cli"
    if [ $? -ne 0 ]; then
        log "Error: Failed to install dependencies."
        exit 1
    fi
    log "Repository and dependencies installed successfully."
}

attach_and_mount_disk() {
    log "Attaching and mounting the Persistent Disk..."
    gcloud alpha compute tpus tpu-vm attach-disk $TPU_NAME \
        --zone $ZONE \
        --disk $PD_NAME \
        --mode read-only
    if [ $? -ne 0 ]; then
        log "Error: Failed to attach the persistent disk."
        exit 1
    fi
    gcloud compute tpus tpu-vm ssh --zone "$ZONE" $TPU_NAME --project "$PROJECT" --worker=all \
        --command="sudo mkdir -p /mnt/disks/storage && sudo mount -o ro,noload /dev/sdb /mnt/disks/storage"
    if [ $? -ne 0 ]; then
        log "Error: Failed to mount the persistent disk."
        exit 1
    fi
    log "Persistent Disk mounted successfully."
}

sort_github
# Start both processes concurrently
install_dependencies
# attach_and_mount_disk &

# Wait for both processes to finish
wait

# 6. Create a tmux session
log "Creating a new tmux session on all TPU pods..."
gcloud compute tpus tpu-vm ssh --zone "$ZONE" $TPU_NAME --project "$PROJECT" --worker=all \
    --command="tmux new-session -d -s cambrian"
if [ $? -ne 0 ]; then
    log "Error: Failed to create the tmux session."
    exit 1
fi
log "Tmux session created."

# 7. Run the provided script (if available)
if [ -n "$SCRIPT" ]; then
    log "Running the provided script on all TPU pods..."
    gcloud compute tpus tpu-vm ssh --zone "$ZONE" $TPU_NAME --project "$PROJECT" --worker=all \
        --command="cd ~/cambrian_code && tmux send-keys -t cambrian 'cd ~/cambrian_code && export HF_TOKEN=$HF_TOKEN && bash $SCRIPT' C-m"
    if [ $? -ne 0 ]; then
        log "Error: Failed to execute the provided script."
        exit 1
    fi
    log "Script sent to tmux session."
else
    log "No script provided. Initial setup completed."
fi

log "All steps completed successfully."

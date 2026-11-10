#!/usr/bin/env bash
# Install Miniforge and the Phase 1 (genome audit) environment on a new Ubuntu VM.
# Run from the repository root:  bash scripts/00_setup/install_tools.sh
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
CONDA_DIR="${HOME}/miniforge3"

sudo apt-get update
sudo apt-get install -y build-essential git wget curl unzip tmux htop pigz

if [ ! -d "${CONDA_DIR}" ]; then
    wget -q "https://github.com/conda-forge/miniforge/releases/latest/download/Miniforge3-Linux-x86_64.sh" \
        -O /tmp/miniforge.sh
    bash /tmp/miniforge.sh -b -p "${CONDA_DIR}"
    rm /tmp/miniforge.sh
    "${CONDA_DIR}/bin/conda" init bash
fi

# shellcheck disable=SC1091
source "${CONDA_DIR}/etc/profile.d/conda.sh"

if conda env list | grep -q "^mite-audit "; then
    conda env update -n mite-audit -f "${REPO_ROOT}/envs/audit.yml"
else
    conda env create -f "${REPO_ROOT}/envs/audit.yml"
fi

# Record the installed versions for the protocol
mkdir -p "${REPO_ROOT}/protocol/env_exports"
conda env export -n mite-audit > "${REPO_ROOT}/protocol/env_exports/mite-audit_$(date +%F).yml"

echo "Done. Open a new shell, then: conda activate mite-audit"

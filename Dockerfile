FROM rocm/dev-ubuntu-22.04:6.1

ENV PYTHONUNBUFFERED=1
ENV DEBIAN_FRONTEND=noninteractive
ENV HSA_OVERRIDE_GFX_VERSION=10.3.0
ENV PYTORCH_HIP_ALLOC_CONF=expandable_segments:True

RUN apt update && apt install -y \
    git \
    ffmpeg \
    libgl1 \
    python3-pip \
    python3-dev \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone https://github.com/comfyanonymous/ComfyUI.git
WORKDIR /app/ComfyUI

RUN python3 -m pip install --upgrade pip setuptools wheel

RUN sed -i '/^torch$/d' requirements.txt && \
    sed -i '/^torchvision$/d' requirements.txt && \
    sed -i '/^torchaudio$/d' requirements.txt && \
    sed -i '/^torchsde$/d' requirements.txt

RUN pip install --no-cache-dir torch torchvision torchaudio --index-url https://download.pytorch.org/whl/rocm6.1 && \
    pip install --no-cache-dir torchsde && \
    pip install --no-cache-dir -r requirements.txt

RUN python3 -m pip freeze | grep -E 'torch|torchvision|torchaudio|torchsde' || true

RUN python3 - <<'PY'
import sys
import torch

print("========== TORCH BUILD CHECK ==========")
print("Torch version      :", torch.__version__)
print("Torch location     :", torch.__file__)
print("torch.version.hip  :", torch.version.hip)
print("torch.version.cuda :", torch.version.cuda)
print("=======================================")

if torch.version.hip is None:
    print("ERROR: torch is not built for ROCm/HIP", file=sys.stderr)
    sys.exit(1)

if torch.version.cuda is not None:
    print("ERROR: torch is a CUDA build, not ROCm", file=sys.stderr)
    sys.exit(1)

print("PASS: This image contains ROCm/HIP torch.")
PY

EXPOSE 8188

CMD ["python3", "main.py", "--listen", "0.0.0.0"]

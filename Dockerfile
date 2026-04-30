FROM rocm/dev-ubuntu-22.04:6.1

ENV PYTHONUNBUFFERED=1

RUN apt update && apt install -y \
    git \
    ffmpeg \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

RUN git clone https://github.com/comfyanonymous/ComfyUI.git

WORKDIR /app/ComfyUI

RUN pip install --upgrade pip
RUN pip install -r requirements.txt

EXPOSE 8188

CMD ["python", "main.py", "--listen", "0.0.0.0"]

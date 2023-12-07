FROM registry.access.redhat.com/ubi9
RUN dnf -y install https://dl.fedoraproject.org/pub/epel/epel-release-latest-9.noarch.rpm \
 && dnf -y install conda git gcc \
 && dnf -y update \
 && dnf clean all
RUN conda create -y -n text-gen python=3.11
RUN conda init bash
RUN git clone https://github.com/oobabooga/text-generation-webui -b snapshot-2023-12-03
WORKDIR text-generation-webui
RUN conda run --no-capture-output -n text-gen /bin/bash -c "conda install -y -c 'nvidia/label/cuda-12.1.0' cuda-toolkit cuda-runtime"
RUN conda run --no-capture-output -n text-gen /bin/bash -c "python -m pip install --no-cache-dir -r requirements.txt"
RUN conda run --no-capture-output -n text-gen /bin/bash -c "python -m pip install --no-cache-dir -r extensions/openai/requirements.txt"
RUN conda run --no-capture-output -n text-gen /bin/bash -c "python -m pip install torch==2.0.1+cu118 torchvision==0.15.2+cu118 torchaudio==2.0.2 --index-url https://download.pytorch.org/whl/cu118"
RUN conda run --no-capture-output -n text-gen /bin/bash -c "python -m pip uninstall -y flash-attn"
RUN conda run --no-capture-output -n text-gen /bin/bash -c "python -m pip install --no-cache-dir flash-attn"
RUN conda run --no-capture-output -n text-gen /bin/bash -c "python -m pip install --no-cache-dir bitsandbytes==0.38.1"
RUN conda clean --all
RUN chmod 770 /root \
 && chmod -R g=u /root \
 && chgrp -R 0 /text-generation-webui \
 && chmod -R g=u /text-generation-webui
RUN echo "source activate text-gen" >> /root/.bashrc
ENV HOME /root
ENV LD_LIBRARY_PATH /root/.conda/envs/text-gen/lib:/usr/lib
EXPOSE 5000
EXPOSE 7860
ENTRYPOINT conda run --no-capture-output -n text-gen python server.py --listen --gradio-auth "$GRADIO_USERNAME:$GRADIO_PASSWORD" --api --api-port 5000 --api-key "$API_KEY"

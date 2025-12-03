FROM ubuntu:24.04

RUN apt-get update && \
    apt-get install -y --fix-missing \
    curl \
    libatomic1 \
    libdbus-1-3

    
#install IoT FVP (referenced from https://github.com/pytorch/executorch/blob/12d17ef80bb926a8b80ee62d4cd032e2f5c99de8/backends/arm/scripts/fvp_utils.sh)
ARG corstone300_url_amd64="https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/FVP_Corstone_SSE-300_11.22_20_Linux64.tgz?rev=018659bd574f4e7b95fa647e7836ccf4&hash=22A79103C6FA5FFA7AFF3BE0447F3FF9"
ARG corstone300_model_dir_amd64="Linux64_GCC-9.3"
ARG corstone300_md5_checksum_amd64="98e93b949d0fbac977292d8668d34523"

ARG corstone300_url_arm64="https://developer.arm.com/-/media/Arm%20Developer%20Community/Downloads/OSS/FVP/Corstone-300/FVP_Corstone_SSE-300_11.22_20_Linux64_armv8l.tgz?rev=9cc6e9a32bb947ca9b21fa162144cb01&hash=7657A4CF27D42E892E3F08D452AAB073"
ARG corstone300_model_dir_arm64="Linux64_armv8l_GCC-9.3"
ARG corstone300_md5_checksum_arm64="cbbabbe39b07939cff7a3738e1492ef1"
    
ARG TARGETARCH
# Select URL and checksum based on architecture
RUN if [ "$TARGETARCH" = "amd64" ]; then \
        CORSTONE_URL="${corstone300_url_amd64}" && \
        CORSTONE_CHECKSUM="${corstone300_md5_checksum_amd64}" && \
        FVP_DIR="${corstone300_model_dir_amd64}"; \
        elif [ "$TARGETARCH" = "arm64" ]; then \
        CORSTONE_URL="${corstone300_url_arm64}" && \
        CORSTONE_CHECKSUM="${corstone300_md5_checksum_arm64}" && \
        FVP_DIR="${corstone300_model_dir_arm64}"; \
    else \
        echo "Unsupported architecture: $TARGETARCH" && exit 1; \
    fi && \
    curl --output "FVP_corestone300.tgz" "${CORSTONE_URL}" && \
    echo "${CORSTONE_CHECKSUM}  FVP_corestone300.tgz" | md5sum -c - && \
    mkdir -p FVP-corestone300 && \
    cd FVP-corestone300 && \
    tar -xzf "../FVP_corestone300.tgz" && \
    ./FVP_Corstone_SSE-300.sh --i-agree-to-the-contained-eula --force --destination ./ --quiet --no-interactive && \
    rm -rf FVP_Corstone_SSE-300.sh ../FVP_corestone300.tgz && \
    ln -s "/FVP-corestone300/models/${FVP_DIR}" /opt/fvp_models

ENV PATH="/opt/fvp_models:${PATH}"

COPY executors /executors

CMD [ "/bin/bash" ]

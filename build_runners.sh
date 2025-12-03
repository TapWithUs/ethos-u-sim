# These script was tested on [25.12-rc1 release](https://gitlab.arm.com/artificial-intelligence/ethos-u/ml-embedded-evaluation-kit/-/tree/25.12-rc1?ref_type=tags)

#!/bin/bash
set -e

# Install dependencies
apt-get update && \
    apt-get install -y --fix-missing \
    git \
    curl \
    cmake \
    xz-utils \
    python3.12 \
    python3.12-dev \
    python3.12-venv \
    python3-pip \
    libsndfile1

# install arm-none-eabi-gcc
toolchain_url="https://armkeil.blob.core.windows.net/developer/Files/downloads/gnu/13.3.rel1/binrel/arm-gnu-toolchain-13.3.rel1-aarch64-arm-none-eabi.tar.xz"
toolchain_md5_checksum="303102d97b877ebbeb36b3158994b218"
curl --output "toolchain.tar.xz" -L "${toolchain_url}"
echo "${toolchain_md5_checksum}  toolchain.tar.xz" | md5sum -c -
tar xf toolchain.tar.xz
rm toolchain.tar.xz 
# Add to PATH for this script and for future sessions
export PATH="$PATH:$(pwd)/arm-gnu-toolchain-13.3.rel1-aarch64-arm-none-eabi/bin"
echo "export PATH=\"\$PATH:$(pwd)/arm-gnu-toolchain-13.3.rel1-aarch64-arm-none-eabi/bin\"" >> ~/.bashrc


# clone and prepare environment
git clone "https://gitlab.arm.com/artificial-intelligence/ethos-u/ml-embedded-evaluation-kit.git"
cd ml-embedded-evaluation-kit
git checkout 25.12-rc1
git submodule update --init --recursive
python3 ./set_up_default_resources.py --use-case inference_runner


# Force placement of activation buffer in DDR/DRAM - to enable > 4MB buffer - https://developer.arm.com/documentation/ka006173/1-0
sed -i '/#include "BufAttributes.hpp"/a\
    #undef ACTIVATION_BUF_SECTION\
    #undef ACTIVATION_BUF_SECTION_NAME\
    #define ACTIVATION_BUF_SECTION      section("activation_buf_dram")\
    #define ACTIVATION_BUF_SECTION_NAME ("DDR/DRAM")' \
    /ml-embedded-evaluation-kit/source/use_case/inference_runner/src/MainLoop.cc

mkdir -p build_inference_runner
cd build_inference_runner

# build all U55 variants
for VARIANT in H32 H64 H128 H256; do
    cmake ../ \
        -DUSE_CASE_BUILD=inference_runner \
        -Dinference_runner_DYNAMIC_MEM_LOAD_ENABLED=ON \
        -DETHOS_U_NPU_TIMING_ADAPTER_ENABLED=ON \
        -Dinference_runner_ACTIVATION_BUF_SZ=0x00400000 \
        -DTARGET_PLATFORM=mps3 \
        -DTARGET_SUBSYSTEM=sse-300 \
        -DETHOS_U_NPU_ID=U55 \
        -DETHOS_U_NPU_CONFIG_ID=${VARIANT}
    make -j4
    cp bin/ethos-u-inference_runner.axf ../../inference_runner_${VARIANT}.axf
done

# move binaries to output directory
cd ../..
mkdir -p inf_runners
mv inference_runner*.axf inf_runners/

if [ -d "/output" ]; then
    echo "Copying inf_runners to /output..."
    cp -r inf_runners /output/
fi

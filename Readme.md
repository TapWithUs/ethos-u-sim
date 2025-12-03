## Ethos-U NPU runner

A containerized environment and binaries needed to run vela compiled models on Ethos-U NPU using FVP.

This repository contains the following:
- A Dockerfile to build a container with the FVP simulator and the runner binaries.
- A script to compile the runner binaries with dynamic loading.

### Instructions to rebuild the runner binaries

The process is based on [inference_runner use case](https://gitlab.arm.com/artificial-intelligence/ethos-u/ml-embedded-evaluation-kit/-/blob/main/docs/use_cases/inference_runner.md?ref_type=heads) from [ml-embedded-evaluation-kit](https://gitlab.arm.com/artificial-intelligence/ethos-u/ml-embedded-evaluation-kit). 

The use case is compiled with dynamic loading enabled - to enable arbitrary model inference. 

The binaries are executd on the FVP simulator and the model and data are loaded dynamically from the host.

#### Compile the runner binaries

Build the FVP container:
```bash
git clone https://github.com/TapWithUs/ethos-u-sim.git
cd ethos-u-sim
docker run --rm -v $(pwd)/build_runners.sh:/build_runners.sh -v $(pwd):/output ubuntu:24.04 /bin/bash /build_runners.sh
```

This will produce the inference_runner binaries for all U55 variants in the `inf_runners` directory.

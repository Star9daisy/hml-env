# Introduction

The `hml-env` provides a development environment for interdisciplinary research between high-energy physics and artificial intelligence. Based on the included software and libraries, it is divided into three environments:

1. `base`: Provides the fundamental software for phenomenological research in high-energy physics and can generate simulated collision events.

2. `lite`: Builds upon `base` by adding support for TensorFlow 2.16.

3. `dev`: Builds upon `lite` by adding support for a complete machine learning framework, enabling comprehensive research.

# Configurations

|  | `base` | `lite` | `dev` |
| --- | --- | --- | --- |
| Ubuntu 22.04 | ✔ | ✔ | ✔ |
| CUDA 12.2.2 |  | ✔ | ✔ |
| cuDNN 8 |  | ✔ | ✔ |
| ROOT 6.28.12 | ✔ | ✔ | ✔ |
| Delphes 3.5.0 | ✔ | ✔ | ✔ |
| Madgraph5 (MG5) 3.4.2 | ✔ | ✔ | ✔ |
| HepMC 2.06.09 (by MG5) | ✔ | ✔ | ✔ |
| LHAPDF 6.5.4 (by MG5)  | ✔ | ✔ | ✔ |
| PYTHIA 8.311 (by MG5) | ✔ | ✔ | ✔ |
| Tensorflow 2.16.1 (include Keras 3) |  | ✔ | ✔ |
| PyTorch 2.3.0 |  |  | ✔ |
| Jax 0.4.28 |  |  | ✔ |

- `lite` and `dev` are built based on the image `nvidia/cuda:12.2.2-cudnn8-devel-ubuntu22.04`. Before starting the container, you need to install the NVIDIA Container Toolkit. Please refer to [here](https://github.com/NVIDIA/nvidia-container-toolkit) for installation instructions.

- Delphes is installed separately for performance considerations during compilation. The software installed by MG5 has also undergone some minor modifications to utilize all CPU cores during compilation.

- All three machine learning frameworks support GPU and can be used as backends for Keras versions 3 and above.

- The memory growth of TensorFlow and Jax is limited to prevent a single program from occupying the entire GPU memory at once.

# Use cases

1. Launching the Container and Generating Events with Madgraph5:

    ```bash
    docker run -it --rm star9daisy/hml-env:3.0.0-base
    ```

    After entering the container, type `mg5_aMC` to open the Madgraph5 command-line interface.

2. Starting the Container in the Background and Attaching with VSCode:

    ```bash
    docker run -itd --gpus all star9daisy/hml-env:3.0.0-dev
    ```

    After starting, attach VSCode to the running container, allowing you to open the container as if it were a local directory.

3. The image includes an SSH service, and you can add port mappings and passwords when starting the container:

    ```bash
    docker run -itd --gpus all --publish <port>:22 --env PASSWORD=<password> star9daisy/hml-env:3.0.0-dev
    ```

    When this container is running on a remote server, doing so can save a step: changing from local → remote → container to local → container. Use the following command to SSH directly into the container:

    ```bash
    ssh -p <port> root@<remote server ip>
    ```
# Introduction

`hml-env`提供了高能物理与人工智能交叉研究的开发环境。根据包含的软件和库，分为三种环境：

The hml-env provides a development environment for interdisciplinary research between high-energy physics and artificial intelligence. Based on the included software and libraries, it is divided into three environments:

1. `base`: 提供高能物理唯象学研究的基础软件，可以产生模拟对撞事件；

    `base`: Provides the fundamental software for phenomenological research in high-energy physics and can generate simulated collision events.

2. `lite`: 在`base`的基础上，增加了对TensorFlow 2.16的支持；

    `lite`: Builds upon `base` by adding support for TensorFlow 2.16.

3. `dev`: 在`lite`的基础上，增加了完整的机器学习框架的支持，可以进行完整的研究。

    `dev`: Builds upon `lite` by adding support for a complete machine learning framework, enabling comprehensive research.


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
- `lite`和`dev`是基于镜像`nvidia/cuda:12.2.2-cudnn8-devel-ubuntu22.04`构建的，启动容器前需要安装NVIDIA Container Toolkit，请参考[这里](https://github.com/NVIDIA/nvidia-container-toolkit)进行安装。

    `lite` and `dev` are built based on the image `nvidia/cuda:12.2.2-cudnn8-devel-ubuntu22.04`. Before starting the container, you need to install the NVIDIA Container Toolkit. Please refer to [here](https://github.com/NVIDIA/nvidia-container-toolkit) for installation instructions.

- Delphes单独安装是为了编译时的性能考虑，由MG5安装的软件同样经过了一些小的修改以便编译时可以用到所有的CPU核心。

    Delphes is installed separately for performance considerations during compilation. The software installed by MG5 has also undergone some minor modifications to utilize all CPU cores during compilation.

- 三种机器学习框架都支持GPU，都可以作为Keras 3以后的版本的后端进行使用。

    All three machine learning frameworks support GPU and can be used as backends for Keras versions 3 and above.

- 限制了TensorFlow和Jax的显存增长，防止单一程序一次性占满显存。

    The memory growth of TensorFlow and Jax is limited to prevent a single program from occupying the entire GPU memory at once.


# Use cases

1. 启动容器，使用Madgraph5来产生事件：

    Launching the Container and Generating Events with Madgraph5:

    ```bash
    docker run -it --rm star9daisy/hml-env:3.0.0-base
    ```

    进入容器后，输入`mg5_aMC`来打开Madgraph5的命令行界面。

    After entering the container, type `mg5_aMC` to open the Madgraph5 command-line interface.

2. 将容器放在后台启动，使用vscode进行attach：

    Starting the Container in the Background and Attaching with VSCode:

    ```bash
    docker run -itd --gpus all star9daisy/hml-env:3.0.0-dev
    ```

    启动后，将vscode attach到运行的容器即可像打开本地目录一样打开容器。

    After starting, attach VSCode to the running container, allowing you to open the container as if it were a local directory.

3. 镜像包含了SSH服务，可以在启动容器时增加端口映射以及密码：

    The image includes an SSH service, and you can add port mappings and passwords when starting the container:

    ```bash
    docker run -itd --gpus all --publish <port>:22 --env PASSWORD=<password> star9daisy/hml-env:3.0.0-dev
    ```

    当这个容器运行在一台远程服务器上时，这样做可以节省一次跳转：从local → remote → container变成local → container。使用下面的命令直接SSH进入容器：

    When this container is running on a remote server, doing so can save a step: changing from local → remote → container to local → container. Use the following command to SSH directly into the container:

    ```bash
    ssh -p <port> root@<remote server ip>
    ```
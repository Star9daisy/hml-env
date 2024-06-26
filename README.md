# Environment for high energy physics and machine learning lab (HEP ML Lab)

## Introduction

`hml-env` is a comprehensive programming environment designed to facilitate research and development at the intersection of high-energy physics and machine learning. 

With the seamless integration of Docker technology, it offers a unified and user-friendly environment that ensures compatibility and simplifies configuration. Whether you're a researcher or a developer, `hml-env` comes pre-installed with commonly used software, allowing you to quickly start your work in the field of high-energy physics and machine learning phenomenology. It provides a comprehensive and convenient platform to support your projects and experiments.

## Prerequisites
1. [Docker](https://docs.docker.com/engine/install/ubuntu/)
2. [NVIDIA Container Toolkit](https://docs.nvidia.com/datacenter/cloud-native/container-toolkit/latest/install-guide.html)
3. [NVIDIA GPU Driver](https://docs.nvidia.com/datacenter/tesla/tesla-installation-notes/index.html)

## Installtion
```bash
docker pull star9daisy/hml-env
```

## Softwares

`hml-env` is based on `nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04`. Below is a pre-installed software list:

| Type                | Version                                                                                          |
| ------------------- | ------------------------------------------------------------------------------------------------ |
| General             | shell: zsh (oh-my-zsh)                                                                           |
|                     | Python: 3.11.5 (Miniconda)                                                                       |
| High energy physics | [ROOT](https://root.cern): 6.26.14                                                               |
|                     | [LHAPDF](https://lhapdf.hepforge.org): 6.5.3                                                     |
|                     | [MadGraph5_aMC@NLO](https://launchpad.net/mg5amcnlo): 3.5.4 (with Pythia8 and Delphes installed) |

To set up an univeral environment for PyTorch, TensorFlow, Jax, use the following commands:

```bash
pip install torch==2.3.0 torchvision==0.18.0 tensorflow==2.16.1 "jax[cuda12]==0.4.28" flax==0.8.3
```

| Type             | Version              |
| ---------------- | -------------------- |
| Machine learning | TensorFlow: 2.16.1   |
|                  | PyTorch: 2.3.0+cu121 |
|                  | Jax: 0.4.28          |
|                  | Keras: 3.3.3         |

- Set `TF_CPP_MIN_LOG_LEVEL=3` and `TF_FORCE_GPU_ALLOW_GROWTH=true` to reduce running logs and to control GPU memory usage of TensorFlow;
- Set `XLA_PYTHON_CLIENT_ALLOCATOR=platform` to control GPU memory allocation of Jax, though it’s not recommended by official doc. Tried `XLA_PYTHON_CLIENT_PREALLOCATE=false` but it does not work as normal.
- Since Keras 3 that support multiple backends is just published, its requirement of TensorFlow > 2.15 could not be meet. According the [document](https://keras.io/getting_started/), we check the universal environment of [Colab](https://colab.sandbox.google.com/drive/13cpd3wCwEHpsmypY9o6XB6rXgBm5oSxu) and make all three backends work in `hml-env`.

Or if you want to use `hep-ml-lab` for studies in high-energy physics and machine learning, you can use the following command:

```bash
pip install hep-ml-lab
```

You could check whether these framworks could recognize GPUs by running the following commands:

```bash
python -c "import torch; print(torch.cuda.is_available())"
# True
```

```bash
python -c "import jax; print(jax.default_backend())"
# gpu
```

```bash
python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"
# [PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]
```
For the version < 2.3.0, the `tensorflow` may not recognize the GPUs correctly. There's a discussion [here](https://github.com/tensorflow/tensorflow/issues/63362). To solve this, let's first install the latest `tensorflow`:

```base
pip install tensorflow[and-cuda]
```

Then run the following script to set the `LD_LIBRARY_PATH` for `tensorflow` to recognize the GPUs:

```bash
# set_nvidia.sh

# Attempt to locate the NVIDIA cudnn library file using Python.
NVIDIA_DIR=$(python -c "import nvidia.cudnn; print(nvidia.cudnn.__file__)" 2>/dev/null)

# Check if the NVIDIA directory variable is set (i.e., cudnn was found).
if [ ! -z "$NVIDIA_DIR" ]; then
    # Get the parent directory of the directory containing the __file__
    NVIDIA_DIR=$(dirname $(dirname $NVIDIA_DIR))

    # Iterate over all directories in the NVIDIA package directory.
    for dir in $NVIDIA_DIR/*; do
        # Check if the directory has a 'lib' subdirectory.
        if [ -d "$dir/lib" ]; then
            # Prepend the library path to LD_LIBRARY_PATH.
            export LD_LIBRARY_PATH="$dir/lib:$LD_LIBRARY_PATH"
        fi
    done
fi
```

```bash
bash set_nvidia.sh
```

To test if the GPUs are correctly recognized, use the following commands:

```bash
python -c "import tensorflow as tf; print(tf.config.list_physical_devices('GPU'))"

# If it is set up successfully, you will see the following output:
# [PhysicalDevice(name='/physical_device:GPU:0', device_type='GPU')]
```

## Daily Usage

- Quick start from the command line:
    
    ```bash
    docker run -it --rm --gpus all star9daisy/hml-env:2.0.0
    ```
    
- Run in the background as a workspace then attach into it via `Vscode`:
    
    ```bash
    docker run -itd --gpus all --name my_workspace star9daisy/hml-env:2.0.0
    ```
    

`hml-env` also supports for connection to the container via `ssh`. Pick a free port,  set a password for one workspace or take the default one `docker`:

- Quick start from the command line and ssh into it:
    
    ```bash
    # In one shell and keep it open
    docker run -it --rm --gpus all -p 2222:22  star9daisy/hml-env:2.0.0
    
    # In another shell
    ssh root@<the container ip address>
    ```
    
    Use `docker inspect` to get the ip address of the container we just started that usually starts with 172.17.
    
- Run in the background and ssh into it:
    
    ```bash
    docker run -itd --gpus all -p 2222:22 -e PASSWORD=hello --name my_workspace star9daisy/hml-env:2.0.0
    ssh root@<the container ip address>
    ```
    

If It succeeds in connecting the address, `hml-env` will print a banner:

![banner](images/banner.png)

Since we have done port forwarding, it’s possible to ssh to this workspace from remote host:

1. Start a workspace on a remote host. Let’s image we do this on a server:
    
    ```bash
    docker run -itd  \
    -p 34810:22 \
    --name my_workspace \
    --gpus all \
    -v /mnt/workspace_ssd/star9daisy:/root/workspace_ssd \
    -v /mnt/workspace_hdd/star9daisy:/root/workspace_hdd \
    -e PASSWORD=star9daisy \
    star9daisy/hml-env:2.0.0
    ```
    
2. Create virtual server in the configuration page of your router. It’s better to make the external port the same as the internal one.
3. Make sure the IP address of the server is static or something same during a small period.
4. Then let’s ssh into it using our own laptop (local host):
    
    ```bash
    ssh root@<your server ip address> -p 34810
    ```
    
    If it’s all good, you will see the above banner.

## History

### 2.3.0
- Upgrade cuda:11.8.0 to 12.2.2 to support the all backends of Keras 3
- Upgrade ubuntu:20.04 to 22.04
- Upgrade Madgraph5_aMC@NLO:3.5.3 (download link is missing) to 3.5.4
- Drop removing cuda.list

### 2.2.1
- Fixed the issue of incorrect LHAPDF library path

### 2.2.0
- Upgrade python 3.10 to 3.11

### 2.1.0
- Remove the deep learning pacakages to reduce the size of the image (19.7GB -> 12.8GB)

### 2.0.0
- Upgrade python:3.8 to 3.10
- Support for Keras 3 and all backends

### 1.8.0
- Upgrade cuda:11.2.2 to 11.8.0
- Support for modifying password at runtime

### 1.7.3
- Fix missing catch of environment variables due to spaces at the beginning

### 1.7.2
- Fix locale via environment variables
- Add welcome banner when a user uses ssh

### 1.7.1
- Fix environment variables missing when sshing into a container

### 1.7
- Support ssh server
- Fix locales and Delphes enviroment variables

### 1.6
- Remove python packages
- Remove external Delphes, FastJet, fjcontrib
- Change entry point to allow users to run commands directly and launch zsh by
  default

### 1.5
- Fix auto-update issue of madgraph5
    > `auto_update = 0` does not work as it says "no update check" but "update check every time". So it has been set to 600 meaning 600 days.
- Remove pythia8 from conda-force
    > since `PYTHIA8DATA` environment variable is reset by it without notification and as a consequence, madgraph5 or commands from delphes raise error associated with the version of pythia8.

### 1.4.1
- Fix the conflict of pythia8 inside of madgraph5 and the one installed by conda

### 1.4
- Add support for pytorch

### 1.3.1
- Remove pythia8-config with python to fix the conflict of compiled pythia8
- Turn off the auto-updates of MG5

### 1.3
- Change python version from 3.9 to 3.8 to be compatible with pyROOT and pythia8
- Add lhapdf6.5.3 to support usage in MG5
- Add support to conda version Pythia8
- Fix the pyROOT not found in miniconda python

### 1.2
- Change zsh into official intallation way
- Fix "which conda" not correctly showing the conda path

### 1.1
- Remove GUILD_HOME
- Set zsh as the default shell and add plugins

### 1.0
- support for usual softwares used in HEP (MG5, Pythia8, Delphes3, FastJet3).
- support for machine learning.
FROM nvidia/cuda:11.8.0-cudnn8-devel-ubuntu20.04

# ============================================================================ #
#                                Basic Settings                                #
# ============================================================================ #
ENV DEBIAN_FRONTEND=noninteractive
ENV SHARED_DIR=share INSTALL_DIR=/root/softwares
ENV LC_ALL=C.UTF-8 LANG=C.UTF-8

# ============================================================================ #
#                              Basic Dependencies                              #
# ============================================================================ #
WORKDIR ${INSTALL_DIR}

# general -------------------------------------------------------------------- #
RUN rm /etc/apt/sources.list.d/cuda.list && \
    apt-get update && apt-get install -yq \
    apt-utils software-properties-common \
    vim wget curl tree duc screen && \
    apt-add-repository ppa:git-core/ppa && \
    apt-get update && apt-get install -yq git && \
    apt-get clean

# root dependencies ---------------------------------------------------------- #
RUN apt-get update && apt-get install -yq \
    dpkg-dev cmake g++ gcc binutils \
    libx11-dev libxpm-dev libxft-dev libxext-dev python3 libssl-dev \
    gfortran make rsync ghostscript gnuplot && \
    apt-get clean

# proxy ---------------------------------------------------------------------- #
RUN echo "alias setproxy=\"export ALL_PROXY=socks5://172.17.0.1:7890\"" >> ~/.zshrc && \
    echo "alias unsetproxy=\"unset ALL_PROXY\"" >> ~/.zshrc && \
    echo "alias ip=\"curl http://ip-api.com/json\"" >> ~/.zshrc && \
    git config --global http.proxy socks5://172.17.0.1:7890 && \
    git config --global https.proxy socks5://172.17.0.1:7890

# zsh ------------------------------------------------------------------------ #
RUN apt-get -yq install zsh && \
    sh -c "$(wget -O- https://install.ohmyz.sh)" && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    sed -i 's/plugins=(git)/plugins=(z git zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc && \
    apt-get clean

# miniconda3 ----------------------------------------------------------------- #
ENV MINICONDA3_DIR=/root/miniconda3 \
    MINICONDA3_FILE=Miniconda3-py310_23.10.0-1-Linux-x86_64.sh
RUN mkdir MINICONDA3_DIR && \
    wget -O ${MINICONDA3_FILE} https://repo.anaconda.com/miniconda/${MINICONDA3_FILE} && \
    bash ${MINICONDA3_FILE} -b -u -p ${MINICONDA3_DIR} && \
    ${MINICONDA3_DIR}/bin/conda init zsh && \
    ${MINICONDA3_DIR}/bin/conda install -c conda-forge libpython-static -y
ENV PATH=${MINICONDA3_DIR}/bin:${PATH}

# ============================================================================ #
#                                 Main Programs                                #
# ============================================================================ #
# python --------------------------------------------------------------------- #
RUN pip install --no-cache-dir numpy pandas matplotlib
RUN pip install --no-cache-dir tensorflow==2.14
RUN pip install --no-cache-dir --upgrade "jax[cuda11_local]" -f https://storage.googleapis.com/jax-releases/jax_cuda_releases.html
RUN pip install --no-cache-dir torch==2.1.0 torchvision torchaudio --index-url https://download.pytorch.org/whl/cu118
RUN pip install --no-cache-dir keras==3.0.0 --upgrade

ENV TF_CPP_MIN_LOG_LEVEL=3 \
    TF_FORCE_GPU_ALLOW_GROWTH=true \
    XLA_PYTHON_CLIENT_PREALLOCATE=false \
    XLA_PYTHON_CLIENT_ALLOCATOR=platform

# root6 ---------------------------------------------------------------------- #
ENV ROOT6_DIR=${INSTALL_DIR}/root6 \
    ROOT6_FILE=root_v6.26.14.source.tar.gz
RUN mkdir ${ROOT6_DIR} build src && \
    wget -O ${ROOT6_FILE} https://root.cern/download/${ROOT6_FILE} && \
    tar xf ${ROOT6_FILE} --strip=1 --directory=src && \
    cd build && \
    cmake -DCMAKE_INSTALL_PREFIX=${ROOT6_DIR} -DPython_EXECUTABLE=~/miniconda3/bin/python ../src && \
    cmake --build . --target install -j $(nproc) && \
    echo "# root6" >> ~/.zshrc && \
    echo "source ${ROOT6_DIR}/bin/thisroot.sh" >> ~/.zshrc && \
    cd ${INSTALL_DIR} && rm -rf ${ROOT6_FILE} build src

# lhapdf --------------------------------------------------------------------- #
ENV LHAPDF6_DIR=${INSTALL_DIR}/lhapdf6 \
    LHAPDF6_FILE=LHAPDF-6.5.3.tar.gz
RUN mkdir ${LHAPDF6_DIR} src && \
    wget -O ${LHAPDF6_FILE} https://lhapdf.hepforge.org/downloads/?f=${LHAPDF6_FILE} && \
    tar xf ${LHAPDF6_FILE} --strip=1 --directory=src && cd src && \
    ./configure --prefix=${LHAPDF6_DIR} && \
    make -j $(nproc) && make install && \
    export LD_LIBRARY_PATH="$LD_LIBRARY_PATH:~/miniconda3/lib" && \
    ln -fs ${LHAPDF6_DIR}/bin/lhapdf* /usr/local/bin/ && \
    echo "# lhapdf6" >> ~/.zshrc && \
    echo "export LD_LIBRARY_PATH=${LHAPDF6_DIR}/lib:\$LD_LIBRARY_PATH" >> ~/.zshrc && \
    echo "export PYTHONPATH=${LHAPDF6_DIR}/lib/python3.10/site-packages:\$PYTHONPATH" >> ~/.zshrc && \
    cd ${INSTALL_DIR} && rm -rf ${LHAPDF6_FILE} src && \
    export LD_LIBRARY_PATH=${LHAPDF6_DIR}/lib:\$LD_LIBRARY_PATH && \
    export PYTHONPATH=${LHAPDF6_DIR}/lib/python3.10/site-packages:\$PYTHONPATH && \
    lhapdf install NNPDF23_lo_as_0130_qed

# madgraph5 ------------------------------------------------------------------ #
ENV MADGRAPH5_DIR=${INSTALL_DIR}/madgraph5 \
    MADGRAPH5_FILE=MG5_aMC_v3.5.2.tar.gz
RUN mkdir ${MADGRAPH5_DIR} && \ 
    wget -O ${MADGRAPH5_FILE} https://launchpad.net/mg5amcnlo/3.0/3.5.x/+download/${MADGRAPH5_FILE} && \
    tar xf ${MADGRAPH5_FILE} --strip=1 --directory=${MADGRAPH5_DIR} && \
    ln -fs ${MADGRAPH5_DIR}/bin/mg5_aMC /usr/local/bin/ && \
    echo "n" | mg5_aMC && \
    echo "install pythia8" | mg5_aMC && \
    export ROOTSYS=${ROOT6_DIR} && \
    export PATH=$PATH:$ROOTSYS/bin && \
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ROOTSYS/lib && \
    export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$ROOTSYS/lib && \
    echo "install Delphes" | mg5_aMC && \
    sed -i 's/# auto_update = 7/auto_update = 600/g' ${MADGRAPH5_DIR}/input/mg5_configuration.txt && \
    sed -i 's/^# lhapdf_py3 = lhapdf-config$/lhapdf_py3 = lhapdf-config/' ${MADGRAPH5_DIR}/input/mg5_configuration.txt && \
    echo "set auto_convert_model T" | mg5_aMC && \
    echo "# delphes3" >> ~/.zshrc && \
    echo "export LD_LIBRARY_PATH=${MADGRAPH5_DIR}/Delphes:\$LD_LIBRARY_PATH" >> ~/.zshrc && \
    echo "export ROOT_INCLUDE_PATH=${MADGRAPH5_DIR}/Delphes/external:\$ROOT_INCLUDE_PATH" >> ~/.zshrc && \
    rm -rf py.py ${MADGRAPH5_FILE}

# ============================================================================ #
#                                Openssh Server                                #
# ============================================================================ #
# Change ssh config
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd && \
    sed -i '/#\?PermitRootLogin/s/.*/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Default password
ENV PASSWORD docker

# Creating a new script to start both sshd and any command passed as an argument
# Change password at runtime
RUN echo '#!/bin/zsh' > /start.sh \
    && echo '/usr/sbin/sshd' >> /start.sh \
    && echo 'echo "root:${PASSWORD}" | chpasswd' >> /start.sh \
    && echo 'exec "$@"' >> /start.sh \
    && chmod +x /start.sh

EXPOSE 22

# Setup banner
ENV VERSION 2.0.0
RUN apt install figlet && \
    figlet -f slant "hml env ${VERSION}" >> /etc/banner.txt && \
    sed -i 's/#Banner none/Banner \/etc\/banner.txt/' /etc/ssh/sshd_config && \
    chmod -x /etc/update-motd.d/*

# ============================================================================ #
#                             Environment Variables                            #
# ============================================================================ #
# As users ssh into the container, the environment set by Docker won't appear
# in .zshrc, so here we export all variables into .zshrc
RUN echo "# Docker env variables" >> ~/.zshrc && \
    grep -P '^\s*export ' ~/.zshrc | awk '{print $2}' | awk -F= '{print $1}' | sort | uniq > /tmp/existing-vars.txt && \
    printenv > /tmp/container-env.txt && \
    while IFS='=' read -r var value; do \
    if grep -q "^$var\$" /tmp/existing-vars.txt; then \
    echo "export $var=\"\$$var:$value\"" >> ~/.zshrc; \
    else \
    echo "export $var=\"$value\"" >> ~/.zshrc; \
    fi; \
    done < /tmp/container-env.txt

# Since cern root will set environment variables as well, we put it in the final
RUN echo "# root6" >> ~/.zshrc && \
    echo "source ${ROOT6_DIR}/bin/thisroot.sh" >> ~/.zshrc

# ============================================================================ #
#                                    Ending                                    #
# ============================================================================ #
WORKDIR /root
# Change the default shell for root user from bash to zsh when a user ssh to
# the container
RUN sed -i 's#^root:x:0:0:root:/root:/bin/bash#root:x:0:0:root:/root:/bin/zsh#' /etc/passwd
CMD ["/start.sh", "zsh"]

FROM nvidia/cuda:11.2.2-cudnn8-devel-ubuntu20.04

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
    apt-get update && apt-get install -yq git

# zsh ------------------------------------------------------------------------ #
RUN apt-get -yq install zsh && \
    sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    sed -i 's/plugins=(git)/plugins=(z git zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc

# proxy ---------------------------------------------------------------------- #
RUN echo "alias setproxy=\"export ALL_PROXY=socks5://172.17.0.1:7890\"" >> ~/.zshrc && \
    echo "alias unsetproxy=\"unset ALL_PROXY\"" >> ~/.zshrc && \
    echo "alias ip=\"curl http://ip-api.com/json\"" >> ~/.zshrc && \
    git config --global http.proxy socks5://172.17.0.1:7890 && \
    git config --global https.proxy socks5://172.17.0.1:7890

# miniconda3 ----------------------------------------------------------------- #
ADD https://repo.anaconda.com/miniconda/Miniconda3-py38_23.5.2-0-Linux-x86_64.sh /tmp/miniconda.sh
ENV MINICONDA3_DIR=/root/miniconda3
RUN bash /tmp/miniconda.sh -b && \
    ${MINICONDA3_DIR}/bin/conda init zsh && \
    echo "\n# fix which conda" >> ~/.zshrc &&\
    echo "alias which=\"which -p\"" >> ~/.zshrc
# disable tensorflow logging and limit GPU usage
ENV PATH=${MINICONDA3_DIR}/bin:${PATH} \
    TF_CPP_MIN_LOG_LEVEL=3 \
    TF_FORCE_GPU_ALLOW_GROWTH=true

# ============================================================================ #
#                                 Main Programs                                #
# ============================================================================ #
# root dependencies ---------------------------------------------------------- #
RUN apt-get update && apt-get install -yq \
    dpkg-dev cmake g++ gcc binutils \
    libx11-dev libxpm-dev libxft-dev libxext-dev python libssl-dev \
    gfortran make rsync ghostscript gnuplot

# root6 ---------------------------------------------------------------------- #
ADD https://root.cern/download/root_v6.24.02.Linux-ubuntu20-x86_64-gcc9.3.tar.gz /tmp/root6.tar.gz
ENV ROOT6_DIR=${INSTALL_DIR}/root6
RUN mkdir ${ROOT6_DIR} && \
    tar xf /tmp/root6.tar.gz --strip=1 --directory=${ROOT6_DIR}

# lhapdf --------------------------------------------------------------------- #
ADD https://lhapdf.hepforge.org/downloads/LHAPDF-6.5.3.tar.gz /tmp/lhapdf.tar.gz
ENV LHAPDF6_DIR=${INSTALL_DIR}/lhapdf6
RUN mkdir src && \
    tar xf /tmp/lhapdf.tar.gz --strip=1 --directory=src && cd src && \
    ./configure --prefix=${LHAPDF6_DIR} && \
    make -j $(nproc) && make install && \
    ln -fs ${LHAPDF6_DIR}/bin/lhapdf* /usr/local/bin/ && \
    echo "# lhapdf6" >> ~/.zshrc && \
    echo "export LD_LIBRARY_PATH=${LHAPDF6_DIR}/lib:\$LD_LIBRARY_PATH" >> ~/.zshrc && \
    echo "export PYTHONPATH=${LHAPDF6_DIR}/lib/python3.8/site-packages:\$PYTHONPATH" >> ~/.zshrc && \
    cd ${INSTALL_DIR} && rm -rf src && \
    export LD_LIBRARY_PATH=${LHAPDF6_DIR}/lib:\$LD_LIBRARY_PATH && \
    export PYTHONPATH=${LHAPDF6_DIR}/lib/python3.8/site-packages:\$PYTHONPATH && \
    lhapdf install NNPDF23_lo_as_0130_qed

# madgraph5 ------------------------------------------------------------------ #
ADD https://launchpad.net/mg5amcnlo/3.0/3.5.x/+download/MG5_aMC_v3.5.1.tar.gz /tmp/madgraph5.tar.gz
ENV MADGRAPH5_DIR=${INSTALL_DIR}/madgraph5
RUN mkdir ${MADGRAPH5_DIR} && \ 
    tar xf /tmp/madgraph5.tar.gz --strip=1 --directory=${MADGRAPH5_DIR} && \
    rm /tmp/madgraph5.tar.gz && \
    ln -fs ${MADGRAPH5_DIR}/bin/mg5_aMC /usr/local/bin/ && \
    echo "n" | mg5_aMC && \
    echo "install pythia8" | mg5_aMC && \
    export ROOTSYS=${ROOT6_DIR} && \
    export PATH=$PATH:$ROOTSYS/bin && \
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ROOTSYS/lib && \
    export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$ROOTSYS/lib && \
    echo "install Delphes" | mg5_aMC && \
    rm py.py && \
    sed -i 's/# auto_update = 7/auto_update = 600/g' ${MADGRAPH5_DIR}/input/mg5_configuration.txt && \
    sed -i 's/^# lhapdf_py3 = lhapdf-config$/lhapdf_py3 = lhapdf-config/' ${MADGRAPH5_DIR}/input/mg5_configuration.txt && \
    echo "# delphes3" >> ~/.zshrc && \
    echo "export LD_LIBRARY_PATH=${MADGRAPH5_DIR}/Delphes:\$LD_LIBRARY_PATH" >> ~/.zshrc && \
    echo "export ROOT_INCLUDE_PATH=${MADGRAPH5_DIR}/Delphes/external:\$ROOT_INCLUDE_PATH" >> ~/.zshrc

# ============================================================================ #
#                                Openssh Server                                #
# ============================================================================ #
RUN apt-get update && apt-get install -y openssh-server
RUN mkdir /var/run/sshd && \
    echo 'root:docker' | chpasswd && \
    sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin yes/' /etc/ssh/sshd_config && \
    sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

# Creating a new script to start both sshd and any command passed as an argument
RUN echo '#!/bin/zsh' > /start.sh \
    && echo '/usr/sbin/sshd' >> /start.sh \
    && echo 'exec "$@"' >> /start.sh \
    && chmod +x /start.sh

EXPOSE 22

# Setup banner
ENV VERSION 1.7.2
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

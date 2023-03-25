FROM nvidia/cuda:11.2.2-cudnn8-devel-ubuntu20.04

# ================================================================================================ #
#                                          Basic Settings                                          #
# ================================================================================================ #
ENV DEBIAN_FRONTEND=noninteractive \
    # directories
    SHARED_DIR=share \
    INSTALL_DIR=/root/softwares \
    WORK_DIR=/root/workspace \
    # locales
    LC_ALL=C.UTF-8 \
    LANG=C.UTF-8

# timezone
RUN apt-key adv --fetch-keys https://developer.download.nvidia.com/compute/cuda/repos/ubuntu2004/x86_64/3bf863cc.pub && \
    apt-get update && \
    apt-get install -yq tzdata && \
    ln -fs /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && \
    dpkg-reconfigure -f noninteractive tzdata

# ================================================================================================ #
#                                          Basic Programs                                          #
# ================================================================================================ #
WORKDIR ${INSTALL_DIR}

# general ---------------------------------------------------------------------------------------- #
RUN apt-get update && apt-get install -yq apt-utils software-properties-common
RUN apt-get install -yq htop vim wget curl tree duc screen &&\
    apt-add-repository ppa:git-core/ppa &&\
    apt-get update && apt-get -yq install git

# zsh -------------------------------------------------------------------------------------------- #
RUN apt-get -yq install zsh
RUN sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
COPY ${SHARED_DIR}/zsh-autosuggestions /root/.oh-my-zsh/custom/plugins/zsh-autosuggestions
COPY ${SHARED_DIR}/zsh-syntax-highlighting /root/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
RUN sed -i 's/plugins=(git)/plugins=(z git zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc

# proxy ------------------------------------------------------------------------------------------ #
RUN echo "alias setproxy=\"export ALL_PROXY=socks5://172.17.0.1:7890\"" >> ~/.zshrc && \
    echo "alias unsetproxy=\"unset ALL_PROXY\"" >> ~/.zshrc && \
    echo "alias ip=\"curl http://ip-api.com/json\"" >> ~/.zshrc && \
    git config --global http.proxy socks5://172.17.0.1:7890 && \
    git config --global https.proxy socks5://172.17.0.1:7890

# miniconda3 ------------------------------------------------------------------------------------- #
ENV MINICONDA3_DIR=/root/miniconda3 \
    MINICONDA3_FILE=Miniconda3-py38_23.1.0-1-Linux-x86_64.sh
COPY ${SHARED_DIR}/${MINICONDA3_FILE} .
RUN bash ${MINICONDA3_FILE} -b && \
    ${MINICONDA3_DIR}/bin/conda init zsh && \
    rm ${MINICONDA3_FILE} &&\
    echo "\n# fix which conda" >> ~/.zshrc &&\
    echo "alias which=\"which -p\"" >> ~/.zshrc
# disable tensorflow logging and limit GPU usage
ENV PATH=${MINICONDA3_DIR}/bin:${PATH} \
    TF_CPP_MIN_LOG_LEVEL=3 \
    TF_FORCE_GPU_ALLOW_GROWTH=true

# ================================================================================================ #
#                                           Main Programs                                          #
# ================================================================================================ #
# python packages -------------------------------------------------------------------------------- #
RUN pip install numpy pandas matplotlib jupyterlab tensorflow numpythia pyjet
RUN pip install torch torchvision torchaudio --extra-index-url https://download.pytorch.org/whl/cu116
RUN conda install -c conda-forge pythia8 && rm ${MINICONDA3_DIR}/bin/pythia8-config

# root dependences ------------------------------------------------------------------------------- #
RUN apt-get update && apt-get install -yq dpkg-dev cmake g++ gcc binutils
RUN apt-get update && apt-get install -yq libx11-dev libxpm-dev libxft-dev libxext-dev python libssl-dev
RUN apt-get update && apt-get install -yq gfortran make rsync ghostscript gnuplot

# root6 ------------------------------------------------------------------------------------------ #
ENV ROOT6_DIR=${INSTALL_DIR}/root6 \
    ROOT6_FILE=root_v6.24.02.Linux-ubuntu20-x86_64-gcc9.3.tar.gz
COPY ${SHARED_DIR}/${ROOT6_FILE} .
RUN mkdir ${ROOT6_DIR} && \
    tar xf ${ROOT6_FILE} --strip=1 --directory=${ROOT6_DIR} && \ 
    rm ${ROOT6_FILE} && \
    echo "# root6" >> ~/.zshrc && \
    echo "source ${ROOT6_DIR}/bin/thisroot.sh" >> ~/.zshrc

# lhapdf ----------------------------------------------------------------------------------------- #
ENV LHAPDF6_DIR=${INSTALL_DIR}/lhapdf6 \
    LHAPDF6_FILE=LHAPDF-6.5.3.tar.gz
COPY ${SHARED_DIR}/${LHAPDF6_FILE} .
RUN mkdir src && \
    tar xf ${LHAPDF6_FILE} --strip=1 --directory=src && cd src && \
    ./configure --prefix=${LHAPDF6_DIR} && \
    make -j $(nproc) && make install && \
    ln -fs ${LHAPDF6_DIR}/bin/lhapdf* /usr/local/bin/ && \
    echo "# lhapdf6" >> ~/.zshrc && \
    echo "export LD_LIBRARY_PATH=${LHAPDF6_DIR}/lib:\$LD_LIBRARY_PATH" >> ~/.zshrc && \
    echo "export PYTHONPATH=${LHAPDF6_DIR}/lib/python3.8/site-packages:\$PYTHONPATH" >> ~/.zshrc && \
    cd ${INSTALL_DIR} && rm -rf ${LHAPDF6_FILE} src && \
    export LD_LIBRARY_PATH=${LHAPDF6_DIR}/lib:\$LD_LIBRARY_PATH && \
    export PYTHONPATH=${LHAPDF6_DIR}/lib/python3.8/site-packages:\$PYTHONPATH && \
    lhapdf install NNPDF23_lo_as_0130_qed

# madgraph5 -------------------------------------------------------------------------------------- #
ENV MADGRAPH5_DIR=${INSTALL_DIR}/madgraph5 \
    MADGRAPH5_FILE=MG5_aMC_v3.3.1.tar.gz
COPY ${SHARED_DIR}/${MADGRAPH5_FILE} .
RUN mkdir ${MADGRAPH5_DIR} && \ 
    tar xf ${MADGRAPH5_FILE} --strip=1 --directory=${MADGRAPH5_DIR} && \
    rm ${MADGRAPH5_FILE} && \
    ln -fs ${MADGRAPH5_DIR}/bin/mg5_aMC /usr/local/bin/ && \
    echo "n" | mg5_aMC && \
    echo "install pythia8" | mg5_aMC && \
    export ROOTSYS=${ROOT6_DIR} && \
    export PATH=$PATH:$ROOTSYS/bin && \
    export LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$ROOTSYS/lib && \
    export DYLD_LIBRARY_PATH=$DYLD_LIBRARY_PATH:$ROOTSYS/lib && \
    echo "install Delphes" | mg5_aMC && \
    rm py.py && \
    sed -i 's/# auto_update = 7/auto_update = 0/g' ${MADGRAPH5_DIR}/input/mg5_configuration.txt

# fastjet3 --------------------------------------------------------------------------------------- #
ENV FASTJET3_DIR=${INSTALL_DIR}/fastjet3 \
    FASTJET3_FILE=fastjet-3.4.0.tar.gz
COPY ${SHARED_DIR}/${FASTJET3_FILE} .
RUN mkdir src && \
    tar xf ${FASTJET3_FILE} --strip=1 --directory=src && cd src && \
    ./configure --prefix=${FASTJET3_DIR} --enable-pyext && \
    make -j $(nproc) && make install && \
    ln -fs ${FASTJET3_DIR}/bin/fastjet-config /usr/local/bin/ && \
    echo "# fastjet3" >> ~/.zshrc && \
    echo "export PYTHONPATH=$(fastjet-config --pythonpath):\$PYTHONPATH" >> ~/.zshrc && \
    cd ${INSTALL_DIR} && rm -rf ${FASTJET3_FILE} src

# fjcontrib -------------------------------------------------------------------------------------- #
ENV FJCONTRIB_FILE=fjcontrib-1.046.tar.gz
COPY ${SHARED_DIR}/${FJCONTRIB_FILE} .
RUN mkdir src && \
    tar xf ${FJCONTRIB_FILE} --strip=1 --directory=src && cd src && \
    ./configure --fastjet-config=${FASTJET3_DIR}/bin/fastjet-config && \
    make -j $(nproc) && make install  && \
    cd ${INSTALL_DIR} && rm -rf ${FJCONTRIB_FILE} src

# pythia8 ---------------------------------------------------------------------------------------- #
ENV PYTHIA8_DIR=${INSTALL_DIR}/pythia8 \
    PYTHIA8_FILE=pythia8244.tar
COPY ${SHARED_DIR}/${PYTHIA8_FILE} .
RUN mkdir src && \
    tar xf ${PYTHIA8_FILE} --strip=1 --directory=src && cd src && \
    ./configure --prefix=${PYTHIA8_DIR} --with-fastjet3=${FASTJET3_DIR} && \
    make -j $(nproc) && make install && \
    ln -fs ${PYTHIA8_DIR}/bin/pythia8-config /usr/local/bin/ && \
    cd ${INSTALL_DIR} && rm -rf ${PYTHIA8_FILE} src

# delphes3 --------------------------------------------------------------------------------------- #
ENV DELPHES3_DIR=${INSTALL_DIR}/delphes3 \
    DELPHES3_FILE=Delphes-3.5.0.tar.gz
COPY ${SHARED_DIR}/${DELPHES3_FILE} .
RUN mkdir src && \
    tar xf ${DELPHES3_FILE} --strip=1 --directory=src && cd src && \
    mkdir build && cd build && \
    cmake -DCMAKE_PREFIX_PATH=${ROOT6_DIR}/cmake/ -DCMAKE_INSTALL_PREFIX=${DELPHES3_DIR} .. && \
    make HAS_PYTHIA8=true -j $(nproc) install && \
    # export PYTHIA8=${PYTHIA8_DIR} && make HAS_PYTHIA8=true install && \
    echo "# delphes3" >> ~/.zshrc && \
    echo "export LD_LIBRARY_PATH=${DELPHES3_DIR}/lib:\$LD_LIBRARY_PATH" >> ~/.zshrc && \
    echo "export ROOT_INCLUDE_PATH=${DELPHES3_DIR}/include:\$ROOT_INCLUDE_PATH" >> ~/.zshrc && \
    ln -fs ${DELPHES3_DIR}/bin/Delphes* /usr/local/bin/ && \
    cd ${INSTALL_DIR} && rm -rf ${DELPHES3_FILE} src

# ================================================================================================ #
#                                                End                                               #
# ================================================================================================ #
WORKDIR ${WORK_DIR}
ENTRYPOINT [ "zsh" ]

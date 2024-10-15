FROM nvidia/cuda:12.2.2-cudnn8-devel-ubuntu22.04

# ============================================================================ #
#                                Basic Settings                                #
# ============================================================================ #
ENV DEBIAN_FRONTEND=noninteractive \
    INSTALL_DIR=/root/softwares

RUN apt-get update && apt-get install -y \
    wget aria2 git zsh vim python3 python3-pip python3-dev && \
    apt clean

# Oh-my-zsh ------------------------------------------------------------------ #
RUN sh -c "$(wget -O- https://install.ohmyz.sh)" && \
    git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions && \
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting && \
    sed -i 's/plugins=(git)/plugins=(z git zsh-autosuggestions zsh-syntax-highlighting)/g' ~/.zshrc

# ============================================================================ #
#                                Main Softwares                                #
# ============================================================================ #
WORKDIR ${INSTALL_DIR}

# Cern ROOT ------------------------------------------------------------------ #
# https://root.cern/install/
# Variables
ENV HML_ENV_ROOT_VERSION=6.28.12
ENV ROOT_DIR=${INSTALL_DIR}/root_v${HML_ENV_ROOT_VERSION}
ENV ROOT_FILE=root_v${HML_ENV_ROOT_VERSION}.Linux-ubuntu22-x86_64-gcc11.4.tar.gz

ENV ROOTSYS=${ROOT_DIR}
ENV PATH=${PATH}:${ROOTSYS}/bin
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${ROOTSYS}/lib
ENV DYLD_LIBRARY_PATH=${DYLD_LIBRARY_PATH}:${ROOTSYS}/lib

# Dependencies
RUN apt-get update && apt-get install -y \
    dpkg-dev cmake g++ gcc binutils \
    libx11-dev libxpm-dev libxft-dev libxext-dev python3 libssl-dev \
    gfortran make rsync ghostscript gnuplot && \
    apt clean

# Installation
RUN aria2c -x 16 https://root.cern/download/${ROOT_FILE}
RUN mkdir ${ROOT_DIR} && \
    tar xvf ${ROOT_FILE} --strip=1 --directory=${ROOT_DIR} && \
    rm -rf ${ROOT_FILE}

# Others
RUN echo "# Cern ROOT" >> ~/.zshrc && \
    echo "source ${ROOT_DIR}/bin/thisroot.sh" >> ~/.zshrc

# Delphes -------------------------------------------------------------------- #
# https://cp3.irmp.ucl.ac.be/projects/delphes/wiki/WorkBook/QuickTour
# https://cp3.irmp.ucl.ac.be/projects/delphes/wiki/WorkBook/Pythia8
# Variables
ENV HML_ENV_DELPHES_VERSION=3.5.0
ENV DELPHES_DIR=${INSTALL_DIR}/delphes_v${HML_ENV_DELPHES_VERSION}
ENV DELPHES_FILE=Delphes-${HML_ENV_DELPHES_VERSION}.tar.gz

ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${DELPHES_DIR}
ENV ROOT_INCLUDE_PATH=${ROOT_INCLUDE_PATH}:${DELPHES_DIR}/external
ENV PATH=${PATH}:${DELPHES_DIR}/bin

# Installation
RUN aria2c -x 16 http://cp3.irmp.ucl.ac.be/downloads/${DELPHES_FILE}
RUN mkdir ${DELPHES_DIR} && \
    tar -xvf ${DELPHES_FILE} --strip=1 --directory=${DELPHES_DIR} && \
    cd ${DELPHES_DIR} && \
    make -j $(nproc) && \
    rm -rf ${INSTALL_DIR}/${DELPHES_FILE}

# MadGraph5 ------------------------------------------------------------------ #
# https://launchpad.net/mg5amcnlo
# Variables
ENV HML_ENV_MADGRAPH5_VERSION=3.4.2
ENV MADGRAPH5_DIR=${INSTALL_DIR}/madgraph5_v${HML_ENV_MADGRAPH5_VERSION}
ENV MADGRAPH5_FILE=MG5_aMC_v${HML_ENV_MADGRAPH5_VERSION}.tar.gz

ENV LHAPDF_DIR=${MADGRAPH5_DIR}/HEPTools/lhapdf6_py3
ENV LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${LHAPDF_DIR}/lib
ENV PYTHONPATH=${PYTHONPATH}:${LHAPDF_DIR}/local/lib/python3.10/dist-packages
ENV PATH=${PATH}:${LHAPDF_DIR}/bin
ENV PATH=${PATH}:${MADGRAPH5_DIR}/bin

# Dependencies
RUN pip install six

# Installation
RUN aria2c -x 16 https://launchpad.net/mg5amcnlo/3.0/3.4.x/+download/${MADGRAPH5_FILE}
RUN mkdir ${MADGRAPH5_DIR} && \
    tar -xvf ${MADGRAPH5_FILE} --strip=1 --directory=${MADGRAPH5_DIR} && \
    rm -rf ${MADGRAPH5_FILE} && \
    echo "n" | mg5_aMC

# use this to install HEPToolsInstallers
RUN echo "install zlib" | mg5_aMC
# turn off auto-refresh
RUN sed -i '5958,5996s/^/# /' ${MADGRAPH5_DIR}/madgraph/interface/madgraph_interface.py
# add -j flag to speed up compilation
RUN sed -i '/make$/s/$/ -j $(nproc)/' ${MADGRAPH5_DIR}/HEPTools/HEPToolsInstallers/installLHAPDF6.sh && \
    echo "install lhapdf6" | mg5_aMC
RUN sed -i '/make$/s/$/ -j $(nproc)/' ${MADGRAPH5_DIR}/HEPTools/HEPToolsInstallers/installHEPMC2.sh && \
    echo "install hepmc" | mg5_aMC
RUN sed -i '/make$/s/$/ -j $(nproc)/' ${MADGRAPH5_DIR}/HEPTools/HEPToolsInstallers/installPYTHIA8.sh && \
    echo "install pythia8" | mg5_aMC
RUN sed -i '5958,5996s/^# //'  ${MADGRAPH5_DIR}/madgraph/interface/madgraph_interface.py

# Others
RUN echo "set delphes_path ${DELPHES_DIR}" | mg5_aMC && \
    echo "set auto_convert_model T" | mg5_aMC && \
    echo "set auto_update 0" | mg5_aMC && \
    rm py.py

# ============================================================================ #
#                                    Ending                                    #
# ============================================================================ #
WORKDIR /root/workspace
CMD ["zsh"]

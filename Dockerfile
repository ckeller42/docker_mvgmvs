
## Setup the base
FROM buildpack-deps:xenial
#FROM ubuntu:16.04

ARG user=omvg

RUN apt-get update \
    && apt-get install -y \
    sudo 
    
# setup user
RUN useradd --create-home --system --shell /bin/bash $user && echo "$user:$user" | chpasswd  &&  adduser $user sudo
RUN echo "$user ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers



# setup system and get build dependencies


USER $user
ENV PATH $PATH:/home/$user/bin/

# clone build and install
WORKDIR /home/$user




RUN sudo apt-get update \
    && sudo apt-get install -y \
    cmake \
    libxxf86vm-dev \
    libxi-dev \
    python-pip \
    libglu1-mesa-dev

# EIGEN
RUN mkdir -p src && cd src \
 && hg clone https://bitbucket.org/eigen/eigen#3.2 \
 && mkdir eigen_build && cd eigen_build \
 && cmake . ../eigen \
 && make -j $(nproc) && sudo make install


RUN sudo apt-get update \
    && sudo apt-get install -y \
    libboost-iostreams-dev libboost-program-options-dev libboost-system-dev libboost-serialization-dev \
    libopencv-dev libcgal-dev libcgal-qt5-dev \
    libatlas-base-dev libsuitesparse-dev

# CERES
RUN mkdir -p src \ 
 && cd src \
 &&  git clone https://ceres-solver.googlesource.com/ceres-solver ceres-solver \
 &&  mkdir ceres_build && cd ceres_build \
 &&  cmake . ../ceres-solver/ -DMINIGLOG=ON -DBUILD_TESTING=OFF -DBUILD_EXAMPLES=OFF \
 && make -j $(nproc) && sudo make install 


# openMVG build options
ARG branch=master
ARG BUILD_TESTS=OFF
ARG BUILD_EXAMPLES=ON

# openMVG
RUN mkdir -p src \
 && git clone --single-branch -b $branch --recursive https://github.com/openmvg/openmvg src/openMVG \
 && cd src/openMVG \
 && git submodule update --init --recursive \
 && mkdir build \
 && cd build \
 && cmake \
      -DCMAKE_BUILD_TYPE=RELEASE \
      -DOpenMVG_BUILD_TESTS=$BUILD_TESTS \
      -DOpenMVG_BUILD_EXAMPLES=$BUILD_EXAMPLES \
      . \
      ../src/ \
 && make -j $(nproc) \
 && if [ $BUILD_TESTS = ON ] ; then  make test ; fi  \
 && make install


# VCS
RUN mkdir -p src \
 && cd src/ && git clone --single-branch -b $branch https://github.com/cdcseacave/VCG.git vcglib

# openMVS
RUN  mkdir -p src \
 && git clone https://github.com/cdcseacave/openMVS.git openMVS \
 && mkdir openMVS_build && cd openMVS_build \
 && cmake . ../openMVS -DCMAKE_BUILD_TYPE=Release -DVCG_DIR="/home/$user/src/vcglib" \
 && make -j $(nproc) && sudo make install


CMD ["/bin/bash", "-l"]

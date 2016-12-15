FROM geodata/gdal:2.1.2

USER root
WORKDIR /tmp

RUN apt-get update -qq && \
    apt-get install -yy \
        wget \
        python-pip \
        python-numpy \
        python-scipy \
        libgdal-dev \
        libatlas-base-dev \
        gfortran \
        libfreetype6-dev

RUN wget https://bootstrap.pypa.io/get-pip.py \
    && python get-pip.py \
    && pip install virtualenv \
    && virtualenv -p python2.7 /tmp/venv \
    && . /tmp/venv/bin/activate \
    && pip install numpy \
    && pip install -U \
        rasterio \
        rio-color \
        rio-hist \
        rio-toa \
        landsat-util

RUN rm /bin/sh && ln -s /bin/bash /bin/sh

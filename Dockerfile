FROM jupyter/datascience-notebook:82b978b3ceeb

USER root
RUN mkdir /opt/pulsar
RUN chown -R jovyan /opt/pulsar
RUN sed -i -e s#jessie\ main#jessie\ main\ non-free#g /etc/apt/sources.list
RUN apt-get update -y && apt-get install -y \
    autoconf \
    libtool \
    pgplot5 \
    libfftw3-bin \
    libfftw3-dbg \
    libfftw3-dev \
    libfftw3-double3 \
    libfftw3-long3 \
    libfftw3-quad3 \
    libfftw3-single3 \
    libcfitsio-dev \ 
    libglib2.0-dev \
    libx11-dev \ 
    swig \
    pkg-config \ 
    openssh-client \
    openssh-server \ 
    libhealpix-cxx-dev \
    libhealpix-cxx0v5 \
    libchealpix-dev \ 
    libreadline-dev \ 
    libeigen2-dev \ 
    imagemagick \
    latex2html \ 
    gv \
    tcsh \
    libsuitesparse-dev \
    rsync \ 
    dvipng \
    libgsl-dev \
    libopenmpi-dev \
    libmagickwand-dev \
    nano \ 
    vim \ 
    emacs \
    less \
    gnuplot

USER jovyan
# make calceph
RUN wget --no-check-certificate -q https://www.imcce.fr/content/medias/recherche/equipes/asd/calceph/calceph-2.3.2.tar.gz && \
    tar zxvf calceph-2.3.2.tar.gz && \
    cd calceph-2.3.2 && \
    ./configure --prefix=/opt/pulsar && \
    make && make install && \
    cd .. && rm -rf calceph-2.3.2 calceph-2.3.2.tar.gz

# make tempo2
ENV TEMPO2=/opt/pulsar/share/tempo2
RUN wget -q https://bitbucket.org/psrsoft/tempo2/get/master.tar.gz && \
    tar zxf master.tar.gz && \
    cd psrsoft-tempo2-* && \
    ./bootstrap && \    
    CPPFLAGS="-I/opt/pulsar/include" LDFLAGS="-L/opt/pulsar/lib" ./configure --prefix=/opt/pulsar --with-calceph=/opt/pulsar/ && \
    make && make install && make plugins && make plugins-install && \
    mkdir -p /opt/pulsar/share/tempo2 && \
    cp -Rp T2runtime/* /opt/pulsar/share/tempo2/. && \
    cd .. && rm -rf psrsoft-tempo2-* master.tar.gz

# get extra ephemeris
RUN cd /opt/pulsar/share/tempo2/ephemeris && \
    wget -q ftp://ssd.jpl.nasa.gov/pub/eph/planets/bsp/de435t.bsp && \
    wget -q ftp://ssd.jpl.nasa.gov/pub/eph/planets/bsp/de436t.bsp 
#    wget -q https://github.com/nanograv/tempo/raw/master/ephem/DE435.1950.2050 && \
#    wget -q https://github.com/nanograv/tempo/raw/master/ephem/DE436.1950.2050

# install libstempo (before other Anaconda packages, esp. matplotlib, so there's no libgcc confusion)
RUN git clone https://github.com/vallis/libstempo.git && \
    cd libstempo && \
    pip install .  --global-option="build_ext" --global-option="--with-tempo2=/opt/pulsar" && \
    cp -rp demo /home/jovyan/libstempo-demo && chown -R jovyan /home/jovyan/libstempo-demo && \
    /bin/bash -c "source activate python2 && \
    pip install .  --global-option=\"build_ext\" --global-option=\"--with-tempo2=/opt/pulsar\"" && \
    cd .. && rm -rf libstempo


# non-standard-Anaconda packages
RUN /bin/bash -c "source activate python2 && pip install healpy acor line_profiler"
RUN pip install healpy acor line_profiler

# install PTMCMCSampler
RUN git clone https://github.com/jellis18/PTMCMCSampler && \
    cd PTMCMCSampler && \
    /bin/bash -c "source activate python2 && pip install . " && \
    cd .. && rm -rf PTMCMCSampler

# install PAL2 (do not remove it)
RUN git clone https://github.com/jellis18/PAL2.git && \
    cd PAL2 && \
    /bin/bash -c "source activate python2 && pip install . " && \
    cp -rp demo /home/jovyan/PAL2-demo && chown -R jovyan /home/jovyan/PAL2-demo && \
    cd .. && rm -rf PAL2

# install NX01 (rather, check it out and copy it to the jovyan user)
RUN git clone https://github.com/stevertaylor/NX01.git && \
    chown -R jovyan /home/jovyan/NX01 


ENV PGPLOT_DIR=/usr/lib/pgplot5 
ENV PGPLOT_FONT=/usr/lib/pgplot5/grfont.dat 
ENV PGPLOT_INCLUDES=/usr/include 
ENV PGPLOT_BACKGROUND=white 
ENV PGPLOT_FOREGROUND=black 
ENV PGPLOT_DEV=/xs
ENV PSRHOME=/opt/pulsar

ENV PRESTO=$PSRHOME/presto 
ENV PATH=$PATH:$PRESTO/bin 
ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PRESTO/lib 
ENV PYTHONPATH=$PYTHONPATH:$PRESTO/lib/python

RUN git clone https://github.com/scottransom/presto.git
RUN mv presto $PSRHOME/presto

WORKDIR $PRESTO/src
RUN make prep && \
    make
WORKDIR $PRESTO/python
RUN /opt/conda/envs/python2/bin/python setup.py install --home=$PRESTO 

ENV PSRCHIVE=$PSRHOME/psrchive 
#ENV PATH=$PATH:$PSRCHIVE/install/bin 
#ENV C_INCLUDE_PATH=$C_INCLUDE_PATH:$PSRCHIVE/install/include 
#ENV LD_LIBRARY_PATH=$LD_LIBRARY_PATH:$PSRCHIVE/install/lib 
ENV PYTHONPATH=$PYTHONPATH:$PSRCHIVE/install/lib/python2.7/site-packages 

RUN git clone git://git.code.sf.net/p/psrchive/code psrchive
RUN mv psrchive $PSRHOME
WORKDIR $PSRCHIVE
RUN /bin/bash -c "source /opt/conda/bin/activate python2; \
    ./bootstrap; \
    ./configure F77=gfortran --prefix=$PSRHOME --enable-shared CFLAGS=\"-fPIC -std=gnu11 -DHAVE_CFITSIO\" CXXFLAGS=\"-std=gnu -DHAVE_CFITSIO\" FFLAGS=\"-fPIC\";\
    ./packages/epsic.csh;\
    ./configure F77=gfortran --prefix=$PSRHOME --enable-shared CFLAGS=\"-fPIC -std=gnu11 -DHAVE_CFITSIO\" CXXFLAGS=\"-std=gnu -DHAVE_CFITSIO\" FFLAGS=\"-fPIC\";\
    make && make install && make clean;" 
RUN cp /opt/pulsar/lib/python2.7/site-packages/* /opt/conda/envs/python2/lib/python2.7/site-packages/

ENV NANOGRAVDATA=/nanograv/data

COPY start-singleuser.sh /usr/local/bin/start-singleuser.sh
COPY notebook-setup.sh /usr/local/bin/notebook-setup.sh

RUN mkdir /home/jovyan/.local
RUN ln -sf /home/jovyan/work/custom/lib /home/jovyan/.local/lib
RUN ln -sf /home/jovyan/work/custom/bin /home/jovyan/.local/bin

COPY requirements.txt /var/tmp/requirements.txt
RUN /bin/bash -c "source activate python2 && pip install -r /var/tmp/requirements.txt"
RUN pip install -r /var/tmp/requirements.txt

# tempo 
ENV TEMPO=$PSRHOME/tempo 
ENV PATH=$PATH:$PSRHOME/tempo/bin

RUN git clone git://git.code.sf.net/p/tempo/tempo
RUN mv tempo $PSRHOME

WORKDIR ${TEMPO}
RUN ./prepare && \
    ./configure --prefix=$PSRHOME/tempo && \
    make && \
    make install && \
    cd util/print_resid && \
    make

# install Piccard

WORKDIR /home/jovyan

RUN git clone https://github.com/vhaasteren/piccard.git && \
    cd piccard && \
    sed -i -e s#liomp5#lgomp#g setup.py && \
    /bin/bash -c "source /opt/conda/bin/activate python2 && python setup.py install" && \
    cd /home/jovyan/work && ln -s /home/jovyan/piccard piccard 

RUN git clone https://github.com/nanograv/PINT.git && \
    cd PINT && \
    python setup.py install && \
    /bin/bash -c "source /opt/conda/bin/activate python2 && python setup.py install"

USER root
RUN bash -c "source activate python2 && git clone https://github.com/kstovall/psrfits_utils.git && \
    cd psrfits_utils && \
    ./prepare && \
    ./configure && \
    make && make install"

RUN cp /opt/pulsar/lib/python2.7/site-packages/* /opt/conda/envs/python2/lib/python2.7/site-packages/

COPY MultiNest_v3.11.tar.gz ./
RUN tar xvfz MultiNest_v3.11.tar.gz
COPY Makefile MultiNest_v3.11/Makefile
COPY Makefile.polychord /var/tmp/Makefile
RUN cd MultiNest_v3.11 && make && make libnest3.so && cp libnest3* /usr/lib

RUN bash -c "source activate python2 && git clone https://github.com/LindleyLentati/TempoNest.git && \
              cd TempoNest && ./autogen.sh && CPPFLAGS=\"-I/opt/pulsar/include\" \
                LDFLAGS=\"-L/opt/pulsar/lib\" ./configure --prefix=/opt/pulsar && cd PolyChord && \
                cp /var/tmp/Makefile Makefile && make \
                 && make libchord.so && cp src/libchord* /usr/lib && cd ../ && make && make install"

USER jovyan
COPY tai2tt_bipm2016.clk /opt/pulsar/share/tempo2/clock/tai2tt_bipm2016.clk
COPY ao2gps.clk /opt/pulsar/share/tempo2/clock/ao2gps.clk
COPY gbt2gps.clk /opt/pulsar/share/tempo2/clock/gbt2gps.clk
USER root
RUN /bin/bash -c "source /opt/conda/bin/activate python2 && pip install Wand"
RUN pip install Wand
RUN apt-get clean
RUN systemctl enable ssh
RUN mkdir /var/run/sshd
RUN sed 's/X11Forwarding yes/X11Forwarding yes\nX11UseLocalhost no/' -i /etc/ssh/sshd_config
COPY start-notebook.sh /usr/local/bin/start-notebook.sh
COPY start.sh /usr/local/bin/start.sh
RUN chmod a+x /usr/local/bin/start-notebook.sh
RUN chmod a+x /usr/local/bin/start.sh
RUN git clone https://github.com/demorest/tempo_utils.git && \
    cd tempo_utils && \
    /bin/bash -c "source /opt/conda/bin/activate python2 && python setup.py install"
RUN  git clone https://github.com/nanograv/enterprise && \
     cd enterprise && \
     bash -c "source /opt/conda/bin/activate python2 && pip install -r requirements.txt && python setup.py install && cd ../ && rm -rf enterprise"
USER jovyan
COPY .bashrc /home/jovyan/.bashrc
COPY .profile /home/jovyan/.profile
COPY .vimrc /home/jovyan/.vimrc
USER root
ENV PATH=/opt/pulsar/bin:$PATH
ENV LD_LIBRARY_PATH=/opt/pulsar/lib:$LD_LIBRARY_PATH
RUN bash -c "source activate python2 && git clone git://git.code.sf.net/p/dspsr/code dspsr && cd dspsr && ./bootstrap && ./configure && make && make install"
RUN chown -R jovyan /home/jovyan
ENV GRANT_SUDO=1
COPY clig /usr/bin/clig
WORKDIR /usr/lib
COPY clig.tar.gz ./
RUN tar xvfz clig.tar.gz
RUN apt install -y tk
WORKDIR /home/jovyan
RUN git clone https://github.com/nategarver-daniels/afr.git
RUN /bin/bash -c "cd afr && git pull && make && make install"
WORKDIR /home/jovyan/work
EXPOSE 22

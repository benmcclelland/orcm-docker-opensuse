FROM opensuse

MAINTAINER Ben McClelland <ben.mcclelland@gmail.com>

RUN zypper --no-gpg-checks --non-interactive install wget unzip tar git gcc m4 gcc-c++ make flex openssl \
                                                     openssl-devel unixODBC unixODBC-devel xz patch libtool rpm-build

RUN wget http://mirror.anl.gov/pub/centos/6.5/os/x86_64/Packages/sigar-1.6.5-0.4.git58097d9.el6.x86_64.rpm && \
    wget http://mirror.anl.gov/pub/centos/6.5/os/x86_64/Packages/sigar-devel-1.6.5-0.4.git58097d9.el6.x86_64.rpm && \
    zypper --no-gpg-checks --non-interactive install sigar-1.6.5-0.4.git58097d9.el6.x86_64.rpm \
                                                     sigar-devel-1.6.5-0.4.git58097d9.el6.x86_64.rpm &&\
    rm -f sigar-1.6.5-0.4.git58097d9.el6.x86_64.rpm sigar-devel-1.6.5-0.4.git58097d9.el6.x86_64.rpm

RUN wget http://ipmiutil.sourceforge.net/FILES/ipmiutil-2.9.4-1.src.rpm && \
    rpmbuild --rebuild ipmiutil-2.9.4-1.src.rpm && \
    rm -f ipmiutil-2.9.4* && \
    zypper --no-gpg-checks --non-interactive install /usr/src/packages/RPMS/x86_64/ipmiutil-2.9.4-1.x86_64.rpm \
                                                     /usr/src/packages/RPMS/x86_64/ipmiutil-devel-2.9.4-1.x86_64.rpm && \
    rm -rf /usr/src/packages/RPMS

ENV PATH /usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/opt/open-rcm/bin
ENV LD_LIBRARY_PATH /opt/open-rcm/lib

RUN wget http://ftp.gnu.org/gnu/autoconf/autoconf-2.69.tar.xz && \
    tar xf autoconf-2.69.tar.xz && cd autoconf-2.69 && \
    ./configure --prefix=/usr/local && make && make install && \
    cd .. && rm -rf autoconf-2.69*

RUN wget http://ftp.gnu.org/gnu/automake/automake-1.12.2.tar.xz && \
    tar xf automake-1.12.2.tar.xz && cd automake-1.12.2 && \
    ./configure --prefix=/usr/local && make && make install && \
    cd .. && rm -rf automake-1.12.2*

RUN wget http://ftp.gnu.org/gnu/libtool/libtool-2.4.2.tar.xz && \
    tar xf libtool-2.4.2.tar.xz && cd libtool-2.4.2 && \
    ./configure --prefix=/usr/local && make && make install && \
    cd .. && rm -rf libtool-2.4.2*


RUN git config --global http.sslVerify false
RUN git clone https://github.com/open-mpi/orcm.git && \
    cd orcm && \
    mkdir -p /opt/open-rcm && \
    ./autogen.pl && \
    ./configure --prefix=/opt/open-rcm \
                --with-platform=./contrib/platform/intel/hillsboro/orcm-linux && \
    make -j 4 && \
    make install

ADD orcm-site.xml /opt/open-rcm/etc/orcm-site.xml

RUN echo "export LD_LIBRARY_PATH=/opt/open-rcm/lib" >>/root/.profile
RUN echo "export PATH=/usr/local/bin:/bin:/usr/bin:/sbin:/usr/sbin:/opt/open-rcm/bin" >>/root/.profile

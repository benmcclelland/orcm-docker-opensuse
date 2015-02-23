FROM opensuse

MAINTAINER Ben McClelland <ben.mcclelland@gmail.com>

RUN zypper --no-gpg-checks --non-interactive install wget unzip tar git gcc m4 gcc-c++ make flex openssl \
                                                     openssl-devel unixODBC unixODBC-devel xz patch libtool \
                                                     rpm-build cmake

RUN wget http://vault.centos.org/6.5/os/Source/SPackages/sigar-1.6.5-0.4.git58097d9.el6.src.rpm && \
    rpm -ihv ./sigar-1.6.5-0.4.git58097d9.el6.src.rpm

ADD sigar.spec /usr/src/packages/SPECS/sigar.spec

RUN rpmbuild -bb --clean --rmsource --rmspec /usr/src/packages/SPECS/sigar.spec && \
    zypper --no-gpg-checks --non-interactive install /usr/src/packages/RPMS/x86_64/sigar-1.6.5-0.4.git58097d9.x86_64.rpm \
                                                     /usr/src/packages/RPMS/x86_64/sigar-devel-1.6.5-0.4.git58097d9.x86_64.rpm && \
    rm -rf sigar*

RUN wget http://ipmiutil.sourceforge.net/FILES/ipmiutil-2.9.5-1.src.rpm && \
    rpmbuild --rebuild ipmiutil-2.9.5-1.src.rpm && \
    rm -f ipmiutil-2.9.5* && \
    zypper --no-gpg-checks --non-interactive install /usr/src/packages/RPMS/x86_64/ipmiutil-2.9.5-1.x86_64.rpm \
                                                     /usr/src/packages/RPMS/x86_64/ipmiutil-devel-2.9.5-1.x86_64.rpm && \
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


RUN git config --global http.sslVerify false && \
    git clone https://github.com/open-mpi/orcm.git && \
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

RUN zypper --no-gpg-checks --non-interactive ar -f http://download.opensuse.org/repositories/server:/database:/postgresql/SLE_12/ postgresql9.3 && \
    zypper --no-gpg-checks --non-interactive install postgresql93 postgresql93-server psqlODBC sudo

EXPOSE 55805 55820 5432

RUN perl -pi -e "s:<Path to the PostgreSQL ODBC driver>:$(rpm -ql psqlODBC | grep psqlodbcw.so):" orcm/contrib/database/psql_odbc_driver.ini && \
    odbcinst -i -d -f orcm/contrib/database/psql_odbc_driver.ini && \
    perl -pi -e "s:<Name of the PostgreSQL driver>:$(rpm -ql psqlODBC | grep psqlodbcw.so):" orcm/contrib/database/orcmdb_psql.ini && \
    perl -pi -e "s:<Name or IP address of the database server>:db:" orcm/contrib/database/orcmdb_psql.ini && \
    odbcinst -i -s -f orcm/contrib/database/orcmdb_psql.ini -h

RUN /etc/init.d/postgresql start && \
    /etc/init.d/postgresql stop

ADD pg_hba.conf /var/lib/pgsql/data/pg_hba.conf
ADD postgresql.conf /var/lib/pgsql/data/postgresql.conf

RUN chown -R postgres: /var/lib/pgsql/data

RUN /etc/init.d/postgresql start && \
    sudo -u postgres psql --command "CREATE USER orcmuser WITH SUPERUSER PASSWORD 'orcmpassword';" && \
    sudo -u postgres createdb -O orcmuser orcmdb && \
    sudo -u postgres psql --username=orcmuser --dbname=orcmdb -f orcm/contrib/database/orcmdb_psql.sql

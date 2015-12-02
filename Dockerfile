FROM ubuntu:15.10
MAINTAINER Riccardo Tonon <riccardo.tonon@gmail.com>
ENV build_date 2015-11-20

RUN apt-get update -y
RUN apt-get install -y \
    build-essential \
    curl \
    libssl-dev \
    libncurses5-dev \
    libnewt-dev \
    libxml2-dev \
    linux-headers-$(uname -r) \
    libsqlite3-dev \
    libjansson-dev \
    uuid-dev

#Download DAHDI
RUN curl -sf -o /tmp/dahdi.tar.gz -L http://downloads.asterisk.org/pub/telephony/dahdi-linux-complete/dahdi-linux-complete-current.tar.gz

#Unzip dahdi
RUN mkdir /tmp/dahdi
RUN tar -xzf /tmp/dahdi.tar.gz -C /tmp/dahdi --strip-components=1
WORKDIR /tmp/dahdi
RUN make all 1> /dev/null
RUN make install 1> /dev/null
RUN make config 1> /dev/null

# Download asterisk
# Currently Certified Asterisk 13.1 cert 2.
RUN curl -sf -o /tmp/asterisk.tar.gz -L http://downloads.asterisk.org/pub/telephony/certified-asterisk/certified-asterisk-13.1-cert2.tar.gz

# unzip asterisk
RUN mkdir /tmp/asterisk
RUN tar -xzf /tmp/asterisk.tar.gz -C /tmp/asterisk --strip-components=1
WORKDIR /tmp/asterisk

# make asterisk.
# Configure
#RUN ./configure --libdir=/usr/lib64 1> /dev/null
RUN ./configure CFLAGS=-mtune=generic 1> /dev/null
# Remove the native build option
RUN make menuselect 1> /dev/null
RUN make 1> /dev/null
RUN make install 1> /dev/null
RUN make config 1> /dev/null
RUN make samples 1> /dev/null
WORKDIR /

# Update max number of open files.
RUN sed -i -e 's/# MAXFILES=/MAXFILES=/' /usr/sbin/safe_asterisk

RUN mkdir -p /etc/asterisk
# ADD modules.conf /etc/asterisk/
ADD iax.conf /etc/asterisk/
ADD extensions.conf /etc/asterisk/
ADD chan_dahdi.conf /etc/asterisk/
CMD asterisk -f

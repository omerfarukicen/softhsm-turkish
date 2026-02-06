FROM obsstnb/java21-senderbaseimage:latest

ARG SOFTHSM2_VERSION=2.5.0

ENV SOFTHSM2_VERSION=${SOFTHSM2_VERSION} \
    SOFTHSM2_SOURCES=/tmp/softhsm2 \
    SOFTHSM2_CONF=/etc/softhsm2.conf

# Sertifika Deposu indir

# build deps
RUN apt-get update && apt-get install -y \
    build-essential \
    autoconf \
    automake \
    git \
    libtool \
    openssl \
    libssl-dev \
    opensc \
    pkg-config \
 && rm -rf /var/lib/apt/lists/*

# build SoftHSM
RUN git clone https://github.com/opendnssec/SoftHSMv2.git ${SOFTHSM2_SOURCES}
WORKDIR ${SOFTHSM2_SOURCES}

RUN git checkout ${SOFTHSM2_VERSION} \
    && sh autogen.sh \
    && ./configure --prefix=/usr/local --disable-gost \
    && make -j$(nproc) \
    && make install


WORKDIR /root
RUN rm -rf ${SOFTHSM2_SOURCES}

# SoftHSM config
RUN mkdir -p /var/lib/softhsm/tokens \
 && echo "directories.tokendir = /var/lib/softhsm/tokens" > /etc/softhsm2.conf

ENV SOFTHSM2_CONF=/etc/softhsm2.conf

# kopyala
COPY test_kok_sertifika test_kok_sertifika
COPY cert.pem /root/cert.pem
COPY key.pem /root/key.pem

# Sertifika yükle
# Sertifika yükle + slot'u kaydet
RUN softhsm2-util --show-slots \
 && SLOT=$(softhsm2-util --show-slots | awk '/Slot [0-9]+/ {print $2}' | head -n1) \
 && echo "Init logical slot $SLOT" \
 && REAL_SLOT=$(softhsm2-util --init-token --slot "$SLOT" \
        --label "MyToken" \
        --so-pin 123456 \
        --pin 123456 \
        | awk '/reassigned to slot/ {print $NF}') \
 && echo "Using real slot $REAL_SLOT" \
 && echo "$REAL_SLOT" > /etc/softhsm.slot \
 && pkcs11-tool \
      --module /usr/local/lib/softhsm/libsofthsm2.so \
      --slot "$REAL_SLOT" \
      --login --pin 123456 \
      --write-object /root/key.pem \
      --type privkey \
      --id 01 \
      --label "MyKey" \
 && pkcs11-tool \
      --module /usr/local/lib/softhsm/libsofthsm2.so \
      --slot "$REAL_SLOT" \
      --login --pin 123456 \
      --write-object /root/cert.pem \
      --type cert \
      --id 01 \
      --label "MyCert"
ENV SOFTHSM_REAL_SLOT_FILE=/etc/softhsm.slot

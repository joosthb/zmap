# builder image
FROM alpine:3.20 AS builder

ARG ZMAP_COMMIT=main
ENV ZMAP_COMMIT ${ZMAP_COMMIT}

# install dependencies
RUN apk add --no-cache cmake gengetopt flex byacc libdnet g++ make json-c-dev gmp-dev libunistring-dev libpcap-dev linux-headers python3 dumb-init judy-dev

# build/install dumb-init which allows us to more easily 
# send signals to zmap, for example by allowing ctrl-c of
# a running container and zmap will stop.

RUN wget -q https://github.com/zmap/zmap/archive/refs/heads/${ZMAP_COMMIT}.zip && unzip -q ${ZMAP_COMMIT}.zip && cd zmap-${ZMAP_COMMIT} && (cmake . && make -j4 && make install)

# ---------------------------------------------------------
# create run container
FROM alpine:3.20

# install necessary libraries
RUN apk add --no-cache json-c gmp libunistring libpcap judy-dev

# copy out dumb-init and zmap from build container
COPY --from=builder /usr/bin/dumb-init ./
COPY --from=builder /usr/local/sbin/zmap ./

ENTRYPOINT ["/dumb-init", "/zmap"]


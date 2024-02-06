FROM debian:latest

RUN apt-get -qq update && apt-get install -qq dh-make devscripts && \
    useradd -m builder && \
    install -dm 0700 --owner builder --group builder /sources && \
    install -dm 0700 --owner builder --group builder /output

VOLUME ["/sources", "/output"]

ENV DEBMAINTAINER=

USER builder:builder
WORKDIR /home/builder
COPY Makefile ./
CMD make

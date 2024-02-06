FROM archlinux:latest

RUN pacman -Syyu --noconfirm

RUN pacman -Syy --noconfirm --needed base-devel git && \
    useradd -m builder && \
    install -dm 0700 --owner builder --group builder /sources && \
    install -dm 0700 --owner builder --group builder /output

VOLUME ["/sources", "/output"]

ENV PACKAGER=

USER builder:builder
WORKDIR /home/builder
COPY Makefile ./
CMD make

FROM archlinux:latest

RUN ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
RUN date
RUN pacman -Syu --noconfirm
RUN pacman-key --init
RUN pacman -S archlinux-keyring base-devel git python jq --noconfirm
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"] 

IMAGENAME="my-ubuntu"
SERVICENAME=$IMAGENAME
VERSION="20.04"
MIRROR="mirror.kakao.com"

USERNAME="mg0721"
PASSWORD="mg0721"
HOSTNAME="GANDALF"

cat <<'EOF' > Dockerfile
ARG VERSION

FROM ubuntu:$VERSION

ARG APTFILE=/etc/apt/sources.list
ARG MIRROR
ARG USERNAME
ARG PASSWORD
ARG PACKAGE_DEF

RUN cp $APTFILE $APTFILE.bak

RUN sed -i "s/archive.ubuntu.com/$MIRROR/g" $APTFILE && \
    sed -i "s/security.ubuntu.com/$MIRROR/g" $APTFILE

RUN apt update && \
    apt install -y $PACKAGE_DEF

RUN adduser \
        --quiet \
        --disabled-password \
        --shell /bin/bash \
        --home /home/$USERNAME \
        --gecos "User" $USERNAME
RUN echo "$USERNAME:$PASSWORD" | chpasswd
RUN usermod -aG sudo $USERNAME
USER $USERNAME
EOF

cat <<EOF > docker-compose.yml
version: "3"

services:
  $SERVICENAME:
    image: $IMAGENAME:$VERSION
    working_dir: /home/$USERNAME
    hostname: $HOSTNAME
    network_mode: host
    stdin_open: true  # docker run -i
    tty: true         # docker run -t
    environment:
      - TERM=xterm-256color
EOF

PWD="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"
PACKAGE_DEF="$(cat $PWD/data/packages.list | tr '\n' ' ')"

docker build -t $IMAGENAME:$VERSION . \
    --build-arg MIRROR=$MIRROR \
    --build-arg VERSION=$VERSION \
    --build-arg USERNAME=$USERNAME \
    --build-arg PASSWORD=$PASSWORD \
    --build-arg PACKAGE_DEF="$PACKAGE_DEF"
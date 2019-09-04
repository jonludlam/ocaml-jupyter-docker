ARG BASE_CONTAINER=jupyter/minimal-notebook
FROM $BASE_CONTAINER

USER root

RUN apt-get -y update && \
  DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential curl git libcap-dev sudo && \
  curl -OL https://github.com/projectatomic/bubblewrap/releases/download/v0.3.1/bubblewrap-0.3.1.tar.xz && \
  tar xf bubblewrap-0.3.1.tar.xz && \
  cd bubblewrap-0.3.1 && ./configure --prefix=/usr/local && make && sudo make install && \
  rm -rf bubblewrap-0.3.1.tar.xz bubblewrap-0.3.1 && \
  git config --global user.email "docker@example.com" && \
  git config --global user.name "Docker" && \
  git clone -b 2.0 git://github.com/ocaml/opam /tmp/opam && \
  sh -c "cd /tmp/opam && make cold && mkdir -p /usr/local/bin && cp /tmp/opam/opam /usr/local/bin/opam && cp /tmp/opam/opam-installer /usr/local/bin/opam-installer && chmod a+x /usr/local/bin/opam /usr/local/bin/opam-installer && rm -rf /tmp/opam"
FROM $BASE_CONTAINER
USER root
COPY --from=0 /usr/local/bin/bwrap /usr/bin/bwrap
COPY --from=0 /usr/local/bin/opam /usr/bin/opam
COPY --from=0 /usr/local/bin/opam-installer /usr/bin/opam-installer
RUN ln -fs /usr/share/zoneinfo/Europe/London /etc/localtime && \
  apt-get -y update && \
  DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
  echo 'Acquire::Retries "5";' > /etc/apt/apt.conf.d/mirror-retry && \
  apt-get -y update && \
  DEBIAN_FRONTEND=noninteractive apt-get -y upgrade && \
  DEBIAN_FRONTEND=noninteractive apt-get -y install build-essential curl git rsync sudo unzip nano libcap-dev libx11-dev && \
  echo 'jovyan ALL=(ALL:ALL) NOPASSWD:ALL' > /etc/sudoers.d/jovyan && \
  chmod 440 /etc/sudoers.d/jovyan && \
  chown root:root /etc/sudoers.d/jovyan
USER jovyan
ENV HOME /home/jovyan
WORKDIR /home/jovyan
RUN mkdir .ssh && \
  chmod 700 .ssh && \
  echo 'wrap-build-commands: []' > ~/.opamrc-nosandbox && \
  echo 'wrap-install-commands: []' >> ~/.opamrc-nosandbox && \
  echo 'wrap-remove-commands: []' >> ~/.opamrc-nosandbox && \
  echo 'required-tools: []' >> ~/.opamrc-nosandbox && \
  echo '#!/bin/sh' > /home/jovyan/opam-sandbox-disable && \
  echo 'cp ~/.opamrc-nosandbox ~/.opamrc' >> /home/jovyan/opam-sandbox-disable && \
  echo 'echo --- opam sandboxing disabled' >> /home/jovyan/opam-sandbox-disable && \
  chmod a+x /home/jovyan/opam-sandbox-disable && \
  sudo mv /home/jovyan/opam-sandbox-disable /usr/bin/opam-sandbox-disable && \
  echo 'wrap-build-commands: ["%{hooks}%/sandbox.sh" "build"]' > ~/.opamrc-sandbox && \
  echo 'wrap-install-commands: ["%{hooks}%/sandbox.sh" "install"]' >> ~/.opamrc-sandbox && \
  echo 'wrap-remove-commands: ["%{hooks}%/sandbox.sh" "remove"]' >> ~/.opamrc-sandbox && \
  echo '#!/bin/sh' > /home/jovyan/opam-sandbox-enable && \
  echo 'cp ~/.opamrc-sandbox ~/.opamrc' >> /home/jovyan/opam-sandbox-enable && \
  echo 'echo --- opam sandboxing enabled' >> /home/jovyan/opam-sandbox-enable && \
  chmod a+x /home/jovyan/opam-sandbox-enable && \
  sudo mv /home/jovyan/opam-sandbox-enable /usr/bin/opam-sandbox-enable && \
  git config --global user.email "docker@example.com" && \
  git config --global user.name "Docker" && \
  git clone git://github.com/ocaml/opam-repository /home/jovyan/opam-repository
WORKDIR /home/jovyan/opam-repository
RUN opam-sandbox-disable && \
  opam init -k git -a /home/jovyan/opam-repository
RUN opam install -y depext
RUN opam depext -y jupyter merlin bos ocamlformat
RUN opam install -y jupyter merlin bos ocamlformat
RUN /opt/conda/bin/jupyter kernelspec install --user --name ocaml-jupyter "$(opam config var share)/jupyter"
WORKDIR /home/jovyan

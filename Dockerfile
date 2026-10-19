# Workshop-Sandbox: opencode + Werkzeuge, nur der Workshop-Ordner ist sichtbar (/work).
# Bauen und starten: ./docker-run.sh (macOS/Linux) bzw. .\docker-run.ps1 (Windows)

# ---- Berry-Interpreter für den Desktop-Test (app/desktop_harness.be)
FROM debian:bookworm-slim AS berry
RUN apt-get update && apt-get install -y --no-install-recommends \
      build-essential git ca-certificates python3 libreadline-dev \
 && rm -rf /var/lib/apt/lists/*
RUN git clone --depth 1 https://github.com/berry-lang/berry /src/berry \
 && make -C /src/berry -j4

# ---- Sandbox
FROM debian:bookworm-slim
ARG OPENCODE_VERSION=2.0.32
RUN apt-get update && apt-get install -y --no-install-recommends \
      bash ca-certificates curl git less nano tar gzip libreadline8 \
 && rm -rf /var/lib/apt/lists/* \
 && git config --system safe.directory /work
COPY --from=berry /src/berry/berry /usr/local/bin/berry

RUN useradd -m -u 1000 -s /bin/bash agent
USER agent
ENV HOME=/home/agent PATH=/home/agent/.opencode/bin:$PATH
RUN curl -fsSL https://opencode.ai/v2/install | bash -s -- --version ${OPENCODE_VERSION} --no-modify-path
# Mountpunkt des Volumes für Sitzungen; existiert er im Image, übernimmt ein neues Volume die Rechte
RUN mkdir -p /home/agent/.local/share/opencode
# Linux-Hosts starten mit eigener UID (docker-run.sh): HOME muss für alle schreibbar sein
USER root
RUN chmod -R a+rwX /home/agent
USER agent

WORKDIR /work
CMD ["opencode"]

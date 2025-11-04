# 🧱 Base Image (Ubuntu 22.04)
FROM ubuntu:22.04

LABEL maintainer="os-hardening-factory"
LABEL project="os-hardened-base"
LABEL description="Baseline hardened Ubuntu image for enterprise use."

# 🛡️ Perform system updates and install minimal secure packages
RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl \
    vim \
    ca-certificates \
    apt-transport-https \
    gnupg \
    sudo \
    auditd \
    ufw && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# 🧩 Add baseline hardening (example placeholder)
# COPY ./hardening-scripts/ /opt/hardening/
# RUN bash /opt/hardening/apply.sh

# 🔒 Set default umask and enforce basic security limits
RUN echo "umask 027" >> /etc/profile

# 🔥 Enable UFW firewall by default (example baseline)
RUN ufw --force enable || true

# ✅ Health check
HEALTHCHECK CMD curl -f https://example.com || exit 1

CMD ["bash"]


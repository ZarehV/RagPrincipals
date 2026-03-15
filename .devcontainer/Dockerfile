FROM python:3.14-slim

# Install system dependencies required for building Python packages
# and common development tooling
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Install uv — the project's preferred package manager
RUN curl -Ls https://astral.sh/uv/install.sh | sh
ENV PATH="/root/.local/bin:${PATH}"

# Create a non-root user for development
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=${USER_UID}

RUN groupadd --gid ${USER_GID} ${USERNAME} \
    && useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} \
    && apt-get update \
    && apt-get install -y sudo \
    && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
    && chmod 0440 /etc/sudoers.d/${USERNAME} \
    && rm -rf /var/lib/apt/lists/*

# Make uv available to the vscode user
RUN cp /root/.local/bin/uv /usr/local/bin/uv \
    && chmod +x /usr/local/bin/uv

USER ${USERNAME}

WORKDIR /workspace

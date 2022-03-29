# https://docs.github.com/en/actions/creating-actions/dockerfile-support-for-github-actions
FROM ubuntu:jammy
SHELL ["/bin/bash", "-c"]
# alpine:3.15 has a maximum version for gh of 2.2, but --generate-notes was added in 2.4
# https://github.com/cli/cli/discussions/4943 < --generate-notes added.
# https://pkgs.alpinelinux.org/packages?name=github-cli&branch=v3.15&repo=community
# So we need the edge version https://github.com/cli/cli/blob/trunk/docs/install_linux.md
# RUN echo "@community http://dl-cdn.alpinelinux.org/alpine/edge/community" >> /etc/apk/repositories && \
#     apk add --no-cache bash git github-cli@community
# Alternatively we can use, and thus pin, the 2.4 version available on ubuntu 22
COPY github-cli-pin /etc/apt/preferences.d/gh
RUN apt update && apt install -y curl && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt update && apt install -y git gh
COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

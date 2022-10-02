# https://docs.github.com/en/actions/creating-actions/dockerfile-support-for-github-actions
FROM ubuntu:jammy
SHELL ["/bin/bash", "-c"]
COPY github-cli-pin /etc/apt/preferences.d/gh
RUN apt update && apt install -y curl && \
    curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list > /dev/null && \
    apt update && apt install -y git gh
COPY entrypoint.sh /entrypoint.sh
# Allow git to run on mounted directories
# https://github.com/git/git/commit/8959555cee7ec045958f9b6dd62e541affb7e7d9
# https://github.com/actions/runner/issues/2033
RUN git config --global --add safe.directory '*'
ENTRYPOINT ["/entrypoint.sh"]

ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite-deck"
ARG BASE_TAG="stable"

FROM ${BASE_IMAGE}:${BASE_TAG}

ARG COPR_OWNER="lnvso"
ARG COPR_PROJECT="new-lg4ff"

# runuser shim: see akmods-runuser-shim for why akmods can't build under
# rootless buildah without it.
COPY akmods-runuser-shim /tmp/akmods-runuser-shim

# 1. Add COPR repo
# 2. Install akmods first so we can neuter akmodsbuild
# 3. Stub akmodsbuild (akmods >=0.6 refuses to run as root, which breaks the
#    akmod %post inside the rpm-ostree transaction). The real build happens
#    explicitly below after restoring it.
# 4. Install the akmod source package
# 5. Restore akmodsbuild, swap in the runuser shim, and build the kmod
#    against the base image's kernel. akmods builds as the unprivileged
#    "akmods" user via runuser, which can't open a PAM session under buildah;
#    the shim drops privileges with setpriv instead. runuser is restored
#    immediately afterwards so the final image keeps the real binary.
RUN set -euxo pipefail && \
    FEDORA_VER="$(rpm -E %fedora)" && \
    REPO_FILE="/etc/yum.repos.d/_copr_${COPR_OWNER}-${COPR_PROJECT}.repo" && \
    curl -fsSL -o "${REPO_FILE}" \
        "https://copr.fedorainfracloud.org/coprs/${COPR_OWNER}/${COPR_PROJECT}/repo/fedora-${FEDORA_VER}/${COPR_OWNER}-${COPR_PROJECT}-fedora-${FEDORA_VER}.repo" && \
    rpm-ostree install akmods kmodtool && \
    cp -a /usr/sbin/akmodsbuild /usr/sbin/akmodsbuild.real && \
    printf '#!/bin/sh\nexit 0\n' > /usr/sbin/akmodsbuild && \
    chmod +x /usr/sbin/akmodsbuild && \
    rpm-ostree install akmod-hid-logitech-new && \
    mv -f /usr/sbin/akmodsbuild.real /usr/sbin/akmodsbuild && \
    rm -f "${REPO_FILE}" && \
    KERNEL_VERSION="$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-core)" && \
    RUNUSER="$(readlink -f "$(command -v runuser || echo /usr/sbin/runuser)")" && \
    cp -a "${RUNUSER}" "${RUNUSER}.orig" && \
    install -m0755 /tmp/akmods-runuser-shim "${RUNUSER}" && \
    akmods --force --kernels "${KERNEL_VERSION}" --kmod hid-logitech-new || true; \
    mv -f "${RUNUSER}.orig" "${RUNUSER}"; \
    rm -f /tmp/akmods-runuser-shim; \
    KO="$(find /usr/lib/modules/"${KERNEL_VERSION}"/extra -name 'hid-logitech*.ko*' -print -quit 2>/dev/null || true)"; \
    if [ -z "${KO}" ]; then \
        echo "=== ERROR: akmods did not build a hid-logitech module for ${KERNEL_VERSION}; akmods logs follow ===" >&2; \
        for f in /var/cache/akmods/hid-logitech-new/*.log; do \
            [ -f "$f" ] || continue; \
            echo "----- $f -----" >&2; \
            cat "$f" >&2; \
        done; \
        exit 1; \
    fi && \
    modinfo "${KO}" && \
    depmod -a "${KERNEL_VERSION}" && \
    rpm-ostree cleanup -m && \
    ostree container commit

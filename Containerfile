ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite-deck"
ARG BASE_TAG="stable"

FROM ${BASE_IMAGE}:${BASE_TAG}

ARG COPR_OWNER="lnvso"
ARG COPR_PROJECT="new-lg4ff"

RUN set -euxo pipefail && \
    FEDORA_VER="$(rpm -E %fedora)" && \
    REPO_FILE="/etc/yum.repos.d/_copr_${COPR_OWNER}-${COPR_PROJECT}.repo" && \
    curl -fsSL -o "${REPO_FILE}" \
        "https://copr.fedorainfracloud.org/coprs/${COPR_OWNER}/${COPR_PROJECT}/repo/fedora-${FEDORA_VER}/${COPR_OWNER}-${COPR_PROJECT}-fedora-${FEDORA_VER}.repo" && \
    rpm-ostree install akmod-hid-logitech-new && \
    rm -f "${REPO_FILE}" && \
    KERNEL_VERSION="$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-core)" && \
    akmods --force --kernels "${KERNEL_VERSION}" --kmod hid-logitech-new && \
    modinfo "/usr/lib/modules/${KERNEL_VERSION}/extra/hid-logitech-new/hid-logitech-new.ko"* && \
    rpm-ostree cleanup -m && \
    ostree container commit

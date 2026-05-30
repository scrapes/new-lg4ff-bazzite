ARG BASE_IMAGE="ghcr.io/ublue-os/bazzite-deck"
ARG BASE_TAG="stable"

FROM ${BASE_IMAGE}:${BASE_TAG}

ARG COPR_REPO="kylegospo/new-lg4ff"

RUN curl -fsSL -o /etc/yum.repos.d/_copr_${COPR_REPO//\//-}.repo \
        "https://copr.fedorainfracloud.org/coprs/${COPR_REPO}/repo/fedora-$(rpm -E %fedora)/${COPR_REPO//\//-}-fedora-$(rpm -E %fedora).repo" && \
    rpm-ostree install \
        akmod-new-lg4ff \
        new-lg4ff-udev && \
    rm -f /etc/yum.repos.d/_copr_${COPR_REPO//\//-}.repo && \
    KERNEL_VERSION="$(rpm -q --queryformat '%{VERSION}-%{RELEASE}.%{ARCH}' kernel-core)" && \
    akmods --force --kernels "${KERNEL_VERSION}" --kmod new-lg4ff && \
    modinfo "/usr/lib/modules/${KERNEL_VERSION}/extra/new-lg4ff/hid-logitech-new.ko"* && \
    rpm-ostree cleanup -m && \
    ostree container commit

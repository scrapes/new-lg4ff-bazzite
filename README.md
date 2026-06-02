# bazzite-deck-nvidia-lg4ff

Bazzite Deck (NVIDIA) image layered with the [new-lg4ff](https://github.com/berarma/new-lg4ff)
Logitech force-feedback kernel module, built nightly on GitHub Actions and
published to GHCR.

Image: `ghcr.io/scrapes/bazzite-deck-nvidia-lg4ff:stable`

Base: `ghcr.io/ublue-os/bazzite-deck-nvidia:stable`
Module: `akmod-hid-logitech-new` from COPR `lnvso/new-lg4ff`

## Rebase an existing Bazzite install

```bash
# 1. Switch to the unsigned image once to pick up the new origin
rpm-ostree rebase ostree-unverified-registry:ghcr.io/scrapes/bazzite-deck-nvidia-lg4ff:stable

# 2. Reboot, then switch to the signed reference
systemctl reboot
rpm-ostree rebase ostree-image-signed:docker://ghcr.io/scrapes/bazzite-deck-nvidia-lg4ff:stable
systemctl reboot
```

## Local build

```bash
podman build -t bazzite-deck-nvidia-lg4ff .
```

## Signing

The workflow signs pushed images with cosign. Generate a keypair with
`cosign generate-key-pair`, commit `cosign.pub`, and store `cosign.key`
as the `SIGNING_SECRET` repo secret. If no secret is set, the workflow
falls back to keyless (OIDC) signing.

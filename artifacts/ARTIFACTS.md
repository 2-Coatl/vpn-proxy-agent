# Artifacts Documentation

This directory contains build artifacts and generated outputs from the VPN/Proxy Agent project.

## Directory Structure

```
artifacts/
├── builds/          # Compiled binaries and build outputs
├── packages/        # Distribution packages (.tar.gz, .deb, etc.)
├── logs/            # Build logs
└── checksums/       # SHA256 checksums for artifacts
```

## Generated Artifacts

### Python Builds

When building CPython from source, artifacts are stored here:

- `Python-X.Y.Z/` - Extracted source directory
- `Python-X.Y.Z.tgz` - Downloaded source tarball
- `python-X.Y.Z-build.log` - Build log
- `python-X.Y.Z.sha256` - Checksum file

### Docker Images

If Docker images are built locally:

- `docker-images/` - Exported Docker images
- `image-name-tag.tar` - Exported image tarball

### Configuration Backups

Backup copies of important configurations:

- `ssh-config-backup-YYYYMMDD.tar.gz`
- `docker-config-backup-YYYYMMDD.tar.gz`
- `system-config-backup-YYYYMMDD.tar.gz`

## Artifact Naming Convention

All artifacts follow this naming pattern:

```
{component}-{version}-{os}-{arch}.{extension}
```

Examples:
- `vpn-agent-1.0.0-ubuntu2204-amd64.tar.gz`
- `python-3.12.6-ubuntu2204-amd64.tar.xz`
- `wireguard-config-1.0.0-20251107.tar.gz`

## Checksums

All artifacts include SHA256 checksums:

```bash
# Generate checksum
sha256sum artifact.tar.gz > artifact.tar.gz.sha256

# Verify checksum
sha256sum -c artifact.tar.gz.sha256
```

## Cleaning Artifacts

To clean old artifacts:

```bash
# Remove all artifacts older than 30 days
find artifacts/ -type f -mtime +30 -delete

# Remove specific artifact type
rm -rf artifacts/builds/python-*
```

## Retention Policy

- **Build artifacts:** 30 days
- **Release packages:** Indefinite
- **Logs:** 90 days
- **Backups:** Per backup policy (default 7 days)

## Notes

- Large artifacts (>100MB) are not committed to git
- Add `.gitignore` entries for build artifacts
- Use `artifacts/.gitkeep` to preserve directory structure
- Store release artifacts separately (e.g., GitHub Releases)

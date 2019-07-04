# Changelog

## Unreleased

### Added

- Remote Server cleanup once backup ops are completed
  - Delete db backup
- Custom `backup_exclude` option: A comma seperated string of files/folders to exclude
- `wp_path` option
- `rsync` now utilises the `ssh_port` number

### Fixed

- Issue with database creation due to permissions
- Incorrect path used on rsync

### Changed

- General cleanup of vvv-init.sh
- **`ssh_user` and `ssh_host` is now required**
- File backup now uses `rsync` instead of `tar` and `scp`: This means backups will only add files if they do not exist or are newer; saves time on future provisions!
- Due to the added `backup_exclude` option nothing is excluded from backup by default

## 1.0.2 - 2019-07-02

### Fixed

- Specifically check for .tar.gz extensions when taking a backup

### Added

- Custom ssh_port option
- Custom provision_type option

### Changed

- Refactored code to package it into functions

## [1.0.1] - Before 2019-07-01 Changelog didn't exist

# Changelog

## 1.0.4 - 2019-07-05

## Fixed

- DB Import error caused by console output being added to sql file
- `WP_DEBUG` is now set to `true` before attempting to set `home` and `siteurl` options so failure to update options shows why

## Removed

- Verbose output of `ssh` commands

## 1.0.3 - 2019-07-04

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
- Changed `ssh` and `scp` calls to use `noroot`
- WP-CLI is no longer used on the remote host as it cannot be certain that it will be installed

## 1.0.2 - 2019-07-02

### Fixed

- Specifically check for .tar.gz extensions when taking a backup
- `ssh` command using the incorrect argument for specifying the port

### Added

- Custom ssh_port option
- Custom provision_type option

### Changed

- Refactored code to package it into functions

## [1.0.1] - Before 2019-07-01 Changelog didn't exist

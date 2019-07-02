#Changelog

# Unreleased

# Added

- Remove error if db already exists
- Remote Server cleanup once backup ops are completed
  - Delete db backup
  - Delete file backup
- Custom backup_exclude option: A comma seperated string of files/folders to exclude

# 1.0.2 - 2019-07-02

# Fixed

- Specifically check for .tar.gz extensions when taking a backup

# Added

- Custom ssh_port option
- Custom provision_type option

# Changed

- Refactored code to package it into functions

# [1.0.1] - Before 2019-07-01 Changelog didn't exist

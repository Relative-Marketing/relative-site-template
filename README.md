# Relative Site template

## Overview

Sync a live site using just the `vvv-custom.yml` file

## Configuration

Make sure your local machine has a key setup that can be used to access the server you would like to replicate.

### The minimum required configuration:

```
my-site:
  repo: git@github.com:Relative-Marketing/relative-site-template.git
  hosts:
    - my-site.test
  custom:
    ssh_host: A valid ssh host
    ssh_user: A valid ssh user (that is associated with the key on your local machine)
```

### Additional accepted options

```
custom:
    # A comma seperated list of files/folders to exclude from file sync - default=false
    backup_excludes: 'wp-content/some-dir,*.tar,*.zip'
    # Use a custom name for the database backup - default='vvv-db-backup.sql'
    db_backup_name: 'my-custom-sql-backup-name.sql'
    # The ssh port to use - default=2020
    ssh_port: 22
    # The remote path of your wordpress install - default='public_html'
    wp_path: "htdocs"
    # If you just want to provision files or db - allowed options 'all', 'db', 'files' - default='all'
    provision_type: db

```
## Common problems

### Wordfence

If you provision a site that has wordfence installed your initial provision may not work. To resolve the issue loading your newly provisioned site you need to delete the references to wordfence mentioned [here](https://wordpress.org/support/topic/fatal-error-with-wordfence-2/)

For most cases simply deleting your `.user.ini` file will be the solution:

`rm -rf /path/to/site/public_html/.user.ini`

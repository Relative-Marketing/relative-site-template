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

#### 1. Disable Wordfence

`vagrant ssh`

`cd /path/to/site`

`wp plugin deactivate wordfence`

#### 2. Delete your `.user.ini` file or remove references to wordfence in that file:

`rm -rf /path/to/site/public_html/.user.ini`

#### 3. Reactivate wordfence

Repeat step 1 but change the wp command to activate

`wp plugin activate wordfence`

### "Going to mydomain.test always redirects to my live site"

This usually means that your site has php errors (which could be caused by php setting differences). For example you may have a plugin installed that opens a php tag like this:

`<?`

some servers will allow this but vvv by default does not, so you need to look through the provision log to assess what errors are being produced. Once you have identified the errors you should resolve them on your local machine (and on your live site to prevent this issue happening again) then reprovision.

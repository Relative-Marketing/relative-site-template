# Relative Site template

## Overview

Take a backup of an existing site using just the `vvv-custom.yml` file

# Configuration

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

## Configuration Options

```
hosts:
    - foo.test
    - bar.test
    - baz.test
```

Defines the domains and hosts for VVV to listen on.
The first domain in this list is your sites primary domain.

```
custom:
    db_backup_name: name_of_db_file_.sql
    tar_name: name_of_backup_.tar.gz
```

Once you've installed your backup and have a local setup you may choose to skip provisioning the site. This is because you may not want to redownload the backup everytime you provision, this is especially true if you use this site template for multiple sites (It could take forever to backup all your sites!)

@TODO - Clean up tar and sql files after successful install.

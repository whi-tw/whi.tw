---
title: "Encrypted Automatic Off Site Backup Replication With Rclone"
date: 2017-07-16T12:11:19+01:00
draft: false
tags: ["backups", "rclone"]
---

[rclone](https://rclone.org/) is an rsync-like command line program to sync files and directories to and from various cloud storage providers.

This post relates specifically to using Memset's [Cloud Storage product](https://www.memset.com/cloud/storage/) as a backend, however the methodology translates to the various other backends as well.

This guide does not deal with the creation of the backups themselves, it assumes that backups are created and placed somewhere on the local machine (or no backups are taken, and this method is used to provide simple directory replication).

<!-- markdownlint-disable MD002 MD022-->
## Installation
<!-- markdownlint-enable MD002 MD022-->

rclone is not shipped as a traditional package, and must be installed from the archives provided [on the website](https://rclone.org/downloads/). Once downloaded, place the rclone binary somewhere on the machine where it is accessible to the user running the backup. On *nix systems, I have the binary installed at: `/usr/bin/rclone`.

Ensure it is executable (`chmod +x /usr/bin/rclone`).

You should now be able to run it:

```markup
tom@localhost:~ rclone
Usage:
  rclone [flags]
  rclone [command]

Available Commands:
...
```

Next is time for configuration. This is best not repeated here - use the [documentation](https://rclone.org/docs/#configure) on the maintainer's site.

However, it is important to set up both a configuration for your cloud storage provider, *and* a 'crypt' type provider as well.

### Example configuration

```ini
[memset]
type = swift
user = *backup user*
key = *secretkey*
auth = https://auth.storage.memset.com/v2.0
domain =
tenant = *mstestyaa1*
tenant_domain =
region =
storage_url =
auth_version =

[memset_crypt]
type = crypt
remote = memset:server1.example.com
filename_encryption = off
password = *super_secret_password*
password2 = *super_secret_salt*
```

## Piecing it all together

So, we have rclone installed and configured, now what?

First, for the rest of this guide to function correctly, you will need to move the rclone.conf file to a more permanent home.

I have specified `/etc/rclone/rclone.conf` as this home.

This file will need to be protected. I would recommend either having it owned by root:root, with 0400 permissions, or changing the owner of the directory and file to a separate user (eg. backup), again applying 0400 permissions.

### Automation configuration

This is the step that brings in the actual backup configurations.

Create and open the file `/etc/rclone/jobs.yml`.

Some sample content for this file is as follows:

```yaml
tasks:
  - name: backup_something
    local: "/path/to/sync"
    remote: "memset_crypt:path/to/remote"
    operation: sync
  - name: backup_something_else
    local: "/another/path/to/sync"
    remote: "memset_crypt:another/path/to/remote"
    operation: sync
```

### Breakdown of jobs.yml

<!-- markdownlint-disable MD009-->
**name**: A unique identifier for each job. These must not contain spaces (there is no error checking for this as yet, so be careful!)  
**local**: The absolute path to the local directory you are replicating.  
**remote**: A combination of the remote you are using, and the path on that remote (without a preceding '/')  
**operation**: The rclone operation you would like to use, chosen from [the list on the official rclone site](https://rclone.org/commands/). For replication purposes, sync will suffice.
<!-- markdownlint-enable MD009-->

## The sync script

Finally, it is time to add the script which pulls all this configuration together.

This script is available to download [from GitHub](https://gist.githubusercontent.com/tnwhitwell/834b10c80a5985e62df8b6e2ba358683/raw/1a8a99c5adbba2db68e69d7bedd97918f6eb03a9/rclonesync.py). Download this on to the machine and place it somewhere your backup user can access. I have this located at `/opt/scripts/rcbackup.py` on my own setup. Ensure this file is executable (`chmod +x /opt/scripts/rcbackup.py`)

# Running for the first time

If you have followed these instructions so far, you *should* be able to run the script and have the files you specified in `jobs.yml` uploaded to your remote.

If there are any stack-traces, look them over - it may be a typo in jobs.yml, or a missing path. I have tried to catch all these, but YMMV.

# Running on a schedule

If the on-demand run completed successfully, you can now set the jobs to run with cron. This can be achieved in one of two ways:

1. If you would like the backups run as root, a simple symlink in one of the `/etc/cron.{hourly,daily,weekly}` directories will suffice: `ln -s /opt/scripts/rcbackup.py /etc/cron.daily/backup-sync`.
1. If you would like the script run as a different user (backup-user in this example), create a file at `/etc/cron.d/backup-sync` with the following contents. The time selection is obviously more fine-grained in this example as well.

```cron
00 00 * * * backup-user /opt/scripts/rcbackup.py
```

# Thoughts / improvements

I know that a great deal of improvement can be done in this script, including (but not limited to) error handling and better configuration options.

The script was knocked together pretty quickly to avoid backups running at the same time as each other. While uploading ~500GB of photos for the first time on an hourly schedule, it became a little annoying to have the next one start before the previous had finished. I chose a combination of python and sockets to make these job-locks less file-dependant - if a machine crashes and leaves a stale lock file behind, I don't want this to break backups. Linux will clean up any sockets left over after the process completes - avoiding stale locks.

Another addition will be to allow different schedules per-job. That will involve a different scheduler than cron, though. Or - thinking about it, it could be a flag. I will try to get on this and update when it's done!

If you use this, let me know in the comments, or [by email](mailto:hi@whi.tw) - if you have any thoughts on improvements, it would be appreciated!

---
title: "Blocking Wordpress xmlrpc Attacks on Cpanel"
date: 2016-12-14T12:00:00+01:00
draft: false
tags: ["cpanel", "wordpress", "firewalling"]
---

> Finally, a way to block those pesky WordPress DoS attacks on cPanel

A very common DOS attack on a cPanel server is against the WordPress API scripts, chiefly xmlrpc.php and wp-login.php.

If you have been subjected to this kind of attack in the past, and have attempted to prevent reoccurrence, you will likely know that the oft-quoted .htaccess solutions, such as:

```apache
<Files xmlrpc.php>
        order deny,allow
        deny from all
</Files>
```

Have limited success in mitigating this kind of attack.

The popular WordPress plugin [Wordfence](https://www.wordfence.com/) does mitigate this kind of attack, and I do often suggest that our customers install it, as it is a very comprehensive plugin, which prevents against all manner of attacks, and WILL bother you with update notifications!

However, I was looking for a way to permanently block attackers at firewall level.

I discovered recently that the popular software firewall [ConfigServer Security & Firewall (csf)](https://configserver.com/cp/csf.html) for cPanel supports wildcards in its custom logs, which has made this firewall-level blocking possible.

<!-- markdownlint-disable MD002 MD022-->
### Useful Links
<!-- markdownlint-enable MD002 MD022-->

* [Project Homepage](https://configserver.com/cp/csf.html)
* [Official Install Guide](https://download.configserver.com/csf/install.txt)

## WARNING

> This may result in blocked IPs, for example, people using the WordPress App.
>
> If the WordPress App is being used in your environment, [Wordfence](https://www.wordfence.com/) may be a better solution, as it does some 'under-the-hood smarts' to separate legitimate traffic from abuse.

## Adding the magic

### Adding the account domain logs to lfd's 'watchlist'

Open `/etc/csf/csf.conf` in an editor, and locate the line:

```ini
CUSTOM1_LOG = "/var/log/customlog"
```

Change this to read:

```ini
CUSTOM1_LOG =  "/usr/local/apache/domlogs/*/*"
```

Save and close this file.

#### Adding the rule to csf's custom regex rule configuration

First create a copy of the file:

```bash
cp /etc/csf/regex.custom.pm /etc/csf/regex.custom.pm.bak
```

Now open the file in an editor and replace the contents with the following:

```perl
#!/usr/local/cpanel/3rdparty/bin/perl
###############################################################################
# Copyright 2006-2016, Way to the Web Limited
# URL: http://www.configserver.com
# Email: sales@waytotheweb.com
###############################################################################

sub custom_line {
    my $line = shift;
    my $lgfile = shift;

    # DETECT AND BLOCK xmlrpc.php POST DOS attacks (requires: CUSTOM1_LOG = "/usr/local/apache/domlogs/*/*" in csf.conf)

    if (($globlogs{CUSTOM1_LOG}{$lgfile}) and ($line =~ /(.*) \- \- .*POST .*xmlrpc\.php.*/)) {
        return ("xmlrpc.php POST attack from",$1,"xmlrpc","20","80,443","1");
    }

    return 0;
}

1;
```

At this point, you can restart csf and lfd with: `csf -ra`.

<!-- markdownlint-disable MD001 MD022-->
### Testing the rule
<!-- markdownlint-enable MD001 MD022-->

> **HERE BE DRAGONS**
>
> YOU CAN AND WILL BLOCK YOUR IP FROM ACCESSING YOUR SERVER.
>
> It may be worth following these instructions over a VPN, or from another server so your real IP is masked from lfd.

You can test if this rule has worked with the following bash one-liner:

```bash
while true; do curl -X POST http://www.example.com/xmlrpc.php ; done
```

This will simulate the attack, and will trigger the rule. You can confirm the rule has been trigged by checking `/var/log/lfd.log` - you will see a line similar to this:

```markup
Dec  7 10:18:16 servername lfd[22889]: (xmlrpc) xmlrpc.php POST attack from 198.51.100.45 (GB/United Kingdom/example.org): 20 in the last 3600 secs - *Blocked in csf* [LF_CUSTOMTRIGGER]
```

### Unblocking blocked IPs

To unblock an IP, the easiest and quickest method is on the CLI:

```bash
csf -dr 198.51.100.45
```

And to whitelist that IP in future:

```bash
csf -a 198.51.100.45 [optional comment]
```

If you would prefer, the block can be removed from the WebUI:

1. WHM >> Plugins >> ConfigServer Security & Firewall
1. Enter the blocked IP in the box adjacent to the 'Quick Unblock' button
1. Click 'Quick Unblock'

And whitelist the IP:

1. WHM >> Plugins >> ConfigServer Security & Firewall
1. Enter the blocked IP (and optional comment) in the box(es) adjacent to the 'Quick Allow' button
1. Click 'Quick Allow'

*This article was also posted on the Memset Official Blog, [here](https://www.memset.com/blog/block-wordpress-dos-attacks-cpanel/).*

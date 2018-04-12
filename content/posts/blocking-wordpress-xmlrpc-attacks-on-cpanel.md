---
title: "Blocking Wordpress xmlrpc Attacks on Cpanel"
date: 2016-12-14T12:00:00+01:00
draft: false
tags: ["cpanel", "wordpress", "firewalling"]
---

> Finally, a way to block those pesky WordPress DoS attacks on cPanel

A very common DOS attack on a cPanel server is against the WordPress API scripts, chiefly xmlrpc.php and wp-login.php.

If you have been subjected to this kind of attack in the past, and have attempted to prevent reoccurrence, you will likely know that the oft-quoted .htaccess solutions, such as:

<!-- markdownlint-disable MD031-->
{{< highlight apache >}}
```apache
<Files xmlrpc.php>
        order deny,allow
        deny from all
</Files>
```
{{< /highlight >}}
<!-- markdownlint-enable MD031-->

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

<!-- markdownlint-disable MD031-->
{{< highlight ini>}}
```ini
CUSTOM1_LOG = "/var/log/customlog"
```
{{< /highlight >}}
<!-- markdownlint-enable MD031-->

Change this to read:

<!-- markdownlint-disable MD031-->
{{< highlight ini>}}
```ini
CUSTOM1_LOG =  "/usr/local/apache/domlogs/*/*"
```
{{< /highlight >}}
<!-- markdownlint-enable MD031-->

Save and close this file.

#### Adding the rule to csf's custom regex rule configuration

First create a copy of the file:

<!-- markdownlint-disable MD031-->
{{< highlight bash >}}
```bash
cp /etc/csf/regex.custom.pm /etc/csf/regex.custom.pm.bak
```
{{< /highlight >}}
<!-- markdownlint-enable MD031-->

Now open the file in an editor and replace the contents with the following:

<!-- markdownlint-disable MD031-->
{{< highlight perl >}}
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

# Do not edit before this point
###############################################################################
#
# Custom regex matching can be added to this file without it being overwritten
# by csf upgrades. The format is slightly different to regex.pm to cater for
# additional parameters. You need to specify the log file that needs to be
# scanned for log line matches in csf.conf under CUSTOMx_LOG. You can scan up
# to 9 custom logs (CUSTOM1_LOG .. CUSTOM9_LOG)
#
# The regex matches in this file will supercede the matches in regex.pm
#
# Example:
#   if (($globlogs{CUSTOM1_LOG}{$lgfile}) and ($line =~ /^\S+\s+\d+\s+\S+ \S+ pure-ftpd: \(\?\@(\d+\.\d+\.\d+\.\d+)\) \[WARNING\] Authentication failed for user/)) {
#       return ("Failed myftpmatch login from",$1,"myftpmatch","5","20,21","1");
#   }
#
# The return values from this example are as follows:
#
# "Failed myftpmatch login from" = text for custom failure message
# $1 = the offending IP address
# "myftpmatch" = a unique identifier for this custom rule, must be alphanumeric and have no spaces
# "5" = the trigger level for blocking
# "20,21" = the ports to block the IP from in a comma separated list, only used if LF_SELECT enabled. To specify the protocol use 53;udp,53;tcp
# "1" = n/temporary (n = number of seconds to temporarily block) or 1/permanant IP block, only used if LF_TRIGGER is disabled

    # DETECT AND BLOCK xmlrpc.php POST DOS attacks (requires: CUSTOM1_LOG = "/usr/local/apache/domlogs/*/*" in csf.conf)

    if (($globlogs{CUSTOM1_LOG}{$lgfile}) and ($line =~ /(.*) \- \- .*POST .*xmlrpc\.php.*/)) {
        return ("xmlrpc.php POST attack from",$1,"xmlrpc","20","80,443","1");
    }


# If the matches in this file are not syntactically correct for perl then lfd
# will fail with an error. You are responsible for the security of any regex
# expressions you use. Remember that log file spoofing can exploit poorly
# constructed regex's
###############################################################################
# Do not edit beyond this point

    return 0;
}

1;
```
{{< /highlight >}}
<!-- markdownlint-enable MD031-->

At this point, you can restart csf and lfd with: `csf -ra`.

### Testing the rule

> **HERE BE DRAGONS**
>
> YOU CAN AND WILL BLOCK YOUR IP FROM ACCESSING YOUR SERVER.
>
> It may be worth following these instructions over a VPN, or from another server so your real IP is masked from lfd.

You can test if this rule has worked with the following bash one-liner:

<!-- markdownlint-disable MD031-->
{{< highlight bash >}}
```bash
while true; do curl -X POST http://www.example.com/xmlrpc.php ; done
```
{{< /highlight >}}
<!-- markdownlint-enable MD031-->

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
2. Enter the blocked IP in the box adjacent to the 'Quick Unblock' button
3. Click 'Quick Unblock'

And whitelist the IP:

1. WHM >> Plugins >> ConfigServer Security & Firewall
2. Enter the blocked IP (and optional comment) in the box(es) adjacent to the 'Quick Allow' button
3. Click 'Quick Allow'

*This article was also posted on the Memset Official Blog, [here](https://www.memset.com/blog/block-wordpress-dos-attacks-cpanel/).*

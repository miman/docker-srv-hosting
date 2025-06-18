# Nextcloud

## Post installation config

The following must be added to the config.php file if you want to have nginx in front of your Nextcloud instance

```
  array (
    0 => '192.168.68.130:4520',
    1 => 'nextcloud.CHANGEME.duckdns.org',
    2 => 'nextcloud.CHANGEME.duckdns.org'
  ),
  'allow_local_remote_servers' => true,
  'forwarded_for_headers' =>
  array (
    0 => 'HTTP_X_FORWARDED_FOR',
  ),
  'overwritehost' => 'nextcloud.CHANGEME.duckdns.org',
```

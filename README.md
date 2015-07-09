# Zabbix Template Rddiff-backup stats

A Zabbix template for monitoring rdiff-backup stats

It uses Zabbix LLD for scaning directory and parsing session_statics files

Tested on:

```
 CentOS 6.x X86_64
 Zabbix 2.2.x
```

### Authors
* Patrik Majer <patrik.majer.pisek@gmail.com>


### installation - Manual

* install a configure zabbix-agent

* copy file "configs/zabbix-rdiff-backup-stats.conf" into your zabbix-agent include folder (e.g. /etc/zabbix/zabbix_agentd)

* copy sudo config "configs/sudoers.d--zabbix-rdiff-backup-stats" in "/etc/sudoers.d

* copy files from folder "scripts" into "/etc/zabbix/plugins"

* reboot zabbix-agent service

* import template file into your zabbix server


### Monitored items

* T.B.D

### Docs

* https://exchange.nagios.org/directory/Plugins/Backup-and-Recovery/check_rdiff/details

* https://www.thomas-krenn.com/de/wiki/Rdiff-backup_Monitoring_Plugin

* https://www.thomas-krenn.com/de/wiki/Analyse_von_rdiff-backup_Statistiken

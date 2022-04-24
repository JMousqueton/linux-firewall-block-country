# Quick & Dirty script to block China netblocks with iptables 🔥 🇨🇳

## Usage

1. Copy [iptables.firewall.rules](/etc/iptables.firewall.rules) to /etc
2. Execute [block-china.sh](block-china.sh) 
3. Add to crontab :

```crontab -e```
```
0 5 * * * /etc/block-china.sh
```

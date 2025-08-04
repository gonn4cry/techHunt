# TechHunt
website technology checker and web technology lookup. find out what cms, programming languages, frameworks website is using and much more

 Disclaimer : All websites that are scanned with this tool will be exposed publicly on Ful.io.

Usage : 
```
Tech Hunter for Bug Bounty
Usage: ./tech.sh [options] <domain>

Options:
  -t, --tech      Show technology information only
  -e, --email     Show email information only
  -d, --desc      Show technology descriptions
  -r, --ref       Show technology references
  -a, --all       Show both descriptions and references
  -p, --proxy     Use random proxy from proxies.txt
  -h, --help      Show this help message

Examples:
  ./tech.sh -d -p example.com        # Use proxy with descriptions
  ./tech.sh -e -v example.com       # Verbose email discovery
  ./tech.sh -a -t example.com        # Full tech details
```

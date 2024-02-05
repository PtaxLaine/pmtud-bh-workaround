## About
A little and naive workaround for Path MTU Discovery Black Hole issues.

## Usage
```
pmtud-bh-workaround.sh TARGET_ASN TARGET_MTU
    TARGET_ASN - target autonomous system number. Example: "AS64496"
    TARGET_MTU - MTU for target AS subnets. Example: "1280"
```

`$ sudo systemctl enable --now pmtud-bh-workaround@"AS64496 1280".service`

`$ sudo systemctl enable --now pmtud-bh-workaround@"AS64496 1280".timer`


## Dependencies
- gawk 
- whois 
- gzip 
- iproute2
### Install dependencies on deb-based (Ubuntu, Debian, etc)
```console
$ sudo apt install gawk whois gzip iproute2
```

### Install dependencies on pacman-based (ArchLinux, Manjaro, etc)
```console
$ sudo pacman -S --needed gawk whois gzip iproute2
```

## Installation
- Check the above `Dependencies` 
- Copy `pmtud-bh-workaround.sh` to `/opt/pmtud-bh-workaround.sh`
- Copy `systemd/pmtud-bh-workaround@.service` and `systemd/pmtud-bh-workaround@.timer` to `/etc/systemd/system`
- Reload systemd daemons
```console
$ sudo systemctl daemon-reload
```
- Enable and start `pmtud-bh-workaround@.timer` or  `pmtud-bh-workaround@.service`
```console
$ sudo systemctl enable --now pmtud-bh-workaround@"AS64496\x201280".timer
```
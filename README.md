## About
A little and naive workaround for Path MTU Discovery Black Hole issues.

## Usage
```
pmtud-bh-workaround TARGET_ASN TARGET_MTU --service
    TARGET_ASN - target autonomous system number. Example: "AS64496"
    TARGET_MTU - MTU for target AS subnets. Example: "1280"
    --service run as service
```

`$ sudo systemctl enable --now pmtud-bh-workaround@"AS64496:1280".service`

*Notice:* "AS64496:1280" means:
- AS64496 — target autonomous system number - 64496
- : — delimiter
- 1280 — target MTU - 1280

## Dependencies
- gawk 
- whois 
- gzip 
- iproute2

## Installation
- Install one of [prepared packages](https://github.com/PtaxLaine/pmtud-bh-workaround/releases)
- Or…
    <details>
    <summary>Manual installation</summary>

    - Check the above ["Dependencies"](#dependencies) section
    - Copy `pmtud-bh-workaround.sh` to `/usr/bin/pmtud-bh-workaround`
    - Copy `systemd/pmtud-bh-workaround@.service` to `/usr/lib/systemd/system/pmtud-bh-workaround@.service`

    </details>


- Reload systemd daemons
```console
$ sudo systemctl daemon-reload
```
- Enable and start `pmtud-bh-workaround@.service`
```console
$ sudo systemctl enable --now pmtud-bh-workaround@"AS64496:1280".service
```
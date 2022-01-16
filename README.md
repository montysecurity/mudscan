# mudscan

This tool was created in an effort to learn defense evasion during port scanning. Rather than tricking the firewall to evade detection, this tool aims to "muddy-up" the logs.

It does this by scanning two networks at the same time.

## Usage

```
Port scanning designed to deceive

By default, each use of this tool runs a basic nmap scan, ACK scan, XMAS scan, and IDLE scan against the target. (IDLE requires root; else it omits this scan)

The deception comes with forcing nmap to scan another IP range that is not the target just to "muddy-up" the logs. This is done with -f, --fake-target.

The fake target MUST contain at least 10 times more IPs than the real target. However, the network does not have to actually be reachable or exist. This is so the real target does not show up as frequent as the fake one.

The --ratio is x:y where x is the number of fake targets it will scan per y real targets. The larger the ratio the stealthier. However, too large of a ratio and you will not finish scanning the real target (the tool will error out before scanning if this is the case). The default ratio will scan the stealthiest way possible. x/y must be > 10

-h | --help
-r | --real-target (req)
-f | --fake-target
-n | --max-nmap-processes
-s | --sleep between scans (def. 0)
-p | --nmap-paranoia-level (def. 3)
-t | --ratio of targets to scan per iteration (x y = x fake to y real) (x/y must be > 10)

Examples:
    Scan a Target Network w/o Scanning a Fake Network
	bash mudscan.sh -r 192.168.1.0/24

    Scan a Target Network and a Fake Network
	bash mudscan.sh -r 192.168.1.0/24 -f 10.0.0.0/8

    Scan a Target Network and a Fake Network with custom parameters
	bash mudscan.sh -r 192.168.1.0/24 -f 10.0.0.0/8 -n 6 -s 2 --ratio 15 1
```

## disclaimers

Do not use this to with malicious intent to decieve blue teams. It's intended as a training tool to teach network analysis, or to be used in sanctioned red/purple team excercises.

Do not use this against a network you are not authorized to test. The tool will scan the "fake target" provided. It is recommended to use an unreachable RFC 1918 netblock as the fake network.

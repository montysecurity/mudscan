#!/bin/bash

HELP="Port scanning designed to deceive

By default, each use of this tool runs a basic nmap scan, ACK scan, XMAS scan, and IDLE scan against the target. (IDLE requires root; else it omits this scan)

The deception comes with forcing nmap to scan another IP range that is not the target just to \"muddy-up\" the logs. This is done with -f, --fake-target.

The fake target MUST contain at least 10 times more IPs than the real target. However, the network does not have to actually be reachable or exist.

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
	bash mudscan.sh -r 192.168.1.0/24 -f 10.0.0.0/8 -n 6 -s 2 --ratio 15 1"

export REAL_ITERATOR=9
export FAKE_ITERATOR=100
export SCAN_LIMIT=4
export SLEEP=0
export PARANOIA=3
SCAN_ID=`date +%s | md5sum | awk -F ' ' '{print $1}'`
OUTPUT_DIR=~/.mudscan/$SCAN_ID
mkdir -p $OUTPUT_DIR 
mkdir $OUTPUT_DIR/realscans

if [[ $# -eq 0 ]];
then
    echo "$HELP"
    exit
fi

while [[ $# -gt 0 ]];
do
    case "$1" in
	-h|--help)
	    echo "$HELP"
	    exit ;;
	-r|--real-target)
	    shift
	    export REAL_TARGET=$1 
	    shift ;;
	-f|--fake-target)
	    shift
	    export FAKE_TARGET=$1
	    export STEALTH=1 
	    shift ;;
	-n|--max-nmap-processes)
	    shift
	    export SCAN_LIMIT=$1 
	    shift ;;
	-s|--sleep)
	    shift
	    export SLEEP=$1
	    shift ;;
	-p|--paranoia)
	    shift
	    export PARANOIA=$1 
	    shift ;;
	-t|--ratio)
	    shift
	    export CUSTOM_RATIO=1
	    export FAKE_ITERATOR=$1
	    shift
	    export REAL_ITERATOR=$1 
	    shift ;;
    esac
done

echo "[+] Generating Targets" | tee -a ~/.mudscan/$SCAN_ID/log.txt
echo "[+] Networks Larger than a /16 may take a while" | tee -a ~/.mudscan/$SCAN_ID/log.txt
export REAL_LIST=$(nmap -sn -sL -n $REAL_TARGET | awk '/Nmap scan report/{print $NF}' > $OUTPUT_DIR/reallist.txt)
export REAL_COUNT=$(cat $OUTPUT_DIR/reallist.txt | wc -l)
echo "[+] Finished Generating Real Targets"

if [[ $STEALTH -eq 1 ]];
then
    echo "[+] Generating Fake Targets" | tee -a ~/.mudscan/$SCAN_ID/log.txt
    export FAKE_LIST=$(nmap -sn -sL -n $FAKE_TARGET | awk '/Nmap scan report/{print $NF}' > $OUTPUT_DIR/fakelist.txt)
    export FAKE_COUNT=$(cat $OUTPUT_DIR/fakelist.txt | wc -l)
    mkdir $OUTPUT_DIR/fakescans
    echo "[+] Finished Generating Fake Targets"
fi

check_math () {

    if [[ $STEALTH -eq 1 ]];
    then
	if [[ $CUSTOM_RATIO -eq 1 ]];
	then
	    export RATIO=$(( $FAKE_ITERATOR / $REAL_ITERATOR ))
	else
	    export RATIO=$(( $FAKE_COUNT / $REAL_COUNT ))
	    export FAKE_ITERATOR=$RATIO
	    export REAL_ITERATOR=1
	fi
	export REAL_ITERATIONS=$(( $REAL_COUNT / $REAL_ITERATOR + 1 ))
	export FAKE_ITERATIONS=$(( $FAKE_COUNT / $FAKE_ITERATOR + 1 ))
	export TOP_LIMIT=$FAKE_ITERATIONS
	echo "[+] Real Targets: $REAL_COUNT" | tee -a ~/.mudscan/$SCAN_ID/log.txt
	echo "[+] Fake Targets: $FAKE_COUNT" | tee -a ~/.mudscan/$SCAN_ID/log.txt
	echo "[+] Real Targets Scanned Per Loop: $REAL_ITERATOR" | tee -a ~/.mudscan/$SCAN_ID/log.txt
	echo "[+] Fake Targets Scanned Per Loop: $FAKE_ITERATOR" | tee -a ~/.mudscan/$SCAN_ID/log.txt
	echo "[+] Number of Seconds to Sleep After Each Loop: $SLEEP" | tee -a ~/.mudscan/$SCAN_ID/log.txt
	echo "[+] Nmap Paranoia Level: $PARANOIA" | tee -a ~/.mudscan/$SCAN_ID/log.txt
	echo "[+] Number of Iterations Needed for the Real Target: $REAL_ITERATIONS" | tee -a ~/.mudscan/$SCAN_ID/log.txt
	echo "[+] Number of Iterations Needed for the Fake Target: $FAKE_ITERATIONS" | tee -a ~/.mudscan/$SCAN_ID/log.txt
	echo "[+] Ratio: $RATIO:1" | tee -a ~/.mudscan/$SCAN_ID/log.txt
	
	if [[ $REAL_ITERATIONS -gt $FAKE_ITERATIONS ]];
	then
	    echo "[-] Error: Fake Iterations > Real Iterations" | tee -a ~/.mudscan/$SCAN_ID/log.txt
	    exit 1
	fi

	if [[ $RATIO -lt 10 ]];
	then
	    echo "[-] Error: Ratio < 10:1" | tee -a ~/.mudscan/$SCAN_ID/log.txt
	    exit 1
	fi
    else
	export REAL_ITERATOR=9
	export TOP_LIMIT=$(( $REAL_COUNT / 9 + 1))
	export REAL_ITERATIONS=$(( $REAL_COUNT / 9 + 1))
	echo "[+] Real Targets: $REAL_COUNT" | tee -a ~/.mudscan/$SCAN_ID/log.txt
	echo "[+] Real Targets Scanned Per Loop: $REAL_ITERATOR" | tee -a ~/.mudscan/$SCAN_ID/log.txt
	echo "[+] Number of Iterations Needed for the Real Target: $REAL_ITERATIONS" | tee -a ~/.mudscan/$SCAN_ID/log.txt
    fi

    echo "[+] Concurrent Scan Limit: $SCAN_LIMIT" | tee -a ~/.mudscan/$SCAN_ID/log.txt

}

# scan template
basic_scan () {

    for i in {1..255};
    do
	# when setting the faketarget as something local that did not exist (RFC 1918) and disabling arp in nmap, it still sent ARP requests, why?
	echo "[+] Starting Scan $i of $TOP_LIMIT" | tee -a ~/.mudscan/$SCAN_ID/log.txt 
	if [[ $STEALTH -eq 1 ]];
	then
	    head -n $(( $i * $FAKE_ITERATOR )) $OUTPUT_DIR/fakelist.txt | tail -n $FAKE_ITERATOR | xargs nmap -n -T$PARANOIA $FLAGS -oN $OUTPUT_DIR/fakescans/$i\_$TYPE.txt &> /dev/null &
	fi
	head -n $(( $i * $REAL_ITERATOR )) $OUTPUT_DIR/reallist.txt | tail -n $REAL_ITERATOR | xargs nmap -n -T$PARANOIA -sn $FLAGS -oN $OUTPUT_DIR/realscans/$i\_$TYPE.txt &> /dev/null &
	sleep $SLEEP

	while [[ $(ps aux | grep nmap | grep -v grep | wc -l) -ge $SCAN_LIMIT ]];
	do
	    sleep 1
	done

	if [[ $i -eq $TOP_LIMIT ]];
	then
	    break
	fi

    done

}


ack_scan() {

    export FLAGS=" -sA "
    export TYPE="ack"
    echo "[+] ACK Scan" | tee -a ~/.mudscan/$SCAN_ID/log.txt
    basic_scan
    unset FLAGS
    unset TYPE

}

xmas_scan() {

    export FLAGS=" -sX "
    export TYPE="xmas"
    echo "[+] XMAS Scan" | tee -a ~/.mudscan/$SCAN_ID/log.txt
    basic_scan
    unset TYPE
    unset FLAGS

}

identify_zombie_scan() {

    export FLAGS=" -O -v "
    export TYPE="identify_zombie"
    echo "[+] ZOMBIE Scan" | tee -a ~/.mudscan/$SCAN_ID/log.txt
    basic_scan
    unset TYPE
    unset FLAGS

}

report () {

    sleep 0
    # placeholder to format and build a pretty report from the results
    # echo "[+] POSSIBLE ZOMBIES"
    # cat realscans/*_identify_zombie.txt | grep -e "Nmap scan report for" -e "Incremental" | grep -v "host down" | sed "s/IP ID Sequence Generation//g" | sed "s/: Incremental/:Incremental /g" | sed "s/Nmap scan report for / /g" | tr -d '\n' | grep "[a-zA-Z0-9|\.]*:Incremental"

}

main () {

    echo "[+] Scan Started at $(date)" | tee -a ~/.mudscan/$SCAN_ID/log.txt
    echo "[+] Output Directory: $OUTPUT_DIR" | tee -a ~/.mudscan/$SCAN_ID/log.txt
    check_math
    echo "[+] BASIC SCAN" | tee -a ~/.mudscan/$SCAN_ID/log.txt
    basic_scan
    echo "[+] ACK SCAN" | tee -a ~/.mudscan/$SCAN_ID/log.txt # or use null scan? point is to identify firewall rules. Both and compare in report?
    ack_scan
    echo "[+] XMAS SCAN" | tee -a ~/.mudscan/$SCAN_ID/log.txt
    xmas_scan
    if [ "$EUID" -eq 0 ];
    then
	echo "[+] ID ZOMBIE SCAN" | tee -a ~/.mudscan/$SCAN_ID
	identify_zombie_scan
    fi
    echo "[+] Scan Finished at $(date)" | tee -a ~/.mudscan/$SCAN_ID/log.txt
    echo "[+] Output Directory: $OUTPUT_DIR" | tee -a ~/.mudscan/$SCAN_ID/log.txt
    # other scans to add: sV sC, vuln and safe, full-port

}

main

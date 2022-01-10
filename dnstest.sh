#!/usr/bin/env bash

command -v bc > /dev/null || { echo "bc was not found. Please install bc."; exit 1; }
{ command -v drill > /dev/null && dig=drill; } || { command -v dig > /dev/null && dig=dig; } || { echo "dig was not found. Please install dnsutils."; exit 1; }



NAMESERVERS=`cat /etc/resolv.conf | grep ^nameserver | cut -d " " -f 2 | sed 's/\(.*\)/&#&/'`

PROVIDERS="
1.1.1.1#cloudflare1 
1.0.0.1#cloudflare2 
1.0.0.2#cloudflare3 
1.1.1.2#cloudflare4 
4.2.2.1#level3 
8.8.8.8#google1 
8.8.4.4#google2 
9.9.9.9#quad91 
149.112.112.112#quad92 
80.80.80.80#freenom 
208.67.222.123#opendns1 
208.67.222.222#opendns2
208.67.222.220#opendns3 
199.85.126.20#norton 
185.228.168.168#cleanbrowsing 
77.88.8.7#yandex1 
77.88.8.8#yandex2 
77.88.8.1#yandex3 
77.88.8.2#yandex4 
77.88.8.88#yandex5 
176.103.130.132#adguard 
156.154.70.3#neustar1 
64.6.64.6#neustar2 
64.6.65.6#neustar3 
156.154.71.3#neustar4 
8.26.56.26#comodo
208.67.222.222#cisco1
208.67.220.220#cisco2
"

# Domains to test. Duplicated domains are ok
DOMAINS2TEST="www.google.com amazon.com facebook.com www.youtube.com www.reddit.com  wikipedia.org twitter.com gmail.com www.google.com whatsapp.com"


totaldomains=0
printf "%-18s" ""
for d in $DOMAINS2TEST; do
    totaldomains=$((totaldomains + 1))
    printf "%-8s" "test$totaldomains"
done
printf "%-8s" "Average"
echo ""


for p in $NAMESERVERS $PROVIDERS; do
    pip=${p%%#*}
    pname=${p##*#}
    ftime=0

    printf "%-18s" "$pname"
    for d in $DOMAINS2TEST; do
        ttime=`$dig +tries=1 +time=2 +stats @$pip $d |grep "Query time:" | cut -d : -f 2- | cut -d " " -f 2`
        if [ -z "$ttime" ]; then
	        #let's have time out be 1s = 1000ms
	        ttime=1000
        elif [ "x$ttime" = "x0" ]; then
	        ttime=1
	    fi

        printf "%-8s" "$ttime ms"
        ftime=$((ftime + ttime))
    done
    avg=`bc -lq <<< "scale=2; $ftime/$totaldomains"`

    echo "  $avg"
done


exit 0;

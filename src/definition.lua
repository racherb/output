local PING = {}

PING.OK = {
    short = 'PING_OK $(server) $(ip) $(seq) $(ttl) $(time) $(um)',
    expanded = '64 bytes from $(server) $(ip): icmp_seq=$(seq) ttl=$(ttl) time=$(time) $(um)',
    expected = {'$(time) <= 200'},
    alarm = {'$(time) > 400'}
}

PING.NAME_RESOLUTION_FAIL = {
    short = 'PING_NR_FAIL $(server)',
    expanded = 'ping: $(server): Temporary failure in name resolution',
    causes = {'Missing or Wrongly Configured resolv.conf File', 'Firewall Restrictions'},
    strategy = {
        etc_resolv_conf = {},
        local_firewall = {}
    }
}

PING.NETWORK_UNREACHABLE = {
    short = 'PING_NET_UNREACHABLE',
    expanded = 'ping: sendmsg: Network is unreachable',
    strategy = {
        etc_resolv_conf = {},
        local_firewall = {}
    }
}

--[[
    PING 8.8.8.8 (8.8.8.8) 56(84) bytes of data.
    64 bytes from 8.8.8.8: icmp_seq=1 ttl=121 time=28.7 ms

    PING www.axity.com (104.22.51.222) 56(84) bytes of data.
    64 bytes from 104.22.51.222 (104.22.51.222): icmp_seq=1 ttl=61 time=31.8 ms

    PING dzlgdtxcws9pb.cloudfront.net (65.8.247.136) 56(84) bytes of data.
    64 bytes from 65.8.247.136 (65.8.247.136): icmp_seq=1 ttl=245 time=184 ms

    PING www.google.com (172.217.192.103) 56(84) bytes of data.
    64 bytes from 172.217.192.103: icmp_seq=1 ttl=111 time=28.5 ms

    PING github.com (140.82.113.3) 56(84) bytes of data.
    64 bytes from lb-140-82-113-3-iad.github.com (140.82.113.3): icmp_seq=1 ttl=49 time=261 ms

]]
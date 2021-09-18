local PING = {}

PING.OK = {
    short = 'PING_OK $(server) $(ip) $(seq) $(ttl) $(time) $(um)',
    expanded = '64 bytes from $(server) $(ip): icmp_seq=$(seq) ttl=$(ttl) time=$(time) $(um)'
}

PING.NAME_RESOLUTION_FAIL = {
    short = 'PING_NR_FAIL $(server)',
    expanded = 'ping: $(server): Temporary failure in name resolution',
    causes = {
        'Missing or Wrongly Configured resolv.conf File',
        'Firewall Restrictions'
    }
}

PING.NETWORK_UNREACHABLE = {
    short = 'PING_NET_UNREACHABLE',
    expanded = 'ping: sendmsg: Network is unreachable'
}

return PING
# ROUTE RULES
ip route add local default dev lo table 100
ip rule add fwmark 1 lookup 100

# CREATE TABLE
iptables -t mangle -N V2RAY

# RETURN LOCAL AND LANS
iptables -t mangle -A V2RAY -d 0.0.0.0/8 -j RETURN
iptables -t mangle -A V2RAY -d 127.0.0.0/8 -j RETURN

iptables -t mangle -A V2RAY -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A V2RAY -d 240.0.0.0/4 -j RETURN

iptables -t mangle -A V2RAY -d 255.255.255.255/32 -j RETURN

iptables -t mangle -A V2RAY -d 10.0.0.0/8 -p tcp -j RETURN
iptables -t mangle -A V2RAY -d 169.254.0.0/16 -p tcp -j RETURN
iptables -t mangle -A V2RAY -d 172.16.0.0/12 -p tcp -j RETURN
iptables -t mangle -A V2RAY -d 192.168.0.0/16 -p tcp -j RETURN

iptables -t mangle -A V2RAY -d 10.0.0.0/8 -p udp ! --dport 53 -j RETURN
iptables -t mangle -A V2RAY -d 169.254.0.0/16 -p udp ! --dport 53 -j RETURN
iptables -t mangle -A V2RAY -d 172.16.0.0/12 -p udp ! --dport 53 -j RETURN
iptables -t mangle -A V2RAY -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN

# FORWARD ALL
iptables -t mangle -A V2RAY -p tcp -j TPROXY --on-port 12345 --tproxy-mark 0x01/0x01
iptables -t mangle -A V2RAY -p udp -j TPROXY --on-port 12345 --tproxy-mark 0x01/0x01

# REDIRECT
iptables -t mangle -A PREROUTING -j V2RAY


# CREATE TABLE: GATE SELF
iptables -t mangle -N V2RAY_MASK

# RETURN LOCAL AND LANS
iptables -t mangle -A V2RAY_MASK -d 0.0.0.0/8 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 127.0.0.0/8 -j RETURN

iptables -t mangle -A V2RAY_MASK -d 224.0.0.0/4 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 240.0.0.0/4 -j RETURN

iptables -t mangle -A V2RAY_MASK -d 255.255.255.255/32 -j RETURN

iptables -t mangle -A V2RAY_MASK -d 10.0.0.0/8 -p tcp -j RETURN
iptables -t mangle -A V2RAY_MASK -d 169.254.0.0/16 -p tcp -j RETURN
iptables -t mangle -A V2RAY_MASK -d 172.16.0.0/12 -p tcp -j RETURN
iptables -t mangle -A V2RAY_MASK -d 192.168.0.0/16 -p tcp -j RETURN

iptables -t mangle -A V2RAY_MASK -d 10.0.0.0/8 -p udp ! --dport 53 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 169.254.0.0/16 -p udp ! --dport 53 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 172.16.0.0/12 -p udp ! --dport 53 -j RETURN
iptables -t mangle -A V2RAY_MASK -d 192.168.0.0/16 -p udp ! --dport 53 -j RETURN

iptables -t mangle -A V2RAY_MASK -j RETURN -m mark --mark 0xff

iptables -t mangle -A V2RAY_MASK -p udp -j MARK --set-mark 1
iptables -t mangle -A V2RAY_MASK -p tcp -j MARK --set-mark 1

iptables -t mangle -A OUTPUT -j V2RAY_MASK

#!/bin/bash
# Memulihkan jaringan eksternal DevStack setelah VM menyala

# Tunggu br-ex muncul (maksimal 60 detik)
for i in $(seq 1 60); do
  ip link show br-ex > /dev/null 2>&1 && break
  sleep 1
done

# Tambah IP hanya kalau belum ada
ip addr show br-ex | grep -q "172.24.4.1/24" || ip addr add 172.24.4.1/24 dev br-ex
ip link set br-ex up
sysctl -w net.ipv4.ip_forward=1
# Tambah aturan NAT hanya kalau belum ada
iptables -t nat -C POSTROUTING -s 172.24.4.0/24 -o ens33 -j MASQUERADE 2>/dev/null \
  || iptables -t nat -A POSTROUTING -s 172.24.4.0/24 -o ens33 -j MASQUERADE

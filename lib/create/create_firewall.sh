if hcloud firewall list | grep -q $CLUSTER_NAME; then
  echo "Firewall already exists, skipping."
else
  echo "Creating firewall..."

  cat <<-EOF > /tmp/firewall
    [
      {
        "direction": "in",
        "protocol": "tcp",
        "port": "22",
        "source_ips": [
          "0.0.0.0/0",
          "::/0"
        ],
        "destination_ips": []
      },
      {
        "direction": "in",
        "protocol": "icmp",
        "port": null,
        "source_ips": [
          "0.0.0.0/0",
          "::/0"
        ],
        "destination_ips": []
      },
      {
        "direction": "in",
        "protocol": "tcp",
        "port": "6443",
        "source_ips": [
          "0.0.0.0/0",
          "::/0"
        ],
        "destination_ips": []
      },
      {
        "direction": "in",
        "protocol": "tcp",
        "port": "any",
        "source_ips": [
          "10.0.0.0/16"
        ],
        "destination_ips": []
      },
      {
        "direction": "in",
        "protocol": "udp",
        "port": "any",
        "source_ips": [
          "10.0.0.0/16"
        ],
        "destination_ips": []
      }
    ]
EOF

  hcloud firewall create --name $CLUSTER_NAME --rules-file /tmp/firewall
fi

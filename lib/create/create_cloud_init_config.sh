cat << EOF > /tmp/user-data
#cloud-config
packages:
  - fail2ban
runcmd:
  - sed -i 's/[#]*PermitRootLogin yes/PermitRootLogin prohibit-password/g' /etc/ssh/sshd_config
  - sed -i 's/[#]*PasswordAuthentication yes/PasswordAuthentication no/g' /etc/ssh/sshd_config
  - systemctl restart sshd
EOF

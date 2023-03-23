# VM Instialize
- VM Initilize script (for me)

## Quick start
```bash
git clone http://github.com/soulkst/vm-init.git \
    && sudo sh vm-init/init.sh -ip [IP_ADDR] \
    && export SKIP_IPTABLES=1;curl -fsSL https://get.docker.com/rootless | sh \
    && sudo reboot now

sh init-docker-compose.sh
```

### docker
```bash
# Defuault
curl -fsSL https://get.docker.com | sh

# Rootless
# Execute by non-root user
export SKIP_IPTABLES=1;curl -fsSL https://get.docker.com/rootless | sh
```
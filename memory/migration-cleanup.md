# Migration Cleanup Checklist
# DO NOT run these now — only after workspace is fully transferred and running

## Changes to reverse on the new MSI laptop (nagato):
- [ ] Remove SSH key added to ~/.ssh/authorized_keys
- [ ] Revert PasswordAuthentication to 'no' in /etc/ssh/sshd_config
- [ ] Revert ListenAddress back to commented out (#ListenAddress 0.0.0.0)
- [ ] Restart SSH after reverting: sudo systemctl restart ssh
- [ ] Optionally remove openssh-server: sudo apt remove --purge openssh-server

## Changes to reverse on this VM (Debian):
- [ ] Remove SSH key: rm ~/.ssh/akatsuki-transfer ~/.ssh/akatsuki-transfer.pub
- [ ] Kill any leftover python HTTP servers
- [ ] Remove workspace.tar.gz from /tmp

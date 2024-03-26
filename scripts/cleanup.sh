#!/bin/bash -eux

# Wait for cloud-init to be done
echo "Waiting for cloud-init to finish"
cloud-init status --wait
STATUS=$(cloud-init status --format=json | jq -r .status)
if [ "$STATUS" != "done" ]; then
	echo FAILED to run cloud-init successfully.
	cat /var/log/cloud-init.log
	exit 1
fi

# Make sure to prevent kubernetes packages from updating in this image.
apt-mark hold kubelet kubeadm kubectl

echo "Cloud-init is done running. Cleanup has begun."
# Cleanup
apt-get -y autoremove --purge
apt-get clean

# Remove the default password from the default user
passwd --lock debian

# Zero out the rest of the free space using dd, then delete the written file.
#dd if=/dev/zero of=/EMPTY bs=1M
#rm -f /EMPTY

# Add `sync` so Packer doesn't quit too early, before the large file is deleted.
#sync

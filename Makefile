STACKS = $(shell ls -1 ./stacks/)
APPS = $(shell ls -1 --ignore=HOSTNAME --ignore receiver  /home/git/)

all:

install: /usr/bin/docker /home/git/receiver /usr/local/bin/upaas \
		/etc/init/git-init-session-setup.conf /etc/init/git-init-session.conf \
		stacks
	usermod -aG docker git
	start git-init-session-setup || exit 0

update:
	@$(MAKE) -B /home/git/receiver /usr/local/bin/upaas

/usr/bin/docker:
	curl http://get.docker.io/gpg | apt-key add -
	echo deb http://get.docker.io/ubuntu docker main > /etc/apt/sources.list.d/docker.list
	apt-get update -y
	lsmod | grep aufs || modprobe aufs || apt-get install -y linux-image-extra-`uname -r`
	apt-get install -y lxc-docker

/usr/local/bin/upaas: ./upaas
	cp $< $(@D)

/usr/local/bin/gitreceive: ./gitreceive
	cp $< $(@D)

/etc/init/git-init-session-setup.conf: ./git-init-session-setup.conf
	cp $< $(@D)

/etc/init/git-init-session.conf: ./git-init-session.conf
	cp $< $(@D)

/home/git/receiver: /usr/local/bin/gitreceive
	gitreceive init
	cp ./receiver $(@D)

stacks: $(STACKS:%=stack-%)

stack-%: $(PWD)/stacks/%
	docker build -t "upaas/stack/$(@:stack-%=%)" $<

upstart: $(APPS:%=upstart-%)

upstart-%:
	sudo -i -u git upaas install-upstart-script $(@:upstart-%=%)

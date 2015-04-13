#
# install the latest docker from https://get.docker.io
#	see https://blog.talpor.com/2014/07/saltstack-beginners-tutorial/
#
  docker-kernel-pkgs:  # Install these kernel packages
    pkg.latest:
     - pkgs:
        - linux-image-generic-lts-raring
        - linux-headers-generic-lts-raring


  docker-apt-https-transport-method: # Run this command...
    cmd.run:
      - name: apt-get update & apt-get install -y apt-transport-https
      - unless: [ ! -e /usr/lib/apt/methods/https ] # ... unless this is true
      - require:
        - pkg: docker-kernel-pkgs # This state has to run successfully first



  docker-repo: # Install the Ubuntu PPA for Docker...
    pkgrepo.managed:
      - name: deb https://get.docker.io/ubuntu docker main
      - file: /etc/apt/sources.list.d/docker.list
      - keyserver: hkp://keyserver.ubuntu.com:80
      - keyid: 36A1D7869245C8950F966E92D8576A8BA88D21E9
      - require:
        - cmd: docker-apt-https-transport-method # ...only if this state ran



  docker-pkg: # Install the package lxc-docker...
    pkg.latest:
      - name: lxc-docker
      - require:
        - pkgrepo: docker-repo # ...only if you ran the state docker-repo already



  docker-serv:            # Make sure that the 'docker' is up and
    service.running:      # running...
      - name: docker
      - enable: True      # ... also set it to start at boot.
      - watch:            
        - pkg: docker-pkg # If this package changes, restart this service.

  python-requests:
    pkg:
     - installed

  python-pip:
    pkg:
      - installed

  docker-py:
    pip.installed:
      - reload_modules: True
      - require:
        - pkg: python-pip

  apache-test-img:
    docker.installed:
      - image: tutum/hello-world:latest
      - force: true

  apache-test-running:
    docker.running:
      - container:  apache-test-img
      - port_bindings:
          "80/tcp":
              HostIp: ""
              HostPort: "10000"

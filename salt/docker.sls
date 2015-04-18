#
# get the python environment setup
#

  python-requests:
    pkg:
     - installed

#
#  Installing pip on Ubuntu 14.04 is non-trivial.
#  See:  https://bugs.launchpad.net/ubuntu/+source/python-pip/+bug/1306991
#
#  python-pip:
#    pkg:
#      - installed

  /usr/local/sbin/get-pip.py:
    file.managed:
      - source: https://raw.github.com/pypa/pip/master/contrib/get-pip.py
      - source_hash:  md5=d151ff23e488d8f579d68a7a5777badc

  installpip:
    cmd.run:
      - name: /usr/bin/python /usr/local/sbin/get-pip.py
#      - unless: which pip
#      - require:
#        - pkg: python
#        - file: /usr/local/sbin/get-pip.py
      - reload_modules: True

  docker-py:
    pip.installed:
      - reload_modules: True
#      - require:
#        - pkg: python-pip

{% if grains[ 'os_family' ] == 'Debian' %}
# ubuntu specific:
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
      - unless: test -e /usr/lib/apt/methods
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
{% endif %}

{% if grains[ 'os_family' ] == 'RedHat' %}
# Redhat specific:
#
# install the latest docker from normal repositories
#

  docker-pkg:
    pkg.latest:
      - name: docker

{% endif %}

  /etc/default/docker:
    file.managed:
      - source: salt://docker-service.conf

  docker-serv:            # Make sure that the 'docker' is up and
    service.running:      # running...
      - name: docker
      - enable: True      # ... also set it to start at boot.
      - watch:            
        - file:  /etc/default/docker
        - pkg: docker-pkg # If this package changes, restart this service.

  apache-test-img:
    docker.pulled:
      - name: internal-registry-tmp.dstresearch.com/hello-world
      - insecure_registry: true
#      - require:
#        - pkg: python-pip

  apache-test-container:
    docker.installed:
      - image: internal-registry-tmp.dstresearch.com/hello-world

  apache-test-running:
    docker.running:
      - container:  apache-test-container
      - port_bindings:
          "80/tcp":
              HostIp: ""
              HostPort: "10000"

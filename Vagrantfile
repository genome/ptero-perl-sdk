# -*- mode: ruby -*-
# vi: set ft=ruby :

BOX_MEMORY  = ENV["BOX_MEMORY"] || "512"
SDK_VERSION = ENV["SDK_VERSION"]
DEBFULLNAME = ENV["MAINTAINER_NAME"]
DEBEMAIL    = ENV["MAINTAINER_EMAIL"]
DISTRO_NAME = ENV["DISTRO_NAME"] || "lucid-genome-development"

Vagrant::configure("2") do |config|
  config.vm.host_name = "ptero-perl-sdk"
  config.vm.box = "lucid64"
  config.vm.box_url = "http://files.vagrantup.com/lucid64.box"

  config.vm.provider :virtualbox do |vb|
    vb.customize ["modifyvm", :id, "--memory", BOX_MEMORY]
  end


  PTERO_SDK_DIR = "/home/vagrant/ptero-perl-sdk"
  config.vm.synced_folder ".", PTERO_SDK_DIR

  config.vm.provision 'apt-get update',             type: "shell", inline: "apt-get update"
  config.vm.provision 'install packaging deps',     type: "shell", inline: "DEBIAN_FRONTEND=noninteractive apt-get -qq -y install libdist-zilla-perl build-essential fakeroot devscripts debhelper"
  config.vm.provision 'install build deps',         type: "shell", inline: "DEBIAN_FRONTEND=noninteractive apt-get -qq -y install libdevel-cover-perl libtest-exception-perl libdata-dump-perl libdate-calc-perl libdatetime-format-strptime-perl libfile-slurp-perl libgraph-perl libjson-perl liblog-log4perl-perl liblwp-useragent-determined-perl libmoose-perl libmoosex-aliases-perl libparams-validate-perl libset-scalar-perl libtemplate-perl libwww-perl libio-string-perl"
  config.vm.provision 'update debian/changelog',    type: "shell", inline: "cd #{PTERO_SDK_DIR}; DEBFULLNAME='#{DEBFULLNAME}' DEBEMAIL='#{DEBEMAIL}' dch -v #{SDK_VERSION}-1 --force-distribution --distribution #{DISTRO_NAME} 'PTero client'"
  config.vm.provision 'create dist.ini',            type: "shell", inline: "cd #{PTERO_SDK_DIR}; sed 's/VERSION/#{SDK_VERSION}/' < dist.ini.tmpl > dist.ini"
  config.vm.provision 'create dist directory',      type: "shell", inline: "cd #{PTERO_SDK_DIR}; dzil build --notgz"
  config.vm.provision 'create package',             type: "shell", inline: "cd #{PTERO_SDK_DIR}/Ptero-#{SDK_VERSION}; dpkg-buildpackage"
end

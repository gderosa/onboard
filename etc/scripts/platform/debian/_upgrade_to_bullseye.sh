SOURCES_LIST='/etc/apt/sources.list'
if (egrep '^[^#]+buster' $SOURCES_LIST); then
    cp $SOURCES_LIST $SOURCES_LIST.buster
    sed -e 's/buster/bullseye/g' $SOURCES_LIST.buster | sed -e 's/^\s*deb-src/#deb-src/' > $SOURCES_LIST
    apt-get update
    apt-get -y dist-upgrade
    apt-get -y upgrade
fi

apt-get -y autoremove

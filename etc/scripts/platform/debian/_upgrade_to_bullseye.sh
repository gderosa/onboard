SOURCES_LIST='/etc/apt/sources.list'


do_upgrade_to_bullseye() {
    cp $SOURCES_LIST $SOURCES_LIST.buster
    sed -e 's/buster/bullseye/g' $SOURCES_LIST.buster | sed -e 's/^\s*deb-src/#deb-src/' > $SOURCES_LIST
    apt-get update
    apt-get -y dist-upgrade
    apt-get -y upgrade
    apt-get -y autoremove
}

if (egrep '^[^#]+buster' $SOURCES_LIST > /dev/null); then
    echo "Upgrade to Debian 11 (\"bullseye\")? Answer:"
    echo "  'Y' or 'y' to upgrade;"
    echo "  'N' or 'n' to continue with Debian 10 (buster) and use QEMU 3 instead of 4 (not recommended);"
    echo "  'Q', 'q' or anything else to exit."
    read yn
    case $yn in
        [Yy] )
            do_upgrade_to_bullseye
            ;;
        [Nn] )
            ;;
        * )
            exit
    esac
fi
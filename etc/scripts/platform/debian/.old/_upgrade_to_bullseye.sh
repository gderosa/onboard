DEBIAN_FRONTEND=noninteractive

SOURCES_LIST='/etc/apt/sources.list'

backup_sources_list() {
    if [ ! -f $SOURCES_LIST.buster ]; then
        cp $SOURCES_LIST $SOURCES_LIST.buster
    fi
}

modified_sources_list_content() {
    cat $SOURCES_LIST.buster | while read line || [[ -n $line ]];
    do
        if [[ $line =~ ^\ *deb-src ]]; then
            line="#$line"
        fi
        if [[ $line =~ ^[#\ ]*deb(-src)?\ .*security.*debian\.org ]]; then
            if [[ $line =~ buster-security ]]; then
                echo "$line" | sed 's/buster-security/bullseye-security/g'
            else
                echo "$line" | sed 's/buster/bullseye-security/g'
            fi
        elif [[ $line =~ ^\s*#\s*deb-cdrom ]]; then
            # Line is a commented cdrom line, leave untouched
            echo "$line"
        elif [[ $line =~ cdrom ]]; then
            # Comment-out cdrom lines
            echo "#$line"
        else
            # Replace distro release names otherwise
            echo "$line" | sed 's/buster/bullseye/g'
        fi
    done
}


if (egrep '^[^#]+buster' $SOURCES_LIST > /dev/null); then
    echo
    echo "Switch to Debian 11 (\"bullseye\")? Please type:"
    echo "  'Y' or 'y' to switch to Debian 11 \"bullseye\" (dist-upgrade will follow);"
    echo "  'N' or 'n' to continue with Debian 10 (buster) and use QEMU 3 instead of 4;"
    echo "  'Q' or 'q', or anything else, to exit."
    read yn
    case $yn in
        [Yy] )
            backup_sources_list
            modified_sources_list_content > $SOURCES_LIST
            ;;
        [Nn] )
            ;;
        * )
            exit
    esac
    apt-get update
    apt-get -y dist-upgrade
    apt-get -y upgrade
    apt-get -y autoremove
fi

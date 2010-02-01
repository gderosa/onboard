#!/bin/sh
LANG='en_US.UTF-8' \
	thin -C config.yml -R config.ru start

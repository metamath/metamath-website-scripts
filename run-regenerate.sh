#!/bin/sh
# run-regenerate - run regenerate-website as user "generator"
# This is helpful in debugging run-regenerate

cp -p /root/regenerate-website.sh /home/generator/
runuser -u generator -- '/home/generator/regenerate-website.sh'

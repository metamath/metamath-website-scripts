#!/bin/sh
# run-regenerate - run regenerate-website as user "generator"
# This is helpful in debugging run-regenerate

cp -p /root/regenerate-website.sh /home/generator/
cp -p /root/build-website.sh /home/generator/

# Note: regenerate-website.sh runs build-website.sh

runuser -u generator -- '/home/generator/regenerate-website.sh'

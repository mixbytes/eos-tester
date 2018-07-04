#!/bin/bash

mkdir -p /opt/eos-tester
cp eos-tester.sh /opt/eos-tester
cp -r scripts /opt/eos-tester

ln -s /opt/eos-tester/eos-tester.sh /usr/bin/eos-tester

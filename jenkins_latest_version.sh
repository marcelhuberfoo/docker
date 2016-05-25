#!/bin/sh

curl -sSL http://repo.jenkins-ci.org/public/org/jenkins-ci/main/jenkins-war/maven-metadata.xml | sed -n -r 's/.*<latest>([^<]+).*$/\1/p'

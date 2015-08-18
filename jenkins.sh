#! /bin/bash

set -e

# Copy files from $JENKINS_REFDIR into JENKINS_HOME
# So the initial JENKINS_HOME is set with expected content. 
# Don't override, as this is just a reference setup, and use from UI 
# can then change this, upgrade plugins, etc.
copy_reference_file() {
  f=${1%/} 
  echo " processing [$f]" >> $REFCOPY_LOGFILE
  rel=${f#$JENKINS_REFDIR/}
  dir=$(dirname ${rel})
  if [[ ! -e $JENKINS_HOME/${rel} ]] 
  then
    echo "  COPYING [$rel] to [$JENKINS_HOME/$dir]" >> $REFCOPY_LOGFILE
    mkdir -p $JENKINS_HOME/$dir
    cp -p $JENKINS_REFDIR/$rel $JENKINS_HOME/$dir;
    # pin plugins on initial copy
    [[ $rel == plugins/*.jpi ]] && touch $JENKINS_HOME/${rel}.pinned
  fi; 
}
export -f copy_reference_file
echo "--- Copying files at $(date)" >> $REFCOPY_LOGFILE
find $JENKINS_REFDIR/ -type f -exec bash -c "copy_reference_file '{}'" \;

# if `docker run` first argument start with `--` the user is passing jenkins launcher arguments
if [[ $# -lt 1 ]] || [[ "$1" == "--"* ]]; then
  eval exec java $JAVA_OPTS -jar $JENKINS_INSTALLDIR/jenkins.war $JENKINS_OPTS "$@"
fi

# As argument is not jenkins, assume user want to run his own process, for sample a `bash` shell to explore this image
exec "$@"


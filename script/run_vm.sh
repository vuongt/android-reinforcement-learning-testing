#!/usr/bin/env bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPTDIR=/home/vagrant/scripts/
APPDIR=/home/vagrant/subjects/
RESULTDIR=/vagrant/results/`hostname`/mytool2h/

TOOLDIR=/vagrant/android-reinforcement-learning-testing

STEP=25
EP=200

source $SCRIPTDIR/env.sh

cd $APPDIR

#for p in `ls -d */`; do
for p in `cat $DIR/projects2.txt`; do

    echo "Setting up AVD"
    cd $SCRIPTDIR
    ./setupEmu.sh android-19

    echo "@@@@@@ Processing project " $p "@@@@@@@"
    mkdir -p $RESULTDIR$p
    cd $APPDIR$p
    echo "** BUILDING APP " $p
    #ant clean
    #ant emma debug install &> $RESULTDIR$p/build.log
    ant installd &> $RESULTDIR$p/install.log
    cp bin/coverage.em $RESULTDIR$p/
    app=`ls bin/*-debug.apk`
    echo "** PROCESSING APP " $app
    package=`aapt d xmltree $app AndroidManifest.xml | grep package | awk 'BEGIN {FS="\""}{print $2}'`

    echo "** RUNNING LOGCAT"
    adb logcat &> $RESULTDIR$p/mytool.logcat &

    echo "** DUMPING INTERMEDIATE COVERAGE "
    cd $SCRIPTDIR
    ./dumpCoverage.sh $RESULTDIR$p &> $RESULTDIR$p/icoverage.log &

    echo "** RUNNING MY TOOL FOR" $package
    #cd $TOOLDIR
    # . ./venv/bin/activate
    cd $TOOLDIR/src
    timeout 2h python main.py emulator-5554 $package $STEP $EP


    echo "-- FINISHED RUNNING MY TOOL"
    adb shell am broadcast -a edu.gatech.m3.emma.COLLECT_COVERAGE
    adb pull /mnt/sdcard/coverage.ec $RESULTDIR$p/coverage.ec

    NOW=$(date +"%m-%d-%Y-%H-%M")
    echo $NOW.$p >> $RESULTDIR/status.log

    killall dumpCoverage.sh
    killall adb

    cd $DIR
    mv ../src/mytool.log $RESULTDIR$p/

done
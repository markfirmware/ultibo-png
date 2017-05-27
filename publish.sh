#/bin/bash

cd  ../a4fbe0b0aea9f0589eee2898dd0d23d4

git rm *.png
cp -a ../ultibo-png/PNGTest.lpr .
cp -a ../ultibo-png/run-qemu.sh .
cp -a ../ultibo-png/*screen*.png .
git add .
git commit -am .
git push

cd ~/github.com/markfirmware/ultibo-png

#/bin/bash

cd  ../1eb7ab5c97078c751435b1ec806fc61e

git rm *.png
cp -a ../ultibo-png/PNGTest.lpr .
cp -a ../ultibo-png/uCanvas.pas .
cp -a ../ultibo-png/*screen*.png .
git add .
git commit -am .
git push

cd ~/github.com/markfirmware/ultibo-png

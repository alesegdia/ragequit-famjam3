
make win
mv ../bin/RAGEQUIT[win].zip ~/Dropbox/Public/rqwin.zip
# zip ~/Dropbox/Public/rqwin.zip cajitas.json spawns.json gameparms.json

./makelove

# cd ..
# rm ~/Dropbox/Public/rqlin.zip
# zip ~/Dropbox/Public/rqlin.zip ragequit.love
cp ../ragequit.love ~/Dropbox/Public/rqlin.love
# cd project
# zip ~/Dropbox/Public/rqlin.zip cajitas.json spawns.json gameparms.json

echo "WINDOWS"
dropbox puburl ~/Dropbox/Public/rqwin.zip
echo "LINUX"
dropbox puburl ~/Dropbox/Public/rqlin.love

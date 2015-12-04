#!/bin/bash

PKG=$1
VERS=$2
BIN=$3
if [ "x$BIN" = "x" ]; then
  BIN=$1
fi

if [ ! -f involucro ]; then
  wget https://storage.googleapis.com/involucro-1149.appspot.com/involucro
  chmod u+x involucro
fi

cat > invfile.lua <<EOF

inv.task('build')
  .using('busybox')
    .run('mkdir', '-p', 'dist')
  .using('thriqon/linuxbrew-alpine')
    .withConfig({entrypoint = {"/bin/sh", "-c"}})
    .withHostConfig({binds = {"./dist:/root/brew/Cellar"}})
    .run('/root/brew/bin/brew install $PKG && /root/brew/bin/brew test $PKG')
  .wrap('dist').inImage('mwcampbell/muslbase-runtime')
    .at("/root/brew/Cellar")
    .withConfig({entrypoint = {"/root/brew/Cellar/$PKG/$VERS/bin/$BIN"}})
    .as('thriqon/mulled:$PKG')
  .using('busybox')
    .run('rm', '-rf', 'dist')
EOF

./involucro build

#!/bin/bash

PKG=$1
VERS=$2
EXEC=$3
if [ "x$EXEC" = "x" ]; then
  EXEC=$1
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
    .at("/cellar")
    .withConfig({entrypoint = {"/cellar/$PKG/$VERS/bin/$EXEC"}})
    .as('thriqon/mulled:$PKG')
  .using('busybox)
    .run('rm', '-rf', 'dist')
EOF

./involucro build

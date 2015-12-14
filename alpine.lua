
extractInfo = 'apk info -wd  ' .. ENV.PACKAGE .. [==[
| (
  read fline ;
        echo -n '{"version":"' ;
        echo $fline | cut -d" " -f1 | cut -d"-" -f 2-3 | tr '\n' '"';

  echo -n ', "description": "'; read desc; echo -n $desc ;

  read discard ;
  read discard ;
  
  read homepage ; echo '", "homepage": "'$homepage'"}'
) > /info/info.json
]==]

inv.task('build')
        .using('busybox')
                .run('mkdir', '-p', 'dist', 'info')
        .using('alpine')
                .run('apk', '--root', '/source/dist',
                        '--update-cache',
                        '--repository', 'http://dl-4.alpinelinux.org/alpine/v3.2/main',
                        '--keys-dir', '/etc/apk/keys',
                        '--initdb',
                        'add', ENV.PACKAGE)

                .withHostConfig({binds = {"./info:/info"}})
                .withConfig({entrypoint = {"/bin/sh", "-c"}})
                .run(extractInfo)
        .using('busybox')
                .run('rm', '-rf', 'dist/lib/apk', 'dist/var/cache/apk/')

inv.task('package')
        .wrap('dist').at('/')
        .withConfig({cmd = {"/usr/bin/" .. ENV.BINARY}})
        .as('thriqon/mulled:' .. ENV.PACKAGE)

inv.task('clean')
        .using('busybox')
                .run('rm', '-rf', 'dist', 'info')

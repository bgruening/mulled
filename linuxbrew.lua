
inv.task('build')
  .using('busybox')
    .run('mkdir', '-p', 'dist/bin')
  .using('thriqon/linuxbrew-alpine')
    .withConfig({
      entrypoint = {"/bin/sh", "-c"},
      env = {
        "BREW=/root/brew/orig_bin/brew"
      }
    })
    .withHostConfig({binds = {
      "./dist/bin:/root/brew/bin",
      "./dist/Cellar:/root/brew/Cellar"
    }})
    .run('$BREW install ' .. ENV.PACKAGE .. ' && $BREW test ' .. ENV.PACKAGE)

inv.task('package')
  .wrap('dist').inImage('mwcampbell/muslbase-runtime')
    .at("/root/brew/")
    .withConfig({entrypoint = {"/root/brew/bin/" .. ENV.BINARY}})
    .as('thriqon/mulled:' .. ENV.PACKAGE)

inv.task('clean')
  .using('busybox')
    .run('rm', '-rf', 'dist')

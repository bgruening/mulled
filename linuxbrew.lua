
builder = inv.task('build')
  .using('busybox')
    .run('mkdir', '-p', 'dist/bin')
    .run('mkdir', '-p', 'info')

  .using('thriqon/linuxbrew-alpine')
    .withConfig({
      entrypoint = {"/bin/sh", "-c"},
      env = {
        "BREW=/root/brew/orig_bin/brew"
      }
    })
    .withHostConfig({binds = {
      "./dist/bin:/root/brew/bin",
      "./dist/Cellar:/root/brew/Cellar",
      "./info:/info"
    }})
if ENV.ADDITIONAL_PACKAGES ~= "" then
  builder.run('$BREW install ' .. ENV.ADDITIONAL_PACKAGES)
end
builder
    .run('$BREW install ' .. ENV.PACKAGE)
    .run('$BREW test ' .. ENV.PACKAGE)
    .run('$BREW info --json=v1 ' .. ENV.PACKAGE .. ' | jq ".[0]" | ' .. 
        'jq "{homepage: .homepage, description: .desc, version: .versions.stable}" > /info/info.json')

inv.task('package')
  .wrap('dist').inImage('mwcampbell/muslbase-runtime')
    .at("/root/brew/")
    .withConfig({entrypoint = {"/root/brew/bin/" .. ENV.BINARY}})
    .as('thriqon/mulled:' .. ENV.PACKAGE)

inv.task('clean')
  .using('busybox')
    .run('rm', '-rf', 'dist')
    .run('rm', '-rf', 'info')

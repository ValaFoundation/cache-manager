cache_manager_sources = files(
  'cache_item.vala',
  'cache.vala',
)

cache_manager_deps = [
  dependency('glib-2.0'),
  dependency('gio-2.0'),
  dependency('gee-0.8'),
]

subdir('simple')

cache_manager_shared = shared_library(
  meson.project_name(),
  cache_manager_sources,
  dependencies: cache_manager_deps,
  install: true,
  vala_vapi: 'vapi/' + meson.project_name() + '.vapi',
  vala_header: meson.project_name() + '.h'
)

cache_manager_dep = declare_dependency(
  link_with: cache_manager_shared,
  include_directories: include_directories('.'),
)

pkg = import('pkgconfig')
pkg.generate(
  cache_manager_shared,
  version: meson.project_version(),
  name: meson.project_name(),
  filebase: meson.project_name(),
  description: 'Vala Library Template.'
)

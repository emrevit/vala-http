project(
  'vala-http',
  'vala',
)

http_deps = [
  dependency('glib-2.0'),
  dependency('gobject-2.0'),
  dependency('gee-0.8'),
  dependency('gio-2.0')
]

http_lib = shared_library(
  'http',
  'src/http.vala',
  vala_header: 'http.h',
  vala_vapi: 'http.vapi',
  dependencies: http_deps,
  install: true
)

executable(
  'http-get',
  'examples/http-get.vala',
  link_with: http_lib,
  dependencies: http_deps,
)

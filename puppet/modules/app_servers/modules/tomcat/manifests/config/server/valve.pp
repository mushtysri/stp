define tomcat::config::server::valve (
  $catalina_base         = undef,
  $class_name            = undef,
  $parent_host           = undef,
  $parent_service        = 'Catalina',
  $valve_ensure          = 'present',
  $additional_attributes = {},
  $attributes_to_remove  = [],
  $server_config         = undef,
) {
  include tomcat
  $_catalina_base = pick($catalina_base, $::tomcat::catalina_home)
  tag(sha1($_catalina_base))

  if versioncmp($::augeasversion, '1.0.0') < 0 {
    fail('Server configurations require Augeas >= 1.0.0')
  }

  validate_re($valve_ensure, '^(present|absent|true|false)$')
  validate_hash($additional_attributes)

  if $class_name {
    $_class_name = $class_name
  } else {
    $_class_name = $name
  }

  if $parent_host {
    $base_path = "Server/Service[#attribute/name='${parent_service}']/Engine/Host[#attribute/name='${parent_host}']/Valve[#attribute/className='${_class_name}']"
  } else {
    $base_path = "Server/Service[#attribute/name='${parent_service}']/Engine/Valve[#attribute/className='${_class_name}']"
  }

  if $server_config {
    $_server_config = $server_config
  } else {
    $_server_config = "${_catalina_base}/conf/server.xml"
  }

  if $valve_ensure =~ /^(absent|false)$/ {
    $changes = "rm ${base_path}"
  } else {
    $_class_name_change = "set ${base_path}/#attribute/className ${_class_name}"
    if ! empty($additional_attributes) {
      $_additional_attributes = suffix(prefix(join_keys_to_values($additional_attributes, " '"), "set ${base_path}/#attribute/"), "'")
    } else {
      $_additional_attributes = undef
    }
    if ! empty(any2array($attributes_to_remove)) {
      $_attributes_to_remove = prefix(any2array($attributes_to_remove), "rm ${base_path}/#attribute/")
    } else {
      $_attributes_to_remove = undef
    }

    $changes = delete_undef_values(flatten([$_class_name_change, $_additional_attributes, $_attributes_to_remove]))
  }

  augeas { "${_catalina_base}-${parent_service}-${parent_host}-valve-${_class_name}":
    lens    => 'Xml.lns',
    incl    => $_server_config,
    changes => $changes,
  }
}

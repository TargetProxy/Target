//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <flutter_alone/flutter_alone_plugin_c_api.h>
#include <proxy_manager/proxy_manager_plugin.h>
#include <targetlib/targetlib_plugin_c_api.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  FlutterAlonePluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("FlutterAlonePluginCApi"));
  ProxyManagerPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("ProxyManagerPlugin"));
  TargetlibPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("TargetlibPluginCApi"));
}

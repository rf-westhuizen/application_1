//
//  Generated file. Do not edit.
//

// clang-format off

#include "generated_plugin_registrant.h"

#include <newpos_sdk/newpos_sdk_plugin_c_api.h>
#include <pax_api_plugin/pax_api_plugin_c_api.h>
#include <sqlite3_flutter_libs/sqlite3_flutter_libs_plugin.h>

void RegisterPlugins(flutter::PluginRegistry* registry) {
  NewposSdkPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("NewposSdkPluginCApi"));
  PaxApiPluginCApiRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("PaxApiPluginCApi"));
  Sqlite3FlutterLibsPluginRegisterWithRegistrar(
      registry->GetRegistrarForPlugin("Sqlite3FlutterLibsPlugin"));
}

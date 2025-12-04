// Uncrumpled Service SDK Module
//
// This module provides the Service SDK for building services that integrate
// with the Uncrumpled Context Switcher daemon.
//
// To use this module, add the sdk directory to your import path and:
//   #import "sdk";
//
// Or import directly:
//   #load "src/sdk/client.jai";
//
// Example:
//   client: Service_Client;
//   init_service_client(*client);
//   defer deinit_service_client(*client);
//
//   if connect(*client) {
//       reg := make_registration("my-service", "My Service", "/tmp/my.sock");
//       register_service(*client, *reg);
//   }

#scope_export

#load "client.jai";

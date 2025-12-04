// API Module
//
// This module provides JSON-RPC API handlers for the daemon.
// It includes handlers for:
// - Context operations (context.*)
// - Service registration (service.*)
// - Subscription management (subscribe, unsubscribe)
// - Handshake & version negotiation (handshake)
// - Preview operations (preview.*)
// - Log queries (logs.*) - TODO

// Dependencies - these must be loaded/imported before loading this module:
// - Basic, String, Hash_Table, Thread
// - jason module
// - context_store.jai
// - rpc/module.jai (or rpc/protocol.jai)

#load "context.jai";
#load "service.jai";
#load "subscription.jai";
#load "handshake.jai";
#load "preview.jai";

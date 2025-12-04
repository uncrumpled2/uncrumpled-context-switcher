// Events Module
//
// This module provides the event dispatching system for the daemon.
// It handles dispatching events (context changes, service updates, etc.)
// to subscribed services, and manages heartbeat monitoring for
// subscribers and services.

#load "dispatcher.jai";
#load "heartbeat.jai";

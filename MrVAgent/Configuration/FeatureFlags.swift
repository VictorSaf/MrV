import Foundation

/// Centralized feature flags for development and configuration
/// Follow the pattern established by InterfaceMode.swift
enum FeatureFlags {
    /// Authentication feature flag
    /// - When `true`: Standard authentication flow with password
    /// - When `false`: Bypass authentication, go directly to VoidView
    /// - Production: true
    /// - Development: false (for faster iteration)
    static let authenticationEnabled = false
}

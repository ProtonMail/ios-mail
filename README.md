# Proton Mail iOS

**Proton Mail iOS** is the Proton Mail iOS client for encrypted email.

## Important Notice

> **This project cannot currently be built directly from the GitHub repository.**
>
> The application depends on the Proton Mail SDK, which is open sourced in a separate repository. However, the SDK integration currently relies on an internal distribution system that is not publicly accessible.
>
> We are open sourcing this project in its current state to provide transparency into our development process, even though it cannot be built externally at this time. We are working toward making the full stack buildable from open-source components.

## About

This repository contains the iOS application code for Proton Mail's Engineering Transformation initiative. The project is built using:

- **Swift** for iOS application development
- **SwiftUI** for modern user interface components
- **Rust** for core business logic and cross-platform functionality
- **Swift Package Manager** for dependency management

## Architecture

The application follows a layered architecture where the iOS client provides the user interface and platform-specific integrations, while the core business logic resides in the Proton Mail SDK written in Rust. This SDK-based approach enables:

- **Cross-platform consistency**: Business logic is shared across iOS and Android
- **Security**: Core encryption and security operations are implemented in Rust
- **Performance**: Critical operations benefit from Rust's efficiency
- **Maintainability**: Business logic is centralized in the SDK rather than duplicated across platform clients

The iOS application communicates with the Rust SDK through Swift bindings, handling UI rendering, navigation, and iOS-specific features while delegating email processing, encryption, and business rules to the SDK layer.

## Contributions

We are not currently accepting contributions through the GitHub repository.

This open-source release is intended for transparency and reference purposes.


## Internal Development

If you are a Proton team member with access to internal infrastructure, please refer to [DEVELOPMENT.md](./DEVELOPMENT.md) for setup instructions and debugging tools.

*Note: This file references private Proton infrastructure and is not included in the public repository.*

## About Proton

Proton is a privacy-focused technology company that builds secure and easy-to-use communication tools. Learn more at [proton.me](https://proton.me).

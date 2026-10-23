# Developer guide

Each component is developed in its own repository, and each README is the reference for building, testing and configuring it:

- [qsp-agent](https://github.com/Ham-QSP/qsp-agent): Rust workspace (`cargo build --workspace --locked`, `cargo test --workspace --locked`), Debian packaging under `package/`.
- [qsp-signaling-server](https://github.com/Ham-QSP/qsp-signaling-server)
- [qsp-authentication](https://github.com/Ham-QSP/qsp-authentication)
- [qsp-web](https://github.com/Ham-QSP/qsp-web)
- [qsp-proto-files](https://github.com/Ham-QSP/qsp-proto-files): shared message definitions; changes here affect several components.

The umbrella repository, [Ham-QSP/Qsp](https://github.com/Ham-QSP/Qsp), contains a `CLAUDE.md` that describes the overall architecture and the conventions used across the repositories. Read it, and the README of the repository you are changing, before you start. Check each repository for contribution notes before opening a pull request.

To get a complete instance to develop against, use the [self-hosting example](self-hosting.md).

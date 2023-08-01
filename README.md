# dotnet-builds

.NET binary builds for Haiku.

## What's included

At the time of writing, this repo currently builds a preview release of .NET 8.

- [dotnet/runtime](https://github.com/trungnt2910/dotnet-runtime): .NET Runtime, ported to Haiku.
- [dotnet/sdk](https://github.com/trungnt2910/dotnet-sdk): .NET SDK, ported to Haiku.
- [dotnet/msbuild](https://github.com/trungnt2910/dotnet-msbuild): MSBuild, configured to recognize Haiku.

Other components, notably ASP.NET and NativeAOT are not supported yet.

## Installation

- Install dependencies:
```sh
pkgman install -y gmp krb5 libiconv llvm12_libunwind mpfr
pkgman install -y jq # Required for the dotnet-install script.
```
- Run the dotnet-install.sh script:
```sh
bash -c "$(curl -fsSL https://raw.githubusercontent.com/trungnt2910/dotnet-builds/HEAD/dotnet-install.sh)" -- --install-dir=/path/to/where/you/want/to/install/dotnet
```
- Add the .NET installation folder to the system's `$PATH`.
- Add a custom NuGet source containing essential Haiku-specific packages. `your_github_token` should be a [personal access token](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-nuget-registry#authenticating-to-github-packages) with at least the `read:packages` permission:
```sh
dotnet nuget add source --username your_github_username --password your_github_token --store-password-in-clear-text --name dotnet_haiku_nuget "https://nuget.pkg.github.com/trungnt2910/index.json"
```
- Now you can carry out the basic steps to create a "Hello, World!" application:
```sh
mkdir helloworld
cd helloworld
dotnet new console
dotnet run
```

## Build frequency

This repository will be built:
- At the start of every week to keep track of Haiku updates.
- Whenever the default branch (currently `haiku-dotnet8`) of any of the repositories mentioned above is pushed.
- Whenever the default branch (`master`) of this repository is pushed.
- Whenever [@trungnt2910](https://github.com/trungnt2910) wants to create a new release.

## FAQs

### Why do I need a GitHub token to install public packages?

For some weird reasons, GitHub NuGet feeds [require](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-nuget-registry#authenticating-to-github-packages) authentication, even for public packages.

### Why are the packages published on GitHub instead of NuGet?

The packages involved cannot be published on [nuget.org](https://nuget.org) because their names start with `Microsoft.`, and that prefix is [reserved](https://learn.microsoft.com/en-us/nuget/nuget-org/id-prefix-reservation). If there are any better free NuGet package hosting options, please let me know by opening an issue.

### Why are you telling me to store my password in clear text?

This is not a malicious attempt to expose your GitHub token, but a technical limitation by .NET:

```
error: Password encryption is not supported on .NET Core for this platform. The following feed try to use an encrypted password: 'dotnet_haiku_nuget'. You can use a clear text password as a workaround.
error:   Encryption is not supported on non-Windows platforms.
```

### Will there be a HaikuPorts recipe and `.hpkg` packages?

Not in the near future, because:
- The current branch is using a prerelease version of .NET 8.
- Many PRs are waiting to get merged upstream.
- No official documentation (at least, not among the ones I know) on how to create packages that have themselves as a build prerequisite.
- Unconventional installation layout. All of .NET lives in one directory, and it should be writable so that additional workloads or other optional components can be installed through NuGet, instead of being divided into `/bin`, `/lib`, etc. like other UNIX applications.

More discussion can be found in [this](https://discuss.haiku-os.org/t/gsoc-2023-net-port/13237/44) forum comment and the following ones.

## License

.NET binary releases and artifacts belong to the .NET Foundation and Contributors, and are covered by the [MIT License](https://github.com/dotnet/runtime/blob/main/LICENSE.TXT).

Scripts and documentation in this repository (C) 2023 Trung Nguyen. All rights reserved.

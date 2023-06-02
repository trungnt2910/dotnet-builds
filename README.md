# dotnet-builds

.NET binary builds for Haiku.

## What's included

At the time of writing, this repo currently builds a preview release of .NET 8.

- [dotnet/runtime](https://github.com/trungnt2910/dotnet-runtime): .NET Runtime, ported to Haiku.
- [dotnet/sdk](https://github.com/trungnt2910/dotnet-sdk): .NET SDK, ported to Haiku.

Other components, notably ASP.NET and NativeAOT are not supported yet.

## Installation

- Download a copy of `net8-haiku-x64-<randomly seeming build number>.tar.gz` from the latest [release](https://github.com/trungnt2910/dotnet-builds/releases/latest).
- Extract the archive to any folder and add it to the system's `$PATH`.
- Add some hack environment variables mentioned [here](https://discuss.haiku-os.org/t/gsoc-2023-net-port/13237/39) to the `dotnet` binary:
```sh
addattr SYS:ENV "DOTNET_SYSTEM_NET_DISABLEIPV6=1\\0COMPlus_EnableWriteXorExecute=0" /path/to/where/you/extract/the/zip/file/dotnet
```
- Add a custom NuGet source containing essential Haiku-specific packages. `your_github_token` should be a [personal access token](https://docs.github.com/en/packages/working-with-a-github-packages-registry/working-with-the-nuget-registry#authenticating-to-github-packages) with at least the `read:packages` permission.
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

### Why is `dotnet` so slow on Haiku compared to running on other platforms?

Don't ask me, ask whoever's responsible for Haiku's virtual memory code.

If you want a more serious answer, look at this `strace`:

```
/Data> strace -c /Data/dotnet/dotnet --version
8.0.100-preview.6.23303.2

Time % Usecs      Calls   Usecs/call Syscall
------ ---------- ------- ---------- --------------------
 51.59    1374087    7096        193 _kern_get_clock
 26.63     709385    4263        166 _kern_set_memory_protection
  5.37     142989      82       1743 _kern_map_file
  4.15     110445      30       3681 _kern_debug_output
  3.95     105204     652        161 _kern_mutex_unlock
  2.49      66350     493        134 _kern_read_stat
  1.57      41705     509         81 _kern_get_next_image_info
  0.54      14421     144        100 _kern_read
  0.38      10101      92        109 _kern_open
  0.37       9966      63        158 _kern_normalize_path
  0.37       9884      28        353 _kern_mutex_switch_lock
  0.37       9874      61        161 _kern_resize_area
  0.31       8299      75        110 _kern_fcntl
  0.18       4848      51         95 _kern_close
  0.18       4748      20        237 _kern_spawn_thread
  0.12       3104      20        155 _kern_resume_thread
[some entries omitted]
```

`_kern_get_clock` is heavily used in Debug builds. Release builds are currently unstable and have weird bugs like [this one](https://github.com/dotnet/runtime/issues/55803#issuecomment-1547175040).

The real problem here lies in `_kern_set_memory_protection`, something heavily used by both Debug and Release builds. `_kern_map_file` also has an unacceptably high average processing time.

## License

.NET binary releases and artifacts belong to the .NET Foundation and Contributors, and are covered by the [MIT License](https://github.com/dotnet/runtime/blob/main/LICENSE.TXT).

Scripts and documentation in this repository (C) 2023 Trung Nguyen. All rights reserved.

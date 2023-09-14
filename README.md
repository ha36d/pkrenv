![CI](https://github.com/ha36d/pkrenv/actions/workflows/test.yml/badge.svg)

# pkrenv

[Packer](https://www.packer.io/) version manager inspired by [tfenv](https://github.com/tfutils/tfenv)

## Support

Currently pkrenv supports the following OSes

- macOS
  - 64bit
  - Arm (Apple Silicon)
- Linux
  - 64bit
  - Arm
- Windows (64bit) - only tested in git-bash - currently presumed failing due to symlink issues in git-bash

## Installation

### Automatic

Install via Homebrew

```console
$ brew tap ha36d/tap
$ brew install pkrenv
```

Install via Arch User Repository (AUR)
   
```console
$ yay --sync pkrenv
```

Install via puppet

Using puppet module [sergk-pkrenv](https://github.com/SergK/puppet-pkrenv)

```puppet
include ::pkrenv
```

### Manual

1. Check out pkrenv into any path (here is `${HOME}/.pkrenv`)

```console
$ git clone --depth=1 https://github.com/ha36d/pkrenv.git ~/.pkrenv
```

2. Add `~/.pkrenv/bin` to your `$PATH` any way you like

```console
$ echo 'export PATH="$HOME/.pkrenv/bin:$PATH"' >> ~/.bash_profile
```

  For WSL users
```bash
$ echo 'export PATH=$PATH:$HOME/.pkrenv/bin' >> ~/.bashrc
```

  OR you can make symlinks for `pkrenv/bin/*` scripts into a path that is already added to your `$PATH` (e.g. `/usr/local/bin`) `OSX/Linux Only!`

```console
$ ln -s ~/.pkrenv/bin/* /usr/local/bin
```

  On Ubuntu/Debian touching `/usr/local/bin` might require sudo access, but you can create `${HOME}/bin` or `${HOME}/.local/bin` and on next login it will get added to the session `$PATH`
  or by running `. ${HOME}/.profile` it will get added to the current shell session's `$PATH`.

```console
$ mkdir -p ~/.local/bin/
$ . ~/.profile
$ ln -s ~/.pkrenv/bin/* ~/.local/bin
$ which pkrenv
```

## Usage

### pkrenv install [version]

Install a specific version of Packer.

If no parameter is passed, the version to use is resolved automatically via [PKRENV\_PACKER\_VERSION environment variable](#pkrenv_packer_version) or [.packer-version files](#packer-version-file), in that order of precedence, i.e. PKRENV\_PACKER\_VERSION, then .packer-version. The default is 'latest' if none are found.

If a parameter is passed, available options:

- `x.y.z` [Semver 2.0.0](https://semver.org/) string specifying the exact version to install
- `latest` is a syntax to install latest version
- `latest:<regex>` is a syntax to install latest version matching regex (used by grep -e)
- `latest-allowed` is a syntax to scan your Packer files to detect which version is maximally allowed.
- `min-required` is a syntax to scan your Packer files to detect which version is minimally required.

See [required_version](https://www.packer.io/docs/configuration/packer.html) docs. Also [see min-required & latest-allowed](#min-required) section below.

```console
$ pkrenv install
$ pkrenv install 1.9.0
$ pkrenv install latest
$ pkrenv install latest:^1.9
$ pkrenv install latest-allowed
$ pkrenv install min-required
```

If `shasum` is present in the path, pkrenv will verify the download against Hashicorp's published sha256 hash.
If [keybase](https://keybase.io/) is available in the path it will also verify the signature for those published hashes using Hashicorp's published public key.

You can opt-in to using GnuPG tools for PGP signature verification if keybase is not available:

Where `PKRENV_INSTALL_DIR` is for example, `~/.pkrenv` or `/usr/local/Cellar/pkrenv/<version>`

```console
$ echo 'trust-pkrenv: yes' > ${PKRENV_INSTALL_DIR}/use-gpgv
$ pkrenv install
```

The `trust-pkrenv` directive means that verification uses a copy of the
Hashicorp OpenPGP key found in the pkrenv repository.  Skipping that directive
means that the Hashicorp key must be in the existing default trusted keys.
Use the file `${PKRENV_INSTALL_DIR}/use-gnupg` to instead invoke the full `gpg` tool and
see web-of-trust status; beware that a lack of trust path will not cause a
validation failure.

#### .packer-version

If you use a [.packer-version](#packer-version-file) file, `pkrenv install` (no argument) will install the version written in it.

<a name="min-required"></a>
#### min-required & latest-allowed

Please note that we don't do semantic version range parsing but use first ever found version as the candidate for minimally required one. It is up to the user to keep the definition reasonable. I.e.

```packer
// this will detect 0.12.3
packer {
  required_version  = "<0.12.3, >= 0.10.0"
}
```

```packer
// this will detect 0.10.8 (the latest 0.10.x release)
packer {
  required_version  = "~> 0.10.0, <0.12.3"
}
```

### Environment Variables

#### PKRENV

##### `PKRENV_ARCH`

String (Default: `amd64`)

Specify architecture. Architecture other than the default amd64 can be specified with the `PKRENV_ARCH` environment variable

Note: Default changes to `arm64` for versions that have arm64 builds available when `$(uname -m)` matches `aarch64* | arm64*`

```console
$ PKRENV_ARCH=arm64 pkrenv install 0.7.9
```

##### `PKRENV_AUTO_INSTALL`

String (Default: true)

Should pkrenv automatically install packer if the version specified by defaults or a .packer-version file is not currently installed.

```console
$ PKRENV_AUTO_INSTALL=false packer plan
```

```console
$ packer use <version that is not yet installed>
```

##### `PKRENV_CURL_OUTPUT`

Integer (Default: 2)

Set the mechanism used for displaying download progress when downloading packer versions from the remote server.

* 2: v1 Behaviour: Pass `-#` to curl
* 1: Use curl default
* 0: Pass `-s` to curl

##### `PKRENV_DEBUG`

Integer (Default: 0)

Set the debug level for PKRENV.

* 0: No debug output
* 1: Simple debug output
* 2: Extended debug output, with source file names and interactive debug shells on error
* 3: Debug level 2 + Bash execution tracing

##### `PKRENV_REMOTE`

String (Default: https://releases.hashicorp.com)

To install from a remote other than the default

```console
$ PKRENV_REMOTE=https://example.jfrog.io/artifactory/hashicorp
```

##### `PKRENV_REVERSE_REMOTE`

Integer (Default: 0)

When using a custom remote, such as Artifactory, instead of the Hashicorp servers,
the list of packer versions returned by the curl of the remote directory may be inverted.
In this case the `latest` functionality will not work as expected because it expects the
versions to be listed in order of release date from newest to oldest. If your remote
is instead providing a list that is oldes-first, set `PKRENV_REVERSE_REMOTE=1` and
functionality will be restored.

```console
$ PKRENV_REVERSE_REMOTE=1 pkrenv list-remote
```

##### `PKRENV_CONFIG_DIR`

Path (Default: `$PKRENV_ROOT`)

The path to a directory where the local packer versions and configuration files exist.

```console
PKRENV_CONFIG_DIR="$XDG_CONFIG_HOME/pkrenv"
```

##### `PKRENV_PACKER_VERSION`

String (Default: "")

If not empty string, this variable overrides Packer version, specified in [.packer-version files](#packer-version-file).
`latest` and `latest:<regex>` syntax are also supported.
[`pkrenv install`](#pkrenv-install-version) and [`pkrenv use`](#pkrenv-use-version) command also respects this variable.

e.g.

```console
$ PKRENV_PACKER_VERSION=latest:^0.11. packer --version
```

##### `PKRENV_NETRC_PATH`

String (Default: "")

If not empty string, this variable specifies the credentials file used to access the remote location (useful if used in conjunction with PKRENV_REMOTE).

e.g.

```console
$ PKRENV_NETRC_PATH="$PWD/.netrc.pkrenv"
```

#### Bashlog Logging Library

##### `BASHLOG_COLOURS`

Integer (Default: 1)

To disable colouring of console output, set to 0.


##### `BASHLOG_DATE_FORMAT`

String (Default: +%F %T)

The display format for the date as passed to the `date` binary to generate a datestamp used as a prefix to:

* `FILE` type log file lines.
* Each console output line when `BASHLOG_EXTRA=1`

##### `BASHLOG_EXTRA`

Integer (Default: 0)

By default, console output from pkrenv does not print a date stamp or log severity.

To enable this functionality, making normal output equivalent to FILE log output, set to 1.

##### `BASHLOG_FILE`

Integer (Default: 0)

Set to 1 to enable plain text logging to file (FILE type logging).

The default path for log files is defined by /tmp/$(basename $0).log
Each executable logs to its own file.

e.g.

```console
$ BASHLOG_FILE=1 pkrenv use latest
```

will log to `/tmp/pkrenv-use.log`

##### `BASHLOG_FILE_PATH`

String (Default: /tmp/$(basename ${0}).log)

To specify a single file as the target for all FILE type logging regardless of the executing script.

##### `BASHLOG_I_PROMISE_TO_BE_CAREFUL_CUSTOM_EVAL_PREFIX`

String (Default: "")

*BE CAREFUL - MISUSE WILL DESTROY EVERYTHING YOU EVER LOVED*

This variable allows you to pass a string containing a command that will be executed using `eval` in order to produce a prefix to each console output line, and each FILE type log entry.

e.g.

```console
$ BASHLOG_I_PROMISE_TO_BE_CAREFUL_CUSTOM_EVAL_PREFIX='echo "${$$} "'
```
will prefix every log line with the calling process' PID.

##### `BASHLOG_JSON`

Integer (Default: 0)

Set to 1 to enable JSON logging to file (JSON type logging).

The default path for log files is defined by /tmp/$(basename $0).log.json
Each executable logs to its own file.

e.g.

```console
$ BASHLOG_JSON=1 pkrenv use latest
```

will log in JSON format to `/tmp/pkrenv-use.log.json`

JSON log content:

`{"timestamp":"<date +%s>","level":"<log-level>","message":"<log-content>"}`

##### `BASHLOG_JSON_PATH`

String (Default: /tmp/$(basename ${0}).log.json)

To specify a single file as the target for all JSON type logging regardless of the executing script.

##### `BASHLOG_SYSLOG`

Integer (Default: 0)

To log to syslog using the `logger` binary, set this to 1.

The basic functionality is thus:

```console
$ local tag="${BASHLOG_SYSLOG_TAG:-$(basename "${0}")}";
$ local facility="${BASHLOG_SYSLOG_FACILITY:-local0}";
$ local pid="${$}";
$ logger --id="${pid}" -t "${tag}" -p "${facility}.${severity}" "${syslog_line}"
```

##### `BASHLOG_SYSLOG_FACILITY`

String (Default: local0)

The syslog facility to specify when using SYSLOG type logging.

##### `BASHLOG_SYSLOG_TAG`

String (Default: $(basename $0))

The syslog tag to specify when using SYSLOG type logging.

Defaults to the PID of the calling process.



### pkrenv use [version]

Switch a version to use

If no parameter is passed, the version to use is resolved automatically via [.packer-version files](#packer-version-file) or [PKRENV\_PACKER\_VERSION environment variable](#pkrenv_packer_version) (PKRENV\_PACKER\_VERSION takes precedence), defaulting to 'latest' if none are found.

`latest` is a syntax to use the latest installed version

`latest:<regex>` is a syntax to use latest installed version matching regex (used by grep -e)

`min-required` will switch to the version minimally required by your packer sources (see above `pkrenv install`)

```console
$ pkrenv use
$ pkrenv use min-required
$ pkrenv use 1.9.0
$ pkrenv use latest
$ pkrenv use latest:^0.8
```

Note: `pkrenv use latest` or `pkrenv use latest:<regex>` will find the latest matching version that is already installed. If no matching versions are installed, and PKRENV_AUTO_INSTALL is set to `true` (which is the default) the the latest matching version in the remote repository will be installed and used.

### pkrenv uninstall &lt;version>

Uninstall a specific version of Packer
`latest` is a syntax to uninstall latest version
`latest:<regex>` is a syntax to uninstall latest version matching regex (used by grep -e)

```console
$ pkrenv uninstall 1.9.0
$ pkrenv uninstall latest
$ pkrenv uninstall latest:^1.9
```

### pkrenv list

List installed versions

```console
$ pkrenv list
* 1.9.3 (set by /opt/pkrenv/version)
  1.7.10
```

### pkrenv list-remote

List installable versions

```console
$ pkrenv list-remote
1.9.3
1.9.2
1.9.1
1.9.0
1.9.0-alpha
1.8.7
1.8.6
1.8.5
1.8.4
1.8.3
1.8.2
1.8.1
1.8.0
1.7.10
1.7.9
1.7.8
1.7.7
1.7.6
1.7.5
1.7.4
1.7.3
1.7.2
1.7.1
1.7.0
1.6.6
1.6.5
1.6.4
1.6.3
1.6.2
1.6.1
1.6.0
1.5.6
1.5.5
1.5.4
1.5.3
1.5.2
1.5.1
1.5.0
1.4.5
1.4.4
1.4.3
1.4.2
1.4.1
1.4.0
1.3.5
1.3.4
1.3.3
1.3.2
1.3.1
1.3.0
1.2.5
1.2.4
1.2.3
1.2.2
1.2.1
1.2.0
1.1.3
1.1.2
1.1.1
1.1.0
1.0.4
1.0.3
1.0.2
1.0.1
1.0.0
0.12.3
0.12.2
0.12.1
0.12.0
0.11.0
0.10.2
0.10.1
0.10.0
0.9.0
0.8.6
0.8.5
0.8.3
0.8.2
0.8.1
0.8.0
0.7.5
0.7.2
0.7.1
0.7.0
0.6.1
0.6.0
0.5.2
0.5.1
0.5.0
0.4.1
0.4.0
0.3.11
0.3.10
0.3.9
0.3.8
0.3.7
0.3.6
0.3.5
0.3.4
0.3.3
0.3.2
0.3.1
0.3.0
0.2.3
0.2.2
0.2.1
0.2.0
0.1.5
0.1.4
0.1.3
0.1.2
0.1.1
0.1.0
...
```

## .packer-version file

If you put a `.packer-version` file on your project root, or in your home directory, pkrenv detects it and uses the version written in it. If the version is `latest` or `latest:<regex>`, the latest matching version currently installed will be selected.

Note, that [PKRENV\_PACKER\_VERSION environment variable](#pkrenv_packer_version) can be used to override version, specified by `.packer-version` file.

```console
$ cat .packer-version
0.6.16

$ packer version
Packer v0.6.16

Your version of Packer is out of date! The latest version
is 0.7.3. You can update by downloading from www.packer.io

$ echo 0.7.3 > .packer-version

$ packer version
Packer v0.7.3

$ echo latest:^0.8 > .packer-version

$ packer version
Packer v0.8.8

$ PKRENV_PACKER_VERSION=0.7.3 packer --version
Packer v0.7.3
```

## Upgrading

```console
$ git --git-dir=~/.pkrenv/.git pull
```

## Uninstalling

```console
$ rm -rf /some/path/to/pkrenv
```

## LICENSE

- [tfenv](https://github.com/tfutils/tfenv/blob/master/LICENSE)
- [rbenv](https://github.com/rbenv/rbenv/blob/master/LICENSE)
  - pkrenv partially uses rbenv's and tfenv's source code

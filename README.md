# envy
stackable and composable `sh` profiles

`envy` is a script that enables a POSIX User Portability Utilities Shell to source multiple profiles, and share definitions between them.
these constructs are useful for automation and resource sharing in both interactive and non-interactive environments.

## Synopsis

```sh
envy [path/to/profile/env.sh] [...]
```

## Examples

```sh
$ cat path/to/profile/a.sh
$ cat path/to/profile/b.sh
$ envy path/to/profile/a.sh path/to/profile/b.sh
```

## Environment Variables

`ENVS` is an `IFS` delimited list of profile paths to source.

`ENV` is the same environment variable received by the POSIX User Portability Utilities Shell.
its default value `envy.sh` is an entrypoint that loads the profiles in `ENVS`.
this entrypoint can be extended with its own utility functions, in the same manner as other profiles.

## POSIX Shell Functions

the `envf` function is used to define and override shell functions:

```sh
envf fname -<<'EOT'
  echo parent
  if [ $# -gt 0 ]; then
    echo $@
    shift
    fname "$@"
  fi
  EOT

envf fname -<<'EOT'
  echo child
  if [ $# -gt 3 ]; then
    echo $1
    shift
    fname $@
  else
    $envf_ "$@"
  fi
  EOT

fname 1 2 3 4 5
```

these definitions are then evaluated as follows:

```
fname_ = 0

fname_0 () {
  echo parent
  if [ $# -gt 0 ]; then
    echo $@
    shift
    fname "$@"
  fi
}

fname () {
  fname_0 "$@"
}

fname_1 () {
  fname_prev = "fname_0"
  echo child
  if [ $# -gt 3 ]l then
    echo $1
    shift
    fname $@
  else
    $fname_prev "$@"
  fi
  unset fname_prev
}

fname () {
  fname_1 "$@"
}
```

as seen above, `$envf_` calls the extended implementation `fname_0` from the extention implementation `fname_1`, and `$envf__` calls the current implementation recursively.

the `envc` function is used to document and configure completions for functions defined with `envf`:

the `envs` function is used to source profiles with the working directory set to their dirname:

```sh
$ cat enva.sh
$ cat dirb/envb.sh
$ cat dirb/dirc/envc.sh
$ . enva.sh

```

## Advanced:

this following example is a replacement `ENV` that extends `envs` to interactively review each profile the first time it is sourced, and then sign it with with `ssh-keygen`:

```sh
SAFE_ENVS=${ENVS}
ENVS=
. "${0}.sh"

envf envs-<<'EOT'
  for p in "$@"; do
    echo todo
    read y/N
    if [ review = "y" ]; then
      "${EDITOR} ${p}"
      read y/N
      ssh-keygen ...
    fi
  done
  EOT
```

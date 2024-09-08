# envy
stackable and composable sh profiles

`envy` is a script that enables the POSIX User Portability Utilities Shell to source multiple profiles, and share definitions between them.
these constructs are useful for automation and resource sharing in both interactive and non-interactive environments.

## Synopsis

```sh
envy path/to/profile/env.sh [...]
```

## Examples

```sh
$ cat path/to/profile/a.sh
$ cat path/to/profile/b.sh
$ envy path/to/profile/a.sh path/to/profile/b.sh
```

## Environment Variables

`ENVS` is an `IFS` delimited paths of profiles to source.

`ENV` is the same environment variable received by the POSIX User Portability Utilities Shell.
the default profile `envy.sh` is an entrypoint that loads the profiles in `ENVS`.
it can be extended with its own utility functions in the same manner as other profiles.

## POSIX Shell Functions

the `envf` function is used to define and override shell functions:

```sh
envf fname -<<'EOT'
  echo parent
  if [ $# -gt 0 ]; then
    echo $@
    shift
    $envf_ "$@"
  fi
  EOT

envf fname -<<'EOT'
  echo child
  if [ $# -gt 3 ]l then
    echo $1
    shift
    fname $@
  else
    $envf_ "$@"
  fi
  EOT

envf 1 2 3 4 5
```

these definitions are then evaluated as follows:

```
fname_ = 0

fname_0 () {
  envf_ = "fname_0"
  echo parent
  if [ $# -gt 0 ]; then
    echo $@
    shift
    $envf_ "$@"
  fi
  unset envf_
}

fname () {
  fname_0 "$@"
}

fname_1 () {
  envf_ = "fname_0"
  echo child
  if [ $# -gt 3 ]l then
    echo $1
    shift
    fname $@
  else
    $envf_ "$@"
  fi
  unset envf_
}

the `envc` function is used to document and configure completions for functions defined with `envf`:

the `envs` function is used to source profiles with the working directory set to their dirname:

```sh
$ cat enva.sh
$ cat dirb/envb.sh
$ cat dirb/dirc/envc.sh
$ . enva.sh
```
fname () {
  fname_1 "$@"
}
```

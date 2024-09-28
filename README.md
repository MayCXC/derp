# envy
stackable and composable `sh` profiles

envy is a script generator and a collection of functions that enable a [POSIX User Portability Utilities Shell](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/sh.html) to source multiple profiles, and share definitions between them.
these constructs are useful for automation and resource sharing in both interactive and non-interactive environments.

## Synopsis

`envy` cannot be executed directly. rather, `envy.sh` can be sourced from `$PATH` by a POSIX UPU Shell, either interactively or by an executable script.
such scripts can be generated and placed in a convenient directory, like the root of a version controlled repository, with the executable `envx`:

```sh
[ENVX=bin] envx [path/to/target/directory]
```

which generates an executable `envy`:

```sh
exec ./path/to/target/directory/envy [path/to/profile/env.sh] [...]
```

that sources `envy.sh` either from a copy placed in the directory specified by `$ENVX`, or otherwise from `$PATH`, and calls the function `envy` with its arguments.

## Examples

```sh
$ cat path/to/profile/a.sh
$ cat path/to/profile/b.sh
$ ./envy path/to/profile/a.sh path/to/profile/b.sh
```

## Environment Variables

the following environment variables are provided with default values by `envy`:

* `$ENV` is the same environment variable received by a [POSIX User Portability Utilities Shell](https://pubs.opengroup.org/onlinepubs/9799919799/utilities/sh.html). its default value is `env.sh`, and it is resolved from the dirname of `$0`.

* `$ENVS` is a `:` delimited list of paths that the default profile, `env.sh`, sources. its default value is an empty string.

the following environment variables are provided with default values by the default profile, `env.sh`:

* `$ENVN` is the path sourced by the extended `envs` function from any directory that it receives, [(ex.)](https://github.com/MayCXC/envy/blob/master/env.sh). its default value is the basename of `$ENV`.

## POSIX Shell Functions

the `envt` and `envr` functions serialize strings to and deserialize strings from a series of octal (`\0ddd`) escape sequences.

the `envl` function is used with `eval` to scope local variables by restoring or unsetting their values after a heredoc is evaluated.

the `envf` function is used to define and extend shell functions:

```sh
envf fname <<-'EOT'
  echo parent
  if [ $# -gt 0 ]; then
    echo "$@"
    shift
    fname "$@"
  fi
  EOT

envf fname <<-'EOT'
  echo child
  if [ $# -gt 3 ]; then
    echo $1
    shift
    fname "$@"
  else
    fname_ "$@"
  fi
  EOT

fname 1 2 3 4 5
# todo
```

these definitions are then evaluated as follows:

```sh
fname_0 () {
  echo parent;
  if [ $# -gt 0 ]; then
    echo "$@";
    shift;
    fname "$@";
  fi
}

fname_tail=0

fname () {
  eval "$(
    envl fname_head <<-EOT_
      fname_head=\${fname_tail}
      fname_\${fname_head} "\$@"
      EOT_
  )"
}

fname_ () {
  eval "$(
    envl fname_head <<-EOT_
      fname_head=\$((\${fname_head}-1))
      fname_\${fname_head} "\$@"
      EOT_
  )"
}

fname_1 () {
  echo child;
  if [ $# -gt 3 ]; then
    echo $1;
    shift;
    fname "$@";
  else
    fname_ "$@";
  fi
}

fname_tail=1
```

in the example above, `fname_` calls the extended implementation `fname_0` from the extention implementation `fname_1`.

the `envc` function is used to document and configure completions for functions defined with `envf` (todo, unsure how possible this is to do with posix sh)

the `envd` function applies sane default options to `cd`.

the `envw` function is used with `eval` to change and then return to the working directory before and after a heredoc is evaluated with `envd`.

the `envg` function uses `envf` to define a function that uses `envw` to apply its heredoc in the working directory.

the `envs` function is used to source profiles from their own directories:

```sh
$ cat enva.sh
$ cat dirb/envb.sh
$ cat dirb/dirc/envc.sh
$ ENV=enva.sh ./envy
# todo
```

this allows for relative sources between profiles.
sourced file names are always prepended with `./`, so `envs` will never source a profile from `$PATH`.
if `envs` receives an error exit code when it sources a profile, it exits with that code.
the default profile extends `envs` to append `$ENVN` to any directory paths it encounters, and then uses it to source the profiles in `$ENVS`, [(ex.)](https://github.com/MayCXC/envy/blob/master/env.sh).

the `enve` function separates profiles from `sh` options, and sets `$ENVS` to a `:` delimited list of absolute profile paths.

the `envy` function sets and resolves `$ENV` and `$ENVS`, and then executes `sh` with them in its environment. the default profile extends `envy` to use `.` as its default argument if none were given.

the `envz` function executes `$0` with the current shell options from `set +o` and any given arguments. this can be used to reload profiles to reflect changes made to them, or as a shell subprocess entrypoint.

## Advanced Usage

the following example is a replacement `envy.sh` that extends `envs` to interactively review each profile the first time it is sourced, and then sign it with with `ssh-keygen` (todo):

```sh
. "envy.sh"

envf envs<<-'EOT'
  for p in "$@"; do
    echo todo
    read y/N
    if review "y/N"; then
      "${EDITOR} ${p}"
      read y/N
      ssh-keygen ...
    fi
  done
  EOT
```

the repo (todo) is an example of multiplayer deployment automation for a monorepo with multiple services and deployment environments.
it implements locks with timeouts that users can use to reserve exclusive access to each deployment environment.
it is meant to be placed on a shared bastion host, and accessed via `ssh`.

## Similar Projects

- https://github.com/hyperupcall/autoenv
- https://github.com/direnv/direnv
- https://github.com/direnv/direnv?tab=readme-ov-file#related-projects
- https://github.com/casey/just
- https://github.com/casey/just?tab=readme-ov-file#alternatives-and-prior-art
- https://github.com/pendashteh/colons.sh
- https://github.com/oils-for-unix/oils

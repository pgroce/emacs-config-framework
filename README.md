This isn't the greatest configuration in the world. This is just a framework. <https://www.youtube.com/watch?v=_lK4cX5xGiQ>.

What is this? Why should I care?
================================

This framework introduces a little bit of structure to an Emacs configuration. It doesn't actually configure Emacs, but it introduces conventions that make it easier to split your Emacs configuration up, reuse it on multiple machines, and test changes non-destructively.

Installation
============

To install, clone the repository and run `make install` in the repo.

You will need the Emacs you want to install to in your path. If you want to specify the copy of Emacs to use explicitly, you will need to modify the Makefile, or create a file called `localvars.mk` containing the path to Emacs in the variable `EMACS`.

`make install` doesn't actually install the configuration, because they may blow away Emacs configuration you care about. Instead, it generates commands you can copy/paste into a terminal to install. If you care about the contents of your `init.el`, *back it up before running these commands*.

Features
========

Multiple configuration directories
----------------------------------

Configuration is stored in a directory in `emacs.d` (or whatever the user's `user-emacs-dir` is), so users can keep multiple configurations for multiple purposes. This can be very helpful for testing configuration changes, but this feature could be put to other uses, e.g. specialized configurations for different tasks or environments.

By default, Emacs will start the configuration located in `config`. To change it, specify a different configuration directory in the `EMACS_CONFIG_DIR` environment variable.

Platform-, host-, and user-specific configuration
-------------------------------------------------

The provided default configuration will look for a general configuration file. It will then load a file corresponding to the platform, followed by a file corresponding to the hostname, followed by a file corresponding to the username. If any of these files do not exist, they will be skipped and the configuration will look for the next file.

This permits users to share the more generic parts of their configuration with multiple hosts or accounts, while still being able to easily add more specific or sensitive information in the environments where it's needed. For instance, a user may have their generic configuration in a repo on Github (possibly with platform-specific customizations); have user-specific configurations stored in source control on their corporate or home network; and have individual tweaks stored in host-specific files on different machines.

All of the configuration files are optional; if a user wants to put all their configuration in one of them and ignore the rest, they can.

### Naming conventions

All files are assumed to be within the top level of the configuration directory. (E.g., for a standard Emacs install using the default configuration, the general configuration file would be in `~/.emacs.d/config/emacs-config.el`.)

1.  General configuration

    The general configuration file is named `emacs-config.el`.

2.  Platform-specific configuration

    The platform-specific configuration file (or "platform file") is the return value of `system-type` as a string, with any slashes converted to underscores, plus the file suffix. On an OS X system, for instance, the configuration looks for `darwin.el`, while on Linux, the configuration looks for `gnu_linux.el`.

3.  Host-specific configuration

    The host-specific configuration file (or "host file") is the string returned by the `system-name` function, plus the file suffix. For a host named `foo.bar.baz`, for instance, the file would be `foo.bar.baz.el`.

    Note that machines that change networks (e.g., laptops) may not reliably have the same host name.

4.  User-specific configuration

    The user-specific configuration file (or "user file") is the string returned by the `user-login-name` function, plus the file suffix. For the user `jdoe`, this file would be `jdoe.el`.

The scratch file
----------------

By default, Emacs starts with a `\*scratch\*` buffer. This buffer is in fundamental mode, so the user can run elisp in it. However, nothing in `\*scratch\*` is saved to disk.

This configuration replaces the `\*scratch\*` buffer with a file, `scratch.el`. `scratch.el` is automatically loaded and, by default, is the first buffer visited, just like `\*scratch\*`. However, it is a first-class configuration file; on startup, `scratch.el` is loaded after all other configuration files. `scratch.el` is, thus, a persistent `\*scratch\*`.

`scratch.el` is nice for keeping one's configuration tidy while still trying out new things. Users can put experimental changes in the `scratch.el` buffer and try them out interactively (e.g., with `eval-last-sexp`). If they want to keep the changess around for a while, they can save them to `scratch.el` and the changes will persist on restart. If they don't like a change, it's easy to remove from `scratch.el`. Otherwise, they can think about putting it in a sensible spot in their "real config".

Environment variables
=====================

This configuration permits the use of a few environment variables to change its behavior.

`EMACS_CONFIG_DIR`
------------------

Controls which configuration (or sub-configuration, if you prefer) Emacs will use. Configurations are stored in directories in `~/.emacs.d`, and contain a file called `init.el`.

If this variable is not defined, Emacs will look for a configuration in `~/.emacs.d/config`.

`EMACS_CONFIG_DEBUG`
--------------------

When debugging a configuration, setting this variable will tell the configuration to be more verbose in what it's doing. By default, this will set `use-package-verbose` to `t`. You may also use it to conditionally produce more output for debugging.

Initialization
==============

`init.el` simply figures out which configuration it should use, makes a note of it, and hand off control.

``` commonlisp
(defconst ecfw-config-dir
  (expand-file-name (or (getenv "EMACS_CONFIG_DIR") "config")
                    user-emacs-directory)
  "The directory containing the Emacs configuration read by init.el.")

(load-file (concat ecfw-config-dir "/emacs-init.el"))
```

Default Configuration
=====================

The remainder of this configuration is put in the default location, `~/.emacs.d/config/`. If you want to reuse this framework in other configurations, you can copy it from there before customizing the default configuration. (Alternately, you can copy `config` somewhere else and use `EMACS_CONFIG_DIR` to make *that* your default configuration.)

This file executes the general

    (eval-when-compile (require 'subr-x))

    (defun ecfw--config-file (fname-base)
      "Returns FNAME-BASE as it if was in the configuration
      directory."
      (expand-file-name fname-base ecfw-config-dir))

    (defun ecfw-find-config (fname-stub)
      "Find the preferred configuration file, or return nil (after
    warning the user the file doesn't exist.)"
      (let ((dot-el (ecfw--config-file (concat fname-stub ".el"))))
        (if (file-readable-p dot-el)
            dot-el
          (progn
            (warn "Couldn't find config file '%s'" dot-el)
            nil))))

    (defun ecfw-load-config (fname)
      "Load the configuration file FNAME-BASE."
      (if (file-readable-p fname)
          (progn
            (message "Reading %s" fname)
            (load-file fname))
        (message "Couldn't load %s" fname)))


    ;;; Load platform configuration files
    (let* ((general-config find-config "emacs-config"))
           (platform (replace-regexp-in-string "/" "_" (symbol-name system-type)))
           (platform-config find-config platform))
           (host-config find-config (system-name)))
           (user-config find-config (user-login-name))))
      (when general-config
        (neral-config))
      (when platform-config
        (atform-config))
      (when host-config
        (st-config))
      (when user-config
        (er-config)))

    ;;; Load scratch.el
    (cfw--config-file "scratch.el"))


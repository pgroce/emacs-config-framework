This isn't the greatest configuration in the world. This is just a framework. <https://www.youtube.com/watch?v=_lK4cX5xGiQ>.

What is this? Why should I care?
================================

This framework introduces a little bit of structure to an Emacs configuration. It doesn't actually configure Emacs, but it introduces conventions that make it easier to split your Emacs configuration up, reuse it on multiple machines, and test changes non-destructively.

Installation
============

To install, clone the repository and run `make install` in the repo. Or heck, copy/paste directly from this file; it's virtually no code at all.

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

Bonus: Proxy configuration
--------------------------

This framework provides some functions to deal with a very specific, but irritating problem: Initializing a package-heavy Emacs configuration on a machine that may be behind one of a few proxies (or unproxied). Emacs often needs to know this before it can load packages successfully.

Use of this code is optional, so if you don't have this problem, it will stay out of your way.

The code for proxy autoconfiguration is at the end of this document, in *Appendix 1: Proxy configuration functions*. It is output in a separate file, `ecfw-proxy.el`.

``` commonlisp
(require 'ecfw-proxy)
```

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

We set `package-user-dir` to a directory inside `ecfw-config-dir` so configurations don't share packages by default. Individual configurations can, of course, set it to whatever they please.

``` commonlisp
(defconst ecfw-config-dir
  (expand-file-name (or (getenv "EMACS_CONFIG_DIR") "config")
                    user-emacs-directory)
  "The directory containing the Emacs configuration read by init.el.")

(setq package-user-dir (expand-file-name "elpa/" ecfw-config-dir))

(load-file (expand-file-name "init.el" ecfw-config-dir))
```

Default Configuration
=====================

The remainder of this configuration is put in the default location, `~/.emacs.d/config/`. If you want to reuse this framework in other configurations, you can copy it from there before customizing the default configuration. (Alternately, you can copy `config` somewhere else and use `EMACS_CONFIG_DIR` to make *that* your default configuration.)

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
            (message "NOTE: Couldn't find config file '%s'" dot-el)
            nil))))

    (defun ecfw-load-config (fname)
      "Load the configuration file FNAME-BASE."
      (if (file-readable-p fname)
          (progn
            (message "Reading %s" fname)
            (load-file fname))
        (message "Couldn't load %s" fname)))


    ;;; Load platform configuration files
    (let* ((general-config (ecfw-find-config "emacs-config"))
           (platform (replace-regexp-in-string "/" "_" (symbol-name system-type)))
           (platform-config (ecfw-find-config platform))
           (host-config (ecfw-find-config (system-name)))
           (user-config (ecfw-find-config (user-login-name))))
      (when general-config
        (load-file general-config))
      (when platform-config
        (load-file platform-config))
      (when host-config
        (load-file host-config))
      (when user-config
        (load-file user-config)))

    ;;; Load scratch.el
    (load-file (ecfw--config-file "scratch.el"))

Appendix 1: Proxy configuration functions
=========================================

The framework provides some functionality for automatically assessing which proxy it is behind and configuring accordingly.

``` commonlisp
;;; ecfw-proxy.el --- Proxy autoconfiguration

;; Copyright (C) 2017 Phil Groce

;; Author: Phil Groce <pgroce@gmail.com>
;; Version: 0.1
;; Keywords: network proxies

(require 'url)

(defun ecfw--proxy-works-p (proxy-services test-url)
  (let* ((url-proxy-services proxy-services)
         ;; url-retrieve (well, open-network-stream) will error if it
         ;; can't find the proxy; this is the most likely outcome if
         ;; we're not testing the right proxy
         (buffer (condition-case nil
                     (url-retrieve-synchronously test-url t)
                   (error nil))))
    (if buffer
        (let (rc)
          (with-current-buffer buffer
            (goto-char (point-min))
            (if (re-search-forward
                 "^HTTP/[0-9]\\.[0-9] \\([0-9]\\{3\\}\\)"
                 nil
                 t)
                (let ((code (string-to-number (match-string 1))))
                  (if (= 200 code)
                      (setq rc t)
                    (setq rc nil)))
              (setq rc  nil)))
          rc)
      nil)))

(defun ecfw-proxy-works-p (proxy test-url)
  "Predicate for testing if a proxy is usable.

PROXY is a proxy entry formatted as a record in the
`url-proxy-services' list of proxies. In other words, this is a
cons cell of the form (\"service type\" . \"address:port\").

TEST-URL is a URL which should be accessible through the proxy if
it exists and is configured correctly."
  (ecfw--proxy-works-p `(,proxy) test-url))


(defun ecfw--read-proxies-file (filename)
  (with-temp-buffer
  (insert-file-contents filename)
  (goto-char (point-min))
  (read (current-buffer))))

(defun ecfw--proxy-autoconf (proxies-raw)
  (let ((final-proxies nil))
    (cl-dolist (proxy-rec proxies-raw final-proxies)
      (cl-destructuring-bind (label service addr no-proxy test-urls) proxy-rec
        (let* ((services-rec `(,service . ,addr))
               (proxy-works-p (lambda (test-url)
                                (ecfw-proxy-works-p services-rec test-url))))
          (when (and (not (eq test-urls nil))
                     (cl-every proxy-works-p test-urls))
            (add-to-list 'final-proxies services-rec)
            (when no-proxy
              (add-to-list 'final-proxies `("no_proxy" . ,no-proxy)))))))
    final-proxies))





(defun ecfw-proxy-autoconf (proxies-file-name)
  "Autoconfigure Emacs to use any usable proxies in PROXIES-FILE-NAME.

The format of PROXIES-FILE-NAME is an sexpr list of records. An example might look like this:

  ((work \"http\"
         \"proxy.example.com:1234\"
         nil
         (\"http://www.example.com\"
          \"http://webmail.example.com\"))
   (school http
           \"proxy.university.edu:8080\"
           \"university.edu,foo.org\"
           (\"http://www.moogle.org\"
            \"http://internet-websites.com\")))

Each record consists of the following fields:

  (label service proxy-addr no-proxy test-urls)

The label is a symbol or string that you can use to identify the
record quickly; it is ignored by the code.

The service is one of the proxy services: \"http\", \"https\",
\"ftp\", etc.

The no-proxy string has the same format as the NO_PROXY
environment variable, and specifies domains that should not be
proxied. It is also not used in the code, but is passed into
`url-proxy-services' unchanged.

The test-urls are a set of URLs that should be reachable if this
proxy is usable. If they are not reachable with the proxy
configured, the proxy will not be used. If the list of test-urls
is empty the proxy will never be used.

Note that no entries are needed to configure an unproxied network
connection; if none of the proxies are reachable Emacs will be
configured not to use a proxy. If a proxy is reachable but you do
not wish to use it, you should remove it from your proxies file."
  (setq url-proxy-services
        (ecfw--proxy-autoconf
         (ecfw--read-proxies-file proxies-file-name))))

(provide 'ecfw-proxy)
;;; ecfw-proxy.el ends here
```

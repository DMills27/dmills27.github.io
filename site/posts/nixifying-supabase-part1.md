---
title: "Enhancing Reliability, Performance, and Dev Productivity with Nix: Part 1"
author: Dominic Mills-Howell
date: 2024/07/06
description: "An overview of how Nix-related tooling can improve Supabase's platform"
tags: [nix, postgres, supabase]
---

I've been interested in utilising Nix and Nix-based tooling to showcase how it can vastly improve developer experience. I've chosen the Supabase platform, more specifically their [Postgres repo](https://github.com/DMills27/postgres), to exhibit these improvements and how they can be generally applied to other projects. The reasons for this choice are as follows:

-  Supabase is a popular open source project and thus my findings can be useful for many people who want to self-host their projects. 
-  To highlight how lesser-known, alternative tools can offer a smoother developer experience compared to commonly used ones like Ansible and GitHub Actions. These alternatives can provide benefits such as faster build times, better security hardening, and more deterministic orchestration for large-scale projects.
- 

Most of the discussion with be focused on these aspects:

1. Delving into how [Garnix](https://garnix.io/) provides a more performant alternative to Github actions. Moreover, detailing the benefits of having access to useful NixOS features without necessarily having to fully opting into NixOS itself.  
2. Demonstrating how one can develop more sophisticated [Smoke](https://en.wikipedia.org/wiki/Smoke_testing_(software)), [Integration](https://en.wikipedia.org/wiki/Integration_testing) and [Regression testing](https://en.wikipedia.org/wiki/Regression_testing) using NixOS tests as well as providing more involved and practical examples which are either missing or severely underdocumented in the official Nix documentation. 
3. Showcasing how NixOS can be a more than suitable Ansible replacement that addresses many of Ansible's shortcomings such as configuration drift, lack of atomicity, performance issues, reverting to previous configurations. This builds on the work described [these](https://lmy.medium.com/from-ansible-to-nixos-3a117b140bec) [articles](https://mtlynch.io/notes/nix-first-impressions/) 
4. To illustrate lesser known features of NixOS that are useful in the context of orchestration and choreography, such as [Impermanence](https://nixos.wiki/wiki/Impermanence), [Specialisation](https://nixos.wiki/wiki/Specialisation) and [Boot Counting](https://fosdem.org/2024/schedule/event/fosdem-2024-3045-automatic-boot-assessment-with-boot-counting/), which is particularly beneficial for SRE, DevOps and Cloud engineers.



```{.nix .numberLines}
{ pkgs, ... }:

let
  shellcheckPackage = pkgs.shellcheck;
in {
  checkShellScripts = pkgs.stdenv.mkDerivation {
    name = "check-shell-scripts";

    src = ./.;

    buildInputs = [ shellcheckPackage ];

    buildPhase = ''
      ${shellcheckPackage}/bin/shellcheck ${self.src}/ansible/files/admin_api_scripts -e SC2001 -e SC2002 -e SC2143
      ${shellcheckPackage}/bin/shellcheck ${self.src}/ansible/files/admin_api_scripts/pg_upgrade_scripts -e SC2001 -e SC2002 -e SC2143
    '';

    meta = {
      description = "Run ShellCheck on shell scripts";
      license = pkgs.lib.licenses.mit;
    };
  };
}

```
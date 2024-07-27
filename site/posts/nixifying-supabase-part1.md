---
title: "Enhancing Reliability, Performance, and Dev Productivity with Nix: Part 1"
author: Dominic Mills-Howell
date: 2024/07/06
description: "An overview of how Nix-related tooling can improve Supabase's platform"
tags: [nix, postgres, supabase]
---

I've been eager to explore how Nix and Nix-based tools can significantly enhance developer experience. For this, I’ve zeroed in on the Supabase platform, specifically their [Postgres repo](https://github.com/DMills27/postgres), to showcase these improvements and demonstrate their broader applicability to other projects. Here’s why I chose Supabase:

- **Widespread Use**: Supabase is a popular open source project, making my findings valuable for anyone looking to self-host their projects.

- **Alternative Tools**: I aim to highlight how lesser-known tools can offer a smoother developer experience compared to mainstream options like Ansible and GitHub Actions. These alternatives can deliver faster build times, better security, and more deterministic orchestration for large-scale projects.

Our discussion will dive into:

- **Garnix vs. GitHub Actions**: Exploring how [Garnix](https://garnix.io/)  offers a more performant alternative to GitHub Actions, and the advantages of leveraging NixOS features without fully committing to NixOS.

- **Advanced Testing with NixOS**: Showing how to develop sophisticated [Smoke](https://en.wikipedia.org/wiki/Smoke_testing_(software)), [Integration](https://en.wikipedia.org/wiki/Integration_testing) and [Regression testing](https://en.wikipedia.org/wiki/Regression_testing) using NixOS, with practical examples that fill the gaps in the official Nix documentation.

- **NixOS as an Ansible Alternative**: Demonstrating how NixOS can effectively replace Ansible, addressing issues like configuration drift, lack of atomicity, performance problems, and difficulties in reverting to previous configurations, building on insights from various articles. This builds on the work described [these](https://lmy.medium.com/from-ansible-to-nixos-3a117b140bec) [articles](https://mtlynch.io/notes/nix-first-impressions/) 

- **Exploring NixOS Features**: Highlighting lesser-known NixOS features that enhance orchestration and choreography, such as Impermanence, Specialisation, and Boot Counting, tailored for SRE, DevOps, and Cloud engineers. To illustrate lesser known features of NixOS that are useful in the context of orchestration and choreography, such as [Impermanence](https://nixos.wiki/wiki/Impermanence), [Specialisation](https://nixos.wiki/wiki/Specialisation) and [Boot Counting](https://fosdem.org/2024/schedule/event/fosdem-2024-3045-automatic-boot-assessment-with-boot-counting/), which is particularly beneficial for SRE, DevOps and Cloud engineers.

Let’s dive into these exciting aspects and see how Nix can transform our development workflows!



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
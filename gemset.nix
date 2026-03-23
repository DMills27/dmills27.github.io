{
  addressable = {
    dependencies = ["public_suffix"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0mxhjgihzsx45l9wh2n0ywl9w0c6k70igm5r0d63dxkcagwvh4vw";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.8.8";
  };
  base64 = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0yx9yn47a8lkfcjmigk79fykxvr80r4m1i35q82sxzynpbm7lcr7";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.3.0";
  };
  bibtex-ruby = {
    dependencies = ["latex-decode" "logger" "racc"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "16n6szgybyk7mglpajizgi7b77s48i319brxhhx51pvainkyn46n";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "6.2.0";
  };
  citeproc = {
    dependencies = ["date" "forwardable" "json" "namae" "observer" "open-uri"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "159vnp84r3rywwzji6jbfjldlynai0gll868y6z84ghk924np3i7";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.1.0";
  };
  citeproc-ruby = {
    dependencies = ["citeproc" "csl" "observer"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1sbj6m5j6zl0ddrphhm9k1nyhf881fqz3hyvs5hamb9ma99fcb0r";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.1.8";
  };
  colorator = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0f7wvpam948cglrciyqd798gdc6z3cfijciavd0dfixgaypmvy72";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.1.0";
  };
  concurrent-ruby = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1aymcakhzl83k77g2f2krz07bg1cbafbcd2ghvwr4lky3rz86mkb";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.3.6";
  };
  csl = {
    dependencies = ["forwardable" "namae" "open-uri" "rexml" "set" "singleton" "time"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "18lml5r0iq16bkk5khjy95j35w13whf51ljv2l5iw7zmyvqm4hv2";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.2.1";
  };
  csl-styles = {
    dependencies = ["csl"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "166ya7hgqizb77lgfhhh5mpiidy0mkd2mp20w5fq41q3lvc0g054";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.0.2";
  };
  csv = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0gz7r2kazwwwyrwi95hbnhy54kwkfac5swh2gy5p5vw36fn38lbf";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.3.5";
  };
  date = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1h0db8r2v5llxdbzkzyllkfniqw9gm092qn7cbaib73v9lw0c3bm";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.5.1";
  };
  em-websocket = {
    dependencies = ["eventmachine" "http_parser.rb"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1a66b0kjk6jx7pai9gc7i27zd0a128gy73nmas98gjz6wjyr4spm";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.5.3";
  };
  eventmachine = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0wh9aqb0skz80fhfn66lbpr4f86ya2z5rx6gm5xlfhd05bj1ch4r";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.2.7";
  };
  ffi = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0k1xaqw2jk13q3ss7cnyvkp8fzp75dk4kazysrxgfd1rpgvkk7qf";
      target = "ruby";
      type = "gem";
    };
    targets = [{
      remotes = ["https://rubygems.org"];
      sha256 = "0i9r6kwaxpfskz4qrc6vhmxkjd6y8v20c576hvsmqq20xyk6la7h";
      target = "x86-linux-musl";
      targetCPU = "x86";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0lv0sz3sd3ag6hjmb3zbm3czkzhwsxky4czsibvrlpr6jsxjcxhd";
      target = "arm-linux-musl";
      targetCPU = "arm";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0mpakafxhnr4bbzg2d8rg97s8j9lsbz4cvq6cishnck878f24sq8";
      target = "x86_64-linux-musl";
      targetCPU = "x86_64";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0s2ng1f0hzcayrgcrpimix1smm9drvamg77r6w0frdb87flcxm2v";
      target = "arm-linux-gnu";
      targetCPU = "arm";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0s3hm7bhp8dsl8b4p0sf1fyv583r28vw744avnpg0q35y8ymgb98";
      target = "aarch64-linux-gnu";
      targetCPU = "aarch64";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0zvin2dmgil5yshrvca0qi7agyxj77gmjkf00xzpmqffsiahas8c";
      target = "arm64-darwin";
      targetCPU = "arm64";
      targetOS = "darwin";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0zw85h7gnlw1aqznlrz7v9dy7cqprjrprjqsvhb7pbkscwgv0iip";
      target = "x86_64-linux-gnu";
      targetCPU = "x86_64";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "12cha9qrjv2v7yr0lrq5lihiw3jm6hn2nz3wdfjc71jimzy8i2l6";
      target = "x86-linux-gnu";
      targetCPU = "x86";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "1ck4yxfpyb2rxkg94w3ldpv52cpgghl6pn5pqfnapcbmcyvk62q2";
      target = "aarch64-linux-musl";
      targetCPU = "aarch64";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "1d8bq3r13icr2m3hhk0wdp9gnjqhmf9dsb1jk1cs5yjwxc8ih88z";
      target = "x86_64-darwin";
      targetCPU = "x86_64";
      targetOS = "darwin";
      type = "gem";
    }];
    version = "1.17.3";
  };
  forwardable = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0f78rjpnhm4lgp1qzadnr6kr02b6afh1lvy7w607k4qjk3641kgi";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.4.0";
  };
  forwardable-extended = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15zcqfxfvsnprwm8agia85x64vjzr2w0xn9vxfnxzgcv8s699v0v";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.6.0";
  };
  google-protobuf = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1dsj349xm6jmd94xix8bgdn5m8jqqk9bsivlm9fll8ifa008ab0h";
      target = "ruby";
      type = "gem";
    };
    targets = [{
      remotes = ["https://rubygems.org"];
      sha256 = "0261fi4qfqfzja4hq172r4zlfk76n47ipfmwsr7k3sqffqf8r7lw";
      target = "x86_64-darwin";
      targetCPU = "x86_64";
      targetOS = "darwin";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0cq29hbwm5d2cjfiz3252my6psjz7515s2ndh9jnd7rwqnpgm3r8";
      target = "x86-linux";
      targetCPU = "x86";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0i00b4bpw5rw63bnkkbm1h79zh8j0pdz6gjzx1hk7vir3yix2saq";
      target = "aarch64-linux";
      targetCPU = "aarch64";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0ng9gd7w28csm6yicf5y4g85gmm4bvjf77wjmw7adqim0s8ksy07";
      target = "x86_64-linux";
      targetCPU = "x86_64";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "123lqm6b8yzv10gdn27zmzixqhhd96xg0r6jxp3qnp5j9zyaz572";
      target = "arm64-darwin";
      targetCPU = "arm64";
      targetOS = "darwin";
      type = "gem";
    }];
    version = "3.25.8";
  };
  "http_parser.rb" = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0yh924g697spcv4hfigyxgidhyy6a7b9007rnac57airbcadzs4s";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.8.1";
  };
  i18n = {
    dependencies = ["concurrent-ruby"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1994i044vdmzzkyr76g8rpl1fq1532wf0sb21xg5r1ilj5iphmr8";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.14.8";
  };
  jekyll = {
    dependencies = ["addressable" "base64" "colorator" "csv" "em-websocket" "i18n" "jekyll-sass-converter" "jekyll-watch" "json" "kramdown" "kramdown-parser-gfm" "liquid" "mercenary" "pathutil" "rouge" "safe_yaml" "terminal-table" "webrick"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1h8qpki1zcw4srnzmbba2gwajycm50w53kxq8l6vicm5azc484ac";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "4.4.1";
  };
  jekyll-feed = {
    dependencies = ["jekyll"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1hzwmjrxi57x68i7jx5rxi8qlcbqcbg3di55wywrp53pr0bap6k8";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.17.0";
  };
  jekyll-paginate = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0r7bcs8fq98zldih4787zk5i9w24nz5wa26m84ssja95n3sas2l8";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.1.0";
  };
  jekyll-sass-converter = {
    dependencies = ["sass-embedded"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0hr4hsir8lm8aw3yj9zi7hx2xs4k00xn9inh24642d6iy625v4l3";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.1.0";
  };
  jekyll-seo-tag = {
    dependencies = ["jekyll"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0638mqhqynghnlnaz0xi1kvnv53wkggaq94flfzlxwandn8x2biz";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.8.0";
  };
  jekyll-watch = {
    dependencies = ["listen"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1qd7hy1kl87fl7l0frw5qbn22x7ayfzlv9a5ca1m59g0ym1ysi5w";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.2.1";
  };
  json = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "01fmiz052cvnxgdnhb3qwcy88xbv7l3liz0fkvs5qgqqwjp0c1di";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.18.0";
  };
  kramdown = {
    dependencies = ["rexml"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "131nwypz8b4pq1hxs6gsz3k00i9b75y3cgpkq57vxknkv6mvdfw7";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.5.1";
  };
  kramdown-parser-gfm = {
    dependencies = ["kramdown"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0a8pb3v951f4x7h968rqfsa19c8arz21zw1vaj42jza22rap8fgv";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.1.0";
  };
  latex-decode = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "14m5q817apv3kh2nc23b94i5mx0vxqfj7pm61j738piidr036mp8";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.4.2";
  };
  liquid = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1czxv2i1gv3k7hxnrgfjb0z8khz74l4pmfwd70c7kr25l2qypksg";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "4.0.4";
  };
  listen = {
    dependencies = ["rb-fsevent" "rb-inotify"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0rwwsmvq79qwzl6324yc53py02kbrcww35si720490z5w0j497nv";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.9.0";
  };
  logger = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "00q2zznygpbls8asz5knjvvj2brr3ghmqxgr83xnrdj4rk3xwvhr";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.7.0";
  };
  mercenary = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0f2i827w4lmsizrxixsrv2ssa3gk1b7lmqh8brk8ijmdb551wnmj";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.4.0";
  };
  namae = {
    dependencies = ["racc"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "17fmp6p74ai2w984xayv3kz2nh44w81hqqvn4cfrim3g115wwh9m";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.2.0";
  };
  observer = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1b2h1642jy1xrgyakyzz6bkq43gwp8yvxrs8sww12rms65qi18yq";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.1.2";
  };
  open-uri = {
    dependencies = ["stringio" "time" "uri"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1jl7i0w0vhxpvj54707cpcpqi00maf1dma0mxmm99rirmkyhckvv";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.5.0";
  };
  pathutil = {
    dependencies = ["forwardable-extended"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "12fm93ljw9fbxmv2krki5k5wkvr7560qy8p4spvb9jiiaqv78fz4";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.16.2";
  };
  public_suffix = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "15dhl6k4gbax0xz8frfs4nsb6lg5zgax9vkr1pqzjmhfxddhn2gp";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "7.0.0";
  };
  racc = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0byn0c9nkahsl93y9ln5bysq4j31q8xkf2ws42swighxd4lnjzsa";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.8.1";
  };
  rb-fsevent = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1zmf31rnpm8553lqwibvv3kkx0v7majm1f341xbxc0bk5sbhp423";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.11.2";
  };
  rb-inotify = {
    dependencies = ["ffi"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0vmy8xgahixcz6hzwy4zdcyn2y6d6ri8dqv5xccgzc1r292019x0";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.11.1";
  };
  rexml = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0hninnbvqd2pn40h863lbrn9p11gvdxp928izkag5ysx8b1s5q0r";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.4.4";
  };
  rouge = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0fd77qcz603mli4lyi97cjzkv02hsfk60m495qv5qcn02mkqk9fv";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "4.7.0";
  };
  safe_yaml = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0j7qv63p0vqcd838i2iy2f76c3dgwzkiz1d1xkg7n0pbnxj2vb56";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.0.5";
  };
  sass-embedded = {
    dependencies = ["google-protobuf"];
    groups = ["default"];
    platforms = [];
    source = null;
    targets = [{
      remotes = ["https://rubygems.org"];
      sha256 = "05q1g6iklz1f59fg0skchdm9ddcxv855a8i4y5ad7qabrfjf2kl3";
      target = "x86-cygwin";
      targetCPU = "x86";
      targetOS = "cygwin";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "08r4x6jf83sqrmb247vk7m4sz1ckmc5rmj92yi83b44am3fs7hlg";
      target = "x86-linux-musl";
      targetCPU = "x86";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0a6rdzyya1819bx1q6p10xb0awsyym2cpksaffj6d66fi2wmb4ny";
      target = "x86-linux-gnu";
      targetCPU = "x86";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0d3m8r6mh72fbiyf6zyi6mkp1jz3lv3xnzcsbmlib6k6hrmxlkn8";
      target = "aarch64-linux-gnu";
      targetCPU = "aarch64";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0dnvkfw8i17w0j4z3011wc6y41ls6ar2c77ismaiq64bzsp299d6";
      target = "arm64-darwin";
      targetCPU = "arm64";
      targetOS = "darwin";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0h4ca9iyvnm7858f7frxks6j0ipilyjahvk3d9lbl8ja5pgj8qkg";
      target = "aarch64-linux-musl";
      targetCPU = "aarch64";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0mjd98dcgfkm501b2cr0gabmg8almb7bibrwkvmv9xqja4al7pf5";
      target = "x86_64-linux-musl";
      targetCPU = "x86_64";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0rgz0y7lixk3fn2q589yif8ss7qdk3qdd690ghf01fx4dvq6gq70";
      target = "arm-linux-gnueabihf";
      targetCPU = "arm";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0wz7z965dkspachgwg3p1n6xwrkgwyr6wmvxak4s8r0dnfsl8xga";
      target = "x86-mingw-ucrt";
      targetCPU = "x86";
      targetOS = "mingw";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "0xd3vc2vpgwr713d982gnygz75wv4bx9abm18cqiiaifvdcf4n5n";
      target = "riscv64-linux-musl";
      targetCPU = "riscv64";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "112l00rzkn4w0r83jrpnvl2wxfq67p924knvla98hy6w97mzf9vm";
      target = "riscv64-linux-gnu";
      targetCPU = "riscv64";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "1cyl8lbwxcb0ijkhhdmjvc2j506a695vqyi546vbqxal1ask80sb";
      target = "x86-linux-android";
      targetCPU = "x86";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "1d6pag8vb0mcc9i46cqvsk1pdzil0501g6hc3yn6wx7ahjwsc01h";
      target = "x86_64-linux-gnu";
      targetCPU = "x86_64";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "1gsjnb2x93nx41j03hagzmj3v0dkwr1z1giy9mk3v8q2v9v5digm";
      target = "arm-linux-androideabi";
      targetCPU = "arm";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "1hqdvrjivcyv44f7prgx5hfr89481zcgissbm01rpqssy41ymvhi";
      target = "x86_64-cygwin";
      targetCPU = "x86_64";
      targetOS = "cygwin";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "1hxz4sgr37b6k57hri6806famanx1nr1ad237vwbwl1f05ff53i2";
      target = "x86_64-darwin";
      targetCPU = "x86_64";
      targetOS = "darwin";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "1is8h1dzap2aj0mzglrfr7bznsj9shyj27d0210ch7rfy6b2xk84";
      target = "riscv64-linux-android";
      targetCPU = "riscv64";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "1njykbmlwrk2z82mzy9ybnndqv75pip4d3ahaxfik9ymabqpqaxd";
      target = "arm-linux-musleabihf";
      targetCPU = "arm";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "1q7j5f6p78rlgpzpf574shdk344bbgd44sjsqmwjdq9lkfspb75s";
      target = "aarch64-linux-android";
      targetCPU = "aarch64";
      targetOS = "linux";
      type = "gem";
    } {
      remotes = ["https://rubygems.org"];
      sha256 = "1sjjswg2fcc1yh6x0g93zsqfswpx8jp9cx9wbczyn5ir1ddbz0z1";
      target = "x86_64-linux-android";
      targetCPU = "x86_64";
      targetOS = "linux";
      type = "gem";
    }];
    version = "1.77.5";
  };
  set = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1wcfdmj162d1ydka5wbnan3kj5jv6494qpaav50q0y1f406sccya";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.1.2";
  };
  singleton = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0y2pc7lr979pab5n5lvk3jhsi99fhskl5f2s6004v8sabz51psl3";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.3.0";
  };
  stringio = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1q92y9627yisykyscv0bdsrrgyaajc2qr56dwlzx7ysgigjv4z63";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.2.0";
  };
  tale = {
    dependencies = ["jekyll" "jekyll-feed" "jekyll-paginate" "jekyll-seo-tag"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1jhkmydmpy8ymgi039kr6rcmzq6gx74y9zs4lkkwgxyaqqd18j8m";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.2.1";
  };
  terminal-table = {
    dependencies = ["unicode-display_width"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "14dfmfjppmng5hwj7c5ka6qdapawm3h6k9lhn8zj001ybypvclgr";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "3.0.2";
  };
  time = {
    dependencies = ["date"];
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1arxpii25xgb3fkgqp5acyc0x6179j3qzld78lflgsdxqfcf897k";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "0.4.2";
  };
  unicode-display_width = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0nkz7fadlrdbkf37m0x7sw8bnz8r355q3vwcfb9f9md6pds9h9qj";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "2.6.0";
  };
  uri = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "1ijpbj7mdrq7rhpq2kb51yykhrs2s54wfs6sm9z3icgz4y6sb7rp";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.1.1";
  };
  webrick = {
    groups = ["default"];
    platforms = [];
    source = {
      remotes = ["https://rubygems.org"];
      sha256 = "0ca1hr2rxrfw7s613rp4r4bxb454i3ylzniv9b9gxpklqigs3d5y";
      target = "ruby";
      type = "gem";
    };
    targets = [];
    version = "1.9.2";
  };
}
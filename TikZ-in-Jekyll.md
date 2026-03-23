# LaTeX and TikZ in Jekyll Posts

> This post is work in progress
> 
> *Premature optimization is the root of all evil (or at least most of it) in programming* — Donald Knuth

## ⚠️ Important

* Disclaimer: all code provided here is under GPLv3, use at your own risk.
* Google is your friend :)
* The idea of using a tag to compile *tikz* is inspired by [this snippet](https://github.com/LeNPaul/jekyll-tikz)
* I hope that this post someday becomes obsolete

## 🚀 Introduction

The objective of this post is to **include *tikz* code in *Markdown* files** that is rendered as an image. This is done in a way that the results are available **on-the-fly** on the webpage. It's easy to work with, it doesn't need external programs and the **distraction is minimal**.

The idea to do this is to create a custom tag in Jekyll that takes the LaTeX code, compiles it and then replaces *tikz* code with an HTML image tag of the graphics. The graphics format is SVG to have the **maximum quality**. It also allows to render inline LaTeX and **reuses** and **avoids unneeded recompilations**, as you can see on the *src* of two previous "Latex" images.

More examples: inline LaTeX, display math, TikZ diagrams (Inline TikZ).

### Equations:

*Multiline allowed :)*

Or plots using TikZ:

*TikZ plot using library: automata*

My solution is different than the snippet proposal: First, this solution is able to compile any kind of LaTeX, takes advantage of new multiline features and keeps the official docker *jekyll/jekyll* image to compile the blog, it also prevents unnecessary compilations.

**Requirements of my solution:**

* I want the LaTeX part to be completely independent from the Jekyll.
* I want to compile the images only when it's really needed.
* I don't want the images in the Git repo.
* When I'm writing my blog I don't want to manually call the latex compiler.

## ✨ Solution

> This solution assumes that you are using *jekyll/jekyll* official docker image and *docker-compose* to run the local server. However, it should be easy to adapt it to other workflows.

The idea is to have another container in *docker-compose* that only compiles the graphics LaTeX code when files change. This is important as compiling images is a cpu-intensive task.

First create a Ubuntu based Docker image with LaTeX installed and packages *inotify-tools* and *pdf2svg*. This docker will run a script **forever** waiting for modified *.tex* files using *inotify* and each time that a file changes will convert it to *pdf* and then from *pdf* to *svg* using *pdf2svg*.

## 🔨 Custom Jekyll Tag

The only purpose of this tag is to create *tex* files that then will be compiled by the other container. The Jekyll container does not know anything about the compiling process, but it must know where are the images to create the refs.

There is a **small trick** to avoid unnecessary recompiling of the images. If there are two latex blocks that have the same code and the same name (this also happens at each 'save' of the post) the image doesn't need to be updated. To avoid it, we add the md5sum of the *tex* to the *svg* filename, then before compiling we can know beforehand if the result will be the same.

The code of this tag is easy, just create a `tikz.rb` on the `_plugins` folder on the root of the Jekyll installation. And adapt the following code as you want:

```ruby
require 'digest/md5'

module Jekyll
  module Tags
    class Tikz < Liquid::Block
      def initialize(tag_name, text, tokens)
        super
        @fname = fname.strip
                      .gsub(/[^\w\s_-]+/, '')
                      .gsub(/(^|\b\s)\s+($|\s?\b)/, '\\1\\2')
                      .gsub(/\s+/, '_')
      end

      def render(context)
        @latex = %Q{
\\documentclass[varwidth]{standalone}
\\usepackage{tikz}
\\usepackage{amsmath,amssymb,latexsym}
... [latex/tikz packages] ...
\\begin{document}
#{super}
\\end{document}
}

        dtikz = File.join(Dir.pwd, "_tikz") # dir of tex, pdf files
        dsvg = File.join(Dir.pwd, "assets", "svg") # dir of public svg files
        FileUtils.mkdir_p dtikz
        FileUtils.mkdir_p dsvg

        ftex = File.join(dtikz, "#{@fname}.tex") 
        File.open(ftex, 'w') { |file| file.write("#{@latex}") }

        @md5 = Digest::MD5.hexdigest(@latex)
        @imgsrc = File.join("/assets", "svg", "#{@fname}-#{@md5}.svg")
        "<img width='100%' src=\"#{@imgsrc}\" type=\"image/svg+xml\" />"
      end
    end
  end
end

Liquid::Template.register_tag('latex', Jekyll::Tags::Tikz)
```

**A couple of things:**

* The latex document type is *standalone*, this crops the resulting output file to the content, which is what we want. The parameter *varwidth* enables the **paragraph mode** (multiline).
* *tex* and intermediary *latex* files are inside the *_tikz* folder, the *svg* assets are in *assets/svg*. You can customize the *img* tag with *css*.

Each time that a *markdown* file is processed, the *tex* files are created and the code is replaced by an *HTML img tag*.

## 🔨 LaTeX Container for Compiling *tex* Files

You can create the Ubuntu container as you want, just make sure to install *inotify-tools* and *pdf2svg* and share the blog directory to the container, in this case it's mounted on `/srv/jekyll`.

The following script, that should be run by the container at initialization, converts *tex* files generated in the previous section to *svg*, to do so you can use something like the following:

```bash
#!/bin/bash
# Monitor tex files and compile them
while IFS=$'\n' read line; do
    event=$(echo $line | awk -F '<@>' {'print $1'})
    dir=$(echo $line | awk -F '<@>' {'print $2'})
    file=$(echo $line | awk -F '<@>' {'print $3'})
    if [[ $file == *.tex ]]; then
        fname=$(basename -- "$file")
        fname_noext="${file%.*}"
        new_md5=($(md5sum "$dir$file"))

        fsvg="/srv/jekyll/assets/svg/${fname_noext}-${new_md5}.svg" 
        fpdf="${dir}${fname_noext}.pdf" 
        if [[ ! -f "$fsvg" ]]; then
            echo "[$fname] with hash {"$new_md5"} compiling"
            (pdflatex -output-directory "$dir" "$file" && \
                pdf2svg "$fpdf" "$fsvg")&
        fi;
    fi;
done < <(inotifywait -m -r -e modify --format "%e<@>%w<@>%f" /srv/jekyll/_tikz)
```

Here we are using an infinite loop that awaits *inotifywait* for any file change. If the file is a *tex* file, then we call *pdflatex* with *-output-directory* to create a PDF for each image then it is converted to *svg* using *pdf2svg*.

## 🛠️ Usage

I'm currently doing `<span class="inline-latex">{% latex latex %}\LaTeX{% endlatex %}</span>` for including inline latex, with the following css properties:

```css
.inline-latex {
    display: inline-flex;
    height: 20px;
    vertical-align: text-bottom;
}
```

For large equations or images I'm currently using:

```html
<div class="block-latex">
{% latex figure %}
{% endlatex %}
</div>
```

With the following properties:

```scss
.block-latex {
    margin: 0 auto 5px auto;
    width: 50%;

    &.large {
        width: 80%;
    }

    @media only screen and (max-width: 600px) {
        &.large {
            width: 100%;
        }
        width: 100%;
    }
}
```

This is inside an *scss* file (Works seamlessly with Jekyll)

## 🔭 To Do

* **Clean unused files:** Generated images are never deleted. For now I will clean this up by removing the directory and regenerating everything. However, it's possible to filter them using the hash of the *tex* files and removing unmatching files.
* Images are not unique per post, so don't repeat names, this is not a bug, it's a feature 
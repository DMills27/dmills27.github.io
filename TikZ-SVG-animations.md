# Improving LaTeX to SVG with Animations

## Introduction

What if I told you that the picture on the left is designed in **TikZ**, compiled to SVG, and animated with CSS? Well, it is actually much better than that, the code of the image is on the same file as I am writing this, check my previous post to know how it works.

I wanted to draw the *Ars Demonstrativa* (Ramon Llull) with **TikZ**, and add the animation manually with the animate primitive. In the process, I found a better way to compile **LaTeX** to SVG, including the original text with its fonts and producing smaller files. I also ran into some interesting issues that I was able to overcome, such as injecting SVG to HTML to access its inner elements and controlling the scope of CSS styles.

### Grouping SVG elements in TikZ

I didn't expect that it was so easy to define SVG *ids* for TikZ elements, but here I found the following trick:

```latex
\tikzset{
  svgid/.style={
    execute at begin scope={\special{dvisvgm:raw <g id="#1">}},
    execute at end scope={\special{dvisvgm:raw </g>}},
  }
}
```

Now we can use the `scope` environment to create a group with an *id*, but instead of going the *tex → pdf → svg* path, we do *tex → dvi → svg*.

```latex
\begin{scope}[svgid=<id>] % Group all elements inside <g id=<id>>
\node ...
\draw ..
\end{scope} % End group
```

I was impressed that it worked, even more when I saw that using the DVI format, the files are much smaller and the text is not converted to a vector path! I decided to update all my blog to generate the images in DVI instead of PDF. The next section describes what issues I found while doing this and how I solved them.

### Including SVG in HTML pages

I knew it was possible to edit SVG images using CSS, but browsers only allow you to do it if they are inline. SVG loaded as images `<img src="#" />` do not apply styles from the page. This can be fixed using Javascript to inject the actual SVG code into DOM. For example, the following code downloads the SVG and injects it into the DOM after some preprocessing.

```javascript
function addsvg(container, file) {
    return fetch(file)
    .then(x => x.text())
    .then(x => document.getElementById(container).innerHTML
        = x.replaceAll("font-family:cm", "font-family:cm"+container) /* Fix fontname */
        .replaceAll("text.f", "#"+container+" text.f") /* Fix style scope */
    )
    .catch(console.error.bind(console))
}
```

As you can see, the code above replaces some of the text from the SVG. The problem with injecting SVG is that each one of these files contains the fonts, and these fonts are optimized for each particular SVG. When adding more than one file they get mixed up and result in unreadable images. This happens because the CSS style is global for the HTML document and there is not a nice way to define CSS scopes using tags. This solution limits the scope of CSS styles using a parent selector and also renames the fontname so each image has its own fonts.

Simple example of what is happening:

```css
/* First SVG */
text.f0 {
    font-family:cmbx12;
}

/* Second SVG */
text.f0 {
    font-family:cmbx12; /* This font is not the same as before, but they share the same name */
}
```

To solve both problems, before injecting the SVG we replace the fontnames to include the image name, and limit the scope of the CSS classes by filtering the style to elements of that particular image.

```css
/* First SVG */
#svg0 text.f0 {
    font-family:cmsvg0bx12;
}

/* Second SVG */
#svg1 text.f0 {
    font-family:cmsvg1bx12;
}
```

---

> **Summary:** This post describes an improved workflow for compiling TikZ/LaTeX to SVG using `dvisvgm` instead of the traditional PDF route. Key benefits include:
> - Smaller file sizes
> - Text preserved as text (not vector paths)
> - Ability to assign SVG IDs to TikZ elements via `\special{dvisvgm:raw}`
> - JavaScript-based SVG injection with CSS scoping to avoid font/style conflicts when embedding multiple animated diagrams
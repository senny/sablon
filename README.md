# Sablon

[![Gem Version](https://badge.fury.io/rb/sablon.svg)](http://badge.fury.io/rb/sablon) [![Build Status](https://travis-ci.org/senny/sablon.svg?branch=master)](https://travis-ci.org/senny/sablon)

Is a document template processor for Word `docx` files. It leverages Word's
built-in formatting and layouting capabilities to make template creation easy
and efficient.

*Note: Sablon is still in early development. Please report if you encounter any issues along the way.*

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'sablon'
```


## Usage

```ruby
require "sablon"
template = Sablon.template(File.expand_path("~/Desktop/template.docx"))
context = {
  title: "Fabulous Document",
  technologies: ["Ruby", "Markdown", "ODF"]
}
template.render_to_file File.expand_path("~/Desktop/output.docx"), context
```


### Writing Templates

Sablon templates are normal Word documents (`.docx`) sprinkled with MailMerge fields
to perform operations. The following section uses the notation `«=title»` to
refer to [Word MailMerge](http://en.wikipedia.org/wiki/Mail_merge) fields.

#### Content Insertion

The most basic operation is to insert content. The contents of a context
variable can be inserted using a field like:

```
«=title»
```

It's also possible to call a method on a context object using:

```
«=post.title»
```

NOTE: The dot operator can also be used to perform a hash lookup.
This means that it's not possible to call methods on a hash instance.
Sablon will always try to make a lookup instead.

This works for chained method calls and nested hash lookup as well:

```
«=buyer.address.street»
```

##### WordProcessingML

Generally Sablon tries to reuse the formatting defined in the template. However,
there are situations where more fine grained control is needed. Imagine you need
to insert a body of text containing different formats. If you can't decide the
format ahead of processing time (in the template) you can insert
[WordProcessingML](http://en.wikipedia.org/wiki/Microsoft_Office_XML_formats)
directly.

It's enough to use a simply insertion operation in the template:

```
«=long_description»
```

To insert WordProcessingML prepare the context accordingly:

```ruby
word_processing_ml = <<-XML.gsub("\n", "")
<w:p>
<w:r w:rsidRPr="00B97C39">
<w:rPr>
<w:b />
</w:rPr>
<w:t>this is bold text</w:t>
</w:r>
</w:p>
XML

context = {
  long_description: Sablon.content(:word_ml, word_processing_ml)
}
template.render_to_file File.expand_path("~/Desktop/output.docx"), context
```

IMPORTANT: This feature is very much *experimental*. Currently, the insertion
    will replace the containing paragraph. This means that other content in the same
    paragraph is discarded.

##### Markdown [deprecated]

IMPORTANT: Markdown insertion has been deprecated in favor of HTML
    insertion. For now the behavior is still packaged with sablon. Note that the
    implementation of `Sablon::Content::Markdown` is already based on
    `Sablon::Content::HTML`. Markdown insertion will be removed in the future.

Similar to WordProcessingML it's possible to use markdown while processing the
tempalte. You don't need to modify your templates, a simple insertion operation
is sufficient:

```
«=article.body»
```

To use Markdown insertion prepare the context like so:

```ruby
markdown_body = <<-MD
This text can contain *additional formatting*
according to the **Markdown** specification.
MD
context = {
  article: { body: Sablon.content(:markdown, markdown_body) }
}
template.render_to_file File.expand_path("~/Desktop/output.docx"), context
```

Markdown insertion has built-in support for:

* [Headers](http://spec.commonmark.org/0.17/#atx-header)
* [Paragraphs](http://spec.commonmark.org/0.17/#paragraphs)
* [Emphasis and strong emphasis](http://spec.commonmark.org/0.17/#emphasis-and-strong-emphasis)
* [Hard line breaks](http://spec.commonmark.org/0.17/#hard-line-breaks)
* [Lists](http://spec.commonmark.org/0.17/#lists)

For headings and lists to function properly it is necessary that the template
defines specific styles. Headings use styles called `Heading1`, `Heading2`,
etc. according to the header level. Ordered lists will use the style
`ListNumber` and unordered lists use `ListBullet`. Nested lists are not
supported. Normal text paragraphs use the style `Paragraph`. It's not necessary
to have that style in the template. Word will fall back to using the `Normal` style.

IMPORTANT: This feature is very much *experimental*. Currently, the insertion
    will replace the containing paragraph. This means that other content in the same
    paragraph is discarded. In the near future this feature will most likely be
    implemented on top of HTML insertion.

##### HTML [experimental]

Similar to WordProcessingML it's possible to use html as input while processing the
tempalte. You don't need to modify your templates, a simple insertion operation
is sufficient:

```
«=article.body»
```

To use HTML insertion prepare the context like so:

```ruby
html_body = <<-HTML
<div>This text can contain <em>additional formatting</em>
according to the <strong>HTML</strong> specification.</div>
HTML
context = {
  article: { html_body: Sablon.content(:html, html_body) }
}
template.render_to_file File.expand_path("~/Desktop/output.docx"), context
```

Currently HTML insertion is very limited and strongly focused on the HTML
generated by [Trix editor](https://github.com/basecamp/trix).

IMPORTANT: This feature is very much *experimental*. Currently, the insertion
    will replace the containing paragraph. This means that other content in the same
    paragraph is discarded.


#### Conditionals

Sablon can render parts of the template conditonally based on the value of a
context variable. Conditional fields are inserted around the content.

```
«technologies:if»
    ... arbitrary document markup ...
«technologies:endIf»
```

This will render the enclosed markup only if the expression is truthy.
Note that `nil`, `false` and `[]` are considered falsy. Everything else is
truthy.

For more complex conditionals you can use a predicate like so:

```
«body:if(present?)»
    ... arbitrary document markup ...
«body:endIf»
```

#### Loops

Loops repeat parts of the document.

```
«technologies:each(technology)»
    ... arbitrary document markup ...
    ... use `technology` to refer to the current item ...
«technologies:endEach»
```

Loops can be used to repeat table rows or list enumerations. The fields need to
be placed in within table cells or enumeration items enclosing the rows or items
to repeat. Have a look at the
[example template](test/fixtures/cv_template.docx) for more details.


#### Nesting

It is possible to nest loops and conditionals.

#### Comments

Sometimes it's necessary to include markup in the template that should not be
visible in the rendered output. For example when defining sample numbering
styles for HTML insertion.

```
«comment»
    ... arbitrary document markup ...
«endComment»
```

### Executable

The `sablon` executable can be used to process templates on the command-line.
The usage is as follows:

```
cat <context path>.json | sablon <template path> <output path>
```

If no `<output path>` is given, the document will be printed to stdout.


Have a look at [this test](test/executable_test.rb) for examples.

### Examples

#### Using a Ruby script

There is a [sample template](test/fixtures/cv_template.docx) in the
repository, which illustrates the functionality of sablon:

<p align="center">
  <img
  src="https://raw.githubusercontent.com/senny/sablon/master/misc/cv_template.png"
  alt="Sablon Template"/>
</p>

Processing this template with some sample data yields the following
[output document](test/fixtures/cv_sample.docx).
For more details, check out this [test case](test/sablon_test.rb).

<p align="center">
  <img
  src="https://raw.githubusercontent.com/senny/sablon/master/misc/cv_sample.png"
  alt="Sablon Output"/>
</p>

#### Using the sablon executable

The [executable test](test/executable_test.rb) showcases the `sablon`
executable.

The [template](test/fixtures/recipe_template.docx)

<p align="center">
  <img
  src="https://raw.githubusercontent.com/senny/sablon/master/misc/recipe_template.png"
  alt="Sablon Output"/>
</p>

is rendered using a [json context](test/fixtures/recipe_context.json) to provide
the data. Following is the resulting [output](test/fixtures/recipe_sample.docx):

<p align="center">
  <img
  src="https://raw.githubusercontent.com/senny/sablon/master/misc/recipe_sample.png"
  alt="Sablon Output"/>
</p>

## Contributing

1. Fork it ( https://github.com/senny/sablon/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


## Inspiration

These projects address a similar goal and inspired the work on Sablon:

* [ruby-docx-templater](https://github.com/jawspeak/ruby-docx-templater)
* [docx_mailmerge](https://github.com/annaswims/docx_mailmerge)

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

Sablon templates are normal word documents (`.docx`) sprinkled with MergeFields
to perform operations. The following section will use the notation `«=title»` to
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

The template can use a simple insertion operation like so:

```
«=long_description»
```

The thing that changes is the context passed when processing the template:

```ruby
word_processing_ml = <<-XML
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

**IMPORTANT:** This feature is very much *experimental*. Currently, this only
  works if the insertion is the only thing inside the template paragraph. Other
  content is discarded!

##### Markdown

Similar to WordProcessingML it's possible to insert markdown into a template.
Currently Sablon only supports a limited subset of markdown. More features will
follow in the future. You don't need to modify your templates, a simple
insertion operation is sufficient:

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
[example template](test/fixtures/sablon_sample.docx) for more details.


#### Nesting

It is possible to nest loops and conditionals.


### Executable

The `sablon` executable can be used to process templates on the command-line.
The usage is as follows:

```
cat <context path>.json | sablon <template path> <output path>
```

If no `<output path>` is given, the document will be printed to stdout.


Have a look at [this test](test/executable_test.rb) for examples.

### Examples

There is a [sample template](test/fixtures/sablon_template.docx) in the
repository, which illustrates the functionality of sablon:

<p align="center">
  <img
  src="https://raw.githubusercontent.com/senny/sablon/master/misc/template.png"
  alt="Sablon Template"/>
</p>

Processing this template with some sample data yields the following
[output document](test/fixtures/sablon_sample.docx).
For more details, check out this [test case](test/sablon_test.rb).

<p align="center">
  <img
  src="https://raw.githubusercontent.com/senny/sablon/master/misc/output.png"
  alt="Sablon Output"/>
</p>


## Contributing

1. Fork it ( https://github.com/[my-github-username]/sablon/fork )
2. Create your feature branch (`git checkout -b my-new-feature`)
3. Commit your changes (`git commit -am 'Add some feature'`)
4. Push to the branch (`git push origin my-new-feature`)
5. Create a new Pull Request


## Inspiration

These projects address a similar goal and inspired the work on Sablon:

* [ruby-docx-templater](https://github.com/jawspeak/ruby-docx-templater)
* [docx_mailmerge](https://github.com/annaswims/docx_mailmerge)

# -*- coding: utf-8 -*-
require "test_helper"
require "support/xml_snippets"

class SablonTest < Sablon::TestCase
  include XMLSnippets

  def setup
    super
    @base_path = Pathname.new(File.expand_path("../", __FILE__))
    @template_path = @base_path + "fixtures/cv_template.docx"
    @output_path = @base_path + "sandbox/cv.docx"
    @sample_path = @base_path + "fixtures/cv_sample.docx"
  end

  def test_generate_document_from_template
    template = Sablon.template @template_path

    skill = Struct.new(:index, :label, :rating)
    position = Struct.new(:when, :where, :tasks, :description)
    language = Struct.new(:name, :skill)
    education = Struct.new(:when, :where, :what)
    referee = Struct.new(:name, :company, :position, :phone)

    context = {
      current_time: '15.04.2015 14:57',
      metadata: { generator: "Sablon" },
      title: "Resume",
      person: OpenStruct.new("first_name" => "Ronald", "last_name" => "Anderson",
                             "phone" => "630-384-2975",
                             "email" => "ron.anderson@gmail.com",
                             "address" => {
                               "street" => "1009 Fraggle Drive",
                               "municipality" => "Wheaton",
                               "province_zip" => "IL 60187"}),
      skills: [skill.new("1.", "Java", "★" * 5),
               skill.new("2.", "Ruby", "★" * 3),
               skill.new("3.", "Python", "★" * 1),
               skill.new("4.", "XML, XSLT, JSP"),
               skill.new("5.", "automated testing", "★" * 3),
              ],
      education: [
                  education.new("2005 – 2008", "Birmingham University", "Degree: BSc Hons Computer Science. 2:1 Attained."),
                  education.new("2003 – 2005", "Yale Sixth Form College, Bristol.", "3 A Levels - Mathematics (A), Science (A), History (B)"),
                  education.new("1997 – 2003", "Berry High School, Bristol.", "11 GCSE’s – 5 As, 5 Bs, 1 C")
                 ],
      certifications: [],
      career: [position.new("February 2013 - Present", "Apps Limited", [],
                            "Ruby on Rails Web Developer for this retail merchandising company."),
               position.new("June 2010 - December 2012", "Digital Design Limited",
                            ["Ongoing ASP.NET website development using C#.",
                             "Developed CRM web application using SQL Server 2008.",
                             "SQL Server Reporting.",
                             "Helped junior developers gain understanding of C# and .NET framework and apply this accordingly."],
                            "Software Engineer for this financial services provider."),
               position.new("June 2008 - June 2010", "Development Consultancy Limited",
                            ["Development of new features and testing of functionality.",
                             "Assisted in development and documentation of several ASP.NET based applications.",
                             "Web application maintenance.",
                             "Ensured development was signed off prior to unit testing.",
                             "Liaised with various service providers."])
              ],
      languages: [language.new("English", "native speaker"),
                  language.new("German", "fluent"),
                  language.new("French", "basics"),
                 ],
      about_me: Sablon.content(:html, "I am fond of writing <i>short stories</i> and <i>poems</i> in my spare time,  <br />and have won several literary contests in pursuit of my <b>passion</b>."),
      activities: ["Writing", "Photography", "Traveling"],
      referees: [
                 referee.new("Mary P. Larsen", "Strongbod",
                             "Organizational development consultant", "509-471-9365"),
                 referee.new("Jeanne P. Eldridge", "Widdmann",
                             "Information designer", "530-376-1628")
                ]
    }

    properties = {
      start_page_number: 7
    }

    template.render_to_file @output_path, context, properties

    assert_docx_equal @sample_path, @output_path
  end
end

class SablonConditionalsTest < Sablon::TestCase
  include XMLSnippets

  def setup
    super
    @base_path = Pathname.new(File.expand_path("../", __FILE__))
    @template_path = @base_path + "fixtures/conditionals_template.docx"
    @output_path = @base_path + "sandbox/conditionals.docx"
    @sample_path = @base_path + "fixtures/conditionals_sample.docx"
  end

  def test_generate_document_from_template
    template = Sablon.template @template_path
    context = {
      paragraph: true,
      inline: true,
      table: true,
      table_inline: true,
      object: OpenStruct.new(true_method: true, false_method: false),
      success_content: '✓',
      fail_content: '✗',
      content: 'Some Content'
    }
    #
    template.render_to_file @output_path, context
    assert_docx_equal @sample_path, @output_path
  end
end

class SablonLoopsTest < Sablon::TestCase
  include XMLSnippets

  def setup
    super
    @base_path = Pathname.new(File.expand_path("../", __FILE__))
    @template_path = @base_path + "fixtures/loops_template.docx"
    @output_path = @base_path + "sandbox/loops.docx"
    @sample_path = @base_path + "fixtures/loops_sample.docx"
  end

  def test_generate_document_from_template
    template = Sablon.template @template_path
    context = {
      fruits: %w[Apple Blueberry Cranberry Date].map { |i| { name: i } },
      cars: %w[Silverado Serria Ram Tundra].map { |i| { name: i } }
    }

    template.render_to_file @output_path, context
    assert_docx_equal @sample_path, @output_path
  end
end

class SablonImagesTest < Sablon::TestCase
  def setup
    super
    @base_path = Pathname.new(File.expand_path("../", __FILE__))
    @template_path = @base_path + "fixtures/images_template.docx"
    @output_path = @base_path + "sandbox/images.docx"
    @sample_path = @base_path + "fixtures/images_sample.docx"
    @image_fixtures = @base_path + "fixtures/images"
  end

  def test_generate_document_from_template
    template = Sablon.template @template_path
    #
    # setup two image contents to allow quick reuse
    r2d2 = Sablon.content(:image, @image_fixtures.join('r2d2.jpg').to_s)
    c3po = Sablon.content(:image, @image_fixtures.join('c3po.jpg'))
    darth = Sablon.content(:image, @image_fixtures.join('darth_vader.jpg'))
    #
    im_data = StringIO.new(IO.binread(@image_fixtures.join('clone.jpg')))
    trooper = Sablon.content(:image, im_data, filename: 'clone.jpg')
    #
    # with the following context setup all trooper should be reused and
    # only a single file added to media. R2D2 should get duplicated in the
    # media folder because it is used in two different context keys as
    # separate instances. Darth Vader should not be duplicated because
    # the key "unused_darth" doesn't appear in the template
    context = {
      items: [
        { title: 'C-3PO', image: c3po },
        { title: 'R2-D2', image: r2d2 },
        { title: 'Darth Vader', 'image:image' => @image_fixtures.join('darth_vader.jpg') },
        { title: 'Storm Trooper', image: trooper }
      ],
      'image:r2d2' => @image_fixtures.join('r2d2.jpg'),
      'unused_darth' => darth,
      trooper: trooper
    }

    template.render_to_file @output_path, context
    assert_docx_equal @sample_path, @output_path

    # try to render a document with an image that has no extension
    trooper = Sablon.content(:image, im_data, filename: 'clone')
    context = { items: [], trooper: trooper }
    e = assert_raises ArgumentError do
      template.render_to_file @output_path, context
    end
    assert_equal "Filename: 'clone' has no discernable extension", e.message
  end
end

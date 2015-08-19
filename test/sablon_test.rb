# -*- coding: utf-8 -*-
require "test_helper"
require "support/xml_snippets"

class SablonTest < Sablon::TestCase
  include Sablon::Test::Assertions
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
      current_time: Time.now.strftime("%d.%m.%Y %H:%M"),
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
      about_me: Sablon.content(:markdown, "I am fond of writing *short stories* and *poems* in my spare time,  \nand have won several literary contests in pursuit of my **passion**."),
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

class SablonTest < Sablon::TestCase
  include Sablon::Test::Assertions
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
    context = {paragraph: true, inline: true, table: true, table_inline: true, content: "Some Content"}
    template.render_to_file @output_path, context
    assert_docx_equal @sample_path, @output_path
  end
end

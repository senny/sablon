module XMLSnippets
  def snippet(name)
    File.read(File.expand_path("#{name}.xml", snippet_path))
  end

  def snippet_path
    @snippet_path ||= File.expand_path("../../fixtures/xml", __FILE__)
  end
end

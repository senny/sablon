module HTMLSnippets
  def snippet(name)
    File.read(File.expand_path("#{name}.html", snippet_path))
  end

  def snippet_path
    @snippet_path ||= File.expand_path("../../fixtures/html", __FILE__)
  end
end

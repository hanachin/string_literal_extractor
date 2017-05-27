require 'ripper'

class StringLiteralExtractor < Ripper
  include Enumerable

  %i(heredoc_beg tstring_beg).each do |event|
    module_eval(<<-CODE, __FILE__, __LINE__ + 1)
    def on_#{event}(tok)
      @buf ||= []
      @buf << [[lineno, column]]
    end
    CODE
  end

  def on_tstring_end(tok)
    @buf.last << [lineno, column]
  end

  def on_heredoc_end(tok)
    @buf.last << [lineno, column + tok.size-1]
  end

  def on_CHAR(literal)
    @string_literal_each.call(literal, [[lineno, column], [lineno, column + 1]])
  end

  def on_string_literal(*args)
    pos = @buf.pop
    lineno_pos = pos.map(&:first)
    column_pos = pos.map(&:last)
    lines = @src.lines[lineno_pos.first-1...lineno_pos.last]
    if lineno_pos.first == lineno_pos.last
      lines[0] = lines[0][column_pos.first..column_pos.last]
    else
      lines[0] = lines[0].dup.tap { |l| l[0...column_pos.first] = '' }
      lines[-1] = lines[-1].dup.tap { |l| l[column_pos.last+1..-1] = '' }
    end
    @string_literal_each.call(lines.join, pos)

    args.unshift(:string_literal)
    args
  end

  def initialize(src, filename="(ripper)", lineno=1)
    @src = src
    super
  end

  def each
    @string_literal_each = -> (literal, pos) { yield literal, pos }
    parse
  end
end

return unless $0 == __FILE__

StringLiteralExtractor.new(%q{"#{'hi' + 'hoi'}"}).each do |literal, pos|
  p [literal, pos]
end

StringLiteralExtractor.new(%q{"a" "b"}).each do |literal, pos|
  p [literal, pos]
end

StringLiteralExtractor.new("<<EOS\n  foo  bar\n\nEOS").each do |literal, pos|
  p [literal, pos]
end

StringLiteralExtractor.new('"#{hi}"').each do |literal, pos|
  p [literal, pos]
end

StringLiteralExtractor.new('?a').each do |literal, pos|
  p [literal, pos]
end

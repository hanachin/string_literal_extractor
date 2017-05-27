StringLiteralExtractor
======================

extract string literal from your ruby program

Installation
------------

    % gem install string_literal_extractor

Usage
-----

    require 'string_literal_extractor'
    code = <<~'RUBY'
    name = "john doe"
    puts "Hello, #{name}"
    RUBY
    StringLiteralExtractor.new(code).each { |s| puts s }
    # "john doe"
    # "Hello, #{name}"

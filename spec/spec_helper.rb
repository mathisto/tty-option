# frozen_string_literal: true

if ENV["COVERAGE"] == "true"
  require "simplecov"
  require "coveralls"

  SimpleCov.formatter = SimpleCov::Formatter::MultiFormatter.new([
    SimpleCov::Formatter::HTMLFormatter,
    Coveralls::SimpleCov::Formatter
  ])

  SimpleCov.start do
    command_name "spec"
    add_filter "spec"
  end
end

require "bundler/setup"
require "tty/option"

module Helpers
  def unindent(text)
    text.gsub(/^#{text.scan(/^[ \t]+(?=\S)/).min}/, "")
  end

  def new_parameter(type, name, **settings)
    param_class = Object.const_get("TTY::Option::Parameter::#{type.capitalize}")
    param_class.new(name, **settings)
  end

  def command(name = "Command", parent = nil, &block)
    stub_const(name, parent ? Class.new(parent) : Class.new)
    klass = Object.const_get(name)
    klass.send :include, TTY::Option
    klass.class_eval(&block) if block
    klass
  end

  def new_command(*args, &block)
    command(*args, &block).new
  end
end

RSpec.configure do |config|
  config.include(Helpers)
  # Enable flags like --only-failures and --next-failure
  config.example_status_persistence_file_path = ".rspec_status"

  # Disable RSpec exposing methods globally on `Module` and `main`
  config.disable_monkey_patching!

  config.expect_with :rspec do |c|
    c.syntax = :expect
  end
end

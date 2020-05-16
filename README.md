<div align="center">
  <a href="https://piotrmurach.github.io/tty" target="_blank"><img width="130" src="https://github.com/piotrmurach/tty/raw/master/images/tty.png" alt="tty logo" /></a>
</div>

# TTY::Option

[![Gem Version](https://badge.fury.io/rb/tty-option.svg)][gem]
[![Build Status](https://secure.travis-ci.org/piotrmurach/tty-option.svg?branch=master)][travis]
[![Build status](https://ci.appveyor.com/api/projects/status/gxml9ttyvgpeasy5?svg=true)][appveyor]
[![Maintainability](https://api.codeclimate.com/v1/badges/1083a2fd114d6faf5d65/maintainability)][codeclimate]
[![Coverage Status](https://coveralls.io/repos/github/piotrmurach/tty-option/badge.svg)][coverage]
[![Inline docs](http://inch-ci.org/github/piotrmurach/tty-option.svg?branch=master)][inchpages]

[gem]: http://badge.fury.io/rb/tty-option
[travis]: http://travis-ci.org/piotrmurach/tty-option
[appveyor]: https://ci.appveyor.com/project/piotrmurach/tty-option
[codeclimate]: https://codeclimate.com/github/piotrmurach/tty-option/maintainability
[coverage]: https://coveralls.io/github/piotrmurach/tty-option
[inchpages]: http://inch-ci.org/github/piotrmurach/tty-option

> Parser for command line arguments, keywords, options and environment variables

## Features

* Support for parsing of **positional arguments**, **keyword arguments**, **flags**, **options** and **environment variables**.
* A convenient way to declare parsed parameters via DSL with a fallback to **hash-like syntax**.
* Parsing is flexible and **doesn't force any order for the parameters**. Options can be inserted anywhere between positional or keyword arguments.
* Handling of complex option and keyword argument inputs like **lists** and **maps**.
* Many **conversions types** provided out of the box, from basic integer to more complex hash structures.
* Automatic **help generation** that can be customised with **usage** helpers like banner, examples and more.
* Parsing **doesn't raise errors** by default and collects issues to allow for better user experience. 
* Ability to declare **global options** with inheritance that copies parameters to a child class.

## Installation

Add this line to your application's Gemfile:

```ruby
gem 'tty-option'
```

And then execute:

    $ bundle install

Or install it yourself as:

    $ gem install tty-option

## Contents

* [1. Usage](#1-usage)
* [2. API](#2-api)
  * [2.1 argument](#21-argument)
  * [2.2 keyword](#22-keyword)
  * [2.3 option](#23-option)
  * [2.4 environment](#24-environment)
  * [2.5 parameter settings](#25-parameter-settings)
    * [2.5.1 arity](#251-arity)
    * [2.5.2 convert](#252-convert)
    * [2.5.3 default](#253-default)
    * [2.5.4 description](#254-description)
    * [2.5.5 hidden](#255-hidden)
    * [2.5.6 optional](#256-optional)
    * [2.5.7 permit](#257-permit)
    * [2.5.8 required](#258-required)
    * [2.5.9 validate](#259-validate)
  * [2.6 parse](#26-parse)
  * [2.7 params](#27-params)
    * [2.7.1 errors](#271-errors)
    * [2.7.2 remaining](#272-remaining)
    * [2.7.3 valid?](#273-valid?)
  * [2.8 usage](#28-usage)
    * [2.8.1 header](#281-header)
    * [2.8.2 program](#282-program)
    * [2.8.3 command](#283-command)
    * [2.8.4 banner](#284-banner)
    * [2.8.5 description](#285-description)
    * [2.8.6 example](#286-examples)
    * [2.8.7 footer](#287-footer)
  * [2.9 help](#29-help)
    * [2.9.1 add_before|after](#291-add_beforeafter)
    * [2.9.2 delete](#292-delete)
    * [2.9.3 replace](#293-replace)
    * [2.9.4 :order](#294-order)
    * [2.9.5 :param_display](#295-param_display)
    * [2.9.6 :width](#296-width)

## 1. Usage

To start parsing command line parameters include `TTY::Option` module.

Now, you're ready to define parsed parameters like arguments, keywords, flags, options or environment variables.

For example, a quick demo to create a command that mixes all parameters usage:

```ruby
class Command
  include TTY::Option

  usage do
    program "dock"

    command "run"

    desc "Run a command in a new container"

    example "Set working directory (-w)",
            "  $ dock run -w /path/to/dir/ ubuntu pwd"

    example <<~EOS
    Mount volume
      $ dock run -v `pwd`:`pwd` -w `pwd` ubuntu pwd
    EOS
  end

  argument :image do
    required
    desc "The name of the image to use"
  end

  argument :command do
    optional
    desc "The command to run inside the image"
  end

  keyword :restart do
    default "no"
    permit %w[no on-failure always unless-stopped]
    desc "Restart policy to apply when a container exits"
  end

  flag :help do
    short "-h"
    long "--help"
    desc "Print usage"
  end

  flag :detach do
    short "-d"
    long "--detach"
    desc "Run container in background and print container ID"
  end

  option :name do
    required
    long "--name string"
    desc "Assign a name to the container"
  end

  option :port do
    arity one_or_more
    short "-p"
    long "--publish list"
    convert :list
    desc "Publish a container's port(s) to the host"
  end

  def run
    if params[:help]
      print help
      exit
    else
      pp params.to_h
    end
  end
end
```

Then create a command instance:

```ruby
cmd = Command.new
```

And provided input from the command line:

```
restart=always -d -p 5000:3000 5001:8080 --name web ubuntu:16.4 bash
```

Start parsing from `ARGV` or provide a custom array of inputs:

```ruby
cmd.parse
# or
cmd.parse(%w[restart=always -d -p 5000:3000 5001:8080 --name web ubuntu:16.4 bash])
```

And run the command to see the values:

```ruby
cmd.run
# =>
# {:help=>false,
#  :detach=>true,
#  :port=>["5000:3000", "5001:8080"],
#  :name=>"web",
#  :restart=>"always",
#  :image=>"ubuntu:16.4",
#  :command=>"bash"}
````

The `cmd` object also has a direct access to all the parameters via the `params`:

```ruby
cmd.params[:name]     # => "web"
cmd.params["command"] # => "bash
````

And when `--help` is found on the command line the run will print help:

```ruby
cmd.run
```

To print help information to the terminal use `help` method:

```ruby
print cmd.help
```

This will result in the following output:

```
Usage: dock run [OPTIONS] IMAGE [COMMAND] [RESTART=RESTART]

Run a command in a new container

Arguments:
  command  The command to run inside the image
  image    The name of the image to use

Keywords:
  restart=restart  Restart policy to apply when a container exits (permitted:
                   no, on-failure, always, unless-stopped) (default "no")

Options:
  -d, --detach        Run container in background and print container ID
  -h, --help          Print usage
      --name string   Assign a name to the container
  -p, --publish list  Publish a container's port(s) to the host

Examples:
  Set working directory (-w)
    $ dock run -w /path/to/dir/ ubuntu pwd

  Mount volume
    $ dock run -v `pwd`:`pwd` -w `pwd` ubuntu pwd
```

## 2. API

### 2.1 argument

You can parse positional arguments with the `argument` method. To declare an argument you need to provide a name for the access key in the `params` like so:

```ruby
argument :foo
```

Then parsing command line input:

```
11 12 13
```

Would result only in one argument parsed and the remaining ignored:

```ruby
params[:foo] # => "11"
```

A more involved example to parse multiple positional arguments requires use of helper methods:

```ruby
argument :foo do
  required                   # a default
  variable "foo(int)"        # name for the usage display
  arity one_or_more          # how many times to occur
  convert :int               # values converted to intenger
  validate -> { |v| v < 14 } # validation rule
  desc "Some foo desc"       # description for the usage display
end
```

Parsing the previous input:

```bash
11 12 13
```

Would result in all values being collected and converted to integers:

```ruby
params[:foo] # => [11,12,13]
```

The previous argument definition can also be written using hash syntax. This is especially useful if you want to specify arguments programmatically:

```ruby
argument :foo,
  required: true,
  variable: "foo(int)",
  arity: "+",
  convert: :int,
  validate: -> { |v| v < 14 },
  desc: "Some foo desc"
```

To read more about available settings see [parameter settings](#25-parameter-settings).

### 2.2 keyword

To parse keyword arguments use the `keyword` method. To declare a keyword argument you need to provide a name for the key in the `params` like so:

```ruby
keyword :foo
```

By default the keyword parameter name will be used as the keyword name on the command line:

```bash
foo=11
```

Parsing the above would result in:

```ruby
params[:foo] # => "11"
```

A more involved example to parse multiple keyword arguments requires use of helper methods:

```ruby
keyword :foo do
  required                   # by default keywrod is not required
  arity one_or_more          # how many times to occur
  convert :int               # values converted to intenger
  validate -> { |v| v < 14 } # validation rule
  desc "Some foo desc"       # description for the usage display
end
```

Then provided the following command line input:

```bash
foo=11 foo=12 foo=13
```

The result would be:

```ruby
params[:foo] # => [11,12,13]
```

You can also specify for the keyword argument to accept a list type:

```ruby
keyword :foo do
  required                   # by default keyword is not required
  arity one_or_more          # how many times to occur
  convert :int_list          # input can be a list of intengers
  validate -> { |v| v < 14 } # validation rule
  desc "Some foo desc"       # description for the usage display
end
```

Then command line input can contain a list as well:

```bash
foo=11 12 foo=13
```

Which will result in the same value:

```ruby
params[:foo] # => [11,12,13]
```

A keyword definition can be also a hash. This is especially useful if you intend to specify keyword arguments programmatically:

```ruby
keyword :foo,
  required: true,
  arity: :+,
  convert: :int_list,
  validate: -> { |v| v < 14 },
  desc: "Some foo desc"
```

To read more about available settings see [parameter settings](#25-parameter-settings).

### 2.3 option

To parse options and flags use the `option` or `flag` methods.

To declare an option you need to provide a name for the key used to access value in the `params`:

```ruby
option :foo
```

By default the option parameter name will be used to generate a long option name:

```
--foo=11
```

Parsing the above will result in:

```ruby
params[:foo] # => "11"
```

To specify a different name for the parsed option use the `short` and `long` helpers:

```ruby
option :foo do
  short "-f"     # declares a short flag
  long  "--foo"  # declares a long flag
end
```

If you wish for an option to accept an argument, you need to provide an extra label.

For example, for both short and long flag to require argument do:

```ruby
option :foo do
  short "-f"
  long  "--foo string"  # use any name after the flag name to specify required argument
  # or
  long  "--foo=string"  # you can also separate required argument with =
end
```

To make a long option with an optional argument do:

```ruby
option :foo do
  long "--foo [string]" # use any name within square brackets to make argument optional
end
```

A more involved example that parses a list of integer may look like this:

```ruby
option :foo do
  required                   # by default option is not required
  arity one_or_more          # how many times option can occur
  short "-f"                 # declares a short flag name
  long  "--foo list"         # declares a long flag with a required argument
  convert :int_list          # input can be a list of intengers
  validate -> { |v| v < 14 } # validation rule
  desc "Some foo desc"       # description for the usage display
end
```

Given command line input:

```bash
--foo=10,11 -f 12 13
```

The resulting value will be:

```ruby
params[:foo] # => [10,11,12,13]
```

An option  definition can be declared as a hash as well. This is especially useful if you intend to specify options programmatically:

```ruby
option :foo,
  required: true,
  arity: :+,
  short: "-f",
  long: "--foo list",
  convert: :int_list,
  validate: -> { |v| v < 14 },
  desc: "Some foo desc"
```

To read more about available settings see [parameter settings](#25-parameter-settings).

### 2.4 environment

To parse environment variables use `environment` or `env` methods.

By default, a parameter name will match a environment variable with the same name. For example, specifying a variable `:foo`:

```ruby
env :foo
```

And then given the following command line input:

```
FOO=bar
```

The resulting parameter would be:

```ruby
params[:foo] # => "bar"
````

To change the variable name to something else use `var` or `variable` helper:

```ruby
env :foo do
  var "FOO_ENV"
end
```

And then given a `FOO_ENV=bar` on the command line would result in:

```ruby
params[:foo] # => "bar"
```

A more involved example that parses a list of integer may look like this:

```ruby
environment :foo do
  required                   # by default environment is not required
  arity one_or_more          # how many times env var can occur
  variable "FOO_ENV"         # the command line input name
  convert map_of(:int)       # input can be a map of integers
  validate -> { |v| v < 14 } # validation rule
  desc "Some foo desc"       # description for the usage display
end
```

Given command line input:

```bash
FOO_ENV=a:1&b:2 FOO_ENV=c=3 d=4
```

The resulting `params` would be:

```ruby
params[:foo] # => {a:1,b:2,c:3,d:4}
```

To read more about available settings see [parameter settings](#25-parameter-settings).

### 2.5 parameter settings

These settings are supported by all parameter types with the exception of `short` and `long` which are specific to options only.

#### 2.5.1 arity

To describe how many times a given parameter may appear in the command line use the `arity` method. By default every parameter is assumed to appear only once. Any other occurrence will be disregarded and included in the remaining parameters list.

For example, to match argument exactly 2 times do:

```ruby
argument :foo do
  arity 2
end
````

Then parsing from the command line:

```ruby
bar baz
```

Will give the following:

```ruby
params[:foo] # => ["bar", "baz"]
```

For parameters that expect a value, specifying arity will collect all the values matching arity requirement. For example, matching keywords:

```ruby
keyword :foo do
  arity 3
end
```

And then parsing the following:

```
foo=1 foo=2 foo=3
```

Will produce:

```ruby
params[:foo] # => ["1", "2", "3"]
```

To match any number of times use `:any`, `:*`, `-1`, `any` or `zero_or_more`:

```ruby
argument :foo do
  arity zero_or_more
end
```

To match at at least one time use `:+` or `one_or_more`:

```ruby
option :foo do
  arity one_or_more
  short "-b"
  long "--bar string"
end
```

You can also specify upper boundary with `at_least` helper as well:

```ruby
keyword :foo do
  arity at_least(3)
end
```

#### 2.5.2 convert

You can convert any parameter argument to another type using the `convert` method with a predefined symbol or class name. For example, to convert an argument to integer you can do:

```ruby
argument :foo do
  convert :int
end
```

The conversion types that are supported:

* `:boolean`|`:bool` - e.g. 'yes/1/y/t/' becomes `true`, 'no/0/n/f' becomes `false`
* `:date` - parses dates formats "28/03/2020", "March 28th 2020"
* `:float` - e.g. `-1` becomes `-1.0`
* `:int`|`:integer` - e.g. `+1` becomes `1`
* `:path`|`:pathname` - converts to `Pathname` object
* `:regexp` - e.g. "foo|bar" becomes `/foo|bar/`
* `:uri` - converts to `URI` object
* `:sym`|`:symbol` - e.g. "foo" becomes `:foo`
* `:list`|`:array` - e.g. 'a,b,c' becomes `["a", "b", "c"]`
* `:map`|`:hash` - e.g. 'a:1 b:2 c:3' becomes `{a: "1", b: "2", c: "3"}`

In addition you can specify a plural or append `list` to any base type:

* `:ints` or `:int_list` - will convert to a list of integers
* `:floats` or `:float_list` - will convert to a list of floats
* `:bools` or `:bool_list` - will convert to a list of booleans, e.g. 't,f,t' becomes `[true, false, true]`

Similarly, you can append `map` to any base type:

* `:int_map` - will convert to a map of integers, e.g 'a:1 b:2 c:3' becomes `{a: 1, b: 2, c: 3}`
* `:bool_map` - will convert to a map of booleans, e.g 'a:t b:f c:t' becomes `{a: true, b: false, c: true}`

For example, to parse options with required list and map arguments:

```ruby
option :foo do
  long "--foo map"
  convert :bools
end

option :bar do
  long "--bar int map"
  convert :int_map
end
````

And then parsing the following:

```bash
--foo t,f,t --bar a:1 b:2 c:3
```

Will give the following:

```ruby
params[:foo]
# => [true, false, true]
params[:bar]
# => {a:1, b:2, c:3}
````

You can also provide `proc` to define your own conversion:

```ruby
option :bar do
  long "--bar string"
  convert ->(val) { val.upcase }
end
```

#### 2.5.3 default

#### 2.5.4 description

#### 2.5.5 hidden

#### 2.5.6 optional

#### 2.5.7 permit

The `permit` setting allows you to restrict an input to a set of possible values:

```ruby
option :foo do
  long "--foo string"
  permit ["bar", "baz"]
end
```

And then parsing

```
--foo bar
```

Will populate parameters value:

```ruby
params[:foo] # => "bar"
```

Attempting to parse not permitted value will raise an error:

```
--foo qux
# raises TTY::Option::UnpermitedArgument
```

Permitted values are checked after applying conversion:

```ruby
option :foo do
  long "--foo int"
  confert :int
  permit [11, 12, 13]
end
```

Then parsing:

```
--foo 14
# raises TTY::Option::UnpermittedArgument
```
#### 2.5.8 required

#### 2.5.9 validate

Use the `validate` setting if you wish to ensure only valid inputs are allowed.

You can use a string or regular expression to describe your validation rule:

```ruby
option :foo do
  long "--foo VAL"
  validate "\d+"
end
```

Then parsing:

```
--foo bar
```

Will internally cause an exception `TTY::Option::InvalidArgument` that will be stored in the `errors` list and make `params` invalid.

You can also express a validation rule with a `proc` object:

```ruby
keyword :foo do
  arity one_or_more
  convert :int
  validate ->(val) { val < 12 }
end
```

Then parsing:

```
foo=11 foo=13
```

Will similarly collect the `TTY::Option::InvalidArgument` error and render `params` invalid.

### 2.6 parse

After all parameters are defined, use the `parse` to process command line inputs.

By default the `parse` method takes the input from the `ARGV` and the `ENV` variables.

Alternatively, you can call `parse` with custom inputs. This is especially useful for testing your commands.

Given parameter definitions:

```ruby
argument :foo

flag :bar

keyword :baz

env :qux
```

Then parsing the following inputs:

```ruby
parse(%w[12 --bar baz=a QUX=b])
```

Would populate parameters:

```ruby
params[:foo] # => "12"
params[:bar] # => true
params[:baz] # => "a"
params[:qux] # => "b"
```

The parsing is flexible and doesn't force any order for the parameters. Options can be inserted anywhere between positional or keyword arguments.

It handles parsing of compacted shorthand options that start with a single dash. These need to be boolean options bar the last one that can accept argument. All these are valid:

```
-f
-fbq
-fbqs 12  # mixed with an argument
```

Parameter parsing stops after the `--` terminator is found. The leftover inputs are collected and accessible via the `remaining` method.

### 2.7 params

#### 2.7.1 errors

#### 2.7.2 remaining

#### 2.7.3 valid?

### 2.8 usage

The `usage` and its helper methods allow you to configure the `help` display to your liking. The `header`, `desc(ription)`, `example` and `footer` can be called many times. Each new call will create a new paragraph. If you wish to insert multiple lines inside a given paragraph separate arguments with a comma.

#### 2.8.1 header

To provide information above the banner explaining how to execute a program, use the `header` helper.

```ruby
usage do
  header "A command-line interface for foo service"
end
```

Further, you can add more paragraphs as comma-separated arguments to `header` with an empty string to represent a new line:

```ruby
usage do
  header "A command-line interface for foo service",
         "",
         "Access and retrieve data from foo service"
end
```

Alternatively, you can add paragraphs calling `header` multiple times:

```ruby
usage do
  header "A command-line interface for foo service"

  header "Access and retrieve data from foo service"
end
```

#### 2.8.2 program

By default the program name is inferred for you from the executable file name.

You can override the default name using the `program` helper.

```ruby
usage do
  program "custom-name"
end
````

Then the program name will be used in the banner:

```bash
Usage: custom-name
```

#### 2.8.3 command

By default the command name is inferred from the class name.

For example, based on the following:

```ruby
class NetworkCreate
  include TTY::Option
end
```

The command name will become `network-create`. To change this use the `command` and `commands` helpers:

```ruby
class NetworkCreate
  include TTY::Option

  usage do
    commands "network", "create"
  end
end
````

This will result in the following usage information:

```
Usage: program network create
```

If you don't wish to infer the command name use the `no_command` method:

```ruby
usage do
  no_command
end
````

#### 2.8.4 banner

The usage information of how to use a program is displayed right after header. If no header is specified, it will be displayed first.

This information is handled by the `banner` helper. By default, it will use the parameter definitions to generate usage information.

For example, given the following declarations:

```ruby
usage do
  program :foo

  command :bar
end

argument :baz

keyword :qux do
  convert :uri
end

option :fum
```

The generated usage information will be:

```bash
Usage: foo bar [OPTIONS] BAZ [QUX=URI]
```

If you want to configure how arguments are displayed specify [2.8.2 :param_display](#282-param_display) setting.

You can also change completely how to the banner is displayed:

```ruby
usage do
  program "foo"

  banner "Usage: #{program} BAR BAZ"
end
```

#### 2.8.5 desc(ription)

The description is placed between usage information and the parameters and given with `desc` or `description` helpers.

The `desc` helper accepts multiple strings that will be displayed on separate lines.

```ruby
usage do
  desc "Some description", "on multiline"
end
```

This will result in the following help output:

```
Some description
on multiline
```

The `desc` helper can be called multiple times to build an examples section:

```ruby
usage do
  desc "Some description", "on multiline"

  desc <<~EOS
  Another description
  on multiline
  EOS
end
```

#### 2.8.6 example(s)

To add usage examples section to the help information use the `example` or `examples` methods.

The `example` helper accepts multiple strings that will be displayed on separate lines. For instance, the following class will add a single example:

```ruby
usage do
  example "Some example how to use foo",
          " $ foo bar"
end
```

This will result in the following help output:

```
Examples:
  Some example how to use foo
    $ foo bar
```

The `example` helper can be called multiple times to build an examples section:

```ruby
usage do
  example "Some example how to use foo",
          " $ foo bar"

  example <<~EOS
  Another example how to use foo"
    $ foo baz
  EOS
end
```

The usage help will contain the following:

```
Examples:
  Some example how to use foo
    $ foo bar

  Another example how to use foo
    $ foo baz
```

#### 2.8.7 footer

To provide information after all information in the usage help, use the `footer` helper.

```ruby
usage do
  footer "Run a command followed by --help to see more info"
end
```

Further, you can add more paragraphs as comma-separated arguments to `footer` with an empty string to represent a new line:

```ruby
usage do
  footer "Run a command followed by --help to see more info",
         "",
         "Options marked with (...) can be given more than once"
end
```

Alternatively, you can add paragraphs calling `footer` multiple times:

```ruby
usage do
  footer "Run a command followed by --help to see more info"

  footer "Options marked with (...) can be given more than once"
end
```

### 2.9 help

With the `help` method you can generate usage information.

#### 2.9.1 add_before|after

#### 2.9.2 delete

#### 2.9.3 replace

#### 2.9.4 :order

All parameters are alphabetically ordered in their respective sections. To change this default behaviour use the `:order` keyword when invoking `help`.

The `:order` expects a `Proc` object. For example, to remove any ordering and preserve the parameter declaration order do:

```ruby
help(order: ->(params) { params })
````

#### 2.9.5 :param_display

By default banner positional and keyword arguments are displayed with all letters uppercased.

For example, given the following parameter declarations:

```ruby
program "run"

argument :foo

keyword :bar do
  required
  convert :uri
end

option :baz
```

The banner output would be as follows:

```bash
Usage: run [OPTIONS] FOO BAR=URI
```

To change the banner parameter display use `:param_display` keyword.

For example, to lowercase and surround your parameters with `< >` brackets do:

```ruby
help(param_display: ->(str) { "<#{str.downcase}>" })
```

This will produce the following output:

```
Usage: run [<options>] <foo> <bar>=<uri>
```

#### 2.9.6 :width

By default the help information is wrapped at `80` columns. If this is not what you want you can change it with `:width` keyword.

For example, to change the help to always take up all the terminal columns consider using [tty-screen](https://github.com/piotrmurach/tty-screen):

```ruby
help(width: TTY::Screen.width)
```

## Development

After checking out the repo, run `bin/setup` to install dependencies. Then, run `rake spec` to run the tests. You can also run `bin/console` for an interactive prompt that will allow you to experiment.

To install this gem onto your local machine, run `bundle exec rake install`. To release a new version, update the version number in `version.rb`, and then run `bundle exec rake release`, which will create a git tag for the version, push git commits and tags, and push the `.gem` file to [rubygems.org](https://rubygems.org).

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/piotrmurach/tty-option. This project is intended to be a safe, welcoming space for collaboration, and contributors are expected to adhere to the [code of conduct](https://github.com/piotrmurach/tty-option/blob/master/CODE_OF_CONDUCT.md).

## License

The gem is available as open source under the terms of the [MIT License](https://opensource.org/licenses/MIT).

## Code of Conduct

Everyone interacting in the TTY::Option project's codebases, issue trackers, chat rooms and mailing lists is expected to follow the [code of conduct](https://github.com/piotrmurach/tty-option/blob/master/CODE_OF_CONDUCT.md).

## Copyright

Copyright (c) 2020 Piotr Murach. See LICENSE for further details.

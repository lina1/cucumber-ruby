# frozen_string_literal: true
require 'cucumber/cucumber_expressions/parameter_type'
require 'cucumber/deprecate'

module Cucumber
  module Glue
    # This module provides the methods the DSL you can use to define
    # steps, hooks, transforms etc.
    module Dsl
      class << self
        attr_writer :rb_language

        def alias_adverb(adverb)
          alias_method adverb, :register_rb_step_definition
        end

        def build_rb_world_factory(world_modules, namespaced_world_modules, proc)
          @rb_language.build_rb_world_factory(world_modules, namespaced_world_modules, proc)
        end

        def register_rb_hook(phase, tag_names, proc)
          @rb_language.register_rb_hook(phase, tag_names, proc)
        end

        def define_parameter_type(parameter_type)
          @rb_language.define_parameter_type(parameter_type)
        end

        def register_rb_step_definition(regexp, proc_or_sym, options = {})
          @rb_language.register_rb_step_definition(regexp, proc_or_sym, options)
        end
      end

      # Registers any number of +world_modules+ (Ruby Modules) and/or a Proc.
      # The +proc+ will be executed once before each scenario to create an
      # Object that the scenario's steps will run within. Any +world_modules+
      # will be mixed into this Object (via Object#extend).
      #
      # By default the +world modules+ are added to a global namespace. It is
      # possible to create a namespaced World by using an hash, where the
      # symbols are the namespaces.
      #
      # This method is typically called from one or more Ruby scripts under
      # <tt>features/support</tt>. You can call this method as many times as you
      # like (to register more modules), but if you try to register more than
      # one Proc you will get an error.
      #
      # Cucumber will not yield anything to the +proc+. Examples:
      #
      #    World do
      #      MyClass.new
      #    end
      #
      #    World(MyModule)
      #
      #    World(my_module: MyModule)
      #
      def World(*world_modules, **namespaced_world_modules, &proc)
        Dsl.build_rb_world_factory(world_modules, namespaced_world_modules, proc)
      end

      # Registers a proc that will run before each Scenario. You can register as many
      # as you want (typically from ruby scripts under <tt>support/hooks.rb</tt>).
      def Before(*tag_expressions, &proc)
        Dsl.register_rb_hook('before', tag_expressions, proc)
      end

      # Registers a proc that will run after each Scenario. You can register as many
      # as you want (typically from ruby scripts under <tt>support/hooks.rb</tt>).
      def After(*tag_expressions, &proc)
        Dsl.register_rb_hook('after', tag_expressions, proc)
      end

      # Registers a proc that will be wrapped around each scenario. The proc
      # should accept two arguments: two arguments: the scenario and a "block"
      # argument (but passed as a regular argument, since blocks cannot accept
      # blocks in 1.8), on which it should call the .call method. You can register
      # as many  as you want (typically from ruby scripts under <tt>support/hooks.rb</tt>).
      def Around(*tag_expressions, &proc)
        Dsl.register_rb_hook('around', tag_expressions, proc)
      end

      # Registers a proc that will run after each Step. You can register as
      # as you want (typically from ruby scripts under <tt>support/hooks.rb</tt>).
      def AfterStep(*tag_expressions, &proc)
        Dsl.register_rb_hook('after_step', tag_expressions, proc)
      end

      # Registers a proc that will be called with a step definition argument if it
      # matches the pattern passed as the first argument to Transform. Alternatively, if
      # the pattern contains captures then they will be yielded as arguments to the
      # provided proc. The return value of the proc is consequently yielded to the
      # step definition.
      def Transform(regexp, &proc)
        Cucumber.deprecate(
          'Use ParameterType(...) instead',
          'Transform',
          '2.6.0'
        )
        parameter_type = CucumberExpressions::ParameterType.new(
          regexp.to_s,
          regexp,
          Object,
          proc,
          false,
          true
        )
        Dsl.define_parameter_type(parameter_type)
      end

      def ParameterType(options)
        parameter_type = CucumberExpressions::ParameterType.new(
          options[:name],
          options[:regexp],
          options[:type],
          options[:transformer],
          options[:use_for_snippets],
          options[:prefer_for_regexp_match]
        )
        Dsl.define_parameter_type(parameter_type)
      end

      # Registers a proc that will run after Cucumber is configured. You can register as
      # as you want (typically from ruby scripts under <tt>support/hooks.rb</tt>).
      def AfterConfiguration(&proc)
        Dsl.register_rb_hook('after_configuration', [], proc)
      end

      # Registers a new Ruby StepDefinition. This method is aliased
      # to <tt>Given</tt>, <tt>When</tt> and <tt>Then</tt>, and
      # also to the i18n translations whenever a feature of a
      # new language is loaded.
      #
      # If provided, the +symbol+ is sent to the <tt>World</tt> object
      # as defined by #World. A new <tt>World</tt> object is created
      # for each scenario and is shared across step definitions within
      # that scenario. If the +options+ hash contains an <tt>:on</tt>
      # key, the value for this is assumed to be a proc. This proc
      # will be executed in the context of the <tt>World</tt> object
      # and then sent the +symbol+.
      #
      # If no +symbol+ if provided then the +&proc+ gets executed in
      # the context of the <tt>World</tt> object.
      def register_rb_step_definition(regexp, symbol = nil, options = {}, &proc)
        proc_or_sym = symbol || proc
        Dsl.register_rb_step_definition(regexp, proc_or_sym, options)
      end
    end
  end
end

# TODO: can we avoid adding methods to the global namespace (Kernel)
extend(Cucumber::Glue::Dsl)

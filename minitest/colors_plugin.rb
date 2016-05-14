# encoding: UTF-8

require 'minitest'

# A minitest plugin that adds colors to test reports.
#
# TO DO:
# bypass Colors if io is not a console
#
module Minitest
  def self.plugin_colors_init(options)
    # Clearing reporters is needed to replace the Minitest default reporter
    Minitest.reporter.reporters.clear
    Minitest.reporter << ColoredProgressReporter.new(options[:io], options)
    Minitest.reporter << ColoredSummaryReporter.new(options[:io], options)
  end

  ##
  # Colors for stdout
  #
  class Colors
    DEFAULT_COLOR = "\e[0m"
    WHITE         = "\e[40m\e[37m"
    RED           = "\e[41m\e[37m"
    RED_CHAR      = "\e[31m"
    GREEN         = "\e[42m\e[37m"
    GREEN_CHAR    = "\e[32m"
    YELLOW        = "\e[43m\e[37m"
    YELLOW_CHAR   = "\e[33m"
    BLUE          = "\e[44m\e[37m"
    BLUE_CHAR     = "\e[34m"
  end

  ##
  # A very simple reporter that prints the status and the name
  # of each test during the run.
  # Test statuses are colored as I want.
  #
  # Replace Minitest::ProgressReporter
  #
  class ColoredProgressReporter < ProgressReporter
    def record(result) # :nodoc:
      case result.result_code
      when '.' then
        io.print Colors::GREEN  + 'SUCCESS'
      when 'E' then
        io.print Colors::RED    + 'ERROR  '
      when 'F' then
        io.print Colors::RED    + 'FAILURE'
      when 'S' then
        io.print Colors::YELLOW + 'SKIPPED'
      else
        io.print Colors::BLUE   + '-------'
      end
      io.print Colors::DEFAULT_COLOR
      io.puts " #{result.name}"
    end
  end

  ##
  # A reporter that prints the header, summary,
  # and failure details at the end of the run,
  # as the Minitest default one but I find mine
  # more readable.
  #
  # Replace Minitest::SummaryReporter
  #
  class ColoredSummaryReporter < StatisticsReporter
    def start # :nodoc:
      self.start_time = Minitest.clock_time
      io.puts Colors::BLUE + 'Minitest version ' + VERSION + Colors::DEFAULT_COLOR
      io.puts 'Running...'
      io.puts
    end

    def report # :nodoc:
      aggregate = results.group_by { |r| r.failure.class }
      aggregate.default = []

      self.total_time = Minitest.clock_time - start_time
      self.failures   = aggregate[Assertion].size
      self.errors     = aggregate[UnexpectedError].size
      self.skips      = aggregate[Skip].size

      io.puts
      io.puts summary
      io.puts statistics
      io.puts
      print_aggregated_results
    end

    def statistics # :nodoc:
      'in %.6fs (%.4f runs/s, %.4f assertions/s)' %
        [total_time, count / total_time, assertions / total_time]
    end

    def summary # :nodoc:
      '%d runs, %d assertions, %d failures, %d errors, %d skips' %
        [count, assertions, failures, errors, skips]
    end

    def print_aggregated_results # :nodoc:
      results.each_with_index do |result, i|
        if result.to_s[0] == 'S'
          io.print Colors::YELLOW_CHAR
        else
          io.print Colors::RED_CHAR
        end
        io.print '%3d) %s%s' % [i + 1, result, Colors::DEFAULT_COLOR]
        name, src = result.location.split(' ', 2)
        io.puts 'Run this single test with:'
        io.puts "ruby #{src[1, src.index(':') - 1]} --name #{name}"
        io.puts
      end
    end
  end
end

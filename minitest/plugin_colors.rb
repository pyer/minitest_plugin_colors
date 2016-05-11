# encoding: UTF-8

require 'minitest'

# A minitest plugin that adds colors to test reports.
#
module Minitest
  def self.plugin_colors_init(options)
    # Clearing reporters is needed to replace the Minitest default reporter
    Minitest.reporter.reporters.clear
    Minitest.reporter << ColoredProgressReporter.new(options[:io], options)
    Minitest.reporter << ColoredSummaryReporter.new(options[:io], options)
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
        green
        print 'SUCCESS'
      when 'E' then
        red
        print 'ERROR  '
      when 'F' then
        red
        print 'FAILURE'
      when 'S' then
        yellow
        print 'SKIPPED'
      else
        blue
        print '       '
      end
      reset_color
      io.puts " #{result.name}"
    end

    private

    def white
      io.print "\e[40m\e[37m"
      # io.print "\e[37m"
    end

    def red
      io.print "\e[41m\e[37m"
      # io.print "\e[31m"
    end

    def green
      io.print "\e[42m\e[37m"
      # io.print "\e[32m"
    end

    def yellow
      io.print "\e[43m\e[37m"
      # io.print "\e[33m"
    end

    def blue
      io.print "\e[44m\e[37m"
      # io.print "\e[34m"
    end

    def reset_color
      io.print "\e[0m"
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
      io.puts "\nMinitest version " + VERSION
      io.puts 'Running...'
      io.puts ''
    end

    def report # :nodoc:
      aggregate = results.group_by { |r| r.failure.class }
      aggregate.default = []

      self.total_time = Minitest.clock_time - start_time
      self.failures   = aggregate[Assertion].size
      self.errors     = aggregate[UnexpectedError].size
      self.skips      = aggregate[Skip].size

      io.puts ''
      io.puts summary
      io.puts statistics
      io.puts aggregated_results
    end

    def statistics # :nodoc:
      'in %.6fs (%.4f runs/s, %.4f assertions/s)' %
        [total_time, count / total_time, assertions / total_time]
    end

    def summary # :nodoc:
      '%d runs, %d assertions, %d failures, %d errors, %d skips' %
        [count, assertions, failures, errors, skips]
    end

    def aggregated_results # :nodoc:
      s = results.each_with_index.map { |result, i| "\n%3d) %s" % [i + 1, result] }.join("\n") + "\n"
      s.force_encoding(io.external_encoding) if
        ENCS && io.external_encoding && s.encoding != io.external_encoding
      s
    end
  end
end

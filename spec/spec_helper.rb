require 'chefspec'
require 'chefspec/berkshelf'
require_relative '../libraries/matchers'
require_relative 'platforms'

RSpec.configure do |config|
  # Prohibit using the should syntax
  config.expect_with :rspec do |spec|
    spec.syntax = :expect
  end

  # Run specs in random order to surface order dependencies. If you find an
  # order dependency and want to debug it, you can fix the order by providing
  # the seed, which is printed after each run.
  # --seed 1234
  # config.order = 'random'
  # Library tests first (they are capitalized) to not interfere with coverage
  # config.register_ordering(:global) do |list|
  #   list.sort_by(&:description)
  # end

  # ChefSpec configuration
  config.log_level = :error
  config.color = true
  config.formatter = :documentation
  config.tty = true
end

at_exit { ChefSpec::Coverage.report! }

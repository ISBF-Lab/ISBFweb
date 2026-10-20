# frozen_string_literal: true
puts "Ruby: #{RUBY_VERSION}"
Gem.use_paths(Gem.dir, [*Gem.path, "/var/www/discourse/vendor/bundle/ruby/3.4.0", "/lint-gems"])
%w[
  bundler
  rspec-core
  rspec-rails
  fabrication
  webmock
  mocha
  test-prof
  syntax_tree
  rubocop
  lefthook
].each do |name|
  specifications = Gem::Specification.find_all_by_name(name)
  puts "#{name}: #{specifications.map(&:version).join(", ")}"
end
if File.exist?("/sys/fs/cgroup/memory.peak")
  puts "Peak memory: #{File.read("/sys/fs/cgroup/memory.peak").strip}"
end

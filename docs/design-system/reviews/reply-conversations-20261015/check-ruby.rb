require "json"
require "yaml"

files = JSON.parse(File.read("/review/changed-files.json"))
results = files.filter_map do |file|
  next unless file.end_with?(".rb", ".yml")
  begin
    source = File.read("/workspace/#{file}")
    file.end_with?(".rb") ? RubyVM::InstructionSequence.compile(source) : YAML.parse(source)
    { file: file, parsed: true }
  rescue Exception => error
    { file: file, parsed: false, error: error.message }
  end
end
File.write("/review/ruby-yaml-syntax.json", JSON.pretty_generate(results) + "\n")
puts JSON.generate(results)
exit 1 if results.any? { |result| !result[:parsed] }

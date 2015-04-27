env_file = File.expand_path('.env', __dir__)
if File.exist? env_file
  File.read(env_file).lines.each do |line|
    next unless line =~ /^\s*([^=]+)=["']?([^=]+)["']?\s*$/
    ENV[$1] = $2.chomp
  end
end

$:.unshift File.expand_path('lib', __dir__)
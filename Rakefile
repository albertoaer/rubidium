task default: %w[run]

task :run do
    load './main.rb'
end

task :test do
    exec 'bundle', 'exec', 'rspec', './spec/*'
end
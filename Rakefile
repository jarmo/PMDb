desc "build with exerb"
task :build do
  Dir.chdir "lib" do
    sh *%w[bundle exec mkexy -I. pmdb.rb]
    sh *%w[exerb pmdb.exy]
  end
end

task :default => :build

desc "build with exerb"
task :build do
  Dir.chdir "lib" do
    sh *%w[bundle exec mkexy -I. pmdb.rb]
    sh *%w[exerb pmdb.exy]
  end
  FileUtils.mkdir_p "bin"
  FileUtils.mv Dir.glob("lib/pmdb.{exe,exy}"), "bin/", :verbose => true
end

task :default => :build

require 'find'
require 'yaml'

namespace :gem do

  desc "Install required gems"
  task :install do
   require 'config/java.rb'
   require 'config/R.rb'
   if (ENV['R_HOME'] && ENV['LD_LIBRARY_PATH'] && ENV['JAVA_HOME'])
       sh "gem install rake sqlite3-ruby rino xml-simple mechanize rjb statarray haml"
       sh "gem install rsruby -- --with-R-dir=#{ENV['R_HOME']} --with-R-include=#{ENV['R_INCLUDE']}"
       sh "rake opentox:compile_java"
   else
       puts "ERROR: $R_HOME, $JAVA_HOME or $LD_LIBRARY_PATH not set. Could not install gems rjb and rsruby. Please change your settings in config/java.rb and config/R.rb "
   end
  end

end

namespace :opentox do

  desc "Compile java libraries"
  task :compile_java do
    `cd vendor/plugins/opentox/lib/java; make`
  end

  desc "Configure LD_LIBRARY_PATH for OpenBabel"
  task :config_libs do

    require "rbconfig.rb"    
    include Config

    obsrcdir = RAILS_ROOT+"/vendor/plugins/opentox/lib/ob/"
    obversion = "2.1.1"
    sh "cd /tmp && tar xzvf #{obsrcdir}openbabel-"+obversion+"-ruby.tar.gz"
    sh "cd /tmp/openbabel-"+obversion+" && ./configure && make && make install"
    sh "cd /tmp/openbabel-"+obversion+"/scripts/ruby && ruby extconf.rb && make && make install"
    libconfig = File.new("/etc/ld.so.conf", "a")
    libdir = "/usr/local/lib"
    libconfig.puts libdir

    sh "ln -sf /usr/lib/R/lib/libRlapack.so /usr/lib/R/"
    sh "ln -sf /usr/lib/R/lib/libR.so /usr/lib/R/"
    libconfig = File.new("/etc/ld.so.conf", "a")
    libdir = "/usr/lib/R/"
    libconfig.puts libdir

    puts "-----------------------------------"
    puts "Please run '/sbin/ldconfig' as root"
    puts "-----------------------------------"

  end

  namespace :install do

    desc "Install base packages"
    task :base do 
       sh "apt-get update"
       sh "apt-get install irb"
       sh "rake svn:up"
    end


    desc "Install opentox packages for Debian"
    task :debian => :base do
       sh "apt-get install sqlite3 java-jdk libsqlite3-dev r-base r-base-dev sysutils rdoc"
       sh "ln -sf /usr/lib/R/lib/libRlapack.so /usr/lib/R/"
       sh "ln -sf /usr/lib/R/lib/libR.so /usr/lib/R/"
       #require 'config/java.rb'
       #if (ENV['R_HOME'] && ENV['LD_LIBRARY_PATH'])
       #    sh "gem install -y rake sqlite3-ruby rino xml-simple mechanize rjb statarray rsruby -- --with-R-dir=$R_HOME"
       #    sh "rake opentox:compile_java"
       #else
       #    puts "ERROR: $R_HOME or $LD_LIBRARY_PATH not set. Could not install gems rjb and rsruby (see OpenTox README)."
       #end
       sh "rake db:schema:load"
    end

    desc "Install opentox packages for Ubuntu"
    task :ubuntu => :base do 
       sh "apt-get -y install sqlite3 sun-java6-jdk libsqlite3-dev ruby r-base sysutils rdoc ruby1.8-dev"
       sh "ln -sf /usr/lib/R/lib/libRlapack.so /usr/lib/R/"
       sh "ln -sf /usr/lib/R/lib/libR.so /usr/lib/R/"
       #require 'config/java.rb'
       #if (ENV['R_HOME'] && ENV['LD_LIBRARY_PATH'])
       #    sh "gem install -y rake sqlite3-ruby rino xml-simple mechanize rjb statarray rsruby -- --with-R-dir=$R_HOME"
       #    sh "rake opentox:compile_java"
       #else
       #    puts "ERROR: $R_HOME or $LD_LIBRARY_PATH not set. Could not install gems rjb and rsruby (see OpenTox README)."
       #end
       sh "rake db:schema:load"
    end

  end

end
  
=begin
namespace :db do
  namespace :production do
    desc "Backup production database"
    task :backup do
      t = Time.now
      FileUtils.cp('db/production.sqlite3','db/production.'+t.year.to_s+t.month.to_s+t.day.to_s)
    end
  end

  namespace :development do
    desc "Sync development database with production database"
    task :sync do
      FileUtils.cp('db/production.sqlite3','db/development.sqlite3')
    end
  end

end
=end

namespace :affy do

  desc "Import, normalize and filter Affimetrix CEL files"
  task :import => :environment do

    load(RAILS_ROOT+"/vendor/plugins/opentox/app/models/dags_object.rb")
    load(RAILS_ROOT+"/vendor/plugins/opentox/app/models/inputs_output.rb")
    ENV['R_HOME'] = '/usr/lib/R'

    r = RSRuby.instance
    r.library('affy')
    r.library('genefilter')

    filenames = ''
    file_docs = FileDocument.find(:all)
    file_docs.each do |f|
      if f.file.match(/\.CEL/)
        if filenames == ''
          filenames = '"' + f.file.gsub(/\/home\/ch\/sensitiv\/config\/\.\.\//,'') +'"'
        else
          filenames = filenames + ',"' + f.file.gsub(/\/home\/ch\/sensitiv\/config\/\.\.\//,'') + '"'
        end
      end
    end

    #puts filenames
    r.eval_R("eset <- justRMA(#{filenames})")

    pheno = File.new("#{RAILS_ROOT}/tmp/pheno.txt","w")
    #puts pheno.path
    BioSample.find(1).attributes.each do |c,v|
      pheno.print "\t\"#{c.gsub(/_id/,"").underscore}\""
    end
    pheno.print "\n"

    file_docs = FileDocument.find(:all)
    biosamples = Array.new
    file_docs.each do |f|
      if f.file.match(/\.CEL/)
        puts "#{f.file} has #{f.inputs.size} inputs!" if f.inputs.size > 1
        f.inputs.each do |i|
          if i.class == BioSample

            pheno.print "\"#{File.basename(f.file)}\""

            i.attributes.each do |n,v|
              if v.blank?
                pheno.print "\t\"NA\""
              elsif n.match(/_id/)
                n = n.gsub(/_id/,"")
                value = n.classify.constantize.find(v).name
                pheno.print "\t\"#{value}\""
              else
                pheno.print "\t\"#{v}\""
              end
            end
            pheno.print "\n"
          end
        end
      end
    end

    p = pheno.path
    call = "\"phenoData(eset) <- read.phenoData('"+pheno.path+"')\""
    #puts call
    r.eval_R(call)

    # prefilter
    # 1. at least 20% of the samples have a measured intensity of at least 100
    # 2. coefficient of variation of intensities across samples between 0.7 and 10
    # values from MTPALL.pdf

    r.eval_R("X <- exprs(eset)")
    r.eval_R("ffun <- filterfun(pOverA(p=0.2,A=100),cv(a=0.7,b=10))")
    r.eval_R("filt <- genefilter(2^X,ffun)")
    r.eval_R("filtALL <- eset[filt,]")
    r.eval_R("save(filtALL,file='tmp/all-filtered.R')")

  end

end

#task "opentox:update_production" => "opentox:start_mongrel"
#task "opentox:start_mongrel"=> "db:migrate"
#task "db:migrate" => "opentox:compile_java"
#task "db:migrate" => ["db:schema:dump", "opentox:create_migrations"]
#task "db:schema:dump" => "opentox:copy_production_db"
#task "db:migrate" => "opentox:create_migrations"
#task "db:migrate" => "opentox:backup_production_db"
#task "db:migrate" => "opentox:stop_mongrel"

=begin
	desc "Copies all plugin migrations preserving original migration sequence (use it instead of script/generate plugin_migration)"
	task :create_migrations do

    d = Dir.open('db/migrate/')

    # clean migration directory
    #d.each do |f|
      #FileUtils.mv('db/migrate/'+f,'db/migrate/bak/'+f, :verbose => true) if  f =~ /^\d/
    #end

    # copy plugin migrations to db/migrate (linking does not work with db:migrate)
    Find.find('vendor/plugins/') do |path|
      if FileTest.directory?(path) && File.basename(path) == 'migrate' && path =~ /opentox|lazar/
        d = Dir.open(path)
        d.each do |f|
          FileUtils.cp(path+'/'+f,'db/migrate/'+f, :verbose => true)  if f =~ /^\d.*rb$/
        end
      end
    end

	end
=end
=begin
namespace :db do

  desc "Backup database"
  task :backup => :environment do
    # Skip some tables with binary data or large amounts of data
    SlimRailsInstaller::Database.backup ['mint__config', 'mint_visit', 'mint_outclicks']
  end

  desc "Restore database. Uses FILE or most recent file from db/backup"
  task :restore => :environment do
    filename = ENV['FILE'].blank? ? Dir['db/backup/*.yml'].last : ENV['FILE']
    SlimRailsInstaller::Database.restore(filename)
  end

end
=end

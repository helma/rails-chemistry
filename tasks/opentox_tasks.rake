require 'find'
require 'yaml'

namespace :R do

  path = RAILS_ROOT+"/vendor/lib/R"
  r = RAILS_ROOT+"/vendor/bin/R"

  namespace :install do

    desc "install the kernlab package"
    task :kernlab do
      sh "export R_HOME=#{path}/lib/R &&  #{r} CMD INSTALL http://cran.r-project.org/src/contrib/Archive/kernlab/kernlab_0.9-7.tar.gz"
    end
  end
end

=begin
namespace :openbabel do

  path = RAILS_ROOT+"/vendor/lib/openbabel"
  src = path + "/src"

  task :checkout do
    if File.directory?(src)
      sh "cd #{src} && git pull"
    else
      FileUtils.mkdir_p(path) unless File.directory?(path)
      sh "git clone http://opentox.org/git/ch/openbabel.git #{src}"
      sh "cd #{src} && ./configure --prefix=#{path}"
    end
  end

  # (Re)configure openbabel libraries
  task :configure => "openbabel:checkout" do
    #sh "cd #{src} && ./configure --prefix=#{path}"
    sh "cd #{src} && ./config.status"
  end

  desc "Install/update openbabel libraries"
  task :install => "openbabel:checkout" do
    sh "cd #{src} && make install"
    sh "cd #{src}/scripts/ruby && ruby extconf.rb --with-openbabel-dir=#{path}"
    sh "cd #{src}/scripts/ruby && make && export DESTDIR=#{path} && make install"
  end

end

namespace :R do

  path = RAILS_ROOT+"/vendor/lib/R"
  src = path + "/src"

  task :checkout do
    if File.directory?(src)
      sh "cd #{src} && git pull"
    else
      FileUtils.mkdir_p(path) unless File.directory?(path)
      sh "git clone http://opentox.org/git/ch/R.git #{src}"
      sh "cd #{src} && ./configure --prefix=#{path} --enable-R-shlib"
    end
  end

  # (Re)configure R libraries
  task :configure => "R:checkout" do
    sh "cd #{src} && ./configure --prefix=#{path} --enable-R-shlib"
  end

  task :compile => "R:checkout" do
    sh "cd #{src} && make"
  end

  task :base => "R:compile" do
    sh "cd #{src} && make install rincludedir=#{path}/include/"
  end

  #task :kernlab => "R:install" do
  task :kernlab => "R:base" do
    sh "export R_HOME=#{path}/lib/R && cd #{src} &&  #{path}/bin/R CMD INSTALL kernlab_0.9-7.tar.gz"
  end

  desc "Install/update R libraries"
  task :install => "R:kernlab"

end
=end

namespace :opentox do

  desc "Compile java libraries"
  task :compile_java do
    sh "cd vendor/plugins/opentox/lib/java; make"
  end

  desc "Install opentox plugin with libraries"
  #task :install => ["R:install", "openbabel:install", "opentox:compile_java"] do
  task :install => ["opentox:compile_java"] do
    sh "rake db:schema:load"
  end

end

=begin
namespace :debian do

  desc "Install debian packages for the compilation of libraries and external programs" 
  task :prepare do
     sh "sudo apt-get install sqlite3 java-jdk libsqlite3-dev sysutils ruby rdoc ruby1.8-dev libblas-dev liblapack-dev"
  end

end

namespace :ubuntu do

  desc "Install ubuntu packages for the compilation of libraries and external programs" 
  task :prepare do
     sh "sudo apt-get install sqlite3 java-jdk libsqlite3-dev sysutils rdoc"
     sh "sudo apt-get install sqlite3 sun-java6-jdk libsqlite3-dev sysutils ruby rdoc ruby1.8-dev libblas-dev liblapack-dev"
  end

end
=end
  
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

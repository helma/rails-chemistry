namespace :rchem do

  desc "Install rchem plugin (compile java)"
  task :compile do
    sh "cd vendor/plugins/rails-chemistry/lib/java; make"
  end

end


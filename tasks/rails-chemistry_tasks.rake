require 'find'
require 'yaml'

namespace :rails_chemistry do

  desc "Install rails-chemistry plugin (compile java)"
  task :compile do
    sh "cd vendor/plugins/rails-chemistry/lib/java; make"
  end

end


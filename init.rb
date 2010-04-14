require 'mailee'
ActiveRecord::Base.send(:include, Mailee::Sync)
#ActionController::Base.send(:include, Softa::Uses::DataGrid)
#ActionController::Base.send(:include, Softa::DataGrid::Uses)

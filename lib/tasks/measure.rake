path = File.dirname(__FILE__)
path = path.index('lib') == 0 ? "./#{path}" : path
require 'json'
require 'zlib'
gem 'rubyzip'
require 'zip/zip'
require 'zip/zipfilesystem'
require File.join(path,'../quality-measure-engine')

measures_dir = ENV['MEASURE_DIR'] || 'measures'
bundle_dir = ENV['BUNDLE_DIR'] || './'
xls_dir = ENV['XLS_DIR'] || 'xls'

namespace :measures do
  
  desc 'Build all measures to tmp directory'
  task :build do
    puts "Loading measures from #{measures_dir}"
    dest_dir = File.join('.', 'tmp')
    Dir.mkdir(dest_dir) if !Dir.exist?(dest_dir)
    Dir.glob(File.join(measures_dir, '*')).each do |measure_dir|
      measures = QME::Measure::Loader.load_measure(measure_dir)
      measures.each do |measure|
        id = measure['id']
        sub_id = measure['sub_id']
        json = JSON.pretty_generate(measure)
        file_name = File.join(dest_dir, "#{id}#{sub_id}.json")
        file = File.new(file_name,  "w")
        file.write(json)
        file.close
      end
    end
  end
  
  
  
  desc "run the map_test tool"
  task :map_tool do
    puts "Loading measures from #{measures_dir}"
    require File.join(path,"../../map_test/map_test.rb")
  end
  
  
  desc "bundle measures into a compressed file for deployment"
  task :bundle do
  
    puts "Loading measures from #{measures_dir}"
    md = File.join(bundle_dir,measures_dir)
    js = File.join(bundle_dir,'js')
    bf = File.join(bundle_dir,'bundle.js')
    
    tmp = './tmp'
    bundle_tmp = File.join(tmp,'bundle')
    
    md.sub!(%r[/$],'')
    FileUtils.rm bundle_tmp, :force=>true
    FileUtils.mkdir_p(bundle_tmp)
    archive = File.join(tmp,'bundle.zip')
    FileUtils.rm archive, :force=>true
    
    Zip::ZipFile.open(archive, 'w') do |zipfile|
      Dir["#{md}/**/**"].reject{|f|f==archive}.each do |file|
        zipfile.add(file.sub(bundle_dir,''),file)
      end
          
      Dir["#{js}/**/**"].reject{|f|f==archive}.each do |file|
        zipfile.add(file.sub(bundle_dir,''),file)
      end
      
      if File.exists?(bf)
        zipfile.add(bf.sub(bundle_dir,''),bf)
      end
    end
  end
  
  desc "convert NQF Excel spreadsheets to JSON"
  task :convert do
    require LIB + '/qme/measure/properties_builder'
    require LIB + '/qme/measure/properties_converter'
    dest_dir = File.join('.', 'tmp')    
    Dir.mkdir(dest_dir) if !Dir.exist?(dest_dir)
    Dir.glob(File.join(xls_dir, '*.xlsx')).each do |measure|
      properties = QME::Measure::Converter.from_xls(measure)
      json = JSON.pretty_generate(properties)
      file_name = File.join(dest_dir, "#{File.basename(measure)}.json")
      file = File.new(file_name,  "w")
      file.write(json)
      file.close
    end
  end

end

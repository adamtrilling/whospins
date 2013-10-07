def load_yaml(file)
  yml_file = File.join(Rails.root, 'config', "#{file}.yml")
  erb = ERB.new(File.read(yml_file)).result
  YAML.load(erb).to_hash[Rails.env]
end
require 'xcodeproj'
require 'securerandom'

project_path = '/Users/astorluduena/Documents/XCodeProjects/Randomitas/Randomitas.xcodeproj'
project = Xcodeproj::Project.open(project_path)
target = project.targets.first

# Helper to generate Xcode-like UUIDs
def generate_uuid
  SecureRandom.hex(12).upcase
end

file_path = 'Randomitas/Localizable.xcstrings'
existing_file = project.files.find { |file| file.path == file_path }

if existing_file
  puts "Localizable.xcstrings already in project."
else
  # Find the main group for Randomitas
  main_group = project.main_group.children.find { |c| c.display_name == 'Randomitas' || c.path == 'Randomitas' }
  
  if main_group.class == Xcodeproj::Project::Object::PBXGroup
    puts "Standard PBXGroup found"
    file_ref = main_group.new_file('Localizable.xcstrings')
    target.resources_build_phase.add_file_reference(file_ref, true)
    project.save
    puts "Added Localizable.xcstrings successfully."
  else
    puts "Found newer synchronized group: #{main_group.class}"
    puts "Xcode 16+ uses synchronized groups. Since this file is in the synchronized directory 'Randomitas', Xcode will automatically detect and include it in the build process. No project.pbxproj modification is required for synchronized folders!"
  end
end

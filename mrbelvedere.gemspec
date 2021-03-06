# Generated by jeweler
# DO NOT EDIT THIS FILE DIRECTLY
# Instead, edit Jeweler::Tasks in Rakefile, and run the gemspec command
# -*- encoding: utf-8 -*-

Gem::Specification.new do |s|
  s.name = %q{mrbelvedere}
  s.version = "0.2.0"

  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Delano Mandelbaum"]
  s.date = %q{2011-04-18}
  s.default_executable = %q{mrbelvedere}
  s.description = %q{Basic operational stats for web apps. IN PROGRESS}
  s.email = %q{delano@solutious.com}
  s.executables = ["mrbelvedere"]
  s.extra_rdoc_files = [
    "README.md"
  ]
  s.files = [
    "CHANGES.txt",
     "README.md",
     "Rakefile",
     "VERSION.yml",
     "lib/mrbelvedere.rb",
     "lib/mrbelvedere/jobs.rb",
     "mrbelvedere.gemspec",
     "try/10_basic_try.rb"
  ]
  s.homepage = %q{http://github.com/delano/mrbelvedere}
  s.rdoc_options = ["--charset=UTF-8"]
  s.require_paths = ["lib"]
  s.rubyforge_project = %q{mrbelvedere}
  s.rubygems_version = %q{1.5.2}
  s.summary = %q{Basic operational stats for web apps. IN PROGRESS}

  if s.respond_to? :specification_version then
    s.specification_version = 3

    if Gem::Version.new(Gem::VERSION) >= Gem::Version.new('1.2.0') then
      s.add_runtime_dependency(%q<storable>, [">= 0"])
      s.add_runtime_dependency(%q<familia>, [">= 0"])
      s.add_runtime_dependency(%q<gibbler>, [">= 0"])
      s.add_runtime_dependency(%q<useragent>, [">= 0"])
      s.add_runtime_dependency(%q<addressable>, [">= 0"])
    else
      s.add_dependency(%q<storable>, [">= 0"])
      s.add_dependency(%q<familia>, [">= 0"])
      s.add_dependency(%q<gibbler>, [">= 0"])
      s.add_dependency(%q<useragent>, [">= 0"])
      s.add_dependency(%q<addressable>, [">= 0"])
    end
  else
    s.add_dependency(%q<storable>, [">= 0"])
    s.add_dependency(%q<familia>, [">= 0"])
    s.add_dependency(%q<gibbler>, [">= 0"])
    s.add_dependency(%q<useragent>, [">= 0"])
    s.add_dependency(%q<addressable>, [">= 0"])
  end
end


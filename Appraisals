# frozen_string_literal: true

%w[6.1 7.0 7.1 7.2 8.0].each do |version|
  appraise "activesupport-#{version}" do
    gem "activesupport", "~> #{version}.0"
  end
end

appraise "activesupport-main" do
  gem "activesupport", git: "https://github.com/rails/rails", glob: "activesupport/*.gemspec"
end

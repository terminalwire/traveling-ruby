require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'octokit', '~> 6.0'
end

require 'octokit'
require 'fileutils'

REPO = "terminalwire/traveling-ruby"
GITHUB_TOKEN = ENV.fetch('GITHUB_TOKEN')
COMMIT =  `git rev-parse HEAD`.strip
WORKFLOWS = %w[
  alpine-x86_64.yml
  alpine-arm64.yml
  osx-x86_64.yml
  osx-arm64.yml
  ubuntu-x86_64.yml
  ubuntu-arm64.yml
]

github = Octokit::Client.new(access_token: ENV.fetch('GITHUB_TOKEN'))

WORKFLOWS.each do |workflow|
  puts "Processing #{workflow}"
  architecture = File.basename(workflow, ".yml")
  # Get the latest run.
  # TODO: We might need to sort by date and status.
  run = github.workflow_runs(REPO, workflow, head_sha: COMMIT).workflow_runs.first

  if run
    # Iterate through each each artifact.
    path = Pathname.new("artifacts/#{architecture}")
    FileUtils.mkdir_p path

    github.workflow_run_artifacts(REPO, run.id).artifacts.each do |artifact|
      download_path = path.join(artifact.name)
      puts "Downloading #{artifact.archive_download_url} (#{artifact.size_in_bytes} bytes) to #{download_path}"

      # Download the artifact using Octokit
      File.open(download_path, 'wb') do |file|
        file.write(github.get(artifact.archive_download_url))
      end

      puts "Downloaded #{artifact.name} to #{download_path}"
    end
  else
    puts "No runs found for #{workflow}"
  end
end

require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'octokit', '~> 6.0'
end

require 'octokit'

# Configuration
GITHUB_TOKEN = ENV.fetch('GITHUB_TOKEN')
REPO = 'terminalwire/traveling-ruby' # Replace with your repo

# Initialize Octokit client
client = Octokit::Client.new(access_token: GITHUB_TOKEN)

# List all workflows and artifacts
def list_artifacts_for_workflows(client, repo)
  workflows = client.workflows(repo)[:workflows]

  workflows.each do |workflow|
    puts "Workflow Name: #{workflow[:name]}"
    puts "Path: #{workflow[:path]}"
    puts "State: #{workflow[:state]}"
    puts "-" * 40

    # Get the latest workflow runs for this workflow
    runs = client.workflow_runs(repo, workflow[:id], status: 'success', per_page: 1)
    if runs[:workflow_runs].empty?
      puts "No successful runs found for this workflow."
      next
    end

    # Get the latest run ID
    latest_run = runs[:workflow_runs].first
    puts "Latest Run ID: #{latest_run[:id]}"
    puts "Latest Run URL: #{latest_run[:html_url]}"

    # Get artifacts for the latest run
    artifacts = client.workflow_run_artifacts(repo, latest_run[:id])[:artifacts]
    if artifacts.empty?
      puts "No artifacts found for this run."
    else
      puts "Artifacts:"
      artifacts.each do |artifact|
        puts "  - Name: #{artifact[:name]}"
        puts "    Size: #{artifact[:size_in_bytes]} bytes"
        puts "    URL: #{artifact[:archive_download_url]}"

        # response = client.get(artifact[:archive_download_url])
        # File.write(artifact.name, response)
        puts "Saved to #{artifact.name}"
      end
    end
    puts "-" * 40
  end
end

# Main logic
begin
  puts "Listing all workflows and artifacts for repository: #{REPO}"
  list_artifacts_for_workflows(client, REPO)
rescue StandardError => e
  puts "Error: #{e.message}"
  puts e.backtrace if ENV['DEBUG']
  exit 1
end

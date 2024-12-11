require 'bundler/inline'

gemfile do
  source 'https://rubygems.org'
  gem 'octokit', '~> 6.0'
  gem 'rake'
  gem 'base64'
  gem 'parallel'
end

require 'octokit'

REPO = "terminalwire/traveling-ruby"
GITHUB_TOKEN = ENV.fetch('GITHUB_TOKEN')
COMMIT =  ENV.fetch("COMMIT", `git rev-parse HEAD`.strip)
WORKFLOWS = %w[
  alpine-x86_64.yml
  alpine-arm64.yml
  osx-x86_64.yml
  osx-arm64.yml
  ubuntu-x86_64.yml
  ubuntu-arm64.yml
]
CONCURRENCY = ENV.fetch('CONCURRENCY', 6)

def release_tag(time = Time.now)
  time.utc.strftime('%Y-%m-%d_%H:%M')
end

def concurrently(items, &)
  Parallel.each(items, in_threads: CONCURRENCY, &)
end

github = Octokit::Client.new(access_token: ENV.fetch('GITHUB_TOKEN'))

desc "Download build artifacts"
task :download do
  sh "mkdir -p artifacts/workflow"

  WORKFLOWS.each do |workflow|
    puts "Processing #{workflow}"
    # Get the latest run.
    # TODO: We might need to sort by date and status.
    run = github.workflow_runs(REPO, workflow, head_sha: COMMIT).workflow_runs.first

    if run
      # Iterate through each each artifact.
      concurrently github.workflow_run_artifacts(REPO, run.id).artifacts do |artifact|
        download_path = File.join("artifacts/workflow", artifact.name)
        puts "Downloading #{artifact.archive_download_url} (#{artifact.size_in_bytes} bytes) to #{download_path}"
        File.write download_path, github.get(artifact.archive_download_url)
        puts "Downloaded #{artifact.name} to #{download_path}"
      end
    else
      puts "No runs found for #{workflow}"
    end
  end
end

desc "Unpack build artifacts"
task :unpack do
  sh "mkdir -p artifacts/release"
  Dir.glob("artifacts/workflow/traveling-ruby-*.tar.gz").each do |tarball|
    sh "tar -xzf #{tarball} -C ./artifacts/release"
  end
end

desc "Clean the ./artifacts directory"
task :clean do
  sh "rm -rf artifacts"
end

desc "Create a release with ./artifacts"
task :release do
  # Now create a Github release and we'll put the artfacts into itd
  release = github.create_release(REPO, release_tag,
    draft: true,
    prerelease: true,
    name: "Building: Release #{release_tag}",
    body: "Building: Ruby and gem builds for commit #{COMMIT}."
  )

  # Upload artifacts to the release.
  concurrently Dir.glob("artifacts/release/traveling-ruby-*.tar.gz") do |tarball|
    puts "Uploading #{tarball} to #{release.url}"
    github.upload_asset(
      release.url,
      tarball,
      content_type: "application/gzip"
    )
  end

  # Now finalize the release.
  github.update_release(
    release.url,
    draft: false,  # Make it public
    prerelease: false, # Ensure it's not marked as a pre-release
    name: "Release #{release_tag}",
    body: "Ruby and gem builds for commit #{COMMIT}."
  )
end

task default: %i[clean download unpack release]

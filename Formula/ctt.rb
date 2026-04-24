class Ctt < Formula
  desc "ClaudeCode Task management on Tmux"
  homepage "https://github.com/foresta/ctt"
  version "0.1.0"
  license "Apache-2.0"

  on_macos do
    on_arm do
      url "https://github.com/foresta/ctt/releases/download/v#{version}/ctt-v#{version}-darwin-arm64.tar.gz"
      sha256 "PLACEHOLDER_ARM64_SHA256"
    end

    on_intel do
      url "https://github.com/foresta/ctt/releases/download/v#{version}/ctt-v#{version}-darwin-x64.tar.gz"
      sha256 "PLACEHOLDER_X64_SHA256"
    end
  end

  def install
    bin.install "ctt"
    pkgshare.install ".worktree-link-ignore"
  end

  def post_install
    config_dir = "#{Dir.home}/.config/ctt"
    target = "#{config_dir}/.worktree-link-ignore"
    return if File.exist?(target)

    FileUtils.mkdir_p(config_dir)
    FileUtils.cp("#{pkgshare}/.worktree-link-ignore", target)
  end

  test do
    assert_match version.to_s, shell_output("#{bin}/ctt --version")
  end
end

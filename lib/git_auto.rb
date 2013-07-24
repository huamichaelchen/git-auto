require "active_support/all"
require "git"

# ================================================
# MODULE->GIT-AUTO ===============================
# ================================================
module GitAuto

  # ----------------------------------------------
  # ATTRIBUTES -----------------------------------
  # ----------------------------------------------
  mattr_accessor :commands, :repository

  self.commands   = []
  self.repository = false

  # ----------------------------------------------
  # USAGE ----------------------------------------
  # ----------------------------------------------
  def self.usage
    puts "usage: git-auto <action> [--dry-run]"

    self.commands.each do |command|
      puts command.usage
    end

    return 1
  end

  # ----------------------------------------------
  # MESSAGING ------------------------------------
  # ----------------------------------------------
  def self.fatal(message, error_code=1)
    puts "fatal: #{message}"
    exit error_code
  end

  # ----------------------------------------------
  # GIT ------------------------------------------
  # ----------------------------------------------
  def self.initialize_repository
    begin
      self.repository = Git.open ".", log: Logger.new(STDOUT)
    rescue ArgumentError
      GitAuto.fatal "not a git repository (or any of the parent directories): .git", 128
    end
  end

  def self.commit(message)
    self.repository.commit_all message
  end

  def self.untracked_files
    `git ls-files --other --exclude-standard`.split("\n")
  end

  def self.modified_files
    `git diff-tree --no-commit-id --name-only -r HEAD`.split("\n")
  end

  def self.repository_clean?

    # Are there any file changes?
    return false unless system "git diff-files --quiet --ignore-submodules"

    # Are there any text changes?
    return false unless system "git diff-index --cached --quiet --ignore-submodules HEAD"

    # Are there any untracked files?
    return false unless self.untracked_files.length == 0
    
    # Repository is clean
    true
  end

  # ----------------------------------------------
  # MAIN -----------------------------------------
  # ----------------------------------------------
  def self.main

    # Initialize (and ensure) a Git repository or exit
    GitAuto.initialize_repository

    # Ensure that we do have an unclean repository
    GitAuto.fatal "Your repository is clean; there's nothing to commit." if GitAuto.repository_clean?

    puts GitAuto.modified_files

    return GitAuto.auto if ARGV.length == 0

    # Find the Command and commit
    command = GitAuto.find_command_by_name(ARGV[0])

    # Ensure the command or exit
    GitAuto.fatal "Not a command" unless command

    # Commit based on the command
    command.commit

    # Successful exit
    exit 0
  end
  
  # ----------------------------------------------
  # FIND -----------------------------------------
  # ----------------------------------------------
  def self.find_command_by_name(name)
    self.commands.select { |command| command.name.to_s == name }.first
  end

  # ----------------------------------------------
  # AUTO -----------------------------------------
  # ----------------------------------------------
  def self.auto
    puts "auto"
  end

  # ----------------------------------------------
  # REGISTRATION ---------------------------------
  # ----------------------------------------------
  def self.register_command(*arguments)
    self.commands << Command.new(*arguments)
  end

  # ----------------------------------------------
  # CLASS->COMMAND -------------------------------
  # ----------------------------------------------
  class Command
    attr_accessor :name, :description

    def initialize(name, description)
      @name = name
      @description = description
    end

    def commit_message
      "#{@name}"
    end

    def commit
      GitAuto.commit commit_message
    end

    def usage
      "   #{name}\t#{description}"
    end
  end

  # ----------------------------------------------
  # REGISTER->COMMANDS ---------------------------
  # ----------------------------------------------
  register_command :clean, "Cleaned"
  register_command :typo, "Fixed typo"
  register_command :comment, "Commented"
  register_command :dryed, "DRYed"
  register_command :reorder, "Reordered"
  register_command :wording, "Changed wording"
  register_command :formatting, "Changed formatting"
  register_command :shortened, "Shortened"

end


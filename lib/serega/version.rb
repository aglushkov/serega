# frozen_string_literal: true

class Serega
  # Serega gem version
  #
  # @return [String] SemVer gem version
  #
  VERSION = File.read(File.join(File.dirname(__FILE__), "../../VERSION")).strip
end

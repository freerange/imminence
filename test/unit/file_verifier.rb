require 'test_helper'
require 'imminence/file_verifier'

class FileVerifierTest < ActiveSupport::TestCase
  test "it can be handed a file object" do
    f = File.open(Rails.root.join("features/support/data/register-offices.csv"))
    assert_equal 'text/plain', Imminence::FileVerifier.new(f).get_mime_type
  end

  test "it can be handed a path" do
    f = Rails.root.join("features/support/data/register-offices.csv")
    assert_equal 'text/plain', Imminence::FileVerifier.new(f).get_mime_type
  end
  
  test "it correctly identifies a PNG masquerading as a CSV" do
    f = Rails.root.join("features/support/data/rails.csv")
    assert_equal 'image/png', Imminence::FileVerifier.new(f).get_mime_type
  end
end

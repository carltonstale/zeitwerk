require "test_helper"

class TestLogging < LoaderTest
  def setup
    super
    loader.logger = method(:print)
  end

  def teardown
    Zeitwerk::Loader.default_logger = nil
    loader.logger = nil
    super
  end

  def tagged_message(message)
    "Zeitwerk@#{loader.tag}: #{message}"
  end

  def assert_logged(expected)
    case expected
    when String
      assert_output(tagged_message(expected)) { yield }
    when Regexp
      assert_output(/#{tagged_message(expected)}/) { yield }
    end
  end

  test "accepts objects that respond to :call" do
    logger = Object.new
    def logger.call(message)
      print message
    end

    loader.logger = logger

    message = "test messag :call"
    assert_logged(message) { loader.send(:log, message) }
  end

  test "accepts objects that respond to :debug" do
    logger = Object.new
    def logger.debug(message)
      print message
    end

    loader.logger = logger

    message = "test message :debug"
    assert_logged(message) { loader.send(:log, message) }
  end

  test "new loaders get assigned the default global logger" do
    assert_nil Zeitwerk::Loader.new.logger

    Zeitwerk::Loader.default_logger = Object.new
    assert_same Zeitwerk::Loader.default_logger, Zeitwerk::Loader.new.logger
  end

  test "logs loaded files" do
    files = [["x.rb", "X = true"]]
    with_files(files) do
      with_load_path(".") do
        assert_logged(/constant X loaded from file #{File.realpath("x.rb")}/) do
          loader.push_dir(".")
          loader.setup

          assert X
        end
      end
    end
  end

  test "logs required managed files" do
    files = [["x.rb", "X = true"]]
    with_files(files) do
      with_load_path(".") do
        assert_logged(/constant X loaded from file #{File.realpath("x.rb")}/) do
          loader.push_dir(".")
          loader.setup

          assert require "x"
        end
      end
    end
  end

  test "logs autovivified modules" do
    files = [["admin/user.rb", "class Admin::User; end"]]
    with_files(files) do
      with_load_path(".") do
        assert_logged(/module Admin autovivified from directory #{File.realpath("admin")}/) do
          loader.push_dir(".")
          loader.setup

          assert Admin
        end
      end
    end
  end

  test "logs autoload configured for files" do
    files = [["x.rb", "X = true"]]
    with_files(files) do
      assert_logged("autoload set for X, to be loaded from #{File.realpath("x.rb")}") do
        loader.push_dir(".")
        loader.setup
      end
    end
  end

  test "logs autoload configured for directories" do
    files = [["admin/user.rb", "class Admin::User; end"]]
    with_files(files) do
      assert_logged("autoload set for Admin, to be autovivified from #{File.realpath("admin")}") do
        loader.push_dir(".")
        loader.setup
      end
    end
  end

  test "logs preloads" do
    files = [["x.rb", "X = true"]]
    with_files(files) do
      loader.push_dir(".")
      loader.preload("x.rb")

      assert_logged(/preloading #{File.realpath("x.rb")}/) do
        loader.setup
      end
    end
  end

  test "logs unloads for autoloads" do
    files = [["x.rb", "X = true"]]
    with_files(files) do
      assert_logged(/autoload for X removed/) do
        loader.push_dir(".")
        loader.setup
        loader.reload
      end
    end
  end

  test "logs unloads for loaded objects" do
    files = [["x.rb", "X = true"]]
    with_files(files) do
      assert_logged(/X unloaded/) do
        loader.push_dir(".")
        loader.setup
        assert X
        loader.reload
      end
    end
  end
end

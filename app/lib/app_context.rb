# frozen_string_literal: true

require 'slim'
require 'json'
require 'fileutils'
require 'date'
require_relative '../helpers/application_helper'
require_relative '../helpers/html_helper'
require_relative '../helpers/slim_helper'
require_relative '../helpers/status_helper'
require_relative '../helpers/view_helper'

# Class for View context and helpers
class AppContext
  include ApplicationHelper
  include HtmlHelper
  include StatusHelper
  include ViewHelper
  include SlimHelper
end

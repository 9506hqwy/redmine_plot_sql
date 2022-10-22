# frozen_string_literal: true

basedir = File.expand_path('../lib', __FILE__)
libraries =
  [
    'redmine_plot_sql/utils',
  ]

libraries.each do |library|
  require_dependency File.expand_path(library, basedir)
end

Redmine::Plugin.register :redmine_plot_sql do
  name 'Redmine Plot SQL plugin'
  author '9506hqwy'
  description 'This is a SVG graph rendering macro from SQL.'
  version '0.1.0'
  url 'https://github.com/9506hqwy/redmine_plot_sql'
  author_url 'https://github.com/9506hqwy'

  Redmine::WikiFormatting::Macros.register do
    desc "Run SQL to Plot"
    macro :plot_sql do |obj, args, text|
      plot_obj = RedminePlotSql::Utils.sql_to_js(args, text)
      width = plot_obj[:width]
      height = plot_obj[:height]

      lib = javascript_include_tag('plotly.min.js', plugin: :redmine_plot_sql)

      id = "plot-#{Redmine::Utils.random_hex(16)}"

      graph = "
      #{lib}
      <div style=\"width: #{width}; height: #{height};\">
        <div id=\"#{id}\"></div>
        <script type=\"text/javascript\">
          Plotly.newPlot(document.getElementById(\"#{id}\"), #{plot_obj[:obj]});
        </script>
      </div>
      "

      graph.html_safe
    end
  end
end

# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class WikiTest < Redmine::IntegrationTest
  include Redmine::I18n

  fixtures :enabled_modules,
           :enumerations,
           :issues,
           :member_roles,
           :members,
           :projects,
           :roles,
           :time_entries,
           :users,
           :versions,
           :wiki_content_versions,
           :wiki_contents,
           :wiki_pages,
           :wikis

  def test_wiki_show_1sql
    content = wiki_contents(:wiki_contents_001)
    content.text = "
{{plot_sql(version=1.0)
-- label_column: \"spent_on\"

SELECT time_entries.spent_on, sum(time_entries.hours)
FROM time_entries
JOIN issues ON time_entries.issue_id = issues.id
JOIN versions ON issues.fixed_version_id = versions.id and versions.name = :version
GROUP BY time_entries.spent_on
ORDER BY time_entries.spent_on
}}
"
    content.save!

    log_user('admin', 'admin')

    get('/projects/ecookbook/wiki/CookBook_documentation')

    assert_response :success
    assert_select 'div.wiki-page div[id^="plot-"]'
  end

  def test_wiki_show_2sql
    content = wiki_contents(:wiki_contents_001)
    content.text = "
{{plot_sql(versiona=1.0, versionb=1.0)
-- label_column: \"spent_on\"

SELECT time_entries.spent_on, sum(time_entries.hours)
FROM time_entries
JOIN issues ON time_entries.issue_id = issues.id
JOIN versions ON issues.fixed_version_id = versions.id and versions.name = :versiona
GROUP BY time_entries.spent_on
ORDER BY time_entries.spent_on;

-- label_column: \"spent_on\"

SELECT time_entries.spent_on, sum(time_entries.hours)
FROM time_entries
JOIN issues ON time_entries.issue_id = issues.id
JOIN versions ON issues.fixed_version_id = versions.id and versions.name = :versionb
GROUP BY time_entries.spent_on
ORDER BY time_entries.spent_on;

}}
"
    content.save!

    log_user('admin', 'admin')

    get('/projects/ecookbook/wiki/CookBook_documentation')

    assert_response :success
    assert_select 'div.wiki-page div[id^="plot-"]'
  end
end

# Redmine Plot SQL

This plugin provides a SVG graph rendering macro by using raw SQL.

## Notes

This plugin has security issues by design.
User operates Redmine database by using raw SQL.

## Features

- Render SVG graph by using [Plotly.js](https://plotly.com/javascript/).
- Customize graph by using sql comment.
- Macro arguments is sql placeholder.

## Installation

1. Download plugin in Redmine plugin directory.

   ```sh
   git clone https://github.com/9506hqwy/redmine_plot_sql.git
   ```

2. Start Redmine

## Customization

The sql comment is `obj` in [Plotly.nwePlot function](https://plotly.com/javascript/plotlyjs-function-reference/#plotlynewplot).

This format is `-- KEY: VALUE`.
`KEY` is dotted string, ex) `config.width`.
`VALUE` is value, ex) 1, true, "rgb(0, 0, 0)".

The bellow key is special keyword.

- `default_data_type`: specify default data type (default: scatter)
- `label_column`: specify column name to use as label (default: database column name)
- `config.height`: specify image height (default: 50vh)
- `config.width`: specify image width (default: 50vw)

see bellow examples.

## Examples

This examples uses Redmine4 and PostgreSQL.

- Summation spent time per day in version `1.0.0`

```
{{plot_sql(1.0.0)
-- label_column: "spent_on"
-- data[0].mode: "lines+markers"
-- data[0].line.shape: "spline"

SELECT time_entries.spent_on, sum(time_entries.hours)
FROM time_entries
JOIN issues ON time_entries.issue_id = issues.id
JOIN versions ON issues.fixed_version_id = versions.id AND versions.name = ?
GROUP BY time_entries.spent_on
ORDER BY time_entries.spent_on
}}
```

- Stacked spent time per day in version `1.0.0`

```
{{plot_sql(version=1.0.0)
-- default_data_type: "bar"
-- label_column: "date"
-- data[0].marker.color: "rgb(0, 255, 0)"
-- data[1].marker.color: "rgb(0, 0, 255)"
-- layout.barmode: "stack"
-- config.width: "70vw"
-- config.height: "70vh"

SELECT
    dates.day AS date,
    (
        SELECT sum(time_entries.hours)
        FROM time_entries
        JOIN issues ON issues.id = time_entries.issue_id
        JOIN versions ON versions.id = issues.fixed_version_id AND versions.name = :version
        JOIN enumerations ON enumerations.id = time_entries.activity_id AND enumerations.name = 'Design'
        WHERE time_entries.spent_on <= dates.day
    ) AS Design,
    (
        SELECT sum(time_entries.hours)
        FROM time_entries
        JOIN issues ON issues.id = time_entries.issue_id
        JOIN versions ON versions.id = issues.fixed_version_id AND versions.name = :version
        JOIN enumerations ON enumerations.id = time_entries.activity_id AND enumerations.name = 'Development'
        WHERE time_entries.spent_on <= dates.day
    ) AS Development
FROM (SELECT DATE(d.*) AS day FROM generate_series('2022-08-01'::date, '2022-09-30', '2 day') AS d) AS dates
}}
```

## Tested Environment

- Redmine (Docker Image)
  - 4.0
  - 4.1
  - 4.2
  - 5.0
  - 5.1
  - 6.0
- Database
  - SQLite
  - MySQL 5.7 or 8.0
  - PostgreSQL 14

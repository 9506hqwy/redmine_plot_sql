# frozen_string_literal: true

module RedminePlotSql
  module Utils
    def self.array_to_kwargs(array)
      args = []
      kwargs = {}
      array&.each do |item|
        if item.index('=')
          kv = item.split('=', 2)
          kwargs[kv[0].to_sym] = kv[1]
        else
          args << item
        end
      end

      kwargs.empty? ? args : kwargs
    end

    def self.create_graph_data(table, data, default_data_type, label_column)
      column_names = table.columns.map { |c| c.to_s }

      if label_column
        column_names.delete(label_column)
        labels = table.map { |row| row[label_column] }

        column_names.each_with_index do |name, i|
          data[i] ||= {}
          data[i][:name] ||= name
          data[i][:type] ||=  default_data_type || 'scatter'
          data[i][:x] ||= labels
          data[i][:y] = table.map { |row| row[name] }
        end
      else
        table.each_with_index do |row, i|
          data[i] ||= {}
          data[i][:type] ||=  default_data_type || 'scatter'
          data[i][:x] ||= column_names
          data[i][:y] = column_names.map { |name| row[name] }
        end
      end

      data
    end

    def self.execute_sql(sql, args)
      values = array_to_kwargs(args)

      sql = sql.gsub("\\(", "(")
      sql = sql.gsub("\\)", ")")
      sql = sql.gsub("\\*", "*")
      if values.is_a?(Hash)
        sql = ActiveRecord::Base.send(
          :sanitize_sql_array,
          [sql] << values)
      else
        sql = ActiveRecord::Base.send(
          :sanitize_sql_array,
          [sql] + values)
      end

      ActiveRecord::Base.connection.exec_query(sql)
    end

    def self.kv_to_hash(kv)
      hash = {}

      kv&.each_with_object(hash) do |(key, value), hobj|
        keys = key.split('.')
        last = keys[0..-2].reduce(hobj) do |h, k|
          save_hash(h, k, {})
        end

        save_hash(last, keys[-1], option_to_array(value))
      end

      hash
    end

    def self.option_to_array(value)
      if value&.index(";")
        value.split(";").map { |c| parse_to_value(c.strip) }
      else
        parse_to_value(value)
      end
    end

    def self.parse_to_value(str)
      if str.starts_with?('"')
        str[1..-2]
      elsif ['true', 'false'].include?(str)
        str == 'true'
      else
        str.to_i
      end
    end

    def self.save_hash(hash, key, value)
      if key.index("[")
        index = key.scan(/(.+)\[(\d+)\]$/)[0]
        key0 = index[0].to_sym
        key1 = index[1].to_i
        hash[key0] ||= []
        hash[key0][key1] ||= value
      else
        hash[key.to_sym] ||= value
      end
    end

    def self.split_sql_options(text)
      options = {}
      sql = []
      sqlsets = []

      text.split("\n").map do |line|
        if line.starts_with?('-- ')
          kv = line.split(':', 2)
          key = kv[0].sub(/^--/, '').strip
          value = kv[1]&.strip
          options[key] = value
        else
          sql << line

          if line.rstrip.ends_with?(';')
            sqlsets << {
              sql: sql.join("\n"),
              options: kv_to_hash(options),
            }
            options = {}
            sql = []
          end
        end
      end

      if sql.present?
        sqlsets << {
          sql: sql.join("\n"),
          options: kv_to_hash(options),
        }
      end

      sqlsets
    end

    def self.sql_to_js(args, text)
      obj = { data: [], layout: {}, config: {}, frames: [] }

      split_sql_options(text).map do |result|
        sql = result[:sql]
        graph_options = result[:options]

        table = execute_sql(sql, args)

        default_data_type = graph_options[:default_data_type]
        label_column = graph_options[:label_column]
        data_options = graph_options[:data] || []
        frame_options = graph_options[:frames]

        obj[:data] += create_graph_data(table, data_options, default_data_type, label_column)

        if obj[:layout].empty?
          obj[:layout] = graph_options[:layout] || {}
        end

        if obj[:config].empty?
          obj[:config] = graph_options[:config] || {}
        end

        obj[:frames] += frame_options if frame_options
      end

      width = (obj[:config] || {}).delete(:width) || '50vw'
      height = (obj[:config] || {}).delete(:height) || '50vh'

      {
        obj: obj.to_json,
        width: width,
        height: height,
      }
    end
  end
end

# frozen_string_literal: true

require File.expand_path('../../test_helper', __FILE__)

class UtilsTest < ActiveSupport::TestCase
  fixtures :issues,
           :projects,
           :time_entries

  def test_array_to_kwargs_nil
    array = nil
    values = RedminePlotSql::Utils.array_to_kwargs(array)
    assert_empty values
  end

  def test_array_to_kwargs_empty
    array = []
    values = RedminePlotSql::Utils.array_to_kwargs(array)
    assert_empty values
  end

  def test_array_to_kwargs_ary1
    array = ['a']
    values = RedminePlotSql::Utils.array_to_kwargs(array)
    assert_equal 1,  values.length
    assert_equal 'a', values[0]
  end

  def test_array_to_kwargs_ary2
    array = ['a', 'b']
    values = RedminePlotSql::Utils.array_to_kwargs(array)
    assert_equal 2,  values.length
    assert_equal 'a', values[0]
    assert_equal 'b', values[1]
  end

  def test_array_to_kwargs_hash1
    array = ['a=1']
    values = RedminePlotSql::Utils.array_to_kwargs(array)
    assert_equal 1,  values.length
    assert_equal '1', values[:a]
  end

  def test_array_to_kwargs_hash2
    array = ['a=1', 'b=2']
    values = RedminePlotSql::Utils.array_to_kwargs(array)
    assert_equal 2,  values.length
    assert_equal '1', values[:a]
    assert_equal '2', values[:b]
  end

  def test_array_to_kwargs_mixed
    array = ['a', 'b=2']
    values = RedminePlotSql::Utils.array_to_kwargs(array)
    assert_equal 1,  values.length
    assert_equal '2', values[:b]
  end

  def test_create_graph_data_row
    sql = 'SELECT * FROM issues ORDER BY issues.id'
    table = RedminePlotSql::Utils.execute_sql(sql, nil)
    data =  RedminePlotSql::Utils.create_graph_data(table, {}, nil, nil)
    assert_not_empty data
    Rails.logger.info(data)
    assert_equal 'id', data[0][:x][0]
    assert_equal table.length, data.length
  end

  def test_create_graph_data_column
    sql = 'SELECT * FROM issues ORDER BY issues.id'
    table = RedminePlotSql::Utils.execute_sql(sql, nil)
    data =  RedminePlotSql::Utils.create_graph_data(table, {}, nil, 'id')
    assert_not_empty data
    Rails.logger.info(data)
    assert_equal 1, data[0][:x][0]
    assert_equal table.columns.length - 1, data.length
  end

  def test_execute_sql_ary
    sql = 'SELECT * FROM issues WHERE issues.id = ?'
    args = ['1']
    data = RedminePlotSql::Utils.execute_sql(sql, args).first
    assert_equal 1, data["id"].to_i
  end

  def test_execute_sql_hash
    sql = 'SELECT * FROM issues WHERE issues.id = :id'
    args = ['id=1']
    data = RedminePlotSql::Utils.execute_sql(sql, args).first
    assert_equal 1, data["id"].to_i
  end

  def test_kv_to_hash_nil
    kv = nil
    hash = RedminePlotSql::Utils.kv_to_hash(kv)
    assert_empty hash
  end

  def test_kv_to_hash_empty
    kv = {}
    hash = RedminePlotSql::Utils.kv_to_hash(kv)
    assert_empty hash
  end

  def test_kv_to_hash_depth1
    kv = {'a' => '1'}
    hash = RedminePlotSql::Utils.kv_to_hash(kv)
    assert_equal 1, hash[:a]
  end

  def test_kv_to_hash_depth2
    kv = {'a.b' => '1'}
    hash = RedminePlotSql::Utils.kv_to_hash(kv)
    assert_equal 1, hash[:a][:b]
  end

  def test_kv_to_hash_depth3
    kv = {'a.b.c' => '1'}
    hash = RedminePlotSql::Utils.kv_to_hash(kv)
    assert_equal 1, hash[:a][:b][:c]
  end

  def test_kv_to_hash_path_ary1
    kv = {'a[0]' => '1'}
    hash = RedminePlotSql::Utils.kv_to_hash(kv)
    assert_equal 1, hash[:a][0]
  end

  def test_kv_to_hash_path_ary2
    kv = {'a[1].b' => '1'}
    hash = RedminePlotSql::Utils.kv_to_hash(kv)
    assert_equal 1, hash[:a][1][:b]
  end

  def test_kv_to_hash_path_ary3
    kv = {'a.b[2].c' => '1'}
    hash = RedminePlotSql::Utils.kv_to_hash(kv)
    assert_equal 1, hash[:a][:b][2][:c]
  end

  def test_option_to_array_ary
    value = '1;2'
    array = RedminePlotSql::Utils.option_to_array(value)
    assert_equal 1, array[0]
    assert_equal 2, array[1]
  end

  def test_option_to_array_value
    value = '1'
    array = RedminePlotSql::Utils.option_to_array(value)
    assert_equal 1, array
  end

  def test_parse_to_value_false
    value = 'false'
    ret = RedminePlotSql::Utils.parse_to_value(value)
    assert_not ret
  end

  def test_parse_to_value_true
    value = 'true'
    ret = RedminePlotSql::Utils.parse_to_value(value)
    assert ret
  end

  def test_parse_to_value_str
    value = '"a"'
    ret = RedminePlotSql::Utils.parse_to_value(value)
    assert_equal 'a', ret
  end

  def test_parse_to_value_number
    value = '1'
    ret = RedminePlotSql::Utils.parse_to_value(value)
    assert_equal 1, ret
  end

  def test_split_sql_options_1sql
    text = "
-- a: 1
--- b: 2
-- c: 3

abc
"
    obj = RedminePlotSql::Utils.split_sql_options(text)[0]
    assert 1, obj[:options][:a]
    assert_nil obj[:options][:b]
    assert 3, obj[:options][:c]
  end

  def test_split_sql_options_2sql
    text = "
-- a: 1
--- b: 2
-- c: 3

abc;
-- d: 4
-- e: 5

de
"
    obj = RedminePlotSql::Utils.split_sql_options(text)
    Rails.logger.info(obj)
    assert 1, obj[0][:options][:a]
    assert_nil obj[0][:options][:b]
    assert 3, obj[0][:options][:c]
    assert 4, obj[1][:options][:d]
    assert 5, obj[1][:options][:e]
  end
end

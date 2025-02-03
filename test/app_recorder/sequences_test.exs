defmodule AppRecorder.SequencesTest do
  use AppRecorder.DataCase, async: false

  alias AppRecorder.Sequences

  describe "next/1" do
    test "with an invalid table_name, raises a FunctionClauseError" do
      assert_raise FunctionClauseError, fn ->
        Sequences.next_value!("")
      end
    end

    test "with a valid table_name, returns the next sequence" do
      assert Sequences.next_value!(:events) == 1
      assert Sequences.next_value!(:events) == 2
    end
  end
end

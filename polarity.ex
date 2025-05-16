defmodule Polarity do

  @moduledoc """
    Add your solver function below. You may add additional helper functions if you desire.
    Test your code by running 'mix test --seed 0' from the simple_tester_ex directory.
  """

  def polarity(board, specs) do
    # Your code here!
    # Hard-coded solution to test 1 is below.

    #{ "+-+-X-" , "-+-+X+", "XX+-+-", "XX-+X+", "-+XXX-" }

    #create base with X

    n = String.length(elem(board, 0))
    num = for _ <- 1..n, do: "X"
    base = for _ <- 1..tuple_size(board), do: num

    #call make to populate board

    make(board, specs, base)
  end


  def make(board, specs, res)  do
    left = specs["left"] |> Tuple.to_list()
    new = (make_left(board, left, specs, res, 0))

    # do right specs new "right", updated res, updated specs

    right = specs["right"] |> Tuple.to_list()
    new_res = elem(new, 0)
    new_specs = elem(new, 1)


    #extract final result for left and top
    final_result = make_right(board, right, new_specs, new_res, 0)
    newSpecs = elem(final_result, 1)
    newRes = elem(final_result, 0)

    #convert board for top and bottom
    newSpecs = %{"left" => newSpecs["top"], "right" => newSpecs["bottom"], "top" => newSpecs["left"], "bottom" => newSpecs["right"]}

    newRes = Enum.zip(newRes) |> Enum.map(&Tuple.to_list/1)

    board = Tuple.to_list(board)
    board = Enum.map(board, fn n ->
      n
      |> String.graphemes()
      |> Enum.map(fn
        "T" ->  "L"
        "L" -> "T"
        "B" -> "R"
        "R" -> "B"
      end)
    end)
    board = convert(board)


   #run code for top and bottom
  left = newSpecs["left"] |> Tuple.to_list()
  new = (make_left(board, left, newSpecs, newRes, 0))

  right = newSpecs["right"] |> Tuple.to_list()
  new_res = elem(new, 0)
  new_specs = elem(new, 1)

  # final result converted then returned
  convert(elem(make_right(board, right, new_specs, new_res, 0), 0))


  end

  #final result done
  def make_right(board, [], original_specs, res, row) do
    {res, original_specs}
  end

  def make_right(board, [spec | rest], original_specs, res, row) do
    if (spec == -1 or spec == 0)do
      make_right(board, rest, original_specs, res, row + 1) # current spec doesn't have constraints so we move on
    else
      head_base = Enum.at(res, row) # extract current row from board so head_base = ["X", "X"]

      {new_row, placed} =
      Enum.reduce(Enum.with_index(head_base), {[], -1}, fn {x, idx}, {acc, placed} ->
        if (placed == -1) and valid_placement_neg(res, row, idx, x, original_specs) do  #can i place a neg?
          future_pos = valid_placement_future_pos(board, res, row, idx, original_specs)  #can i place the corresponding pos?
          if (future_pos) do
            {acc ++ ["-"], idx} # place "-" and mark index placed
          else
            {acc ++ [x], placed}
          end
        else
          {acc ++ [x], placed} # keep the current value
        end
      end)

      # update res with modified new_row so ["-", "X"]
      new_res = List.replace_at(res, row, new_row)

      # if a "-" was placed, place a "+" in the corresponding position
      updated_res =
        if placed != -1 do
          {x, y} = placepos(board, row, placed) #placepos will give us pos to place "+"
          newRow = Enum.at(new_res, x) #find row
          updatedRow = List.replace_at(newRow, y, "+")  #find col then replace
          List.replace_at(new_res, x, updatedRow)
        else
          new_res
        end

      # update original_specs
      updated_specs =
        if placed != -1 do
          {x, y} = placepos(board, row, placed)
          new_specs({x, y}, {row, placed}, original_specs)
        else
          original_specs
        end

      spec = spec - 1 #spec is done or not? - to check
        if spec > 0 do # not done
          make_right(board, [spec | rest], updated_specs, updated_res, row)
        else #done so move on to next left spec
          make_right(board, rest, updated_specs, updated_res, row + 1) # call make_left(board, [0], [["+", "X"], ["X", "X"]], row=1)
        end


    end
  end


  def make_left(board, [], original_specs, res, row) do
    {res, original_specs}
  end
  def make_left(board, [spec | rest], original_specs, res, row) do
    if (spec == -1 or spec == 0)do
      make_left(board, rest, original_specs, res, row + 1) # current spec doesn't have constraints so we move on
    else
      head_base = Enum.at(res, row) # extract current row from board so head_base = ["X", "X"]

      {new_row, placed} =
      Enum.reduce(Enum.with_index(head_base), {[], -1}, fn {x, idx}, {acc, placed} ->
        if (placed == -1) and valid_placement_plus(res, row, idx, x, original_specs) do
          future_neg = valid_placement_future_neg(board, res, row, idx, original_specs)
          if (future_neg) do
            {acc ++ ["+"], idx} # place "+" and mark index placed
          else
            {acc ++ [x], placed}
          end
        else
          {acc ++ [x], placed} # keep the current value
        end
      end)

      # update res with modified new_row so ["+", "X"]
      new_res = List.replace_at(res, row, new_row)

      # if a "+" was placed, place a "-" in the corresponding position
      updated_res =
        if placed != -1 do
          {x, y} = placeneg(board, row, placed) #placeneg will give us pos to place "-"
          newRow = Enum.at(new_res, x) #replace row
          updatedRow = List.replace_at(newRow, y, "-")
          List.replace_at(new_res, x, updatedRow)
        else
          new_res
        end

      # update original_specs
      updated_specs =
        if placed != -1 do
          {x, y} = placeneg(board, row, placed)
          new_specs({row, placed}, {x, y}, original_specs)
        else
          original_specs
        end
      spec = spec - 1 #spec is done or not? - to check
        if spec > 0 do #not done
          make_left(board, [spec | rest], updated_specs, updated_res, row)
        else #done so move on to next left spec
          make_left(board, rest, updated_specs, updated_res, row + 1) # call make_left(board, [0], [["+", "X"], ["X", "X"]], row=1)
        end


    end
  end

  def placeneg(board, row, col) do #give position to place neg in corresponding pos
    case String.at(elem(board, row), col) do
    "T" -> {row + 1, col}
    "B" -> {row - 1, col}
    "L" -> {row, col + 1}
    "R" -> {row, col - 1}
    _ -> {row, col}
    end
  end

  def placepos(board, row, col) do #give position to place pos in corresponding pos
    case String.at(elem(board, row), col) do
    "T" -> {row + 1, col}
    "B" -> {row - 1, col}
    "L" -> {row, col + 1}
    "R" -> {row, col - 1}
    _ -> {row, col}
    end
  end


  def valid_placement_plus(res, row, col, current, original_specs) do
    # prevent placing a "+" if it's already there
    if (current == "+" or current == "-") do
      false
    else
    # adjacent positions --> cannot be "+"
      above = if row > 0, do: Enum.at(Enum.at(res, row - 1), col), else: nil
      below = if row < length(res) - 1, do: Enum.at(Enum.at(res, row + 1), col), else: nil
      left  = if col > 0, do: Enum.at(Enum.at(res, row), col - 1), else: nil
      right = if col < length(Enum.at(res, row)) - 1, do: Enum.at(Enum.at(res, row), col + 1), else: nil

    # ensure no adjacent "+" magnets and is within constraints
      cond do
        Enum.any?([above, below, left, right], &(&1 == "+")) -> false
        (not ((elem(original_specs["left"], row) == -1) or (elem(original_specs["left"], row) -1 != -1))) -> false
        (not ((elem(original_specs["top"], col) == -1) or (elem(original_specs["top"], col) -1 != -1))) -> false
        true -> true
      end
    end

  end

  def valid_placement_neg(res, row, col, current, original_specs) do
    # prevent placing a "-" if it's already there
    if (current == "+" or current == "-") do
      false
    else
    # adjacent positions --> cannot be "-"
      above = if row > 0, do: Enum.at(Enum.at(res, row - 1), col), else: nil
      below = if row < length(res) - 1, do: Enum.at(Enum.at(res, row + 1), col), else: nil
      left  = if col > 0, do: Enum.at(Enum.at(res, row), col - 1), else: nil
      right = if col < length(Enum.at(res, row)) - 1, do: Enum.at(Enum.at(res, row), col + 1), else: nil

    # ensure no adjacent "-" magnets and is within constraints
      cond do
        Enum.any?([above, below, left, right], &(&1 == "-")) -> false
        (not ((elem(original_specs["right"], row) == -1) or (elem(original_specs["right"], row) -1 != -1))) -> false
        (not ((elem(original_specs["bottom"], col) == -1) or (elem(original_specs["bottom"], col) -1 != -1))) -> false
        true -> true
      end
    end

  end

  def valid_placement_future_neg(board, res, row, col, original_specs) do
    # where is my future neg?
    {fn_row, fn_col} =
      cond do
        String.at(elem(board, row), col) == "L" -> {row, col + 1}
        String.at(elem(board, row), col) == "R" -> {row, col - 1}
        String.at(elem(board, row), col) == "T" -> {row + 1, col}
        String.at(elem(board, row), col) == "B" -> {row - 1, col}
        true -> {row, col}
      end

    above = if fn_row > 0, do: Enum.at(Enum.at(res, fn_row - 1), fn_col), else: nil
    below = if fn_row < length(res) - 1, do: Enum.at(Enum.at(res, fn_row + 1), fn_col), else: nil
    left  = if fn_col > 0, do: Enum.at(Enum.at(res, fn_row), fn_col - 1), else: nil
    right = if fn_col < length(Enum.at(res, fn_row)) - 1, do: Enum.at(Enum.at(res, fn_row), fn_col + 1), else: nil

    # ensure no adjacent "-" magnets and is within constraints

    cond do
      Enum.any?([above, below, left, right], &(&1 == "-")) -> false
      (not ((elem(original_specs["right"], fn_row) == -1) or (elem(original_specs["right"], fn_row) -1 != -1))) -> false
      (not ((elem(original_specs["bottom"], fn_col) == -1) or (elem(original_specs["bottom"], fn_col) -1 != -1))) -> false
      true -> true
    end
  end

  def valid_placement_future_pos(board, res, row, col, original_specs) do
    # where is my future pos?
    {fn_row, fn_col} =
      cond do
        String.at(elem(board, row), col) == "L" -> {row, col + 1}
        String.at(elem(board, row), col) == "R" -> {row, col - 1}
        String.at(elem(board, row), col) == "T" -> {row + 1, col}
        String.at(elem(board, row), col) == "B" -> {row - 1, col}
        true -> {row, col}
      end

    above = if fn_row > 0, do: Enum.at(Enum.at(res, fn_row - 1), fn_col), else: nil
    below = if fn_row < length(res) - 1, do: Enum.at(Enum.at(res, fn_row + 1), fn_col), else: nil
    left  = if fn_col > 0, do: Enum.at(Enum.at(res, fn_row), fn_col - 1), else: nil
    right = if fn_col < length(Enum.at(res, fn_row)) - 1, do: Enum.at(Enum.at(res, fn_row), fn_col + 1), else: nil

    # ensure no adjacent "+" magnets and is within constraints

    cond do
      Enum.any?([above, below, left, right], &(&1 == "+")) -> false
      (not ((elem(original_specs["left"], fn_row) == -1) or (elem(original_specs["left"], fn_row) -1 != -1))) -> false
      (not ((elem(original_specs["top"], fn_col) == -1) or (elem(original_specs["top"], fn_col) -1 != -1))) -> false
      true -> true
    end
  end


  def new_specs({row, col}, {x, y}, original_specs) do
    # convert tuples to lists
    left_list = Tuple.to_list(original_specs["left"])
    top_list = Tuple.to_list(original_specs["top"])

    right_list = Tuple.to_list(original_specs["right"])
    bottom_list = Tuple.to_list(original_specs["bottom"])

    # subtract 1 from the "left" list at the specified row index
    updated_left =
      left_list
      |> Enum.with_index()
      |> Enum.map(fn {value, idx} -> if idx == row and value != -1, do: value - 1, else: value end)

    updated_top =
      top_list
      |> Enum.with_index()
      |> Enum.map(fn {value, idx} -> if idx == col and value != -1, do: value - 1, else: value end)

    updated_right =
      right_list
      |> Enum.with_index()
      |> Enum.map(fn {value, idx} -> if idx == x and value != -1, do: value - 1, else: value end)

    updated_bottom =
      bottom_list
      |> Enum.with_index()
      |> Enum.map(fn {value, idx} -> if idx == y and value != -1, do: value - 1, else: value end)

    # convert the updated lists back to tuples
    updated_left_tuple = List.to_tuple(updated_left)
    updated_top_tuple = List.to_tuple(updated_top)
    updated_right_tuple = List.to_tuple(updated_right)
    updated_bottom_tuple = List.to_tuple(updated_bottom)

    # return the updated specs
    original_specs
    |> Map.put("left", updated_left_tuple)
    |> Map.put("top", updated_top_tuple)
    |> Map.put("right", updated_right_tuple)
    |> Map.put("bottom", updated_bottom_tuple)
  end

    #FINAL RESULT CONVERTED
  def convert(list) do
    list
    |> Enum.zip()
    |> Enum.map(&Tuple.to_list/1)
    |> Enum.map(&Enum.join(&1, ""))
    |> List.to_tuple()
  end

end

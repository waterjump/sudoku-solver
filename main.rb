class Space
  def initialize(x, y, answer = nil)
    answer = nil if answer.zero?

    @answer = answer
    @starter = !!answer
    @possibilities = answer ? [] : [1, 2, 3, 4, 5, 6, 7, 8, 9]
    @x = x
    @y = y
  end

  attr_reader :answer, :possibilities, :starter, :x, :y

  def output
    if starter
      # prints bold
      print "\e[1m #{answer || ' '} \e[22m"
    else
      # prints in green
      print "\e[32m #{answer || ' '} \e[0m"
    end
    # print possibilities.join(',').ljust(15)
  end

  def mark_as(number)
    @answer = number
    @possibilities = []
  end

  def eliminate_possiblility(possibility)
    return if answer

    @possibilities -= [possibility]
  end
end

class Game
  DEBUG = false

  def initialize(board)
    @start_time = Time.now
    @board = init_board(board)
    @tries = 0
  end

  def play
    # print_board
    if @board.flatten.all?(&:answer)
      print_board
      print "\nGAME COMPLETE!\n"
      print "#{Time.now - @start_time} seconds\n"
    elsif @tries > 5
      print "BRAIN BUSTED\n"
    else
      @tries += 1
      filter_pass
      eval_sectors
      eval_rows
      eval_cols
      play
    end
  end

  private

  attr_accessor :board

  def print_board
    system 'clear'
    board.each_with_index do |row, x|
      row.each_with_index do |space, y|
        space.output

        print ' | ' if [2, 5].include?(y)
      end
      print "\n"
      print "----------+-----------+-----------\n" if [2, 5].include?(x)
    end
  end

  def filter_pass
    (0..8).to_a.each do |x|
      (0..8).to_a.each do |y|
        ans = board[x][y].answer
        next unless ans

        remove_possibility_from_row(ans, x)
        remove_possibility_from_column(ans, y)
        remove_possibility_from_sector(ans, x, y)
      end
    end
  end

  def remove_possibility_from_row(possibility, row_index, except_sector: {})
    (0..8).to_a.each do |x|
      next if except_sector.any? && except_sector[:xs].include?(x)

      board[row_index][x].eliminate_possiblility(possibility)
    end
  end

  def remove_possibility_from_column(possibility, column_index, except_sector: {})
    (0..8).to_a.each do |y|
      next if except_sector.any? && except_sector[:ys].include?(y)

      board[y][column_index].eliminate_possiblility(possibility)
    end
  end

  def remove_possibility_from_sector(possibility, x, y)
    sector_indexes = [[0, 1, 2], [3, 4, 5], [6, 7, 8]]
    sector_xs = sector_indexes.detect { |group| group.include?(x) }
    sector_ys = sector_indexes.detect { |group| group.include?(y) }

    sector_xs.each do |sector_x|
      sector_ys.each do |sector_y|
        next if board[sector_x][sector_y].answer

        board[sector_x][sector_y].eliminate_possiblility(possibility)
      end
    end
  end

  def eval_sectors
    [[0, 1, 2], [3, 4, 5], [6, 7, 8]].each do |sector_xs|
      [[0, 1, 2], [3, 4, 5], [6, 7, 8]].each do |sector_ys|
        puts "SECTOR with Xs #{sector_xs}, and Ys #{sector_ys}"
        sector_spaces = []
        sector_ys.each do |y|
          sector_spaces += board[y][sector_xs.min..sector_xs.max]
        end

        eval_set(sector_spaces, sector: true)
      end
    end
  end

  def eval_rows
    (0..8).to_a.each do |row|
      puts "ROW #{row}"
      row_spaces = board[row]
      eval_set(row_spaces)
    end
  end

  def eval_cols
    (0..8).to_a.each do |col|
      puts "COL #{col}"
      col_spaces = []
      (0..8).to_a.each do |row|
        col_spaces << board[row][col]
      end
      eval_set(col_spaces)
    end
  end

  def puts(*args)
    return unless DEBUG

    super(*args)
  end

  def eval_set(set, sector: false)
    (1..9).to_a.each do |number|
      spaces = set.select do |space|
        space.possibilities.include?(number)
      end

      # Mark only place left for number
      if spaces.count == 1
        mark_space_answered(spaces.first, number)
        puts "  Only one possible space for number #{number}"
      end

      if spaces.count > 1 && spaces.count <= 3 && sector
        if spaces.map(&:y).uniq.one?
          this_y = spaces.first.y

          sector_xs, sector_ys = sector_indexes_from_space(spaces.first)

          remove_possibility_from_row(
            number,
            this_y,
            except_sector: {xs: sector_xs, ys: sector_ys }
          )
        elsif spaces.map(&:x).uniq.one?
          this_x = spaces.first.x

          sector_xs, sector_ys = sector_indexes_from_space(spaces.first)

          remove_possibility_from_column(
            number,
            this_x,
            except_sector: {xs: sector_xs, ys: sector_ys }
          )
        end
      end
    end

    # Mark place that can only have a single number
    set.each do |space|
      next unless space.possibilities.one?

      mark_space_answered(space, space.possibilities.first)
    end
  end

  def sector_indexes_from_space(space)
    sector_indexes = [[0, 1, 2], [3, 4, 5], [6, 7, 8]]
    sector_xs = sector_indexes.detect { |group| group.include?(space.x) }
    sector_ys = sector_indexes.detect { |group| group.include?(space.y) }
    [sector_xs, sector_ys]
  end

  def  mark_space_answered(space, answer)
    @tries = 0
    space.mark_as(answer)
    filter_pass
    print_board
  end

  def init_board(board)
    board.each_with_object([]).with_index do |(row, game_board), index_y|
      game_board <<
        row.each_with_object([]).with_index do |(number, game_row), index_x|
          game_row << Space.new(index_x, index_y, number)
        end
    end
  end
end

board = [
  [2, 0, 3, 0, 0, 0, 0, 0, 0],
  [0, 0, 0, 9, 7, 0, 0, 4, 0],
  [0, 0, 0, 4, 5, 0, 0, 0, 0],
  [3, 0, 0, 6, 0, 9, 0, 0, 0],
  [6, 0, 0, 0, 0, 0, 5, 0, 0],
  [0, 0, 0, 0, 0, 0, 0, 7, 1],
  [0, 8, 0, 0, 0, 0, 0, 0, 0],
  [0, 9, 0, 0, 0, 0, 2, 0, 8],
  [0, 0, 0, 7, 4, 0, 0, 0, 0],
]


Game.new(board).play

require_relative 'pieces'

class Board
	attr_reader :board

	def initialize(to_populate = true)
		@board = make_board
		populate_board if to_populate
	end

	def make_board
		Array.new(8) {Array.new(8)}
	end

	def populate_board	
		odds, evens = [1, 3, 5, 7], [0, 2, 4, 6]

		rows = [0, 2]
		rows.each do |row|
			odds.each {|col| @board[row][col] = Piece.new("black", self, [row, col], false)}
		end

		rows = [5, 7]
		rows.each do |row|
			evens.each {|col| @board[row][col] = Piece.new("red", self, [row, col], false)}
		end

		rows = [1, 6]
		rows.each do |row|
			if row == 1
				evens.each {|col| @board[row][col] = Piece.new("black", self, [row, col], false)}
			else
				odds.each {|col| @board[row][col] = Piece.new("red", self, [row, col], false)}
			end
		end

	end

	def [](row, col)
		@board[row][col]
	end

	# def []=(row, col, piece)
	# 	@board[row][col] = piece
	# end

	def move(start, dest)
		if (start[0] - dest[0]).abs == 1 && (start[1] - dest[1]).abs == 1
			perform_slide(start, dest)
		elsif (start[0] - dest[0]).abs == 2 && (start[1] - dest[1]).abs == 2
			perform_jump(start, dest)
		else
			puts
			puts "That is not a valid move."
		end
	end

	def perform_slide(start, dest)
		if self[start[0], start[1]].slide_diffs.include?([dest[0], dest[1]])
			@board[start[0]][start[1]].position = [dest[0], dest[1]]
			@board[dest[0]][dest[1]] = @board[start[0]][start[1]] 
			@board[start[0]][start[1]] = nil
		else
			puts
			puts "That is not a valid move."
		end

		display

		(@board[d_row][d_col]).maybe_promote
	end

	def perform_jump(start, dest)
		if self[start[0], start[1]].jump_diffs.include?([dest[0], dest[1]])
			@board[start[0]][start[1]].position = [dest[0], dest[1]]
			@board[dest[0]][dest[1]] = @board[start[0]][start[1]] 
			@board[start[0]][start[1]] = nil
			@board[(start[0] + dest[0])/2][(start[1] + dest[1])/2] = nil
		else
			puts
			puts "That is not a valid move."
		end

		display

		(@board[d_row][d_col]).maybe_promote
	end

	def perform_moves!(move_seq) # actually executes all the moves
		move_seq[0..-2].each_index do |i|
			if (move_seq[i][0] - move_seq[i+1][0]).abs == 1 && 
				(move_seq[i][1] - move_seq[i+1][1]).abs == 1
				perform_slide(move_seq[i], move_seq[i+1])
			elsif (move_seq[i][0] - move_seq[i+1][0]).abs == 2 && 
				(move_seq[i][1] - move_seq[i+1][1]).abs == 2
				perform_jump(move_seq[i], move_seq[i+1])
			end
		end
	end

	def dup
		duped_board = Board.new(false)

		pieces.each do |piece|
      		piece.class.new(piece.color, @board, piece.pos)
    	end
	end


	def valid_move_seq?(move_seq)
		duped_board = @board.dup

		move_seq[0..-2].each_index do |i|
			if (move_seq[i][0] - move_seq[i+1][0]).abs == 1 && 
				(move_seq[i][1] - move_seq[i+1][1]).abs == 1
				perform_slide(move_seq[i], move_seq[i+1])
			elsif (move_seq[i][0] - move_seq[i+1][0]).abs == 2 && 
				(move_seq[i][1] - move_seq[i+1][1]).abs == 2
				perform_jump(move_seq[i], move_seq[i+1])
			end
		end


		# begin
 	   # perform move!
		# rescue
	   # if error return false
		# else
		#  # no error return true
	end

	def perform_moves(move_seq)
		valid_move_seq? #perform_moves! but with a duped board
		if valid_move_seq?
			perform_moves! #actually implement all moves
		else
			puts "That move sequence is not valid."
		end
	end

	def display
		display_board = make_board 
	    @board.each_with_index do |row, r_idx|    #referring to original board
      		row.each_with_index do |tile, c_idx|
        		if @board[r_idx][c_idx].is_a?(Piece)
         			 display_board[r_idx][c_idx] = tile.color[0] + " "
        		elsif @board[r_idx][c_idx].nil?
          			display_board[r_idx][c_idx] = "__"
        		end
        	end
      	end

      	print "\n\n\t"+['0 ','1 ','2 ','3 ','4 ','5 ','6 ','7 '].join('   ')+"\n\n"
    	display_board.each_with_index do |row, idx|
      		print "\n" + idx.to_s + "\t"
      		puts row.join('   ')
    	end
    	puts "\n\n"
    end
end

class Piece
	attr_reader :color, :board
	attr_accessor :position, :king_value

	def initialize(color, board, position, king_value = false)
		@color = color
		@board = board
		@position = position
		@king_value = king_value
	end

	def slide_diffs
		possible_moves = color == "black" ? BLACK_MOVES : RED_MOVES
		possible_moves.map do |coord|
			[coord[0] + self.position[0], coord[1] + self.position[1]]
		end.select do |x, y|
			[x, y].all? do |coord|
				coord.between?(0, 7)
			end
		end.select do |x, y|
			board[x, y].nil?
		end
	end

	def jump_diffs
		possible_jumps = color == "black" ? BLACK_JUMPS : RED_JUMPS
		possible_jumps.map do |coord|
			[coord[0] + self.position[0], coord[1] + self.position[1]]
		end.select do |x, y|
			[x, y].all? do |coord|
          		coord.between?(0, 7)
			end
		end.select do |x, y|
			board[x,y].nil?
		end.select do |x, y|
			jumped = @board.board[(self.position[0] + x)/2][(self.position[1] + y)/2]
			jumped.is_a?(Piece) && jumped.color != self.color
		end
	end

	def update_board (board)
		@board = board
	end

	def maybe_promote
		if (color == "black" && position[0] == 7) || (color == "red" && position[0] == 0)
			@king_value = true
		end
	end

	BLACK_MOVES = [[1, -1], [1, 1]]
	RED_MOVES = [[-1, -1], [-1, 1]]

	BLACK_JUMPS = [[2, -2], [2, 2]]
	RED_JUMPS = [[-2, -2], [-2, 2]]

end


class Game
	attr_reader :board

	def initialize
		@board = Board.new
		@board.display
		puts
		play(@board) until false
	end

	def play(board)
		puts "Input starting row:"
		s_row = gets.chomp.to_i
		puts "Input starting column:"
		s_col = gets.chomp.to_i

		puts "Input destination row:"
		d_row = gets.chomp.to_i
		puts "Input destination column:"
		d_col = gets.chomp.to_i

		start = [s_row, s_col]
		destination = [d_row, d_col]

		board.move(start, dest)

		board.display
	end

end



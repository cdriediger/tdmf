class Test

	def initialize(a:"a", b:"b")
		puts "A: #{a}"
		puts "B: #{b}"
	end

end

Test.new(a: "1", b: "2")
Test.new(b: "2")

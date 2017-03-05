toast = Proc.new do
  puts Time.new
end

toast.call
sleep 1
toast.call
sleep 1
toast.call

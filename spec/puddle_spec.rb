require File.expand_path(File.join(File.dirname(__FILE__), 'spec_helper'))

require 'puddle'

describe Puddle do
  
  before do
    @num = 10
    @stuff = Proc.new { sleep(1); }
    @puddle = Puddle.new @num
  end
  
  it "should process stuff in parallel" do
    i = 0
    threads = @num.times.map { @puddle.process { sleep 1; i += 1 } }
    i.should == 0
    sleep 1.5
    i.should == @num
  end
  
  it "should block if too many threads" do
    i = 0
    threads = @num.times.map { @puddle.process { sleep 1; i += 1 } }
    i.should == 0
    thread = @puddle.process { sleep 1; i += 1 }
    i.should == @num # other threads should be done when @num + 1 st thread starts
    sleep 1.5
    i.should == @num+1
  end
  
  it "should finish all threads when drained" do
    i = 0
    threads = @num.times.map { @puddle.process { sleep 1; i += 1 } }
    @puddle.drain
    i.should == @num    
  end
  
  it "should not accept any more jobs when drained"
  
end
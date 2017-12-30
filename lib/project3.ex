defmodule Project3 do
    @moduledoc """
    Documentation for Project3.
    """
  
    @doc """
    Hello world.
  
    ## Examples
  
        iex> Project3.hello
        :world
  
    """
  
     use GenServer
   
  
  # def parse_args([]) do
  #   IO.puts "No parameters entered"
  # end

  # def parse_args(args) do
  #   {_, [numNodes,numRequests], _} = OptionParser.parse(args)
  #   n = String.to_integer(n)
  #   numrequests = String.to_integer(numrequests)
    
  # end


    def init(nodeid) do
      leafset = []
      routingtable = [[]]
      {:ok,[leafset,routingtable]}
    end
    
    def hello do
      :world
    end
  
    def test(n) do
      if(n>=1) do
        IO.puts n
        test(n-1)
      end
      IO.puts "hello"
    end
  

    def main(args) do
      n = String.to_integer(hd(args))
      numrequests = String.to_integer(List.last(args))
      # IO.puts n
      # IO.puts numrequests
      x=5
      nodeCreator(n,x,[],numrequests,n)
    end
  
  
  
    def nodeCreator(n,x,y,numrequests,nodes) do
      if(n>=1) do
        a=Integer.to_string(n)
        hash_val = Base.encode16(:crypto.hash(:sha256, a))
        processID = GenServer.start_link(__MODULE__,%{}, name: String.to_atom(String.slice(hash_val,0..x)))
        y = y ++ [String.slice(hash_val,0..x)]

        nodeCreator(n-1,x,y,numrequests,nodes)
      else
        x=Enum.sort(y)        #x is the sorted list
        #IO.inspect x
        lastindex = Enum.find_index(x, fn(a) -> a == List.last(x) end)
        #IO.puts lastindex
        Enum.each(x, fn(z) -> 
          currindex=Enum.find_index(x, fn(a) -> a == z end)
          #IO.puts currindex
          nextindex=currindex+1
          previndex=currindex-1
          leafset = []
          leafset = [leafMaker(z,x,previndex,nextindex,lastindex,8,leafset)]   # 8 is the number of greater and smaller neighbours
          #IO.inspect leafset
          charlist = ["0","1","2","3","4","5","6","7","8","9","A","B","C","D","E","F"]
          tableMaker(z,x,charlist,[],-1,charlist,nodes) # -1 is the slice counter
        end)
        pastryid = spawn(__MODULE__, :blackforest,[0,nodes*numrequests,0])
        Enum.each(x, fn(z) ->
          messageSender(x,z,numrequests,pastryid)
        end)
        IO.gets("")
      end
    end
    


    def blackforest(hops,total,temp) do
      receive do
        {count} ->
          #IO.puts "balle balle"
          hops = hops + count
          temp = temp+1
          IO.puts hops/total
        end
        if (temp<total) do
          blackforest(hops,total,temp)
        else
          IO.puts "Number of messages sent"
          IO.puts temp
          IO.puts "Average  number of hops:"
          IO.puts hops/total
        end
      end


    def messageSender(x,z,numrequests,pastryid) do
      #IO.puts z
      #GenServer.cast(String.to_atom(z),{:check,z})
      Enum.each(1..numrequests, fn(p) ->
        # IO.puts z
        # IO.puts String.to_atom(z)
        list = [0,z,Enum.random(x),pastryid]
        GenServer.cast(String.to_atom(z), {:message,list})
        #GenServer.cast(String.to_atom(z), {:messsage,0,z,Enum.random(x),pastryid})
      end)
    end
    
    #def handle_cast({:messsage,hops,current,destination,pastryid},state) do
    def handle_cast({:message,list},state) do  
      hops = Enum.at(list,0)
      current = Enum.at(list,1)
      destination = Enum.at(list,2)
      pastryid = Enum.at(list,3)

      
      if (String.to_atom(current) == String.to_atom(destination)) do
        pastrycompleter(hops,pastryid)
        {:noreply,state}
      else 
        # IO.puts "party cancel"
        # IO.inspect Enum.at(state,0)
        #IO.inspect destination
        if (Enum.member?((Enum.at(state,0)),destination)) do
          pastrycompleter(hops+1,pastryid)
        else
          routingalgo(current,destination,Enum.at(state,1),hops,pastryid)
          
        end

        {:noreply,state}
      end
      
    end
    
    def routingalgo(current,destination,routingtable,hops,pastryid) do
      {a,b} = slicer(routingtable,destination,3)
      x = Enum.at(routingtable,a)
      y = Enum.at(x,b)
      # IO.inspect {y,destination}
      # IO.puts y
      # IO.puts destination
      # z= String.to_atom(y)
      # IO.puts z
      
      list = [hops+1,y,destination,pastryid]
      GenServer.cast(String.to_atom(y),{:message,list})
    end
    
    

    def slicer(routingtable,destination,val) do
      #IO.puts "IDHAR AAYA"
      if (val>=0) do
        a = String.slice(destination,0..val)
        b = Enum.at(routingtable,val)
        list1=for n<-b, do: String.slice(n,0..val)  
        if(Enum.member?(list1,a)) do
          j = Enum.find_index(list1, fn(x) -> a == x end)
          #IO.puts "MIL GAYA"
          {val,j}
        else
          slicer(routingtable,destination,val-1)
        end
      end
    end

    def pastrycompleter(hops,pastryid) do
      send pastryid, {hops}
    end

    def tableMaker(z,x,charlist,routingtable,slicecount,appendedchars,n) do
  
      if (slicecount<3) do
        rowmaker(z,x,appendedchars,[],0,0,slicecount+1,[],n)
        #routingtable = routingtable ++ [rubber]
        #IO.inspect rubber
        appendedchars = appendCharlist(z,charlist,slicecount+1,0)
        #IO.inspect charlist
        tableMaker(z,x,charlist,routingtable,slicecount+1,appendedchars,n)
      else 
        #GenServer.cast(String.to_atom(z),{:check,z})
      end
    end

    def handle_cast({:check,z},state) do
      #IO.puts z
      IO.inspect state
      {:noreply,state}
    end

    def appendCharlist(z,charlist,sliceval,charindex) do
      a = String.slice(z,0..sliceval)
      list1=for n<-charlist, do: a<>n
      # IO.inspect z
      # IO.inspect a
      # IO.inspect list1
    end
  
    
    def rowmaker(z,x,charlist,list,charindex,nodeindex,sliceval,dummylist,n) do
      #IO.outs "Hello from rowmaker"
      # # IO.puts charlistval
      # #IO.puts slicednode
      # IO.puts compnode
      if (charindex<=15) do
        if (nodeindex<n) do 
          charlistval = Enum.at(charlist,charindex)
          compnode = Enum.at(x,nodeindex)
          slicednode = String.slice(compnode,0..sliceval)
          if (charlistval == slicednode && z != compnode) do
            dummylist = dummylist ++ [compnode]
            rowmaker(z,x,charlist,list,charindex,nodeindex+1,sliceval,dummylist,n)
          end
          if (charlistval == slicednode && z == compnode) do
            list = list ++ [" "]
            rowmaker(z,x,charlist,list,charindex+1,0,sliceval,[],n)
          end
          if (charlistval != slicednode) do  
            rowmaker(z,x,charlist,list,charindex,nodeindex+1,sliceval,dummylist,n)
          end
        else
          if (List.first(dummylist)) do
            #IO.inspect dummylist
            list = list ++ [Enum.random(dummylist)]
            rowmaker(z,x,charlist,list,charindex+1,0,sliceval,[],n)
          else
            list = list ++ [" "]
            rowmaker(z,x,charlist,list,charindex+1,0,sliceval,[],n)
          end
        end
      else
        #IO.puts z
        GenServer.cast(String.to_atom(z),{:routing_new,list})    
      end
    end
    
    def leafMaker(z,x,previndex,nextindex,lastindex,l,leafset) do
      #  IO.puts "leafmaker"
      #  IO.puts previndex
      #  IO.puts nextindex
      if (l>=1) do
        cond do
          (previndex<0) ->
            leafMaker(z,x,lastindex,nextindex,lastindex,l,leafset)
          
          (nextindex>lastindex) ->
            leafMaker(z,x,previndex,0,lastindex,l,leafset)
          
          (previndex>=0 && nextindex<=lastindex) ->
            # IO.puts previndex
            # IO.puts nextindex
            leafset = leafset ++ [Enum.at(x,previndex)]
            leafset = leafset ++ [Enum.at(x,nextindex)]
            leafMaker(z,x,previndex-1,nextindex+1,lastindex,l-1,leafset)
        end
      else
        #IO.puts z
        GenServer.cast(String.to_atom(z),{:leaf_new,leafset})
        leafset
      end
    end
  
    def handle_cast({:leaf_new,leafset},state) do
      state = List.replace_at(state,0,leafset)
      #IO.inspect state
      {:noreply, state}
    end
    
    def handle_cast({:routing_new,rtable},state) do
      temp = Enum.at(state,1)
      if (Enum.at(temp,0) == []) do
        temp = [rtable]
        state = List.replace_at(state,1,temp)
        # IO.puts "first"
        # IO.inspect (Enum.at(state,1))
        {:noreply,state}
      else
        temp = temp ++ [rtable]
        state = List.replace_at(state,1,temp)
        # IO.puts "2,3,4"
        # IO.inspect (Enum.at(state,1))
        {:noreply,state}
      end
    end
  end
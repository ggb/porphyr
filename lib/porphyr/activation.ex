defmodule Porphyr.Activation do
  alias ParseSKOS.HierarchyNode
  alias Porphyr.HierarchyOperations
  require Logger
  
  @decay_factor 0.4

  defp iterate_broader_nodes([], hierarchy, _activated_nodes), do: hierarchy
  defp iterate_broader_nodes([ current_id | broader_rest ], hierarchy, activated_nodes) do
    current_node = Dict.get(hierarchy, current_id)
    
    all_activated_children = Enum.reduce(activated_nodes, [], fn acc, { ele_id, value } -> 
      case Enum.find(current_node.narrower, fn child -> child == ele_id end) do
        nil -> 
          acc
        _ ->
          [ { ele_id, value } | acc ]
      end
    end)
    
    if length(all_activated_children) >= 2 do
      activated_avg = Enum.reduce(all_activated_children, 0, fn acc, { _id, value } -> acc + value end) / length(all_activated_children)
      updated_hierarchy = Dict.update(hierarchy, current_id, fn hnode -> %HierarchyNode{ hnode | value: hnode.value + activated_avg } end)
      iterate_broader_nodes(broader_rest, updated_hierarchy, activated_nodes)
    else
      iterate_broader_nodes(broader_rest, hierarchy, activated_nodes)
    end    
  end


  @doc """
  
  """
  def one_hop_activation(hierarchy, activated_nodes) do
    Enum.map(activated_nodes, fn { ele_id, _value } -> 
      %HierarchyNode{broader: ancestors} = Dict.get(hierarchy, ele_id)
      ancestors
    end)
    |> Enum.flatten
    |> Enum.uniq
    |> iterate_broader_nodes(hierarchy, activated_nodes)
  end
  
  @doc """
  
  """
  def activation_fun(:no, _decay) do
    fn oldVal, _newVal, _broader -> 
      oldVal
    end
  end
  
  @doc """
  
  """
  def activation_fun(:base, decay) do
    fn oldVal, newVal, _broader -> 
      oldVal + ( newVal * decay )
    end
  end
  
  @doc """

  """
  def activation_fun(:branch, decay) do
    fn oldVal, newVal, broader -> 
      # constant +1 because of arithmetic error...
      oldVal + ( newVal / ( broader * decay + 1) )
    end
  end
  
  @doc """

  """
  def generic_single_node({ identifier, newVal }, hierarchy, fun) do
    %HierarchyNode{ broader: broader, value: oldVal } = Dict.get(hierarchy, identifier)
    currentVal = fun.( oldVal, newVal, broader |> length )
    IO.puts "#{oldVal}, #{newVal}, #{currentVal}"

    updated_hierarchy = Dict.update!(hierarchy, identifier, fn hnode -> 
      %HierarchyNode{ hnode | value: currentVal } 
    end)    

    if broader == [] do
      updated_hierarchy
    else
      Enum.reduce(broader, updated_hierarchy, fn ele, acc -> 
        case Dict.get(acc, ele) do
          %HierarchyNode{ identifier: id } -> 
            generic_single_node({ id, currentVal }, acc, fun)
          nil -> 
            # Logger.debug ele
            #
            # In some cases, e. g. in the SWP-hierarchy their might appear references to 
            # nodes, that do not exist anymore. If that is the case, just return the 
            # current state of the hierarchy and be happy.
            acc
        end 
      end)
    end
  end  

  def get(concepts, hierarchy, activation, decay) when is_atom(activation) do
    get(concepts, hierarchy, activation_fun(activation, decay), decay)
  end

  def get(concepts, hierarchy, activation) when is_atom(activation) do
    get(concepts, hierarchy, activation, @decay_factor)
  end

  def get(concepts, hierarchy, activation) do    
    filled_hierarchy = HierarchyOperations.list_to_hierarchy(concepts, hierarchy)
    
    Enum.reduce(concepts, filled_hierarchy, fn { _label, descriptor }, acc -> 
      generic_single_node({ descriptor, 0 }, acc, activation)
    end)
    |> HierarchyOperations.vectorize_and_normalize
    |> Enum.sort(fn { _, fst }, { _, scd} -> fst > scd end)
  end
  
end

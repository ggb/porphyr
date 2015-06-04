defmodule Porphyr.OneHop do
  alias ParseSKOS.HierarchyNode
  alias Porphyr.HierarchyOperations

  defp calc_all_activated_children(activated_nodes, current_node) do
    try do
      Enum.reduce(activated_nodes, [], fn { _label, descriptor }, acc -> 
        case Enum.find(current_node.narrower, fn child -> child == descriptor end) do
          nil -> 
            acc
          _ ->
            [ { descriptor, current_node.value } | acc ]
        end
      end)
    rescue
      _ -> []
    end
  end

  defp iterate_broader_nodes([], hierarchy, _activated_nodes), do: hierarchy
  defp iterate_broader_nodes([ current_id | broader_rest ], hierarchy, activated_nodes) do
    current_node = Dict.get(hierarchy, current_id)

    all_activated_children = calc_all_activated_children(activated_nodes, current_node)    
    
    if length(all_activated_children) >= 2 do
      activated_avg = Enum.reduce(all_activated_children, 0, fn { _id, value }, acc -> acc + value end) / length(all_activated_children)
      updated_hierarchy = Dict.update!(hierarchy, current_id, fn hnode -> %HierarchyNode{ hnode | value: hnode.value + activated_avg } end)
      iterate_broader_nodes(broader_rest, updated_hierarchy, activated_nodes)
    else
      iterate_broader_nodes(broader_rest, hierarchy, activated_nodes)
    end    
  end


  @doc """
  
  """
  def one_hop_activation(hierarchy, activated_nodes) do
    Enum.map(activated_nodes, fn { _label, descriptor } -> 
      %HierarchyNode{broader: ancestors} = Dict.get(hierarchy, descriptor)
      ancestors
    end)
    |> List.flatten
    |> Enum.uniq
    |> iterate_broader_nodes(hierarchy, activated_nodes)
  end
  
  def get(concepts, hierarchy) do
    filled_hierarchy = HierarchyOperations.list_to_hierarchy(concepts, hierarchy)
    
    one_hop_activation(filled_hierarchy, concepts)
    |> HierarchyOperations.vectorize_and_normalize
    |> Enum.sort(fn { _, fst }, { _, scd} -> fst > scd end)
  end

end

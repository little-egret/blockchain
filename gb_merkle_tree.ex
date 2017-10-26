defmodule GbMerkleTrees do
  @moduledoc """
  由Krzysztof Jurewicz 的erlang版本修改而来。

  树的结构是`{元素数量, 树节点}`， 树节点又分为叶子节点，分支节点或空节点。
  每个非空的树节点都有键与哈希值。
  """
  @gb_merkle_trees_hash_algorithm :sha256
  
  ## 在 2^h(t) <= |t|^c 的情况下，树将会被平衡
  @c 2

  @type key :: binary
  @type value :: binary
  @type hash :: binary

  ## 使用嵌套tuple替代record来表示树以节约空间
  @type leaf_node :: {key, value, hash}
  @type inner_node :: {key, hash | :to_be_computed, left :: inner_node | leaf_node, right :: inner_node | leaf_node}
  @type tree_node :: leaf_node | inner_node | :empty
  @opaque tree :: {size :: non_neg_integer, root_node :: tree_node}
  @type merkle_proof :: {hash | merkle_proof,  hash | merkle_proof}


  @doc """
  从树中删除key，key必须在树上。
  """
  @spec delete(key, tree) :: tree
  def delete(key, {size, root_node}) do
    {size - 1, delete_1(key, root_node)}
  end


  @spec delete_1(key, tree_node) :: tree_node
  defp delete_1(key, {key, _, _}), do: :empty
  defp delete_1(key, {inner_key, _, left_node, right_node}) do
    if key < inner_key do
      case delete_1(key, left_node) do
        :empty ->
          right_node
        new_left_node ->
          {inner_key, inner_hash(node_hash(new_left_node), node_hash(right_node)), new_left_node, right_node}
      end
    else
      case delete_1(key, right_node) do
        :empty ->
          left_node
        new_right_node ->
          {inner_key, inner_hash(node_hash(left_node), node_hash(right_node)), left_node, new_right_node}
      end
    end
  end


  @spec empty() :: tree
  def empty(), do: {0, :empty}

  @spec size(tree) :: non_neg_integer
  def size({size, _}), do: size



  @spec leaf_hash(key, value) :: hash
  def leaf_hash(key, value) do
    key_hash = hash(key)
    value_hash = hash(value)
    hash(key_hash <> value_hash)
  end


  @spec inner_hash(hash, hash) :: hash
  def inner_hash(left_hash, right_hash) do
    hash(left_hash <> right_hash)
  end


  @spec node_hash(tree_node) :: hash | nil
  def node_hash(:empty), do: nil
  def node_hash({_, _, hash}), do: hash
  def node_hash({_, hash, _, _}), do: hash

  @compile :inline_list_funcs
  @compile {:inline, hash: 1}
  def hash(x), do: :crypto.hash(@gb_merkle_trees_hash_algorithm, x)

end

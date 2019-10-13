defmodule P7777776.ConfusionMatrix do
  @moduledoc """
  Documentation for P7777776ConfusionMatrix.


  ## Examples

      iex> P7777776ConfusionMatrix.blah()
      :ok

  """
  alias P7777776.ConfusionMatrix 
  defstruct classes: MapSet.new(), counts: %{}, tp: 0, total: 0, n_actual: %{}, n_predicted: %{}

  def new(), do: %ConfusionMatrix{}

  def add(%ConfusionMatrix{} = cm, actual, predicted, n \\ 1) do
    %ConfusionMatrix{
      classes: cm.classes |> MapSet.put(actual) |> MapSet.put(predicted),
      counts: inc(cm.counts, {actual, predicted}, n),
      total: cm.total + n,
      tp:
        cm.tp +
          if actual == predicted do
            n
          else
            0
          end,
      n_actual: inc(cm.n_actual, actual, n),
      n_predicted: inc(cm.n_predicted, predicted, n)
    }
  end

  defp inc(map, key, n), do: Map.update(map, key, n, fn c -> c + n end)

  def classes(%ConfusionMatrix{classes: classes}), do: MapSet.to_list(classes)
  def empty?(%ConfusionMatrix{total: total}), do: total == 0
  def total(%ConfusionMatrix{total: total}), do: total
  def tp(%ConfusionMatrix{tp: tp}), do: tp
  def tp(%ConfusionMatrix{counts: counts}, class), do: Map.get(counts, {class, class}, 0)

  def count(%ConfusionMatrix{counts: counts}, actual, predicted),
    do: Map.get(counts, {actual, predicted}, 0)

  def n_predicted(%ConfusionMatrix{n_predicted: n_predicted}, class),
    do: Map.get(n_predicted, class, 0)

  # aka support
  def n_actual(%ConfusionMatrix{n_actual: n_actual}, class), do: Map.get(n_actual, class, 0)

  # precision for a class: tp(class) / n_predicted(class)
  def precision(%ConfusionMatrix{} = cm, class) do
    case n_predicted(cm, class) do
      n when n > 0 -> tp(cm, class) / n
      _ -> nil
    end
  end

  # recall for a class: tp(class) / n_actual(class)
  def recall(%ConfusionMatrix{} = cm, class) do
    case n_actual(cm, class) do
      n when n > 0 -> tp(cm, class) / n
      _ -> nil
    end
  end

  def accuracy(%ConfusionMatrix{tp: tp, total: total}) when total > 0, do: tp / total
  def accuracy(_), do: nil
  def macro_avg_precision(cm), do: weighted_sum(cm, &precision/2, &uniformly_weighted/2)
  def macro_avg_recall(cm), do: weighted_sum(cm, &recall/2, &uniformly_weighted/2)
  def weighted_avg_precision(cm), do: weighted_sum(cm, &precision/2, &frequency_weighted/2)
  def weighted_avg_recall(cm), do: weighted_sum(cm, &recall/2, &frequency_weighted/2)

  defp uniformly_weighted(%ConfusionMatrix{classes: classes}, _), do: 1 / MapSet.size(classes)

  defp frequency_weighted(%ConfusionMatrix{total: total} = cm, class),
    do: n_actual(cm, class) / total

  defp weighted_sum(%ConfusionMatrix{classes: classes} = cm, metric, weight) do
    case MapSet.size(classes) do
      n when n > 0 ->
        classes
        |> Enum.map(fn class ->
          case metric.(cm, class) do
            nil -> 0
            m -> m * weight.(cm, class)
          end
        end)
        |> Enum.sum()

      _ ->
        nil
    end
  end
end

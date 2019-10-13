defmodule ConfusionMatrix.Printer do
  defimpl String.Chars, for: P7777776.ConfusionMatrix do
    import P7777776.ConfusionMatrix
    alias P7777776.ConfusionMatrix

    def to_string(%ConfusionMatrix{classes: classes, counts: counts} = cm) do
      cell_width =
        counts
        |> Enum.reduce(0, fn {_, c}, max -> max(c, max) end)
        |> Integer.to_string()
        |> String.length()

      label_width =
        classes
        |> Enum.reduce(0, fn c, max -> max(String.length(Atom.to_string(c)), max) end)

      sorted_classes =
        classes
        |> Enum.sort()

      a_header = String.duplicate(" ", label_width + 3) <> "actual"
      a_labels =
        sorted_classes
        |> Enum.map(fn c -> String.pad_leading(Atom.to_string(c), label_width) end)
        |> Enum.map(fn s -> String.to_charlist(s) end)
        |> Enum.zip()
        |> Enum.map(fn t -> Tuple.to_list(t) end)
        |> Enum.map(fn l ->
          l
          |> Enum.map(fn c -> List.to_string([c]) |> String.pad_leading(cell_width + 1) end)
          |> Enum.join("")
        end)
        |> Enum.map(fn s -> String.duplicate(" ", label_width + 2) <> s end)
        |> Enum.join("\n")

      rows =
        sorted_classes
        |> Enum.sort()
        |> Enum.map(fn predicted_class ->
          row(cm, sorted_classes, predicted_class, label_width, cell_width)
        end)
        |> Enum.join("\n")

      per_class_header = String.duplicate(" ", label_width) <> "  precision  recall"

      per_class =
        sorted_classes
        |> Enum.map(fn c ->
          {String.pad_leading(Atom.to_string(c), label_width), format(precision(cm, c)),
           format(recall(cm, c))}
        end)
        |> Enum.map(fn {c, p, r} -> ~s"#{c}      #{p}   #{r}" end)
        |> Enum.join("\n")

      avgs =
        [
          "              precision  recall",
          ~s"macro-avg         #{format(macro_avg_precision(cm))}   #{
            format(macro_avg_recall(cm))
          }",
          ~s"weighted-avg      #{format(weighted_avg_precision(cm))}   #{
            format(weighted_avg_recall(cm))
          }"
        ]
        |> Enum.join("\n")

      acc = ~s"                       accuracy\n                          #{format(accuracy(cm))}"

      [a_header, "\n", a_labels, "\n", rows, "\n\n", per_class_header, "\n", per_class, "\n\n", avgs, "\n\n", acc]
    end

    defp format(nil), do: " n/a "
    defp format(f), do: List.to_string(:io_lib.format("~5.3.0f", [f]))

    defp row(
           %ConfusionMatrix{counts: counts},
           actual_classes,
           predicted_class,
           label_width,
           cell_width
         ) do
      p_label =
        ("p_" <> Atom.to_string(predicted_class))
        |> String.pad_leading(label_width + 2)

      numbers =
        Enum.map(actual_classes, fn actual_class ->
          Map.get(counts, {actual_class, predicted_class}, 0)
          |> Integer.to_string()
          |> String.pad_leading(cell_width)
        end)
        |> Enum.join(" ")

      Enum.join([p_label, numbers], " ")
    end
  end
end

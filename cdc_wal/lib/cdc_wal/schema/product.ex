defmodule CdcWal.Schema.Product do
  alias CdcWal.Repo
  alias CdcWal.Schema.Product
  use Ecto.Schema
  import Ecto.Changeset

  schema "products_wal" do
    field(:name, :string)
    field(:price, :decimal)
  end

  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :price])
    |> validate_required([:name, :price])
    |> validate_number(:price, greater_than_or_equal_to: 0)
  end

  defp random_product() do
    changeset(%Product{}, %{name: random_name(), price: random_price()})
  end

  defp random_name,
    do:
      (Enum.to_list(?A..?Z) ++ Enum.to_list(?a..?z) ++ Enum.to_list(?0..?9))
      |> Enum.take_random(6)
      |> to_string()

  defp random_price, do: 1..10_000 |> Enum.to_list() |> Enum.take_random(1) |> Enum.at(0)

  def insert_record() do
    Repo.insert!(random_product())
  end

  def update_record() do
    random_product()
    |> Repo.insert!()
    |> changeset(%{price: 3000})
    |> Repo.update()
  end

  def delete_record() do
    product = Repo.insert!(random_product())
    Repo.delete!(product)
  end
end

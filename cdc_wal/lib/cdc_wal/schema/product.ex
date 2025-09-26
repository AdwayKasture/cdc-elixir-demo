defmodule CdcWal.Schema.Product do
  alias CdcWal.Schema.Product
  use Ecto.Schema
  import Ecto.Changeset

  schema "products_wal" do
    field :name, :string
    field :price, :decimal

  end

  # Optional: A basic changeset function is good practice
  def changeset(product, attrs) do
    product
    |> cast(attrs, [:name, :price])
    |> validate_required([:name, :price])
    |> validate_number(:price, greater_than_or_equal_to: 0)
  end


  def random_product() do
    changeset(%Product{},%{name: random_name(),price: random_price()})
  end

  def random_name,do: Enum.to_list(?A..?Z) ++ Enum.to_list(?a..?z) ++ Enum.to_list(?0..?9) |> Enum.take_random(6)|> to_string()

  def random_price,do: 1..10_000 |> Enum.to_list()|> Enum.take_random(1)|>Enum.at(0)
  
end

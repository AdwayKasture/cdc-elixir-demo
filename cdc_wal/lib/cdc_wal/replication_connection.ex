defmodule CdcWal.ReplicationConnection do
  use Postgrex.ReplicationConnection
  import CdcWal.Protocol
  alias CdcWal.Protocol.Decoder.Messages.Delete
  alias CdcWal.Protocol.Decoder.Messages.Commit
  alias CdcWal.Protocol.Decoder.Messages.Relation
  alias CdcWal.Protocol.Decoder.Messages.Begin
  alias CdcWal.Protocol.Decoder.Messages.Update
  alias CdcWal.Protocol.Decoder.Messages.Insert
  alias CdcWal.Protocol.Decoder
  alias CdcWal.Protocol.{KeepAlive, Write}

  def start_link(opts) do
    extra_opts = [auto_reconnect: true]
    Postgrex.ReplicationConnection.start_link(__MODULE__, :ok, opts ++ extra_opts)
  end

  @impl true
  def init(:ok) do
    {:ok, %{step: :disconnected}}
  end

  @impl true
  def handle_connect(state) do
    query = "CREATE_REPLICATION_SLOT postgrex TEMPORARY LOGICAL pgoutput NOEXPORT_SNAPSHOT"
    {:query, query, %{state | step: :create_slot}}
  end

  @impl true
  def handle_result(results, %{step: :create_slot} = state) when is_list(results) do
    query =
      "START_REPLICATION SLOT postgrex LOGICAL 0/0 (proto_version '1', publication_names 'products_wal_pub')"

    state = Map.put(state, :relations, %{})
    {:stream, query, [], %{state | step: :streaming}}
  end

  ## write message 
  @impl true
  def handle_data(data, state) when is_write(data) do
    %Write{message: message} = parse(data)

    message
    |> Decoder.decode_message()
    |> handle_event(state)
    |> noreply()
  end

  ## keep alive 
  @impl true
  def handle_data(data, state) when is_keep_alive(data) do
    %KeepAlive{reply: reply, wal_end: wal_end} = parse(data)
    wal_end = wal_end + 1

    message =
      case reply do
        :now -> standby_status(wal_end, wal_end, wal_end, reply)
        :later -> hold()
      end

    {:noreply, message, state}
  end

  defp handle_event(%Begin{final_lsn: {x_log_file, x_log_offset}}, state) do
    IO.puts("Commiting transaction at file #{x_log_file}, offset: #{x_log_offset}")
    state
  end

  defp handle_event(event = %Relation{}, state) do
    IO.puts("Storing relation for #{event.name}")
    put_in(state, [:relations, event.id], event)
  end

  defp handle_event(event = %Insert{relation_id: relation_id}, state) do
    {id, name, price} = event.tuple_data
    IO.puts("Inserting #{id},#{name},#{price} for #{Map.get(state.relations, relation_id).name}")
    state
  end

  defp handle_event(event = %Update{relation_id: relation_id}, state) do
    {old_id, old_name, old_price} = event.old_tuple_data
    {id, name, price} = event.tuple_data

    IO.puts(
      "Updated #{old_id},#{old_name},#{old_price} to #{id},#{name},#{price} for #{Map.get(state.relations, relation_id).name}"
    )

    state
  end

  defp handle_event(event = %Delete{relation_id: relation_id}, state) do
    {old_id, old_name, old_price} = event.old_tuple_data

    IO.puts(
      "Deleted #{old_id},#{old_name},#{old_price} for #{Map.get(state.relations, relation_id).name}"
    )

    state
  end

  defp handle_event(%Commit{lsn: {x_log_file, x_log_offset}}, state) do
    IO.puts("Commited event at file #{x_log_file},#{x_log_offset}")
    state
  end

  defp noreply(data), do: {:noreply, data}
end

defmodule Ash.Test.TracerTest.AsyncLoadTest do
  @moduledoc false
  use ExUnit.Case, async: false

  import ExUnit.CaptureLog
  require Ash.Query
  alias Ash.Test.Domain, as: Domain

  defmodule Author do
    @moduledoc false
    use Ash.Resource,
      domain: Domain,
      data_layer: Ash.DataLayer.Mnesia,
      authorizers: [
        Ash.Test.Authorizer
      ]

    actions do
      default_accept :*
      defaults [:read, :destroy, create: :*, update: :*]
    end

    attributes do
      uuid_primary_key :id

      attribute :name, :string do
        public?(true)
      end
    end

    calculations do
      calculate :name_length, :integer, fn records, _ ->
        Enum.map(records, fn record ->
          String.length(record.name)
        end)
      end
    end

    relationships do
      has_many :posts, Ash.Test.TracerTest.AsyncLoadTest.Post,
        destination_attribute: :author_id,
        public?: true
    end
  end

  defmodule Post do
    @moduledoc false
    use Ash.Resource,
      domain: Domain,
      data_layer: Ash.DataLayer.Mnesia

    actions do
      default_accept :*
      defaults [:read, :destroy, create: :*, update: :*]
    end

    attributes do
      uuid_primary_key :id

      attribute :title, :string do
        public?(true)
      end
    end

    relationships do
      belongs_to :author, Author, public?: true

      many_to_many :categories, Ash.Test.TracerTest.AsyncLoadTest.Category,
        through: Ash.Test.TracerTest.AsyncLoadTest.PostCategory,
        destination_attribute_on_join_resource: :category_id,
        source_attribute_on_join_resource: :post_id,
        public?: true
    end
  end

  defmodule PostCategory do
    @moduledoc false
    use Ash.Resource, domain: Domain, data_layer: Ash.DataLayer.Mnesia

    actions do
      default_accept :*
      defaults [:read, :destroy, create: :*, update: :*]
    end

    relationships do
      belongs_to :post, Post, primary_key?: true, allow_nil?: false, public?: true

      belongs_to :category, Ash.Test.TracerTest.AsyncLoadTest.Category,
        primary_key?: true,
        allow_nil?: false,
        public?: true
    end
  end

  defmodule Category do
    @moduledoc false
    use Ash.Resource, domain: Domain, data_layer: Ash.DataLayer.Mnesia

    actions do
      default_accept :*
      defaults [:read, :destroy, create: :*, update: :*]
    end

    attributes do
      uuid_primary_key :id

      attribute :name, :string do
        public?(true)
      end
    end

    relationships do
      many_to_many :posts, Post,
        through: PostCategory,
        destination_attribute_on_join_resource: :post_id,
        source_attribute_on_join_resource: :category_id,
        public?: true
    end
  end

  setup do
    capture_log(fn ->
      Ash.DataLayer.Mnesia.start(Domain, [Author, Post, Category, PostCategory])
    end)

    pid = self()

    events =
      [
        [:ash, :request_step],
        [:ash, :domain, :read],
        [:ash, :domain, :create],
        [:ash, :domain, :destroy],
        [:ash, :domain, :update],
        [:ash, :calculation],
        [:ash, :flow]
      ]
      |> Enum.flat_map(fn list ->
        [list ++ [:start], list ++ [:stop]]
      end)

    capture_log(fn ->
      :telemetry.attach_many(
        :test_handler,
        events,
        fn event_name, event_measurements, event_metadata, handler_config ->
          send(
            pid,
            {:telemetry, {event_name, event_measurements, event_metadata, handler_config}}
          )
        end,
        []
      )
    end)

    on_exit(fn ->
      :telemetry.detach(:test_handler)

      capture_log(fn ->
        :mnesia.stop()
        :mnesia.delete_schema([node()])
      end)
    end)

    start_supervised(
      {Ash.Test.Authorizer,
       strict_check: :authorized,
       check: {:error, Ash.Error.Forbidden.exception([])},
       strict_check_context: [:query]}
    )

    :ok
  end

  test "a simple read calls the tracer with the action" do
    Ash.read!(Post, tracer: Ash.Tracer.Simple)

    assert [
             %Ash.Tracer.Simple.Span{
               type: :action,
               name: "domain:post.read",
               metadata: %{
                 action: :read,
                 resource: Ash.Test.TracerTest.AsyncLoadTest.Post
               }
             }
           ] = Ash.Tracer.Simple.gather_spans()
  end

  test "a read with async loads calls the tracer for each" do
    Ash.Changeset.for_create(Post, :create, %{title: "title"}, tracer: Ash.Tracer.Simple)
    |> Ash.create!()

    assert [
             %Ash.Tracer.Simple.Span{
               type: :changeset,
               name: "changeset:post:create"
             },
             %Ash.Tracer.Simple.Span{
               type: :action,
               name: "domain:post.create",
               metadata: %{
                 action: :create,
                 domain: Ash.Test.Domain,
                 resource: Ash.Test.TracerTest.AsyncLoadTest.Post
               }
             }
           ] = Ash.Tracer.Simple.gather_spans()

    assert_receive {:telemetry,
                    {[:ash, :domain, :create, :start], %{system_time: _},
                     %{resource_short_name: :post}, _}}

    assert_receive {:telemetry,
                    {[:ash, :domain, :create, :stop], %{duration: _},
                     %{resource_short_name: :post}, _}}

    Post
    |> Ash.Query.load(:author)
    |> Ash.read!(tracer: Ash.Tracer.Simple)

    assert_receive {:telemetry,
                    {[:ash, :domain, :read, :start], %{system_time: _},
                     %{resource_short_name: :post}, []}}

    assert_receive {:telemetry,
                    {[:ash, :domain, :read, :start], %{system_time: _},
                     %{resource_short_name: :author}, []}}

    assert_receive {:telemetry,
                    {[:ash, :domain, :read, :stop], %{duration: _, system_time: _},
                     %{resource_short_name: :author}, []}}

    assert_receive {:telemetry,
                    {[:ash, :domain, :read, :stop], %{duration: _, system_time: _},
                     %{resource_short_name: :post}, []}}

    refute_receive {:telemetry, _}

    assert [
             %Ash.Tracer.Simple.Span{
               type: :action,
               name: "domain:post.read",
               metadata: %{
                 action: :read,
                 resource: Ash.Test.TracerTest.AsyncLoadTest.Post
               },
               spans: spans
             }
           ] = Ash.Tracer.Simple.gather_spans()

    assert Enum.any?(spans, &(&1.name == "domain:author.read"))
  end

  test "a read with calculation loads calls the tracer" do
    Ash.Changeset.for_create(Author, :create, %{name: "anc"})
    |> Ash.create!()

    assert_receive {:telemetry,
                    {[:ash, :domain, :create, :start], %{system_time: _},
                     %{resource_short_name: :author}, _}}

    assert_receive {:telemetry,
                    {[:ash, :domain, :create, :stop], %{duration: _},
                     %{resource_short_name: :author}, _}}

    Author
    |> Ash.Query.load(:name_length)
    |> Ash.read!(tracer: Ash.Tracer.Simple)

    assert [
             %Ash.Tracer.Simple.Span{
               type: :action,
               name: "domain:author.read",
               metadata: %{
                 action: :read,
                 resource: Ash.Test.TracerTest.AsyncLoadTest.Author
               },
               spans: [
                 %Ash.Tracer.Simple.Span{
                   name: "author:calculation:name_length",
                   type: :calculation,
                   metadata: %{
                     resource: Ash.Test.TracerTest.AsyncLoadTest.Author,
                     resource_short_name: :author,
                     calculation: "name_length",
                     authorize?: true
                   },
                   spans: []
                 }
                 | _
               ]
             }
           ] = Ash.Tracer.Simple.gather_spans()

    assert_receive {:telemetry,
                    {[:ash, :domain, :read, :start], %{system_time: _},
                     %{resource_short_name: :author}, []}}

    assert_receive {:telemetry,
                    {[:ash, :domain, :read, :stop], %{duration: _, system_time: _},
                     %{resource_short_name: :author}, []}}

    assert_receive {:telemetry,
                    {[:ash, :calculation, :start], %{system_time: _},
                     %{resource_short_name: :author, calculation: "name_length"}, []}}

    assert_receive {:telemetry,
                    {[:ash, :calculation, :stop], %{duration: _, system_time: _},
                     %{resource_short_name: :author, calculation: "name_length"}, []}}

    refute_receive {:telemetry, _}
  end
end
